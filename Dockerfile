FROM node:22-bookworm-slim AS build

WORKDIR /app
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

COPY package.json package-lock.json ./
RUN npm ci

COPY index.html vite.config.js ./
COPY public ./public
COPY src ./src
RUN npm run build

FROM node:22-bookworm-slim

WORKDIR /app
ENV NODE_ENV=production \
    CI=true \
    WRANGLER_SEND_METRICS=false \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    PORT=8788 \
    DATA_DIR=/data \
    PATH="/opt/wrangler/node_modules/.bin:${PATH}"

COPY package.json package-lock.json ./
RUN npm ci --omit=dev \
    && WRANGLER_VERSION="$(node -p "require('./package-lock.json').packages['node_modules/wrangler'].version")" \
    && mkdir -p /opt/wrangler \
    && cd /opt/wrangler \
    && npm init -y >/dev/null \
    && npm install "wrangler@${WRANGLER_VERSION}" \
    && npm cache clean --force \
    && rm -rf /root/.npm \
    && cd /app

COPY --from=build /app/dist ./dist
COPY functions ./functions
COPY src/shared/utils.js ./src/shared/utils.js
COPY docker ./docker
RUN chmod +x /app/docker/entrypoint.sh /app/docker/cron-loop.sh \
    && mkdir -p /data

EXPOSE 8788
VOLUME ["/data"]
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=5 \
    CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||8788)+'/').then(r=>process.exit(r.status<500?0:1)).catch(()=>process.exit(1))"
ENTRYPOINT ["/app/docker/entrypoint.sh"]
