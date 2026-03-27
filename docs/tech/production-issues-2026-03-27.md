# Issues de Producción — 2026-03-27

> Primer día de producción en OVH VPS. Documentación de todos los problemas encontrados y sus fixes.

## Configuración del servidor

| # | Issue | Causa | Fix | Status |
|---|---|---|---|---|
| 1 | `solid_cache_store` no disponible | Rails 8 default, gem no incluida | `redis_cache_store` en production.rb | ✅ |
| 2 | `solid_cable` adapter no disponible | Rails 8 default | `redis` adapter en cable.yml | ✅ |
| 3 | `database.yml` multi-DB (4 DBs) | Rails 8 default para Solid suite | Simplificado a `DATABASE_URL` | ✅ |
| 4 | Thruster no en Gemfile | Dockerfile usaba `./bin/thrust` | CMD usa Puma directamente | ✅ |
| 5 | `WhatsAppChannel` vs Zeitwerk | Zeitwerk espera `WhatsappChannel` | Renombrado clase + 32 archivos | ✅ |
| 6 | ActiveStorage sin config en prod | No había `config.active_storage.service` | Agregado `:local` | ✅ |
| 7 | Uploads se pierden en rebuild | No había Docker volume para `/rails/storage` | Volume `storage_data` agregado | ✅ |
| 8 | Permission denied en storage | Dockerfile no daba permisos a `/rails/storage` | `chown rails:rails storage` | ✅ |
| 9 | city-state gem permission denied | Gem escribe cache, usuario non-root | `chmod` en Dockerfile | ✅ |
| 10 | Initializers crashean sin DB | `site_configs_seed.rb` no capturaba `ConnectionNotEstablished` | Rescue ampliado | ✅ |
| 11 | CORS rechazaba agendity.co | Solo tenía `localhost:3000` | Agregados dominios de producción | ✅ |
| 12 | nginx.conf sin SSL ni upstream | `git reset --hard` lo revirtió | Comiteado al repo | ✅ |

## Funcionalidad

| # | Issue | Causa | Fix | Status |
|---|---|---|---|---|
| 13 | Employee schedules no se guardaban | Serializer no los retornaba, PUT los ignoraba | Serializer + `sync_schedules!` + `parse_time` | ✅ |
| 14 | Form muestra defaults, no datos reales | `buildDefaultSchedules` siempre usaba defaults | Usa datos del API, inactiva días sin schedule | ✅ |
| 15 | Auto-create schedules en nuevo empleado | Empleados nuevos sin schedules | `sync_schedules!` en create + fallback business_hours | ✅ |
| 16 | Disponibilidad retorna 0 slots | Empleado sin schedules en DB | Consecuencia del #13 | ✅ |
| 17 | "Validation failed" genérico en registro | Frontend mostraba error sin detalle | Parseo de `details` del API | ✅ |
| 18 | Password mínimo 6 vs 8 (Devise) | Zod decía 6, Devise requiere 8 | Unificado a 8 | ✅ |
| 19 | Check-in posible sin pago confirmado | No valida status `confirmed` | **Pendiente** | ⚠️ |
| 20 | Modal detrás de banners | z-index modal (50) < banners (57-59) | Modal z-index → 100 | ✅ |
| 21 | Botones de email no centrados | Inline styles sin `text-align: center` | `cta-wrapper` en todos los templates | ✅ |
| 22 | Puma se pega en primer request | Posible eager_load lento | Investigar | ⚠️ |

## Deploy / CI-CD

| # | Issue | Causa | Fix | Status |
|---|---|---|---|---|
| 23 | GitHub Actions SSH falla | Llave pública no en authorized_keys | Agregada | ✅ |
| 24 | `git reset --hard` borra nginx.conf | Config local no comiteada | Comiteada al repo | ✅ |
| 25 | `.env` no se borra con git clean | Ya está en `.gitignore` | OK | ✅ |
| 26 | SSL certs no montados en Docker | Faltaba copiar de `/etc/letsencrypt/` | `docker/ssl/` con certs | ✅ |

## Email

| # | Issue | Causa | Fix | Status |
|---|---|---|---|---|
| 27 | Emails llegan a spam | Dominio nuevo sin reputación | SPF + DKIM + DMARC configurados | ⏳ |
| 28 | Devise sender era `@agendity.com` | Hardcoded | Cambiado a ENV (`contacto@agendity.co`) | ✅ |

## Pendientes (no resueltos)

1. **Check-in no debería ser posible sin pago confirmado** (#19)
2. **Onboarding checklist card** — guiar negocios nuevos
3. **Puma se pega ocasionalmente** (#22) — investigar eager_load
4. **Quitar contenedor `web` (Next.js)** del VPS — frontend está en Vercel, no se necesita
