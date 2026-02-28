import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

/* ------------------------------------------------------------------ */
/*  Constants                                                          */
/* ------------------------------------------------------------------ */

const MAX_BASE64_BYTES = 4 * 1024 * 1024; // 4 MB
const AI_TIMEOUT_MS = 15_000;

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

interface RequestBody {
    image_base64: string;
    detail?: string;
    client_timestamp?: string;
    timezone?: string;
    device_id: string;
}

/* ------------------------------------------------------------------ */
/*  Helpers                                                            */
/* ------------------------------------------------------------------ */

function getEnv(key: string): string {
    const v = process.env[key];
    if (!v) throw new Error(`Missing env var: ${key}`);
    return v;
}

function stripDataUrl(raw: string): { mimeType: string; base64: string } {
    const match = raw.match(/^data:(.+);base64,(.+)$/);
    if (match) return { mimeType: match[1], base64: match[2] };
    // Assume raw base64 with JPEG default
    return { mimeType: 'image/jpeg', base64: raw };
}

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
    return createClient(getEnv('SUPABASE_URL'), getEnv('SUPABASE_SERVICE_ROLE_KEY'));
}

async function getRateLimit(supabase: SupabaseClient): Promise<number> {
    const { data } = await supabase
        .from('app_settings')
        .select('value')
        .eq('key', 'rate_limit_per_device_per_day')
        .single();
    return data?.value ?? 5;
}

async function checkAndIncrementRate(
    supabase: SupabaseClient,
    deviceId: string,
    limit: number,
): Promise<{ allowed: boolean; count: number }> {
    const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD

    // Try to upsert (increment or insert)
    const { data: existing } = await supabase
        .from('daily_rate_limits')
        .select('count')
        .eq('day', today)
        .eq('device_id', deviceId)
        .single();

    const currentCount = existing?.count ?? 0;

    if (currentCount >= limit) {
        return { allowed: false, count: currentCount };
    }

    if (existing) {
        await supabase
            .from('daily_rate_limits')
            .update({ count: currentCount + 1 })
            .eq('day', today)
            .eq('device_id', deviceId);
    } else {
        await supabase
            .from('daily_rate_limits')
            .insert({ day: today, device_id: deviceId, count: 1 });
    }

    return { allowed: true, count: currentCount + 1 };
}

async function logRequest(
    supabase: SupabaseClient,
    row: {
        device_id: string | null;
        ip: string | null;
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
  "protein": "integer – grams (maybe in vietnamese)",
  "carbs": "integer – grams (maybe in vietnamese)",
  "fats": "integer – grams (maybe in vietnamese)",
  "health_score": "integer 1-10",
  "confidence": "float 0-1",
  "warnings": ["string"] (maybe in vietnamese)
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
        throw new Error(`Gemini ${res.status}: ${text}`);
    }

    const payload = await res.json();
    const textPart = payload?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    if (!textPart) throw new Error('Empty Gemini response');
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
        throw new Error(`OpenAI ${res.status}: ${text}`);
    }

    const payload = await res.json();
    const content = payload?.choices?.[0]?.message?.content ?? '';
    if (!content) throw new Error('Empty OpenAI response');
    return extractJson(content);
}

/* ------------------------------------------------------------------ */
/*  Main handler                                                       */
/* ------------------------------------------------------------------ */

export default async function handler(
    req: VercelRequest,
    res: VercelResponse,
): Promise<void> {
    // --- Method guard ---
    if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
    }

    // --- Auth ---
    const secretHeader = req.headers['x-app-secret'];
    const secret = Array.isArray(secretHeader) ? secretHeader[0] : secretHeader;
    const expectedSecret = process.env.APP_PROXY_SECRET;
    if (!secret || !expectedSecret || secret !== expectedSecret) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
    }

    const supabase = getSupabase();
    const ip =
        (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() ??
        req.socket?.remoteAddress ??
        null;
    const startMs = Date.now();
    const aiModel = process.env.AI_MODEL ?? 'gemini-2.5-flash';
    const aiProvider = (process.env.AI_PROVIDER ?? 'gemini').toLowerCase();

    try {
        // --- Parse & validate body ---
        const body: RequestBody =
            typeof req.body === 'string' ? JSON.parse(req.body) : req.body;

        const { image_base64, device_id } = body;

        if (!image_base64 || typeof image_base64 !== 'string') {
            res.status(400).json({ error: 'image_base64 is required' });
            return;
        }
        if (!device_id || typeof device_id !== 'string') {
            res.status(400).json({ error: 'device_id is required' });
            return;
        }

        // --- Payload size guard ---
        const rawLen = Buffer.byteLength(image_base64, 'utf8');
        if (rawLen > MAX_BASE64_BYTES) {
            res.status(413).json({ error: 'Image too large' });
            return;
        }

        // --- Rate limit (per device) ---
        const rateLimit = await getRateLimit(supabase);
        const { allowed, count } = await checkAndIncrementRate(
            supabase,
            device_id,
            rateLimit,
        );
        if (!allowed) {
            await logRequest(supabase, {
                device_id,
                ip,
                status: 'rate_limited',
                model: aiModel,
                latency_ms: Date.now() - startMs,
                calories: null,
                confidence: null,
            });
            res.status(429).json({
                error: 'Daily scan limit reached',
                limit: rateLimit,
                used: count,
            });
            return;
        }

        // --- Strip data URL prefix ---
        const { mimeType, base64 } = stripDataUrl(image_base64);

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
            device_id,
            ip,
            status: 'success',
            model: aiModel,
            latency_ms: latencyMs,
            calories: result.calories,
            confidence: result.confidence,
        });

        res.status(200).json(result);
    } catch (err: unknown) {
        const latencyMs = Date.now() - startMs;
        const message = err instanceof Error ? err.message : 'Unknown error';

        // Full error in server logs only
        console.error('[analyze] Error:', message);

        await logRequest(supabase, {
            device_id: (req.body as RequestBody)?.device_id ?? null,
            ip,
            status: 'error',
            model: aiModel,
            latency_ms: latencyMs,
            calories: null,
            confidence: null,
        }).catch(() => { }); // swallow logging errors

        res.status(500).json({ error: 'Analysis failed' });
    }
}
