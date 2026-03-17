# Setup Local — Agendity

> Última actualización: 2026-03-16

## Prerrequisitos

| Software | Versión |
|---|---|
| Node.js | 22+ |
| Ruby | 3.4+ |
| Rails | 8.0+ |
| PostgreSQL | 14+ |
| Redis | 7+ |
| Docker | 20+ (para NATS) |

---

## 1. NATS Server (tiempo real)

NATS es el servidor de mensajería para actualizaciones en tiempo real. Es **opcional** — sin NATS, el sistema funciona con polling.

```bash
# Desde la raíz del proyecto (donde está docker/nats.conf)
cd /path/to/agendity

# Iniciar NATS con Docker
docker run -d --name agendity-nats \
  -p 4222:4222 \
  -p 8222:8222 \
  -v $(pwd)/docker/nats.conf:/etc/nats/nats.conf \
  nats:latest \
  -c /etc/nats/nats.conf

# Verificar que está corriendo
docker logs agendity-nats
# → Listening for websocket clients on ws://0.0.0.0:8222
```

| Puerto | Uso |
|---|---|
| `4222` | Protocolo NATS nativo (backend publica aquí) |
| `8222` | WebSocket (frontend se suscribe aquí) |

> Si no necesitas tiempo real, omite este paso. El frontend usará polling automáticamente.

---

## 2. Backend (agendity-api)

```bash
cd agendity-api

# Instalar dependencias
bundle install

# Crear archivo .env (ya existe, verificar)
cat .env
# DEVISE_JWT_SECRET_KEY=dev-jwt-secret-key-change-in-production
# AGENDITY_WEB_URL=http://localhost:3000
# REDIS_URL=redis://localhost:6379/0
# NATS_URL=nats://localhost:4222
# ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=...
# ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=...
# ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=...
#
# Para generar las claves de encriptacion:
# rails db:encryption:init

# Crear y migrar base de datos
rails db:create
rails db:migrate

# Cargar datos de prueba
rails db:seed

# Iniciar Redis (necesario para slot locking, Sidekiq y NATS publisher)
redis-server --daemonize yes

# Verificar tests
bundle exec rspec
# → 44 examples, 0 failures

# Iniciar servidor
rails server -p 3001

# (En otra terminal) Iniciar Sidekiq para jobs en background
bundle exec sidekiq
```

### Cuentas de demo (seed)

| Email | Password | Rol | Negocio |
|---|---|---|---|
| `carlos@barberia-elite.com` | `password123` | Owner | Barbería Elite (Plan Profesional) |
| `ana@salon-bella.com` | `password123` | Owner | Salón Bella (Plan Básico) |
| `miguel@freshcuts.com` | `password123` | Owner | Fresh Cuts (sin onboarding) |
| `admin@agendity.com` | `password123` | Admin | Panel ActiveAdmin |

### URLs del backend

| URL | Descripción |
|---|---|
| `http://localhost:3001/api/v1/` | API REST |
| `http://localhost:3001/admin` | Panel ActiveAdmin |
| `http://localhost:3001/up` | Health check |

---

## 3. Frontend (agendity-web)

```bash
cd agendity-web

# Instalar dependencias
npm install

# Crear archivo .env.local (ya existe, verificar)
cat .env.local
# NEXT_PUBLIC_API_URL=http://localhost:3001
# NEXT_PUBLIC_APP_URL=http://localhost:3000
# NEXT_PUBLIC_NATS_WS_URL=ws://localhost:8222

# Verificar tests
npm test
# → 28 tests passing (4 archivos)

# Verificar tipos
npx tsc --noEmit
# → 0 errors

# Iniciar servidor
npm run dev
```

### URLs del frontend

| URL | Descripción |
|---|---|
| `http://localhost:3000` | Landing page |
| `http://localhost:3000/login` | Login |
| `http://localhost:3000/register` | Registro |
| `http://localhost:3000/explore` | Explorar negocios (mapa + listado) |
| `http://localhost:3000/barberia-elite` | Página pública de negocio |
| `http://localhost:3000/dashboard/agenda` | Agenda (requiere login) |
| `http://localhost:3000/dashboard/services` | Servicios |
| `http://localhost:3000/dashboard/employees` | Empleados |
| `http://localhost:3000/dashboard/customers` | Clientes |
| `http://localhost:3000/dashboard/payments` | Gestión de pagos |
| `http://localhost:3000/dashboard/checkin` | Check-in de clientes (escaneo de ticket) |
| `http://localhost:3000/dashboard/reports` | Reportes |
| `http://localhost:3000/dashboard/reviews` | Reseñas |
| `http://localhost:3000/dashboard/qr` | Código QR |
| `http://localhost:3000/dashboard/notifications` | Notificaciones |
| `http://localhost:3000/dashboard/settings` | Configuración (perfil, logo, colores, horarios, pagos, notificaciones) |

---

## 4. Verificación rápida

```bash
# 1. Backend funcionando?
curl http://localhost:3001/up
# → 200 OK

# 2. API responde?
curl http://localhost:3001/api/v1/public/explore | python3 -m json.tool

# 3. Login funciona?
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"carlos@barberia-elite.com","password":"password123"}'

# 4. Frontend compila?
cd agendity-web && npm run build

# 5. NATS funcionando? (opcional)
docker logs agendity-nats | tail -5
```

---

## Variables de entorno

### Backend (.env)

| Variable | Descripción | Default |
|---|---|---|
| `DEVISE_JWT_SECRET_KEY` | Secret para firmar JWT | `dev-secret-key` |
| `AGENDITY_WEB_URL` | URL del frontend (para CORS) | `http://localhost:3000` |
| `REDIS_URL` | URL de Redis (Sidekiq + slot locking) | `redis://localhost:6379/0` |
| `NATS_URL` | URL del servidor NATS (tiempo real) | `nats://localhost:4222` |
| `DATABASE_URL` | URL de PostgreSQL (prod) | — |
| `SMTP_ADDRESS` | Servidor SMTP para emails | — |
| `SMTP_PORT` | Puerto SMTP | `587` |
| `SMTP_USERNAME` | Usuario SMTP | — |
| `SMTP_PASSWORD` | Contraseña SMTP | — |
| `SMTP_FROM_EMAIL` | Remitente de emails | `noreply@agendity.com` |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | Clave primaria para encriptacion de datos sensibles (Rails `encrypts`) | — (requerido) |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | Clave determinista para encriptacion (permite queries por columna) | — (requerido) |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | Salt para derivacion de claves de encriptacion | — (requerido) |

### Frontend (.env.local)

| Variable | Descripción | Default |
|---|---|---|
| `NEXT_PUBLIC_API_URL` | URL base del backend API | `http://localhost:3001` |
| `NEXT_PUBLIC_APP_URL` | URL base del frontend | `http://localhost:3000` |
| `NEXT_PUBLIC_NATS_WS_URL` | URL WebSocket de NATS (tiempo real) | `ws://localhost:8222` |

---

## Servicios completos para desarrollo

Para tener el sistema 100% funcional, necesitas estos procesos corriendo:

| Proceso | Comando | Obligatorio |
|---|---|---|
| PostgreSQL | `pg_ctl start` o servicio del sistema | Sí |
| Redis | `redis-server --daemonize yes` | Sí |
| Rails API | `rails server -p 3001` | Sí |
| Next.js | `npm run dev` | Sí |
| Sidekiq | `bundle exec sidekiq` | Sí (notificaciones, reminders) |
| NATS | `docker start agendity-nats` | No (polling como fallback) |

---

## Comandos útiles

```bash
# Backend
rails routes                    # Ver todas las rutas (71+ rutas API)
rails console                   # Consola interactiva
rails db:seed                   # Recargar datos de prueba
bundle exec rspec               # Correr tests (60+ specs)
rails server -p 3001            # Iniciar servidor
bundle exec sidekiq             # Iniciar worker de jobs (notificaciones, reminders)

# Encriptacion de datos de pago
rails db:encryption:init        # Generar claves de encriptacion (copiar al .env)
rails data:encrypt_payment_data # Encriptar datos de pago existentes (nequi, daviplata, bancolombia)

# Frontend
npm run dev                     # Dev server (Turbopack)
npm run build                   # Build producción
npm test                        # Correr tests (Vitest)
npm run test:watch              # Tests en watch mode
npx tsc --noEmit                # Type check

# NATS
docker start agendity-nats      # Iniciar NATS (si ya fue creado)
docker stop agendity-nats       # Detener NATS
docker logs agendity-nats       # Ver logs de NATS
docker rm agendity-nats         # Eliminar contenedor (para recrear)
```
