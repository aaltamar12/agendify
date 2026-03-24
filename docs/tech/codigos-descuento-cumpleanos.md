# Codigos de Descuento y Campanas de Cumpleanos

> Ultima actualizacion: 2026-03-24
> Modelos: `DiscountCode`, `Customer#birth_date`
> Jobs: `BirthdayCampaignJob`

---

## Resumen

Los codigos de descuento permiten aplicar un beneficio economico (porcentaje o monto fijo) sobre el precio final de una reserva. Se crean manualmente por el negocio, o de forma automatica por campanas de cumpleanos. Se aplican **despues** de la tarifa dinamica y **antes** de los creditos.

**Orden de aplicacion de precios en `CreateAppointmentService`:**
```
precio base
  → tarifa dinamica (si aplica)
  → descuento por codigo (si aplica)
  → creditos del cliente (si aplica)
  → penalizacion pendiente (si aplica)
= precio final
```

---

## 1. Modelo: DiscountCode

### Schema

```sql
CREATE TABLE discount_codes (
  id bigint PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses(id),
  code varchar NOT NULL,                    -- ej: "CUMPLE-ABC123" (unico por negocio, case-insensitive)
  name varchar,                             -- nombre descriptivo, ej: "Cumpleanos Maria"
  discount_type varchar DEFAULT 'percentage', -- 'percentage' | 'fixed'
  discount_value decimal(10,2) NOT NULL,    -- % (0-100) o monto fijo en COP
  max_uses integer,                         -- null = usos ilimitados
  current_uses integer DEFAULT 0,           -- contador de usos realizados
  valid_from date,                          -- null = sin fecha de inicio
  valid_until date,                         -- null = sin fecha de fin
  active boolean DEFAULT true,
  source varchar,                           -- 'manual' | 'birthday'
  customer_id bigint REFERENCES customers(id), -- null = publico; presente = solo ese cliente
  timestamps
);

-- Indices
CREATE UNIQUE INDEX ON discount_codes(business_id, LOWER(code));
```

### Scopes

```ruby
scope :active,     -> { where(active: true) }
scope :valid_now,  -> { active.where("(valid_from IS NULL OR valid_from <= ?) AND (valid_until IS NULL OR valid_until >= ?)", Date.current, Date.current) }
scope :available,  -> { valid_now.where("max_uses IS NULL OR current_uses < max_uses") }
```

### Metodos clave

```ruby
code.usable?         # active? && !expired? && !exhausted?
code.expired?        # valid_until.present? && valid_until < Date.current
code.exhausted?      # max_uses.present? && current_uses >= max_uses
code.apply_to(price) # calcula el descuento; retorna el monto a restar (no mas que el precio)
code.record_use!     # increment!(:current_uses)
```

### Campos en Appointment (tracking)

```sql
discount_code_id bigint REFERENCES discount_codes(id)  -- codigo aplicado
discount_amount  decimal(12,2)                          -- monto descontado
original_price   decimal(12,2)                          -- precio antes del descuento (y antes de tarifa dinamica si hubo)
```

---

## 2. API Endpoints (negocio autenticado)

### GET /api/v1/discount_codes

Lista los codigos del negocio. Filtros opcionales: `?active=true`, `?source=birthday`.

```bash
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3001/api/v1/discount_codes?active=true"
```

**Response:**
```json
[
  {
    "id": 1,
    "code": "PROMO20",
    "name": "Promo apertura",
    "discount_type": "percentage",
    "discount_value": 20.0,
    "max_uses": 50,
    "current_uses": 12,
    "valid_from": "2026-03-01",
    "valid_until": "2026-04-30",
    "active": true,
    "source": "manual",
    "customer_id": null
  }
]
```

### POST /api/v1/discount_codes

Crea un nuevo codigo de descuento.

```bash
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "discount_code": {
      "name": "Descuento apertura",
      "discount_type": "percentage",
      "discount_value": 15,
      "max_uses": 100,
      "valid_from": "2026-04-01",
      "valid_until": "2026-04-30"
    }
  }' \
  "http://localhost:3001/api/v1/discount_codes"
```

Si no se envia `code`, el backend genera uno automaticamente (`SecureRandom.alphanumeric(8).upcase`).

### DELETE /api/v1/discount_codes/:id

Elimina un codigo.

---

## 3. Endpoint publico de validacion

### GET /api/v1/public/:slug/validate_code?code=PROMO20

Sin autenticacion. Valida si un codigo existe y esta disponible para el negocio.

```bash
curl "http://localhost:3001/api/v1/public/barberia-elite/validate_code?code=PROMO20"
```

**Response valido:**
```json
{
  "valid": true,
  "discount_type": "percentage",
  "discount_value": 20.0,
  "name": "Promo apertura"
}
```

**Response invalido:**
```json
{ "valid": false }
```

---

## 4. Aplicacion en el booking flow

### Frontend (flujo de reserva publica)

En el paso 5 (Confirmacion), el usuario puede ingresar un codigo de descuento:
- Input de texto + boton "Aplicar"
- Al hacer click, llama a `GET /api/v1/public/:slug/validate_code?code=X`
- Si valido: muestra el descuento calculado y actualiza el desglose de precio
- Si invalido: muestra mensaje de error

**Desglose en confirmacion:**
```
Servicio:          $50,000
Tarifa dinamica:   +$10,000
Descuento (20%):   -$12,000
Creditos:          -$5,000
─────────────────────────
Total a pagar:     $43,000
```

### Backend (CreateAppointmentService)

Parametro recibido: `discount_code` (string, el codigo ingresado por el usuario).

```ruby
# Paso 1: buscar el codigo en los codigos disponibles del negocio
discount_code = business.discount_codes.available.find_by(code: params[:discount_code].upcase)

# Paso 2: si el codigo es especifico para un cliente, verificar que sea el mismo
if discount_code&.customer_id.present? && discount_code.customer_id != customer.id
  discount_code = nil  # no aplica
end

# Paso 3: aplicar descuento
if discount_code
  discount_amount = discount_code.apply_to(final_price)  # min(descuento calculado, precio)
  final_price -= discount_amount
  discount_code.record_use!
end
```

**Validaciones de seguridad:**
- El codigo debe pertenecer al negocio (scope por `business_id`)
- El codigo debe estar en el scope `available` (activo + vigente + con usos restantes)
- Si tiene `customer_id`, solo lo puede usar ese cliente exacto
- No puede descontar mas que el precio actual

---

## 5. Campanas de Cumpleanos (BirthdayCampaignJob)

### Descripcion

Job diario que corre a las 8am. Para cada negocio que tenga `birthday_campaign_enabled: true`, busca clientes con cumpleanos ese dia y les genera un codigo de descuento personalizado, enviando felicitacion por email (+ WhatsApp si el plan lo incluye).

### Campos en Business

```sql
birthday_campaign_enabled   boolean DEFAULT false
birthday_discount_pct       decimal(5,2) DEFAULT 10.0  -- % de descuento del codigo
birthday_discount_days_valid integer DEFAULT 7          -- cuantos dias es valido el codigo
```

### Campo en Customer

```sql
birth_date date   -- se captura en el booking flow; null si no se proporcionó
```

El `birth_date` se captura cuando el usuario reserva:
- Parametro opcional `customer_birth_date` en `POST /api/v1/public/:slug/book`
- Se guarda en el `Customer` si aun no tenia fecha (no sobreescribe)

### Flujo del job

```ruby
# app/jobs/birthday_campaign_job.rb
Business.active.where(birthday_campaign_enabled: true).find_each do |business|
  business.customers.with_email.with_birthday_on(today.month, today.day).find_each do |customer|
    # 1. Crear codigo personalizado
    code = business.discount_codes.create!(
      name: "Cumpleanos #{customer.name}",
      discount_type: "percentage",
      discount_value: business.birthday_discount_pct || 10,
      max_uses: 1,                                           # de un solo uso
      valid_from: Date.current,
      valid_until: Date.current + (business.birthday_discount_days_valid || 7).days,
      source: "birthday",
      customer: customer                                     # solo lo puede usar este cliente
    )

    # 2. Enviar felicitacion por email (+ WhatsApp si el plan lo incluye)
    Notifications::MultiChannelService.call(
      recipient: customer,
      template: :birthday_greeting,
      business: business,
      data: { discount_code: code, booking_url: "#{FRONTEND_URL}/#{business.slug}" }
    )

    # 3. Registrar en ActivityLog
    ActivityLog.log(business: business, action: "birthday_campaign_sent", ...)
  end
end
```

### Scopes en Customer

```ruby
scope :with_email,          -> { where.not(email: [nil, '']) }
scope :with_birthday_on,    ->(month, day) { where("EXTRACT(MONTH FROM birth_date) = ? AND EXTRACT(DAY FROM birth_date) = ?", month, day) }
```

### Caracteristicas del codigo generado

| Campo | Valor |
|-------|-------|
| `source` | `"birthday"` |
| `customer_id` | ID del cliente (solo puede usarlo ese cliente) |
| `max_uses` | 1 (un solo uso) |
| `discount_type` | `"percentage"` |
| `discount_value` | `business.birthday_discount_pct` (default 10%) |
| `valid_until` | Hoy + `business.birthday_discount_days_valid` dias (default 7) |

### Notificacion enviada

El `MultiChannelService` con template `:birthday_greeting` envia:
- **Email:** "Feliz cumpleanos [nombre]! Tienes un [X]% de descuento en [negocio]. Usa el codigo [CODE] al reservar. Valido hasta [fecha]."
- **WhatsApp** (si el plan lo incluye): mensaje equivalente via WhatsApp Business API

### Schedule

```yaml
# config/recurring.yml
birthday_campaign:
  class: BirthdayCampaignJob
  schedule: every day at 8am
```

---

## 6. ActiveAdmin

- **Codigos de descuento**: CRUD completo (`/admin/discount_codes`). Filtros por negocio, source, activo, fechas. Muestra CTR de uso (current_uses / max_uses).
- **Configuracion de campana**: desde el recurso Business en ActiveAdmin se puede activar/desactivar `birthday_campaign_enabled`, y ajustar `birthday_discount_pct` y `birthday_discount_days_valid`.

---

## Archivos clave

```
app/models/discount_code.rb
app/controllers/api/v1/discount_codes_controller.rb
app/controllers/api/v1/public/bookings_controller.rb  (validate_code action)
app/services/appointments/create_appointment_service.rb  (logica de aplicacion)
app/jobs/birthday_campaign_job.rb
app/admin/discount_codes.rb
db/migrate/*_create_discount_codes.rb
db/migrate/*_add_discount_fields_to_appointments.rb
agendity-web/src/app/[slug]/book/  (flujo de reserva, paso confirmacion)
```
