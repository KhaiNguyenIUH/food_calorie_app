import { createRemoteJWKSet, jwtVerify, JWTPayload } from 'jose';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { z } from 'zod';

/* ------------------------------------------------------------------ */
/*  Edge Runtime config                                                */
/* ------------------------------------------------------------------ */

export const config = { runtime: 'edge' };

/* ------------------------------------------------------------------ */
/*  Constants                                                          */
/* ------------------------------------------------------------------ */

const MAX_DECODED_BYTES = 3 * 1024 * 1024; // 3 MB decoded
const AI_TIMEOUT_MS = 15_000;

const ALLOWED_MIME = new Set([
    'image/jpeg',
    'image/png',
    'image/webp',
]);

/* ------------------------------------------------------------------ */
/*  Environment helpers                                                */
/* ------------------------------------------------------------------ */

function getEnv(key: string): string {
    const v = process.env[key];
    if (!v) throw new Error(`Missing env var: ${key}`);
    return v;
}

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */

interface NutritionResult {
    name: string;
    calories: number;
    protein: number;
    carbs: number;
    fats: number;
    health_score: number;
    confidence: number;
    warnings: string[];
}

/* ------------------------------------------------------------------ */
/*  Zod request schema                                                 */
/* ------------------------------------------------------------------ */

const RequestSchema = z.object({
    image_base64: z.string().min(1, 'image_base64 is required'),
    detail: z.enum(['low', 'high', 'auto']).default('low'),
    client_timestamp: z.string().refine(
        (v) => !isNaN(Date.parse(v)),
        { message: 'client_timestamp must be valid ISO8601' },
    ),
    timezone: z.string().min(1, 'timezone is required'),
});

/* ------------------------------------------------------------------ */
/*  JWT verification                                                   */
/* ------------------------------------------------------------------ */

let _jwks: ReturnType<typeof createRemoteJWKSet> | null = null;

function getJwks(): ReturnType<typeof createRemoteJWKSet> {
    if (!_jwks) {
        const supabaseUrl = getEnv('SUPABASE_URL');
        _jwks = createRemoteJWKSet(
            new URL(`${supabaseUrl}/auth/v1/.well-known/jwks.json`),
        );
    }
    return _jwks;
}

interface VerifiedClaims {
    sub: string;
}

async function verifyJwt(authHeader: string | null): Promise<VerifiedClaims> {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new AuthError('Missing or malformed Authorization header');
    }

    const token = authHeader.slice(7);
    const supabaseUrl = getEnv('SUPABASE_URL');

    const { payload } = await jwtVerify(token, getJwks(), {
        issuer: `${supabaseUrl}/auth/v1`,
        audience: 'authenticated',
    });

    const role = (payload as JWTPayload & { role?: string }).role;
    if (role !== 'authenticated') {
        throw new AuthError('Invalid token role');
    }

    if (!payload.sub) {
        throw new AuthError('Token missing sub claim');
    }

    return { sub: payload.sub };
}

class AuthError extends Error {
    constructor(message: string) {
        super(message);
        this.name = 'AuthError';
    }
}

/* ------------------------------------------------------------------ */
/*  Hashing helpers                                                    */
/* ------------------------------------------------------------------ */

async function sha256(input: string): Promise<string> {
    const data = new TextEncoder().encode(input);
    const hash = await crypto.subtle.digest('SHA-256', data);
    return Array.from(new Uint8Array(hash))
        .map((b) => b.toString(16).padStart(2, '0'))
        .join('');
}

function extractIpPrefix(ip: string): string {
    // IPv4: /24 prefix
    if (ip.includes('.')) {
        const parts = ip.split('.');
        return parts.slice(0, 3).join('.') + '.0/24';
    }
    // IPv6: /56 prefix (first 4 groups)
    const groups = ip.split(':');
    return groups.slice(0, 4).join(':') + '::/56';
}

/* ------------------------------------------------------------------ */
/*  Data URL parsing                                                   */
/* ------------------------------------------------------------------ */

function parseDataUrl(raw: string): { mimeType: string; base64: string } {
    const match = raw.match(/^data:([^;]+);base64,(.+)$/s);
    if (!match) {
        throw new ValidationError('image_base64 must be a data URL (data:<mime>;base64,...)');
    }

    const mimeType = match[1];
    if (!ALLOWED_MIME.has(mimeType)) {
        throw new ValidationError(
            `Unsupported image type: ${mimeType}. Allowed: ${[...ALLOWED_MIME].join(', ')}`,
        );
    }

    return { mimeType, base64: match[2] };
}

class ValidationError extends Error {
    constructor(message: string) {
        super(message);
        this.name = 'ValidationError';
    }
}

/* ------------------------------------------------------------------ */
/*  Nutrition result normalization                                     */
/* ------------------------------------------------------------------ */

function normalize(raw: Record<string, unknown>): NutritionResult {
    const toInt = (v: unknown) => Math.max(0, Math.round(Number(v) || 0));
    const toFloat = (v: unknown) =>
        Math.max(0, Math.min(1, Number(v) || 0));

    return {
        name: String(raw.name || 'Unknown'),
        calories: toInt(raw.calories),
        protein: toInt(raw.protein),
        carbs: toInt(raw.carbs),
        fats: toInt(raw.fats),
        health_score: toInt(raw.health_score),
        confidence: toFloat(raw.confidence),
        warnings: Array.isArray(raw.warnings)
            ? raw.warnings.map((w: unknown) => String(w))
            : [],
    };
}

function extractJson(text: string): Record<string, unknown> {
    try {
        return JSON.parse(text);
    } catch {
        const start = text.indexOf('{');
        const end = text.lastIndexOf('}');
        if (start >= 0 && end > start) {
            return JSON.parse(text.slice(start, end + 1));
        }
        throw new Error('Failed to parse AI response as JSON');
    }
}

/* ------------------------------------------------------------------ */
/*  Supabase helpers                                                   */
/* ------------------------------------------------------------------ */

function getSupabase(): SupabaseClient {
    return createClient(
        getEnv('SUPABASE_URL'),
        getEnv('SUPABASE_SERVICE_ROLE_KEY'),
    );
}

interface RateLimitResult {
    allowed: boolean;
    reason?: string;
    subject_count: number;
    subject_limit: number;
    ip_count?: number;
    ip_limit?: number;
}

async function checkRateLimit(
    supabase: SupabaseClient,
    subject: string,
    ipPrefixHash: string,
    subjectLimit: number,
): Promise<RateLimitResult> {
    const { data, error } = await supabase.rpc('check_rate_limit', {
        p_subject: subject,
        p_ip_prefix_hash: ipPrefixHash,
        p_subject_limit: subjectLimit,
        p_ip_limit: 20,
    });

    if (error) {
        throw new Error(`Rate limit RPC failed: ${error.message}`);
    }

    return data as RateLimitResult;
}

async function getRateLimitSetting(supabase: SupabaseClient): Promise<number> {
    const { data } = await supabase
        .from('app_settings')
        .select('value')
        .eq('key', 'rate_limit_per_device_per_day')
        .single();
    return data?.value ?? 5;
}

async function logRequest(
    supabase: SupabaseClient,
    row: {
        subject_hash: string | null;
        ip_prefix_hash: string | null;
        status: string;
        model: string | null;
        latency_ms: number | null;
        calories: number | null;
        confidence: number | null;
    },
): Promise<void> {
    await supabase.from('scan_requests').insert(row);
}

/* ------------------------------------------------------------------ */
/*  AI provider calls                                                  */
/* ------------------------------------------------------------------ */

const NUTRITION_PROMPT = `You are a strict nutritionist API. Analyze the food/foods in the image and return ONLY valid JSON in the exact schema:
{
  "name": "string – name of the food (maybe in vietnamese), can be multiple food",
  "calories": "integer – total kcal",
  "protein": "integer – grams",
  "carbs": "integer – grams",
  "fats": "integer – grams",
  "health_score": "integer 1-10",
  "confidence": "float 0-1",
  "warnings": ["string"]
}`;

const GEMINI_SCHEMA = {
    type: 'OBJECT',
    properties: {
        name: { type: 'STRING' },
        calories: { type: 'INTEGER' },
        protein: { type: 'INTEGER' },
        carbs: { type: 'INTEGER' },
        fats: { type: 'INTEGER' },
        health_score: { type: 'INTEGER' },
        confidence: { type: 'NUMBER' },
        warnings: { type: 'ARRAY', items: { type: 'STRING' } },
    },
    required: [
        'name', 'calories', 'protein', 'carbs',
        'fats', 'health_score', 'confidence', 'warnings',
    ],
};

async function callGemini(
    base64: string,
    mimeType: string,
    model: string,
    apiKey: string,
): Promise<Record<string, unknown>> {
    const body = {
        contents: [
            {
                parts: [
                    { inline_data: { mime_type: mimeType, data: base64 } },
                    { text: NUTRITION_PROMPT },
                ],
            },
        ],
        generationConfig: {
            response_mime_type: 'application/json',
            response_schema: GEMINI_SCHEMA,
        },
    };

    const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey,
            },
            body: JSON.stringify(body),
            signal: AbortSignal.timeout(AI_TIMEOUT_MS),
        },
    );

    if (!res.ok) {
        const text = await res.text();
        throw new UpstreamError(`Gemini ${res.status}: ${text}`);
    }

    const payload = await res.json();
    const textPart = payload?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    if (!textPart) throw new UpstreamError('Empty Gemini response');
    return extractJson(textPart);
}

async function callOpenAI(
    base64: string,
    mimeType: string,
    model: string,
    apiKey: string,
): Promise<Record<string, unknown>> {
    const body = {
        model,
        messages: [
            {
                role: 'user',
                content: [
                    {
                        type: 'image_url',
                        image_url: { url: `data:${mimeType};base64,${base64}` },
                    },
                    { type: 'text', text: NUTRITION_PROMPT },
                ],
            },
        ],
        response_format: { type: 'json_object' },
        max_tokens: 1024,
    };

    const res = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(AI_TIMEOUT_MS),
    });

    if (!res.ok) {
        const text = await res.text();
        throw new UpstreamError(`OpenAI ${res.status}: ${text}`);
    }

    const payload = await res.json();
    const content = payload?.choices?.[0]?.message?.content ?? '';
    if (!content) throw new UpstreamError('Empty OpenAI response');
    return extractJson(content);
}

class UpstreamError extends Error {
    constructor(message: string) {
        super(message);
        this.name = 'UpstreamError';
    }
}

/* ------------------------------------------------------------------ */
/*  JSON response helper                                               */
/* ------------------------------------------------------------------ */

function jsonResponse(
    body: Record<string, unknown>,
    status: number,
    extraHeaders?: Record<string, string>,
): Response {
    return new Response(JSON.stringify(body), {
        status,
        headers: {
            'Content-Type': 'application/json',
            ...extraHeaders,
        },
    });
}

/* ------------------------------------------------------------------ */
/*  Main handler (Edge Runtime)                                        */
/* ------------------------------------------------------------------ */

export default async function handler(req: Request): Promise<Response> {
    // --- Method guard ---
    if (req.method !== 'POST') {
        return jsonResponse({ error: 'Method not allowed' }, 405);
    }

    // --- Auth: verify Supabase JWT ---
    let claims: VerifiedClaims;
    try {
        claims = await verifyJwt(req.headers.get('authorization'));
    } catch (err) {
        const message = err instanceof AuthError
            ? err.message
            : 'Unauthorized';
        return jsonResponse({ error: message }, 401);
    }

    const supabase = getSupabase();
    const ip =
        req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? 'unknown';
    const startMs = Date.now();
    const aiModel = process.env.AI_MODEL ?? 'gemini-2.5-flash';
    const aiProvider = (process.env.AI_PROVIDER ?? 'gemini').toLowerCase();

    // Hash identifiers for privacy
    const subjectHash = await sha256(claims.sub);
    const ipPrefix = extractIpPrefix(ip);
    const ipPrefixHash = await sha256(ipPrefix);

    try {
        // --- Parse & validate body ---
        const rawBody = await req.json();
        const parsed = RequestSchema.safeParse(rawBody);

        if (!parsed.success) {
            return jsonResponse({
                error: 'Validation failed',
                details: parsed.error.issues.map((i) => i.message),
            }, 400);
        }

        const { image_base64, detail } = parsed.data;

        // --- Parse data URL and validate mime ---
        const { mimeType, base64 } = parseDataUrl(image_base64);

        // --- Decoded size guard (3 MB) ---
        const decodedSize = Math.ceil(base64.length * 3 / 4);
        if (decodedSize > MAX_DECODED_BYTES) {
            return jsonResponse({ error: 'Image too large (max 3MB)' }, 413);
        }

        // --- Atomic rate limit ---
        let rateResult: RateLimitResult;
        try {
            const rateLimit = await getRateLimitSetting(supabase);
            rateResult = await checkRateLimit(
                supabase,
                claims.sub,
                ipPrefixHash,
                rateLimit,
            );
        } catch (err) {
            // Fail closed: if rate limiter is down, deny requests
            console.error('[analyze] Rate limiter unavailable:', err);
            await logRequest(supabase, {
                subject_hash: subjectHash,
                ip_prefix_hash: ipPrefixHash,
                status: 'limiter_error',
                model: aiModel,
                latency_ms: Date.now() - startMs,
                calories: null,
                confidence: null,
            }).catch(() => { });
            return jsonResponse(
                { error: 'Service temporarily unavailable' },
                503,
            );
        }

        if (!rateResult.allowed) {
            await logRequest(supabase, {
                subject_hash: subjectHash,
                ip_prefix_hash: ipPrefixHash,
                status: 'rate_limited',
                model: aiModel,
                latency_ms: Date.now() - startMs,
                calories: null,
                confidence: null,
            });
            return jsonResponse({
                error: 'Daily scan limit reached',
                limit: rateResult.subject_limit,
                used: rateResult.subject_count,
            }, 429, {
                'X-RateLimit-Limit': String(rateResult.subject_limit),
                'X-RateLimit-Remaining': String(
                    Math.max(0, rateResult.subject_limit - rateResult.subject_count),
                ),
            });
        }

        // --- Call AI ---
        const apiKey = getEnv('AI_API_KEY');
        let raw: Record<string, unknown>;

        if (aiProvider === 'openai') {
            raw = await callOpenAI(base64, mimeType, aiModel, apiKey);
        } else {
            raw = await callGemini(base64, mimeType, aiModel, apiKey);
        }

        const result = normalize(raw);
        const latencyMs = Date.now() - startMs;

        // --- Audit log ---
        await logRequest(supabase, {
            subject_hash: subjectHash,
            ip_prefix_hash: ipPrefixHash,
            status: 'success',
            model: aiModel,
            latency_ms: latencyMs,
            calories: result.calories,
            confidence: result.confidence,
        });

        return jsonResponse(result as unknown as Record<string, unknown>, 200, {
            'X-RateLimit-Limit': String(rateResult.subject_limit),
            'X-RateLimit-Remaining': String(
                Math.max(0, rateResult.subject_limit - rateResult.subject_count),
            ),
        });
    } catch (err: unknown) {
        const latencyMs = Date.now() - startMs;
        const message = err instanceof Error ? err.message : 'Unknown error';

        console.error('[analyze] Error:', message);

        await logRequest(supabase, {
            subject_hash: subjectHash,
            ip_prefix_hash: ipPrefixHash,
            status: 'error',
            model: aiModel,
            latency_ms: latencyMs,
            calories: null,
            confidence: null,
        }).catch(() => { });

        // Upstream AI errors → 502
        if (err instanceof UpstreamError) {
            return jsonResponse({ error: 'Upstream AI service error' }, 502);
        }

        // Validation errors → 400
        if (err instanceof ValidationError) {
            return jsonResponse({ error: message }, 400);
        }

        return jsonResponse({ error: 'Analysis failed' }, 500);
    }
}
