const secret = process.env.CRON_SECRET || '';
const port = process.env.PORT || '8788';

if (!secret) {
    process.exit(0);
}

const response = await fetch(`http://127.0.0.1:${port}/cron`, {
    headers: { Authorization: `Bearer ${secret}` },
});
const body = await response.text();
console.log(`[cron] ${response.status} ${body.slice(0, 300)}`);
