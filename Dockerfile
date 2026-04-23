FROM node:20-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    bash \
    git \
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

# These repos are cloned during build so deployment works even if submodules
# are not initialized in the root checkout.
ARG SIGNA_API_REPO_URL="https://github.com/josdndev/SignaApiv1.git"
ARG SIGNA_API_REF="master"
ARG SIGNA_WEB_REPO_URL="https://github.com/josdndev/SignaLife.git"
ARG SIGNA_WEB_REF="main"

RUN git clone --depth 1 --branch "${SIGNA_API_REF}" "${SIGNA_API_REPO_URL}" /app/SignaApiv1 \
    && git clone --depth 1 --branch "${SIGNA_WEB_REF}" "${SIGNA_WEB_REPO_URL}" /app/SignaLife

# Backend dependencies
RUN pip3 install --no-cache-dir -r /app/SignaApiv1/requirements.txt

# Frontend dependencies
WORKDIR /app/SignaLife
RUN npm ci

# Startup script from root repo
WORKDIR /app
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
