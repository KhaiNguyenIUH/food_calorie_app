import { createClient } from '@supabase/supabase-js';

export const config = { runtime: 'edge' };

function getEnv(key: string): string {
    const v = process.env[key];
    if (!v) throw new Error(`Missing env var: ${key}`);
    return v;
}

function jsonResponse(
    body: Record<string, unknown>,
    status: number,
): Response {
    return new Response(JSON.stringify(body), {
        status,
        headers: { 'Content-Type': 'application/json' },
    });
}

export default async function handler(req: Request): Promise<Response> {
    if (req.method !== 'GET' && req.method !== 'POST') {
        return jsonResponse({ error: 'Method not allowed' }, 405);
    }

    // Auth: cron secret
    const cronSecret = req.headers.get('x-cron-secret');
    const expected = process.env.CRON_SECRET;
    if (!cronSecret || !expected || cronSecret !== expected) {
        return jsonResponse({ error: 'Unauthorized' }, 401);
    }

    const supabase = createClient(
        getEnv('SUPABASE_URL'),
        getEnv('SUPABASE_SERVICE_ROLE_KEY'),
    );

    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 30);
    const cutoffIso = cutoff.toISOString();
    const cutoffDate = cutoffIso.slice(0, 10); // YYYY-MM-DD

    // Delete old scan_requests
    const { count: deletedScans } = await supabase
        .from('scan_requests')
        .delete({ count: 'exact' })
        .lt('created_at', cutoffIso);

    // Delete old rate limit rows
    const { count: deletedLimits } = await supabase
        .from('daily_rate_limits')
        .delete({ count: 'exact' })
        .lt('day', cutoffDate);

    return jsonResponse({
        deleted_scans: deletedScans ?? 0,
        deleted_limits: deletedLimits ?? 0,
        cutoff: cutoffIso,
    }, 200);
}
