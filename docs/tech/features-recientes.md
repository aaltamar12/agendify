# Features recientes — Agendity

> Ultima actualizacion: 2026-03-24

Documentacion de las features implementadas en las etapas 10-15 y features adicionales.

---

## Multiples servicios por cita (appointment_services)

### Modelo de datos

```sql
CREATE TABLE appointment_services (
  id bigint PRIMARY KEY,
  appointment_id bigint NOT NULL REFERENCES appointments(id),
  service_id bigint NOT NULL REFERENCES services(id),
  price decimal(12,2),           -- precio al momento de la reserva
  duration_minutes integer,       -- duracion al momento de la reserva
  timestamps
);
CREATE UNIQUE INDEX ON appointment_services(appointment_id, service_id);
```

### Flujo
- El usuario selecciona multiples servicios en el booking flow
- El primer servicio es el "principal" (`appointment.service_id`)
- Los adicionales se guardan en `appointment_services`
- `CreateAppointmentService` calcula:
  - `total_duration` = primary + sum(additional durations) → para `end_time` y overlap check
  - `total_price` = primary + sum(additional prices) → antes de dynamic pricing y credits
- Frontend envia `additional_service_ids: [2, 5, 8]` al crear la reserva
- Backwards compatible: appointments existentes sin adicionales siguen funcionando

### Serializacion
La vista `:detailed` del `AppointmentSerializer` incluye:
```json
{
  "appointment_services": [
    { "id": 1, "service_id": 5, "service_name": "Cejas", "price": 8000, "duration_minutes": 10 }
  ]
}
```

---

## Aplicacion de creditos durante reserva

### Flujo del usuario
1. Usuario ingresa email en paso 4 ("Tus datos")
2. `customer_lookup` retorna `credit_balance` del cliente
3. En paso 5 (confirmacion): seccion verde "Tienes creditos disponibles"
4. Toggle para activar + input de monto (editable) + boton "Aplicar todo"
5. Desglose: Subtotal - Creditos = Total a pagar
6. Si creditos cubren todo: "Cubierto con creditos", cita pasa a `confirmed`

### Backend
`CreateAppointmentService` acepta `apply_credits` param:
```ruby
if apply_credits > 0
  credit_account.debit!(credits_to_use, type: :redemption)
  final_price -= credits_to_use
  # Si cubre todo → status: :confirmed (sin pago)
end
```

### Endpoint
`customer_lookup` ahora retorna:
```json
{ "name": "Migue", "email": "migue@email.com", "phone": "123", "credit_balance": 17500 }
```

### Vista de pagos del negocio
Cuando hay creditos aplicados, la card muestra:
- Precio original: $25,000
- Creditos: -$17,500
- **$7,500** (total a cobrar)

---

## Banners publicitarios (Etapa 15)

### Modelo: AdBanner

```sql
CREATE TABLE ad_banners (
  id bigint PRIMARY KEY,
  name varchar NOT NULL,
  placement varchar NOT NULL,      -- booking_summary, booking_confirmation
  image_url varchar,
  link_url varchar,
  alt_text varchar,
  active boolean DEFAULT true,
  priority integer DEFAULT 0,      -- mayor = mas prioridad
  start_date date,
  end_date date,
  impressions_count integer DEFAULT 0,
  clicks_count integer DEFAULT 0,
  timestamps
);
-- ActiveStorage: has_one_attached :image
```

### Placements
| Placement | Donde aparece |
|---|---|
| `booking_summary` | Confirmacion de reserva, antes del boton confirmar |
| `booking_confirmation` | Post-reserva, despues de las instrucciones de pago |

### API (publica, sin auth)
```bash
# Obtener banner para un placement
GET /api/v1/public/ad_banners?placement=booking_summary

# Tracking
POST /api/v1/public/ad_banners/:id/impression
POST /api/v1/public/ad_banners/:id/click
```

### ActiveAdmin
CRUD completo con upload de imagen, CTR% en index, filtros por placement y fechas.

### Diseno
- Fondo gris suave (gray-50), bordes sutiles
- Label "Publicidad" en texto micro (10px, gris)
- No invasivo: retorna null si no hay banner activo
- Responsive

---

## Metas financieras (Etapa 11) — Plan Inteligente

### Modelo: BusinessGoal

```sql
CREATE TABLE business_goals (
  id bigint PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses(id),
  goal_type varchar NOT NULL,     -- break_even, monthly_sales, daily_average, custom
  name varchar,
  target_value decimal(12,2) NOT NULL,
  period varchar DEFAULT 'monthly',
  fixed_costs decimal(12,2),      -- para break_even
  metadata jsonb DEFAULT '{}',
  active boolean DEFAULT true,
  timestamps
);
```

### Tipos de meta
| Tipo | Descripcion | Calculo |
|---|---|---|
| `break_even` | Punto de equilibrio | ingresos vs costos fijos |
| `monthly_sales` | Meta mensual | ingresos del mes vs target |
| `daily_average` | Promedio diario | ingresos/dias vs target diario |
| `custom` | Personalizada | ingresos vs target |

### GoalProgressService
Calcula para cada meta:
- `progress` (0-100%)
- `status`: achieved, on_track, behind, at_risk
- `suggestion`: texto accionable ("Necesitas X citas mas", "Tu promedio diario deberia ser $Y")

### API (Plan Inteligente)
```bash
GET /api/v1/goals              # listar metas activas
POST /api/v1/goals             # crear meta
PATCH /api/v1/goals/:id        # actualizar
DELETE /api/v1/goals/:id       # eliminar
GET /api/v1/goals/progress     # progreso con sugerencias
```

### Escalamiento a IA
Actualmente usa reglas simples. Diseñado para:
- Claude API analice metas vs datos historicos
- Sugiera acciones concretas
- Prediga si se cumplira basado en tendencia
- Recomiende ajustar meta si es irrealista

---

## Precios dinamicos visibles al usuario (Etapa 10)

### Endpoints publicos
```bash
# Preview de precio para una fecha
GET /api/v1/public/:slug/price_preview?service_id=X&date=Y

# Calendario de precios (14 dias)
GET /api/v1/public/:slug/price_calendar?service_id=X&from=Y&days=14
```

### Frontend
- **Calendario de precios** en el date picker: badges verdes (descuento) y naranjas (incremento) por dia
- **Icono zap** para dias con tarifa dinamica
- **Highlight** del dia mas economico
- **Desglose** en confirmacion: Servicio $50k + Tarifa dinamica +$10k = Total $60k
- **Nota** en servicios: "El precio puede variar segun el dia"

---

---

## Email de bienvenida (BusinessMailer#welcome)

Se dispara desde `Auth::RegisterService` justo despues de crear el negocio, usando `deliver_later` (Sidekiq):

```ruby
# app/services/auth/register_service.rb
BusinessMailer.welcome(business).deliver_later
```

**Contenido del email:**
- Bienvenida personalizada con el nombre del dueno
- Fecha de fin del trial (7 dias)
- Links de soporte: `SiteConfig.get("support_email")` y `SiteConfig.get("support_whatsapp")`
- Link de acceso a la app: `SiteConfig.get("app_url")`
- Mini-onboarding: resumen de los 6 pasos a completar (servicios, empleados, horarios, etc.)

**Mailer:**
```ruby
# app/mailers/business_mailer.rb
def welcome(business)
  @business         = business
  @owner            = business.owner
  @trial_ends_at    = business.trial_ends_at
  @support_email    = SiteConfig.get("support_email")
  @support_whatsapp = SiteConfig.get("support_whatsapp")
  @app_url          = SiteConfig.get("app_url")

  mail(to: @owner.email, subject: "¡Bienvenido a Agendity, #{@owner.name}! Tu negocio está listo")
end
```

Ningun valor esta hardcodeado. Todo se lee desde `SiteConfig`.

---

## QR en email de confirmacion de reserva

Cuando el admin aprueba el pago de una cita, se envia al cliente un email de confirmacion que incluye el **QR del ticket** embebido como imagen inline (no como adjunto de descarga).

### Implementacion

**Gema:** `rqrcode` (genera el PNG binary).

**Helper:**
```ruby
# app/helpers/qr_code_helper.rb
module QrCodeHelper
  def self.ticket_qr_png(appointment)
    url = "#{ENV['FRONTEND_URL']}/#{appointment.business.slug}/ticket/#{appointment.ticket_code}"
    qr = RQRCode::QRCode.new(url, level: :m)
    qr.as_png(size: 280, border_modules: 2).to_s  # retorna binary PNG
  end
end
```

**Mailer:**
```ruby
# app/mailers/appointment_mailer.rb
def booking_confirmed(appointment)
  # ...
  if appointment.ticket_code.present?
    attachments.inline["qr-ticket.png"] = {
      mime_type: "image/png",
      content: QrCodeHelper.ticket_qr_png(appointment)
    }
  end
  mail(to: customer.email, subject: "Tu cita en #{business.name} está confirmada — #{appointment.ticket_code}")
end
```

**En la vista HTML del email:**
```erb
<%= image_tag attachments['qr-ticket.png'].url, width: 200, alt: "QR de tu cita" %>
```

El QR encoda la URL del ticket: `{FRONTEND_URL}/{slug}/ticket/{ticket_code}`. Al escanear, el usuario llega directo a su ticket para hacer check-in.

---

## Employee checkin endpoint

El portal del empleado tiene un endpoint propio para hacer check-in por codigo de ticket, separado del endpoint publico.

### POST /api/v1/employee/checkin_by_code

Requiere autenticacion JWT de empleado. Acepta el codigo del ticket y delega a `Appointments::CheckinService`.

```bash
curl -X POST -H "Authorization: Bearer $EMPLOYEE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "ticket_code": "FE89E62168B5" }' \
  "http://localhost:3001/api/v1/employee/checkin_by_code"
```

**Parametros:**
- `ticket_code` (requerido) — codigo del ticket impreso o mostrado por el cliente
- `confirmed` (opcional, boolean) — para confirmar sustituto (ver abajo)
- `substitute_reason` (opcional) — razon si es check-in sustituto

**Casos:**
1. **Check-in normal**: el empleado logueado es el mismo asignado a la cita → `200 OK` con appointment actualizado
2. **Check-in sustituto**: el empleado es diferente al asignado → `409 Conflict` con `{ requires_confirmation: true, assigned_employee: { ... } }`. El frontend muestra un dialogo de confirmacion. Se re-envia con `confirmed: true` y `substitute_reason`.
3. **Cita no encontrada**: `404 Not Found`
4. **Cita no confirmada**: `422 Unprocessable Entity`

**Diferencia con `POST /api/v1/public/checkin_by_code`:**
- El endpoint publico (en el dashboard del negocio) acepta cualquier usuario autenticado como owner
- El endpoint de empleado (`/api/v1/employee/`) requiere el rol employee y scopa por `current_employee.business`

---

## formatCurrency (frontend)

Funcion de formato de moneda colombiana, usada en **todo el frontend** para mostrar precios, totales, creditos, reportes, etc.

```typescript
// agendity-web/src/lib/utils/format.ts
export function formatCurrency(amount: number): string {
  return (
    '$' +
    new Intl.NumberFormat('es-CO', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount)
  );
}
```

**Ejemplos:**
- `formatCurrency(50000)` → `"$50.000"`
- `formatCurrency(1500000)` → `"$1.500.000"`
- `formatCurrency(0)` → `"$0"`

**Nota de locale:** usa `es-CO` que formatea con puntos como separadores de miles (convencion colombiana), sin decimales. Redondea automaticamente si el valor tiene centavos.

**Ubicacion:** `agendity-web/src/lib/utils/format.ts`

Tiene tests en `agendity-web/src/lib/utils/__tests__/format.test.ts`.

---

## Codigos de descuento y campanas de cumpleanos

Ver documentacion completa en [`codigos-descuento-cumpleanos.md`](codigos-descuento-cumpleanos.md).

**Resumen:**
- Modelo `DiscountCode` con tipos `percentage` / `fixed`, usos maximos, vigencia, source (`manual` | `birthday`)
- CRUD: `GET/POST/DELETE /api/v1/discount_codes` (autenticado)
- Validacion publica: `GET /api/v1/public/:slug/validate_code?code=X`
- Aplicacion en booking flow: despues de tarifa dinamica, antes de creditos
- `BirthdayCampaignJob` corre diario a las 8am, genera codigos personalizados para clientes con cumpleanos hoy
- `Customer#birth_date` se captura opcionalmente en el booking flow
- Configuracion en Business: `birthday_campaign_enabled`, `birthday_discount_pct`, `birthday_discount_days_valid`

---

## Copys industry-agnostic y nuevos tipos de negocio

La plataforma fue actualizada para no mencionar especificamente "barberias y salones" en los textos publicos.

**Paginas actualizadas:**
- Landing page (hero, features, how-it-works)
- Pagina de registro (placeholder de nombre de negocio)
- Explore (`/explore` — texto de busqueda y filtros)
- SEO meta tags y Open Graph

**Tipos de negocio disponibles en registro:**
`barbershop`, `salon`, `spa`, `nail_studio`, `clinic`, `massage`, `cosmetology`, y otros.

**Mensaje clave:** "Para cualquier negocio que trabaje con citas" en lugar de "para barberias y salones".

El archivo `onboarding-testing-guide.md` refleja esto en la seccion de registro.

---

## Tabla de planes actualizada

| Feature | Basico ($8/mes) | Profesional ($17/mes) | Inteligente ($23/mes) |
|---|:---:|:---:|:---:|
| Agenda, calendario, reservas | Si | Si | Si |
| Servicios | 5 | Ilimitados | Ilimitados |
| Empleados | 3 | 10 | Ilimitados |
| Multiples servicios por cita | Si | Si | Si |
| Portal del empleado | Si | Si | Si |
| QR scanner (camara) | Si | Si | Si |
| Duracion visible al usuario | Si | Si | Si |
| Bloqueo dias cerrados | Si | Si | Si |
| Banners publicitarios | Si | Si | Si |
| Notificaciones email | Si | Si | Si |
| Notificaciones WhatsApp | No | Si | Si |
| Ticket VIP | No | Si | Si |
| Reportes avanzados + ganancias | No | Si | Si |
| Cierre de caja | No | Si | Si |
| Creditos / Cashback | No | Si | Si |
| Personalizacion marca | No | Si | Si |
| Destacado en Explore | No | Si | Si |
| Tarifas dinamicas (manual) | No | Si | Si |
| Precios dinamicos al usuario | No | Si | Si |
| **Verificado en Explore** | No | No | **Si** |
| **Tarifas dinamicas (sugerencias IA)** | No | No | **Si** |
| **Metas financieras** | No | No | **Si** |
| **Reconciliacion contable** | No | No | **Si** |
| **Analisis inteligente** | No | No | **Si** |
| Soporte | Email | Email + WA | Prioritario |
