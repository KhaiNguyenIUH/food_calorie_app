import type { IncomingMessage, ServerResponse } from 'http';
import { createClient } from '@supabase/supabase-js';

function getEnv(key: string): string {
    const v = process.env[key];
    if (!v) throw new Error(`Missing env var: ${key}`);
    return v;
}

function sendJson(
    res: ServerResponse,
    status: number,
    body: Record<string, unknown>,
): void {
    res.writeHead(status, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(body));
}

export default async function handler(
    req: IncomingMessage,
    res: ServerResponse,
): Promise<void> {
    if (req.method !== 'GET' && req.method !== 'POST') {
        sendJson(res, 405, { error: 'Method not allowed' });
        return;
    }

    // Auth: cron secret
    const cronSecret = Array.isArray(req.headers['x-cron-secret'])
        ? req.headers['x-cron-secret'][0]
        : req.headers['x-cron-secret'];
    const expected = process.env.CRON_SECRET;
    if (!cronSecret || !expected || cronSecret !== expected) {
        sendJson(res, 401, { error: 'Unauthorized' });
        return;
    }

    const supabase = createClient(
        getEnv('SUPABASE_URL'),
        getEnv('SUPABASE_SERVICE_ROLE_KEY'),
    );

    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 30);
    const cutoffIso = cutoff.toISOString();
    const cutoffDate = cutoffIso.slice(0, 10);

    const { count: deletedScans } = await supabase
        .from('scan_requests')
        .delete({ count: 'exact' })
        .lt('created_at', cutoffIso);

    const { count: deletedLimits } = await supabase
        .from('daily_rate_limits')
        .delete({ count: 'exact' })
        .lt('day', cutoffDate);

    sendJson(res, 200, {
        deleted_scans: deletedScans ?? 0,
        deleted_limits: deletedLimits ?? 0,
        cutoff: cutoffIso,
    });
}
