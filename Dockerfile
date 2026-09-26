# =========================
# Stage 1: Build
# =========================
FROM node:24-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build


# =========================
# Stage 2: Runtime
# =========================
FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html

COPY nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p \
    /tmp/client_temp \
    /tmp/proxy_temp \
    /tmp/fastcgi_temp \
    /tmp/uwsgi_temp \
    /tmp/scgi_temp \
    && chown -R nginx:nginx \
       /usr/share/nginx/html \
       /tmp \
       /etc/nginx

USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:9999/ || exit 1

CMD ["nginx", "-g", "daemon off;"]