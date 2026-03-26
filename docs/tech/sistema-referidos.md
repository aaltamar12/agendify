# Sistema de Referidos y Checkout de Suscripcion

> Ultima actualizacion: 2026-03-26
> Modelos: `ReferralCode`, `Referral`, `SubscriptionPaymentOrder`, `SiteConfig`

---

## Resumen

Agendity tiene un programa de referidos que permite a personas o empresas referir nuevos negocios a la plataforma y cobrar una comision cuando el negocio referido paga su primera suscripcion. El checkout de suscripcion es el flujo P2P mediante el cual un negocio elige su plan y sube un comprobante de pago para que el admin lo apruebe manualmente.

---

## 1. Sistema de Referidos

### Modelos

#### ReferralCode

Creado desde ActiveAdmin o auto-generado via endpoint publico. Representa a un referidor.

```sql
CREATE TABLE referral_codes (
  id bigint PRIMARY KEY,
  code varchar NOT NULL UNIQUE,      -- ej: "JUAN2026"
  referrer_name varchar NOT NULL,    -- nombre del referidor
  referrer_email varchar,
  referrer_phone varchar,
  commission_pct decimal(5,2) NOT NULL DEFAULT 10.0,  -- % de comision sobre el primer pago
  active boolean DEFAULT true,
  bank_account varchar,              -- cuenta bancaria para pago de comision
  bank_name varchar,                 -- nombre del banco
  breb_key varchar,                  -- clave Bre-B para pago de comision
  timestamps
);
```

#### Referral

Registro de cada negocio referido. Se crea automaticamente al registrarse con un codigo valido.

```sql
CREATE TABLE referrals (
  id bigint PRIMARY KEY,
  referral_code_id bigint NOT NULL REFERENCES referral_codes(id),
  business_id bigint NOT NULL REFERENCES businesses(id),
  status integer DEFAULT 0,          -- 0=pending, 1=activated, 2=paid
  commission_amount decimal(12,2),   -- calculado al activar (pct * primer pago)
  activated_at timestamp,
  paid_at timestamp,
  timestamps
);
```

**Estados:**
- `pending` — negocio registrado pero aun no ha pagado suscripcion
- `activated` — admin aprobo el primer pago de suscripcion; comision calculada
- `paid` — admin marco el referido como pagado al referidor

### Flujo de referido

```
1. Referidor se registra en /referral (publico) o es creado desde ActiveAdmin
2. Referidor comparte: agendity.co/register?ref=JUAN2026
3. Nuevo negocio abre el link → el frontend guarda el codigo en localStorage
4. Negocio completa el registro → el codigo se envia en el body del POST /api/v1/auth/register
5. Backend valida el codigo y crea Referral { status: :pending }
6. Negocio completa el trial (25 dias) y paga su suscripcion
7. Admin aprueba el comprobante → ApprovePaymentService:
   a. Crea Subscription activa
   b. Busca Referral pendiente para el business
   c. Calcula commission_amount = payment_amount * (commission_pct / 100)
   d. Actualiza Referral { status: :activated, activated_at: Time.current }
8. Admin paga al referidor fuera del sistema y marca desde ActiveAdmin:
   Referral → "Marcar como pagado" → { status: :paid, paid_at: Time.current }
```

### Registro publico de referidores

Cualquier persona puede registrarse como referidor desde la pagina publica `/referral`.

**Endpoint:** `POST /api/v1/public/referral_codes`

```json
// Request
{
  "referral_code": {
    "referrer_name": "Juan Perez",
    "referrer_email": "juan@example.com",
    "referrer_phone": "3001234567",
    "bank_account": "123456789",
    "bank_name": "Bancolombia",
    "breb_key": "juan@breb"
  }
}

// Response (201 Created)
{
  "code": "JUAN2026",
  "referrer_name": "Juan Perez",
  "referrer_email": "juan@example.com",
  "commission_pct": 10.0,
  "message": "Tu codigo de referido fue creado exitosamente"
}
```

**Caracteristicas:**
- Auto-generacion inmediata del codigo (sin aprobacion del admin)
- El codigo se genera automaticamente a partir del nombre del referidor + año
- Los datos de pago (`bank_account`, `bank_name`, `breb_key`) son opcionales al registrarse
- El admin puede editar los datos de pago despues desde ActiveAdmin
- Link en el footer de la landing page

### ActiveAdmin

| Recurso | Acciones |
|---------|----------|
| Codigos de Referido | CRUD (code, nombre, email, telefono, comision %, activo, bank_account, bank_name, breb_key) |
| Referidos | Lista con estado, negocio, codigo, comision calculada; filtros por estado/codigo; panel "Datos de Pago" en show |
| Accion en Referido | "Marcar como pagado" (transicion activated → paid); batch action "Marcar como pagados" |
| Panel Resumen | Metricas: total referidos, activados, comision pendiente, comision pagada |

---

## 2. Checkout de Suscripcion P2P

El checkout reemplaza el flujo manual anterior donde el admin creaba suscripciones directamente. Ahora el negocio elige su plan y sube el comprobante desde el dashboard.

### Pagina

`/dashboard/subscription/checkout`

Accesible para negocios en trial o con suscripcion vencida/suspension.

### Flujo del negocio

1. Ver los tres planes (Basico / Profesional / Inteligente) con precios y features
2. Seleccionar el plan deseado
3. Ver los datos de pago de Agendity (leidos desde `SiteConfig`):
   - Nequi: `SiteConfig.get(:payment_nequi)`
   - Bancolombia: `SiteConfig.get(:payment_bancolombia)`
   - Daviplata: `SiteConfig.get(:payment_daviplata)`
4. Realizar la transferencia desde su app bancaria
5. Subir captura del comprobante en el formulario
6. Enviar → `POST /api/v1/subscription/checkout`

### Backend: CheckoutService

```ruby
# app/services/checkout_service.rb
class CheckoutService < BaseService
  # Crea SubscriptionPaymentOrder con:
  # - business_id
  # - plan_id (plan elegido)
  # - amount (precio del plan)
  # - status: :pending
  # - proof (ActiveStorage: comprobante de pago)
  # Notifica al admin via email + in-app
end
```

### Modelo: SubscriptionPaymentOrder

```sql
CREATE TABLE subscription_payment_orders (
  id bigint PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses(id),
  plan_id bigint NOT NULL REFERENCES plans(id),
  amount decimal(12,2) NOT NULL,
  status integer DEFAULT 0,   -- 0=pending, 1=approved, 2=rejected
  rejection_reason text,
  approved_at timestamp,
  rejected_at timestamp,
  timestamps
);
-- ActiveStorage: has_one_attached :proof
```

### Aprobacion en ActiveAdmin

**approve_proof:**
1. Admin va a ActiveAdmin > Ordenes de Pago
2. Revisa el comprobante adjunto (imagen del recibo)
3. Click "Aprobar" → ejecuta `ApprovePaymentService`

**reject_proof:**
1. Admin hace click "Rechazar"
2. Ingresa razon del rechazo
3. Se notifica al negocio; puede subir nuevo comprobante

### Backend: ApprovePaymentService

```ruby
# app/services/approve_payment_service.rb
class ApprovePaymentService < BaseService
  def call
    ActiveRecord::Base.transaction do
      # 1. Crea Subscription activa para el negocio
      subscription = Subscription.create!(
        business: business,
        plan: order.plan,
        start_date: Date.current,
        end_date: Date.current + 30.days,
        expiry_alert_stage: 0
      )

      # 2. Activa el Referral si existe uno pendiente
      referral = Referral.pending.find_by(business: business)
      if referral
        commission = order.amount * (referral.referral_code.commission_pct / 100)
        referral.update!(
          status: :activated,
          commission_amount: commission,
          activated_at: Time.current
        )
      end

      # 3. Reactiva el negocio si estaba suspendido
      business.update!(status: :active) if business.suspended?

      # 4. Resetea trial_alert_stage
      business.update!(trial_alert_stage: 0)

      # 5. Actualiza la orden
      order.update!(status: :approved, approved_at: Time.current)

      # 6. Notifica al negocio (email + in-app + WhatsApp si aplica)
      notify_business!
    end
  end
end
```

---

## 3. SiteConfig

Modelo key/value para almacenar configuracion de plataforma editable desde ActiveAdmin sin necesidad de hacer deploy.

### Modelo

```sql
CREATE TABLE site_configs (
  id bigint PRIMARY KEY,
  key varchar NOT NULL UNIQUE,
  value text,
  description text,
  timestamps
);
```

### Seeds (claves disponibles)

| Key | Descripcion | Usado por |
|-----|-------------|-----------|
| `support_email` | Email de soporte al cliente | Todos los mailers, checkout |
| `support_whatsapp` | WhatsApp de soporte | `BusinessMailer#trial_expiry_alert`, `trial_ended_thank_you`, checkout |
| `admin_email` | Email del administrador (para notificaciones internas) | `AdminMailer`, jobs de alertas |
| `payment_nequi` | Numero Nequi de Agendity para recibir pagos de suscripcion | Checkout de suscripcion, `trial_ended_thank_you` |
| `payment_bancolombia` | Cuenta Bancolombia de Agendity para pagos de suscripcion | Checkout de suscripcion, `trial_ended_thank_you` |
| `payment_daviplata` | Numero Daviplata de Agendity para pagos de suscripcion | Checkout de suscripcion, `trial_ended_thank_you` |
| `app_url` | URL base de la aplicacion frontend | `BusinessMailer#welcome`, `trial_ended_thank_you` |
| `trm` | Tasa Representativa del Mercado (USD→COP) | Calculo de precios en COP, checkout, landing, ActiveAdmin |

### Uso en mailers

```ruby
# En cualquier mailer:
support_email = SiteConfig.get(:support_email)
payment_nequi = SiteConfig.get(:payment_nequi)
```

Ningun mailer tiene valores hardcoded. Todos leen desde `SiteConfig`.

### ActiveAdmin

En ActiveAdmin > Configuracion aparece la lista de todos los `SiteConfig` con edicion inline. Solo el superadmin puede modificarlos.

---

## 4. Error Codes en API

`ServiceResult` ahora incluye un campo `error_code` opcional para que el frontend pueda manejar errores especificos sin depender del texto del mensaje.

### ServiceResult

```ruby
class ServiceResult
  attr_reader :success, :data, :error, :error_code

  def initialize(success:, data: nil, error: nil, error_code: nil)
    @success = success
    @data = data
    @error = error
    @error_code = error_code
  end
end
```

### render_error en BaseController

```ruby
def render_error(message, status: :unprocessable_entity, code: nil)
  render json: { error: message, error_code: code }, status: status
end
```

### Codigos de error definidos

| Modulo | Codigo | Significado |
|--------|--------|-------------|
| auth | `EMAIL_TAKEN` | Email ya registrado |
| auth | `INVALID_CREDENTIALS` | Email o contrasena incorrectos |
| auth | `ACCOUNT_SUSPENDED` | Negocio suspendido |
| appointments | `SLOT_TAKEN` | Horario ya ocupado |
| appointments | `PAST_SLOT` | No se puede agendar en el pasado |
| appointments | `CLOSED_DAY` | El negocio esta cerrado ese dia |
| bookings | `INVALID_REF_CODE` | Codigo de referido invalido o inactivo |
| cash_register | `ALREADY_CLOSED` | Caja ya cerrada para ese dia |
| cash_register | `FUTURE_DATE` | No se puede cerrar caja de fecha futura |
| credits | `INSUFFICIENT_CREDITS` | El cliente no tiene suficientes creditos |
| invitations | `ALREADY_INVITED` | El empleado ya tiene una invitacion activa |

---

## Archivos clave

- `app/models/referral_code.rb`
- `app/models/referral.rb`
- `app/models/subscription_payment_order.rb`
- `app/models/site_config.rb`
- `app/services/checkout_service.rb`
- `app/services/approve_payment_service.rb`
- `app/jobs/trial_expiry_alert_job.rb`
- `app/admin/referral_codes.rb`
- `app/admin/referrals.rb`
- `app/admin/subscription_payment_orders.rb`
- `app/admin/site_configs.rb`
- `agendity-web/src/app/dashboard/subscription/checkout/page.tsx`
- `db/seeds.rb` (SiteConfig seeds)
