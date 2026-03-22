# Agendity — Setup de desarrollo

## Requisitos

- Docker y Docker Compose
- Node.js 22+ y npm
- Ruby 3.4+ y Bundler
- Git

## Estructura de repos

```
agendity/
├── agendity-api/       # Rails 8 API
├── agendity-web/       # Next.js PWA
├── docker/             # Configs de NATS y Nginx
├── docker-compose.yml  # Servicios de infraestructura
├── .env                # Variables de entorno (no commitear)
└── README.md
```

## Primera vez

### 1. Variables de entorno

```bash
# Raíz (Docker Compose)
cp .env.example .env
# Ajusta valores si es necesario

# Rails API
cd agendity-api
cp .env.example .env
# Ajusta DATABASE_URL, NATS_URL, etc.

# Next.js
cd ../agendity-web
cp .env.example .env.local
```

### 2. Levantar infraestructura (Docker)

```bash
# Parar servicios locales si están corriendo en los mismos puertos
sudo systemctl stop postgresql
sudo systemctl stop keydb-server  # o redis-server

# Levantar PostgreSQL + Redis + NATS
sudo docker compose up postgres redis nats -d
```

### 3. Crear base de datos

```bash
cd agendity-api
rails db:create db:migrate db:seed
```

### 4. Instalar dependencias

```bash
# Rails
cd agendity-api
bundle install

# Next.js
cd ../agendity-web
npm install
```

### 5. Levantar la app

```bash
# Terminal 1 — Rails API (puerto 3001)
cd agendity-api
rails s -p 3001

# Terminal 2 — Sidekiq (background jobs)
cd agendity-api
bundle exec sidekiq

# Terminal 3 — Next.js (puerto 3000)
cd agendity-web
npm run dev
```

## Uso frecuente

### Levantar todo

```bash
# 1. Infraestructura
sudo docker compose up -d

# 2. Rails + Sidekiq + Next.js (en terminales separadas)
cd agendity-api && rails s -p 3001
cd agendity-api && bundle exec sidekiq
cd agendity-web && npm run dev
```

> `docker compose up -d` sin especificar servicios levanta solo los que no requieren build (postgres, redis, nats). Los servicios api/web/sidekiq/nginx necesitan `--build`.

### Apagar todo

```bash
# Parar Rails, Sidekiq y Next.js con Ctrl+C en cada terminal

# Parar infraestructura Docker
sudo docker compose down

# Para eliminar también los volúmenes (BORRA la BD):
sudo docker compose down -v
```

### Restaurar servicios locales (si no quieres usar Docker)

```bash
sudo docker compose down
sudo systemctl start postgresql
sudo systemctl start keydb-server  # o redis-server
```

## Logs

### NATS

```bash
# Logs en tiempo real
sudo docker logs -f agendity-nats-1

# Últimas 50 líneas
sudo docker logs --tail 50 agendity-nats-1
```

### PostgreSQL

```bash
sudo docker logs -f agendity-postgres-1
```

### Redis

```bash
sudo docker logs -f agendity-redis-1
```

### Rails API

Los logs se ven directamente en la terminal donde corre `rails s`. También en:

```bash
tail -f agendity-api/log/development.log
```

### Sidekiq

Los logs se ven directamente en la terminal donde corre `bundle exec sidekiq`.

## Puertos

| Servicio   | Puerto | Tipo   |
| ---------- | ------ | ------ |
| Next.js    | 3000   | Local  |
| Rails API  | 3001   | Local  |
| PostgreSQL | 5432   | Docker |
| Redis      | 6379   | Docker |
| NATS       | 4222   | Docker |
| NATS WS    | 8222   | Docker |

## Variables de entorno

### `.env` (raíz — Docker Compose)

| Variable                                   | Descripción                      | Default               |
| ------------------------------------------ | -------------------------------- | --------------------- |
| `POSTGRES_PASSWORD`                        | Password de PostgreSQL           | `agendity_dev`        |
| `NATS_AUTH_TOKEN`                          | Token de autenticación de NATS   | `dev_nats_token`      |
| `SECRET_KEY_BASE`                          | Secret de Rails                  | —                     |
| `DEVISE_JWT_SECRET_KEY`                    | Secret de JWT                    | —                     |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`     | Encryption key de ActiveRecord   | —                     |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | Deterministic encryption key   | —                     |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | Salt de derivación          | —                     |

### `agendity-api/.env`

| Variable         | Descripción                         | Ejemplo                                                     |
| ---------------- | ----------------------------------- | ----------------------------------------------------------- |
| `DATABASE_URL`   | Conexión a PostgreSQL               | `postgres://agendity:agendity_dev@localhost:5432/agendity_api_development` |
| `REDIS_URL`      | Conexión a Redis                    | `redis://localhost:6379/0`                                  |
| `NATS_URL`       | Conexión a NATS (incluye token)     | `nats://dev_nats_token@localhost:4222`                      |

### `agendity-web/.env.local`

| Variable                       | Descripción              | Ejemplo                    |
| ------------------------------ | ------------------------ | -------------------------- |
| `NEXT_PUBLIC_API_URL`          | URL del API              | `http://localhost:3001`    |
| `NEXT_PUBLIC_APP_URL`          | URL del frontend         | `http://localhost:3000`    |
| `NEXT_PUBLIC_NATS_WS_URL`     | URL WebSocket de NATS    | `ws://localhost:8222`      |
| `NEXT_PUBLIC_NATS_AUTH_TOKEN`  | Token de auth de NATS    | `dev_nats_token`           |

> **Importante:** El `NATS_AUTH_TOKEN` debe ser el mismo en los 3 archivos `.env`.

## Migrar BD local a Docker

Si ya tienes datos en PostgreSQL local y quieres pasarlos a Docker:

```bash
# 1. Dump de la BD local
pg_dump -U <tu_usuario> agendity_api_development --format=custom -f /tmp/agendity_dump.backup

# 2. Parar PostgreSQL local y levantar Docker
sudo systemctl stop postgresql
sudo docker compose up postgres -d

# 3. Crear la BD en Docker
PGPASSWORD=agendity_dev psql -h localhost -U agendity -d agendity_production -c "CREATE DATABASE agendity_api_development OWNER agendity;"

# 4. Restaurar (los warnings de OWNER son normales)
PGPASSWORD=agendity_dev pg_restore -h localhost -U agendity -d agendity_api_development /tmp/agendity_dump.backup

# 5. Verificar
PGPASSWORD=agendity_dev psql -h localhost -U agendity -d agendity_api_development -c "SELECT count(*) FROM appointments;"
```
