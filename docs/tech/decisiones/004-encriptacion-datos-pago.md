# ADR 004 — Encriptacion de datos de pago con Rails `encrypts`

> **Fecha:** 2026-03-16
> **Estado:** Aceptada
> **Contexto:** Los negocios registran datos de pago (Nequi, Daviplata, Bancolombia) para recibir pagos P2P de usuarios finales

## Problema

Los campos `nequi_phone`, `daviplata_phone` y `bancolombia_account` del modelo `Business` almacenan datos financieros sensibles en texto plano en la base de datos. Esto representa un riesgo de seguridad: si la base de datos es comprometida, todos los datos de pago quedan expuestos.

### Requisitos

1. **Encriptacion at rest:** Los datos deben estar encriptados en la base de datos
2. **Queries deterministas:** Se necesita poder buscar por estos campos (para admin/debug)
3. **Transparencia:** El codigo de la aplicacion no debe cambiar significativamente — la encriptacion debe ser transparente
4. **Filtrado en logs:** Los datos no deben aparecer en logs de Rails
5. **Serializer views:** Los endpoints publicos no deben exponer datos de pago; los endpoints autenticados si

## Decision

Usar **Rails 7+ `encrypts`** (Active Record Encryption) con encriptacion determinista para los 3 campos de pago del modelo Business.

### Implementacion

```ruby
# app/models/business.rb
class Business < ApplicationRecord
  encrypts :nequi_phone, deterministic: true
  encrypts :daviplata_phone, deterministic: true
  encrypts :bancolombia_account, deterministic: true
end
```

### Configuracion

3 variables de entorno requeridas (generadas con `rails db:encryption:init`):

| Variable | Proposito |
|---|---|
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | Clave primaria para encriptar/desencriptar |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | Clave para encriptacion determinista (permite queries) |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | Salt para derivacion de claves |

### Filtrado en logs

```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :nequi_phone, :daviplata_phone, :bancolombia_account
]
```

### Serializer views (3 niveles)

| Vista | Campos de pago | Uso |
|---|---|---|
| **public** | Excluidos | Pagina publica del negocio (`GET /api/v1/public/:slug`) |
| **with_payment** | Incluidos (desencriptados) | Respuesta de booking (`POST /api/v1/public/:slug/book`) para mostrar instrucciones de pago |
| **default** | Incluidos (desencriptados) | Dashboard del negocio (`GET /api/v1/business`) |

### Migracion de datos existentes

Rake task para encriptar datos existentes en texto plano:

```bash
rails data:encrypt_payment_data
```

La task lee cada Business, y al guardar, Rails automaticamente encripta los campos con `encrypts`.

## Alternativas consideradas

### Encriptacion manual con `attr_encrypted` gem

- **Rechazada:** Requiere columnas separadas (`encrypted_X`, `encrypted_X_iv`), migraciones adicionales, y manejo manual de claves. Rails `encrypts` es nativo, mas simple y mejor mantenido.

### Encriptacion a nivel de base de datos (pgcrypto)

- **Rechazada:** Acopla la encriptacion a PostgreSQL. Las claves viven en la DB o en queries SQL. Menos portable y mas complejo de gestionar. Rails `encrypts` mantiene las claves fuera de la DB.

### No encriptar (confiar en seguridad de infraestructura)

- **Rechazada:** Violacion de mejores practicas de seguridad. Los datos financieros deben estar encriptados at rest independientemente de la seguridad perimetral.

## Por que Rails `encrypts`

| Criterio | Rails `encrypts` | attr_encrypted | pgcrypto |
|---|---|---|---|
| Nativo de Rails | Si | No (gem externa) | No (extension DB) |
| Transparencia en codigo | Total (getter/setter automatico) | Parcial | Baja (SQL queries) |
| Queries deterministas | Si | Si | Si |
| Migracion de datos | Simple (re-save) | Requiere columnas nuevas | Requiere funciones SQL |
| Manejo de claves | ENV vars | ENV vars | DB config |
| Filtrado en logs | Integrado | Manual | N/A |

## Consecuencias

### Positivas

- **Datos protegidos at rest** — Si la DB es comprometida, los datos de pago son ilegibles
- **Cero cambios en logica de negocio** — `encrypts` es transparente para el resto del codigo
- **Queries posibles** — Encriptacion determinista permite `WHERE nequi_phone = ?`
- **Filtrado automatico** — Los datos no aparecen en logs de Rails
- **3 niveles de exposicion** — Public (sin datos), with_payment (instrucciones post-booking), default (dashboard completo)

### Negativas

- **3 ENV vars adicionales** — Se necesitan las claves de encriptacion en cada entorno (mitigado: se generan una vez y se configuran)
- **Performance minima** — Encriptar/desencriptar agrega microsegundos por operacion (despreciable)
- **Migracion requerida** — Los datos existentes deben ser re-encriptados con el rake task (mitigado: operacion unica)
- **Rotacion de claves** — Cambiar claves requiere re-encriptar todos los registros (mitigado: Rails soporta key rotation nativa)

## Archivos modificados

- `agendity-api/app/models/business.rb` — `encrypts` en 3 campos
- `agendity-api/config/initializers/filter_parameter_logging.rb` — Filtrado de parametros
- `agendity-api/app/serializers/business_serializer.rb` — 3 views (public, with_payment, default)
- `agendity-api/lib/tasks/data.rake` — Task `data:encrypt_payment_data`
- `agendity-api/.env` — 3 nuevas variables de encriptacion
