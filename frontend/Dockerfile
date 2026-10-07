# ============================================================
# E-Pupuk Frontend — Dockerfile (Multi-stage build)
# Stage 1: Build React/Vite app
# Stage 2: Serve dengan Nginx
# ============================================================

# --- Stage 1: Build ---
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --frozen-lockfile

# Copy source & build
COPY . .

# VITE_API_URL bisa di-inject saat build jika diperlukan
ARG VITE_API_URL=""
ENV VITE_API_URL=$VITE_API_URL

RUN npm run build

# --- Stage 2: Serve ---
FROM nginx:1.27-alpine AS runner

LABEL maintainer="E-Pupuk Mojokerto"
LABEL description="Frontend React untuk sistem e-Pupuk Kabupaten Mojokerto"

# Copy hasil build
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy konfigurasi Nginx custom
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost/favicon.svg || exit 1

CMD ["nginx", "-g", "daemon off;"]

