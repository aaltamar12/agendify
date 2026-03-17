# Variables de Entorno — Agendify

> **Ultima actualización:** 2026-03-17
>
> **Regla:** Cada vez que se agregue una nueva variable de entorno en cualquiera de los dos repos, este documento debe actualizarse.

---

## Frontend (agendify-web)

El frontend usa **3 variables custom** + `NODE_ENV`. Todas las `NEXT_PUBLIC_*` se embeben en el bundle de JavaScript en **build time** (no en runtime).

### Variables de aplicacion

| Variable | Requerida | Default | Archivo donde se usa | Descripcion |
|----------|:---------:|---------|----------------------|-------------|
| `NEXT_PUBLIC_API_URL` | Si | — | `src/lib/api/client.ts` | Base URL para todas las llamadas a la API via axios |
| `NEXT_PUBLIC_APP_URL` | Si | `https://agendify.com` | `src/app/dashboard/qr/page.tsx` | URL base para paginas publicas de reserva y generacion de QR |
| `NEXT_PUBLIC_NATS_WS_URL` | No | `ws://localhost:8222` | `src/lib/hooks/use-realtime.ts` | WebSocket de NATS para eventos real-time |
| `NODE_ENV` | No | Auto (Next.js) | `next.config.ts` | Condicional para deshabilitar PWA en desarrollo |

### Valores de desarrollo (.env.example)

```bash
NEXT_PUBLIC_API_URL=http://localhost:3001/api/v1
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_NATS_WS_URL=ws://localhost:8222
```

### Docker build args

En el `Dockerfile` del frontend se declaran como `ARG` y deben pasarse en build time:

```bash
docker build \
  --build-arg NEXT_PUBLIC_API_URL=https://api.agendify.co/api/v1 \
  --build-arg NEXT_PUBLIC_APP_URL=https://agendify.co \
  --build-arg NEXT_PUBLIC_NATS_WS_URL=wss://nats.agendify.co:8222 \
  .
```

---

## Backend (agendify-api)

### Variables criticas (obligatorias en produccion)

| Variable | Default (dev) | Archivo(s) | Descripcion |
|----------|---------------|------------|-------------|
| `DEVISE_JWT_SECRET_KEY` | `dev-jwt-secret-key-change-in-production` | `.env`, `config/initializers/devise.rb` | Clave secreta para firmar JWT tokens. En produccion tambien se busca en `Rails.application.credentials.devise_jwt_secret_key` |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | `dev-primary-key-change-in-prod-32ch` | `.env`, `config/application.rb` | Clave primaria para encriptacion de datos en reposo (nequi_phone, daviplata_phone, bancolombia_account) |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | `dev-deterministic-key-change-32ch` | `.env`, `config/application.rb` | Clave deterministica para busquedas en campos encriptados |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | `dev-salt-change-in-production-32c` | `.env`, `config/application.rb` | Salt para derivacion de claves de encriptacion |
| `REDIS_URL` | `redis://localhost:6379/0` | `.env`, `config/initializers/sidekiq.rb`, `app/services/bookings/slot_lock_service.rb` | Redis para Sidekiq, bloqueo temporal de slots y cache |
| `AGENDIFY_WEB_URL` | `http://localhost:3000` | `.env`, `config/initializers/cors.rb` | URL del frontend — se usa para configurar CORS |
| `NATS_URL` | `nats://localhost:4222` | `.env`, `app/services/realtime/nats_publisher.rb` | Conexion a NATS para publicar eventos real-time. Tiene **graceful degradation**: si NATS no esta disponible, el sistema sigue funcionando con polling |
| `AGENDIFY_API_DATABASE_PASSWORD` | — | `config/database.yml` | Contrasena de PostgreSQL. **Solo produccion** |
| `RAILS_MASTER_KEY` | — | `config/deploy.yml`, `Dockerfile` | Clave maestra para desencriptar `credentials.yml.enc`. **Solo produccion** |

### Variables opcionales (con defaults razonables)

| Variable | Default | Archivo(s) | Descripcion |
|----------|---------|------------|-------------|
| `API_HOST` | `http://localhost:3001` | `app/serializers/business_serializer.rb`, `app/serializers/payment_serializer.rb` | Host para generar URLs absolutas de ActiveStorage (logos, comprobantes de pago) |
| `FRONTEND_URL` | `https://agendify.co` | `app/controllers/api/v1/qr_controller.rb` | URL del frontend para links de reserva en QR. Tambien se busca en `Rails.application.config.x.frontend_url` |
| `RAILS_MAX_THREADS` | `3` (Puma) / `5` (DB pool) | `config/puma.rb`, `config/database.yml` | Threads del servidor y pool de conexiones a la base de datos |
| `PORT` | `3000` | `config/puma.rb` | Puerto donde escucha Puma |
| `WEB_CONCURRENCY` | — | `config/puma.rb`, `config/deploy.yml` | Numero de workers de Puma |
| `RAILS_LOG_LEVEL` | `info` | `config/environments/production.rb` | Nivel de logging en produccion |
| `JOB_CONCURRENCY` | `1` | `config/queue.yml` | Numero de procesos para Solid Queue |
| `PIDFILE` | — | `config/puma.rb` | Path al archivo PID de Puma |
| `SOLID_QUEUE_IN_PUMA` | — | `config/puma.rb`, `config/deploy.yml` | Habilita Solid Queue dentro del proceso Puma |
| `DB_HOST` | — | `config/deploy.yml` | Host de PostgreSQL (deploy con Kamal) |

### Variables internas / automaticas

Estas variables las establece el framework, Docker o CI. **No se configuran manualmente.**

| Variable | Quien la establece | Descripcion |
|----------|--------------------|-------------|
| `RAILS_ENV` | Rails / Docker | Entorno: `development`, `test`, `production` |
| `BUNDLE_GEMFILE` | Bundler | Path al Gemfile |
| `BUNDLE_DEPLOYMENT` | Dockerfile | Flag de deployment mode |
| `BUNDLE_PATH` | Dockerfile | Path de gemas instaladas |
| `BUNDLE_WITHOUT` | Dockerfile | Grupos de gemas excluidos |
| `CI` | GitHub Actions | Indica ejecucion en CI/CD |

### Valores de desarrollo (.env)

```bash
DEVISE_JWT_SECRET_KEY=dev-jwt-secret-key-change-in-production
AGENDIFY_WEB_URL=http://localhost:3000
REDIS_URL=redis://localhost:6379/0
NATS_URL=nats://localhost:4222
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=dev-primary-key-change-in-prod-32ch
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=dev-deterministic-key-change-32ch
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=dev-salt-change-in-production-32c
```

---

## Notas importantes

1. **Seguridad en produccion:** Las variables `DEVISE_JWT_SECRET_KEY`, `ACTIVE_RECORD_ENCRYPTION_*` y `RAILS_MASTER_KEY` deben ser valores unicos, largos y aleatorios. Nunca usar los defaults de desarrollo.

2. **NEXT_PUBLIC_ = publico:** Todas las variables con prefijo `NEXT_PUBLIC_` terminan en el JavaScript del cliente. Nunca poner secretos ahi.

3. **Graceful degradation:** `NATS_URL` y `REDIS_URL` (en slot_lock_service) tienen manejo de errores. Si el servicio no esta disponible, el sistema no se cae — usa polling como fallback.

4. **Build time vs runtime (frontend):** Las variables `NEXT_PUBLIC_*` se resuelven en build time. Si cambias un valor, debes re-buildear la imagen Docker del frontend.

5. **Credentials de Rails:** En produccion, `DEVISE_JWT_SECRET_KEY` tambien se puede configurar via `rails credentials:edit` en lugar de ENV. El codigo busca primero en credentials y luego en ENV.

---

## Resumen rapido

| Repo | Criticas | Opcionales | Internas | Total |
|------|:--------:|:----------:|:--------:|:-----:|
| **agendify-web** | 2 | 2 | 0 | 4 |
| **agendify-api** | 9 | 10 | 6 | 25 |
| **Total** | **11** | **12** | **6** | **29** |
