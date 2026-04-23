FROM node:20-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    bash \
    ca-certificates \
    curl \
    tini \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libjpeg-dev \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Backend dependencies
COPY SignaApiv1/requirements.txt /app/SignaApiv1/requirements.txt
RUN pip3 install --no-cache-dir -r /app/SignaApiv1/requirements.txt

# Frontend dependencies
COPY SignaLife/package*.json /app/SignaLife/
WORKDIR /app/SignaLife
RUN npm ci

# Application source
WORKDIR /app
COPY SignaApiv1 /app/SignaApiv1
COPY SignaLife /app/SignaLife
COPY docker/start-single.sh /app/docker/start-single.sh

# Build Next.js with internal API address for single-container deployment
WORKDIR /app/SignaLife
ENV NEXT_TELEMETRY_DISABLED=1
ENV INTERNAL_API_BASE_URL=http://127.0.0.1:8000
RUN npm run build && npm prune --omit=dev

WORKDIR /app
RUN chmod +x /app/docker/start-single.sh

EXPOSE 3000
EXPOSE 8000

# Persistent storage for SQLite
VOLUME ["/data"]

ENV API_PORT=8000
ENV WEB_PORT=3000
ENV DB_DATA_DIR=/data
ENV DB_FILE=/data/database.db
ENV NEXT_PUBLIC_API_BASE_URL=/api
ENV INTERNAL_API_BASE_URL=http://127.0.0.1:8000

ENTRYPOINT ["tini", "--"]
CMD ["/app/docker/start-single.sh"]
