# Despliegue Completo con un solo Dockerfile

## Build

```bash
docker build -t signa-proyect:single .
```

Este `Dockerfile` clona automáticamente `SignaLife` y `SignaApiv1` durante el build, así que funciona incluso si el proveedor no inicializa submódulos.

## Run (con DB persistente automática)

```bash
docker volume create signa_data
docker run -d \
  --name signa-proyect \
  -p 3000:3000 \
  -v signa_data:/data \
  signa-proyect:single
```

## Qué levanta

- Frontend Next.js en `http://localhost:3000`
- API FastAPI en `http://localhost:8000` (interna para el frontend)

## Base de datos

- Se usa SQLite persistente en `/data/database.db`
- El `Dockerfile` define `VOLUME /data`
- El contenedor crea el archivo automáticamente si no existe
