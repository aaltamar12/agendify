# ADR-001: Eliminar campos genéricos de pago en businesses

> **Fecha:** 2026-03-16
> **Estado:** Aceptada

## Contexto

La tabla `businesses` tenía dos campos genéricos de texto libre para pagos:
- `payment_instructions` (text) — instrucciones generales de pago
- `bank_account_info` (text) — datos bancarios en texto libre

Posteriormente se agregaron campos específicos por método de pago:
- `nequi_phone` (string)
- `daviplata_phone` (string)
- `bancolombia_account` (string)

Esto causaba duplicidad: el negocio podía tener datos en ambos lugares, y el frontend no sabía cuál priorizar.

## Decisión

Eliminar `payment_instructions` y `bank_account_info` de la tabla `businesses`.

Los métodos de pago se gestionan exclusivamente a través de los campos específicos:
- `nequi_phone` — Número de Nequi
- `daviplata_phone` — Número de Daviplata
- `bancolombia_account` — Número de cuenta Bancolombia

Las instrucciones de pago que ve el usuario final en el booking flow se generan automáticamente a partir de estos campos.

## Consecuencias

### Positivas
- Una sola fuente de verdad para datos de pago
- UI más clara: campos específicos en vez de textarea libre
- Más fácil validar (números de teléfono, cuentas)
- El booking flow puede mostrar botones específicos por método de pago

### Negativas
- Si en el futuro se necesita un método de pago no contemplado (ej: Efecty, Nequi Business, otro banco), se necesita agregar un nuevo campo o un modelo `PaymentMethod`
- Se pierde la flexibilidad del texto libre

### Migración
- `db/migrate/20260316201210_remove_deprecated_fields_from_businesses.rb`
- Archivos actualizados: `app/admin/businesses.rb`, `src/components/onboarding/step-payment-methods.tsx`, `src/lib/validations/onboarding.ts`

## Alternativa considerada

Mantener `payment_instructions` como campo adicional para instrucciones custom. Descartada porque agrega complejidad sin valor claro en el MVP.
