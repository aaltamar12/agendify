# ADR 006 — Semántica de estados de negocio (Business status)

> Fecha: 2026-03-17

## Contexto

El modelo Business tiene un enum `status` con 3 valores: `active`, `suspended`, `inactive`. Necesitamos definir claramente qué significa cada uno, quién los cambia, y qué efecto tienen en el sistema.

## Decisión

### Estados definidos

| Estado | Valor | Quién lo cambia | Significado |
|--------|-------|-----------------|-------------|
| `active` | 0 | Sistema (registro) / SuperAdmin | Negocio operando normal |
| `suspended` | 1 | SuperAdmin | Oculto del público, dashboard funcional |
| `inactive` | 2 | SuperAdmin | Completamente deshabilitado |

### `active` — Operación normal
- Aparece en explore, mapa, búsquedas públicas
- Página pública accesible (`/slug`)
- Reservas públicas habilitadas
- Dashboard del negocio funciona normal

### `suspended` — Oculto del público
- NO aparece en explore, mapa, búsquedas
- Página pública bloqueada (retorna 403)
- NO se pueden crear reservas públicas
- El dueño SÍ puede usar su dashboard normalmente
- El dueño SÍ puede crear citas manuales (walk-ins)
- Muestra badge "Oculto" y banner amarillo en el dashboard
- Caso de uso: barbería cierra por mantenimiento, remodelación, vacaciones, o desea pausar reservas online temporalmente

### `inactive` — Deshabilitado completamente
- NO aparece en explore, mapa, búsquedas
- Página pública bloqueada (retorna 403)
- NO se pueden crear reservas
- El dueño NO puede usar el dashboard — ve pantalla de "Cuenta desactivada"
- Caso de uso: negocio que viola términos, o que pidió desactivar su cuenta permanentemente

## Reglas importantes

1. **Solo el SuperAdmin cambia estados** — el dueño del negocio NO puede cambiar su propio status
2. **No pagar NO desactiva** — si un negocio no paga, se hace downgrade a Plan Básico (CheckExpiredSubscriptionsJob). Nunca se cambia el status del negocio por falta de pago
3. **Los datos se preservan siempre** — cambiar a `suspended` o `inactive` nunca borra datos del negocio
4. **El explore solo muestra `active`** — la query usa `WHERE status = 'active'`

## Consecuencias

- El SuperAdmin tiene control total de visibilidad sin afectar los datos del negocio
- Los negocios pueden pausar temporalmente su presencia pública sin perder configuración
- El flujo de pago/suscripción es completamente independiente del status del negocio
