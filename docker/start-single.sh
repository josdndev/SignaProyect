#!/usr/bin/env bash
set -Eeuo pipefail

API_PORT="${API_PORT:-8000}"
WEB_PORT="${WEB_PORT:-3000}"
DB_DATA_DIR="${DB_DATA_DIR:-/data}"
DB_FILE="${DB_FILE:-${DB_DATA_DIR}/database.db}"

mkdir -p "${DB_DATA_DIR}"
touch "${DB_FILE}"

export DATABASE_URL="${DATABASE_URL:-sqlite:////${DB_FILE#/}}"
export SAAS_DATABASE_URL="${SAAS_DATABASE_URL:-${DATABASE_URL}}"
export PORT="${API_PORT}"
export NEXT_PUBLIC_API_BASE_URL="${NEXT_PUBLIC_API_BASE_URL:-/api}"

echo "[entrypoint] DB file: ${DB_FILE}"
echo "[entrypoint] DATABASE_URL: ${DATABASE_URL}"
echo "[entrypoint] API_PORT: ${API_PORT} | WEB_PORT: ${WEB_PORT}"

cd /app/SignaApiv1
python3 -m uvicorn api.main:app --host 0.0.0.0 --port "${API_PORT}" --log-level info &
api_pid=$!

cd /app/SignaLife
./node_modules/.bin/next start -H 0.0.0.0 -p "${WEB_PORT}" &
web_pid=$!

cleanup() {
  for pid in "${api_pid}" "${web_pid}"; do
    if kill -0 "${pid}" >/dev/null 2>&1; then
      kill "${pid}" >/dev/null 2>&1 || true
    fi
  done
  wait || true
}

trap cleanup SIGINT SIGTERM

wait -n "${api_pid}" "${web_pid}"
exit_code=$?
cleanup
exit "${exit_code}"
