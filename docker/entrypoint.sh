#!/bin/sh
set -eu

PORT="${PORT:-8788}"
DATA_DIR="${DATA_DIR:-/data}"
mkdir -p "$DATA_DIR"

node --input-type=module <<'EOF'
import { writeFileSync } from 'node:fs';

const keys = [
    'ADMIN_PASSWORD',
    'COOKIE_SECRET',
    'CORS_ORIGINS',
    'MISUB_PUBLIC_URL',
    'MISUB_CALLBACK_URL',
];
const lines = [];
for (const key of keys) {
    const value = process.env[key];
    if (typeof value === 'string' && value.trim()) {
        lines.push(`${key}=${JSON.stringify(value)}`);
    }
}
writeFileSync('/app/.dev.vars', lines.length ? `${lines.join('\n')}\n` : '');
EOF

if [ -z "${ADMIN_PASSWORD:-}" ]; then
    echo "[misub] 未设置 ADMIN_PASSWORD。首次登录密码是 admin，登录后在「设置」里修改，新密码会写入数据卷。"
else
    echo "[misub] 已使用环境变量 ADMIN_PASSWORD。后台里修改密码不会覆盖这个环境变量。"
fi

cron_pid=""
if [ -n "${CRON_SECRET:-}" ]; then
    /app/docker/cron-loop.sh &
    cron_pid=$!
    echo "[misub] 已启用容器内定时任务，间隔 ${CRON_INTERVAL_SECONDS:-3600} 秒。请把同一密钥填到后台的 Cron Secret。"
fi

cd /app
wrangler pages dev /app/dist \
    --ip 0.0.0.0 \
    --port "$PORT" \
    --kv MISUB_KV \
    --d1 MISUB_DB \
    --persist-to "$DATA_DIR" \
    --compatibility-date 2024-04-01 \
    --compatibility-flag nodejs_compat \
    --log-level info &
app_pid=$!

stop() {
    kill "$app_pid" 2>/dev/null || true
    if [ -n "$cron_pid" ]; then
        kill "$cron_pid" 2>/dev/null || true
    fi
}
trap stop TERM INT
wait "$app_pid"
status=$?
stop
exit "$status"
