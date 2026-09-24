#!/bin/sh
set -eu

interval="${CRON_INTERVAL_SECONDS:-3600}"
case "$interval" in
    '' | *[!0-9]*) interval=3600 ;;
esac
if [ "$interval" -lt 30 ]; then
    interval=30
fi

sleep 20
while true; do
    node /app/docker/cron-tick.mjs || true
    sleep "$interval"
done
