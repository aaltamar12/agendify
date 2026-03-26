# Alertas de Suscripcion

## Descripcion

Sistema automatizado de alertas cuando la suscripcion de un negocio esta por vencer. Ejecuta un job diario que envia notificaciones por multiples canales y suspende negocios que no renuevan.

Adicionalmente, existe un job separado para el periodo de trial (`TrialExpiryAlertJob`) que gestiona el fin del periodo de prueba gratuita.

---

## 1. Alertas de suscripcion pagada (SubscriptionExpiryAlertJob)

### Flujo de alertas

| Stage | Momento | Canales | Accion adicional |
|-------|---------|---------|------------------|
| 1 | 5 dias antes | Email + In-app + NATS + WhatsApp* | Warning |
| 2 | Dia de vencimiento | Email + In-app + NATS + WhatsApp* | Urgencia |
| 3 | Dia +2 despues | Email + In-app + NATS + WhatsApp* | **Negocio suspendido** (`suspended`) |
| 4 | Dia +7 despues | — | **Negocio desactivado** (`inactive`) — dashboard bloqueado total |

*WhatsApp solo si el plan lo incluye (`plan.whatsapp_notifications?`)

### Modelo

Campo `expiry_alert_stage` en `subscriptions`:
- `0` = ninguna alerta enviada
- `1` = alerta de 5 dias enviada
- `2` = alerta de dia de vencimiento enviada
- `3` = alerta final + negocio suspendido (`suspended`)
- `4` = negocio desactivado (`inactive`) — dashboard bloqueado total

Se resetea a `0` cuando se renueva la suscripcion via `process_renewal!`.

### Job

```ruby
# app/jobs/subscription_expiry_alert_job.rb
# Cola: default | Schedule: diario 8am (sidekiq-cron)
class SubscriptionExpiryAlertJob < ApplicationJob
  queue_as :default

  def perform
    # Stage 1: 5 dias antes
    Subscription.expiring_in(5).where(expiry_alert_stage: 0)
      .includes(:plan, business: :owner).find_each { |s| send_alert(s, stage: 1) }

    # Stage 2: Dia de vencimiento
    Subscription.active.where(end_date: Date.current, expiry_alert_stage: 1)
      .includes(:plan, business: :owner).find_each { |s| send_alert(s, stage: 2) }

    # Stage 3: 2 dias despues (gracia) — suspend
    Subscription.expired_since(2).where(expiry_alert_stage: 2)
      .includes(:plan, business: :owner).find_each do |s|
        send_alert(s, stage: 3)
        suspend_business!(s)        # business.suspended!
      end

    # Stage 4: 7 dias despues — deactivate (bloqueo total)
    Subscription.expired_since(7).where(expiry_alert_stage: 3)
      .includes(:plan, business: :owner).find_each do |s|
        deactivate_business!(s)     # s.update!(expiry_alert_stage: 4) + business.inactive!
      end
  end
end
```

**Stage 4 — deactivate_business!:**
```ruby
def deactivate_business!(subscription)
  business = subscription.business
  subscription.update!(expiry_alert_stage: 4)
  business.inactive!

  AdminNotification.notify!(
    title: "Negocio desactivado por suscripcion vencida",
    body: "#{business.name} fue desactivado automaticamente (7 dias sin renovar)",
    notification_type: "business_deactivated",
    link: "/admin/businesses/#{business.id}"
  )

  ActivityLog.log(
    business: business,
    action: "business_deactivated",
    description: "Negocio desactivado por suscripcion vencida (7 dias sin renovar)",
    actor_type: "system",
    resource: subscription
  )
end
```

**Diferencia entre `suspended` e `inactive`:**
- `suspended` (stage 3): dashboard accesible con banner, pagina publica deshabilitada
- `inactive` (stage 4): dashboard completamente bloqueado, pantalla "Cuenta desactivada"

### Scopes en Subscription

```ruby
scope :expiring_in, ->(days) { active.where(end_date: Date.current + days) }
scope :expired_since, ->(days) { active.where(end_date: Date.current - days) }
```

### Renovacion

```ruby
subscription.process_renewal!
# 1. Extiende end_date 30 dias
# 2. Resetea expiry_alert_stage a 0
# 3. Reactiva negocio si estaba suspendido
# 4. Envia notificaciones de confirmacion (email + in-app + NATS + WhatsApp)
```

Disponible desde ActiveAdmin > Subscriptions > "Renovar suscripcion"

---

## 2. Alertas de fin de trial (TrialExpiryAlertJob)

### Contexto

El trial dura **25 dias**. Al registrarse, `Business#trial_ends_at` se fija en `25.days.from_now`. Cuando el trial termina, el negocio debe elegir un plan y subir comprobante de pago para continuar.

### Flujo de alertas

| Stage | Momento | Canales | Accion |
|-------|---------|---------|--------|
| 1 | 5 dias antes del fin del trial | Email + In-app + WhatsApp* | Aviso: "Tu trial termina en 5 dias, elige tu plan" |
| 2 | Dia que termina el trial | Email + In-app + WhatsApp* | `trial_ended_thank_you` + enlace a elegir plan |
| 3 | Dia +2 despues del fin del trial | Email + In-app + WhatsApp* | **Negocio suspendido** (`suspended`) |
| 4 | Dia +10 despues del fin del trial | — | **Negocio desactivado** (`inactive`) — dashboard bloqueado total |

*WhatsApp solo si el plan del trial lo incluye.

### Modelo

Campo `trial_alert_stage` en `businesses`:
- `0` = ninguna alerta enviada
- `1` = alerta de 5 dias antes enviada
- `2` = alerta del dia de fin enviada
- `3` = alerta final + negocio suspendido (`suspended`)
- `4` = negocio desactivado (`inactive`) — dashboard bloqueado total

Sirve como anti-duplicados: cada stage se envia una sola vez.

### Job

```ruby
# app/jobs/trial_expiry_alert_job.rb
# Cola: default | Schedule: diario 8am (sidekiq-cron)
class TrialExpiryAlertJob < ApplicationJob
  queue_as :default

  def perform
    # Stage 1: 5 dias antes
    Business.trial_expiring_in(5).where(trial_alert_stage: 0)
      .includes(:owner, :subscriptions).find_each { |b| send_alert(b, stage: 1) }

    # Stage 2: Dia que termina el trial
    Business.trial_expiring_in(0).where(trial_alert_stage: 1)
      .includes(:owner, :subscriptions).find_each { |b| send_alert(b, stage: 2) }

    # Stage 3: 2 dias despues (suspender)
    Business.trial_expired_since(2).where(trial_alert_stage: 2)
      .includes(:owner, :subscriptions).find_each do |b|
        send_alert(b, stage: 3)
        suspend_business!(b)          # business.suspended!
      end

    # Stage 4: 10 dias despues (desactivar — bloqueo total)
    Business.trial_expired_since(10).where(trial_alert_stage: 3)
      .includes(:owner, :subscriptions).find_each do |b|
        deactivate_business!(b)       # business.update!(trial_alert_stage: 4) + business.inactive!
      end
  end
end
```

**Stage 4 — deactivate_business!:**
```ruby
def deactivate_business!(business)
  business.update!(trial_alert_stage: 4)
  business.inactive!

  AdminNotification.notify!(
    title: "Negocio desactivado por trial vencido",
    body: "#{business.name} fue desactivado (10 dias sin suscribirse)",
    notification_type: "business_deactivated",
    link: "/admin/businesses/#{business.id}"
  )

  ActivityLog.log(
    business: business,
    action: "business_deactivated",
    description: "Negocio desactivado por trial vencido (10 dias sin suscribirse)",
    actor_type: "system",
    resource: business
  )
end
```

### Mailer

```ruby
# app/mailers/business_mailer.rb
BusinessMailer.trial_expiry_alert(business, stage)
# stage 1: aviso anticipado
# stage 2: dia de fin (email de agradecimiento + CTA elegir plan)
# stage 3: suspension
```

### Relacion con checkout

Cuando el negocio elige un plan y sube su comprobante (`POST /api/v1/subscription/checkout`), el admin aprueba el pago desde ActiveAdmin. `ApprovePaymentService` crea la suscripcion, reactiva el negocio y resetea `trial_alert_stage = 0`. Ver [sistema-referidos.md](sistema-referidos.md) para el flujo completo de checkout.

---

## Mailer compartido

```ruby
# app/mailers/business_mailer.rb
BusinessMailer.subscription_expiry_alert(business, subscription, stage)
BusinessMailer.subscription_renewed(business, subscription)
BusinessMailer.trial_expiry_alert(business, stage)
```

Todos los mailers usan `SiteConfig.get(:support_email)` y `SiteConfig.get(:support_whatsapp)` en vez de valores hardcoded.

Templates:
- `app/views/business_mailer/subscription_expiry_alert_stage_{1,2,3}.html.erb`
- `app/views/business_mailer/subscription_renewed.html.erb`
- `app/views/business_mailer/trial_expiry_alert_stage_{1,2,3}.html.erb`

---

## Banners del Dashboard

El dashboard tiene 4 banners que se apilan verticalmente en la parte superior. Cada uno ocupa `40px` de alto y se posiciona con `position: fixed` y z-index decreciente.

### Orden de apilamiento

| # | Banner | z-index | Condicion |
|---|--------|---------|-----------|
| 1 | Demo | 59 | Solo en modo demo (`isDemoMode()`) |
| 2 | Impersonacion | 59 | SuperAdmin observando como negocio |
| 3 | Oculto (amarillo) | 58 | `isBusinessSuspended && !showSubscriptionBanner` |
| 4 | Suscripcion | 57 | `daysUntilExpiry !== null && daysUntilExpiry <= 5` |

El offset vertical de cada banner se calcula dinamicamente contando cuantos banners superiores estan visibles.

### Logica de visibilidad (layout.tsx)

```typescript
const showSubscriptionBanner = daysUntilExpiry !== null && daysUntilExpiry <= 5;
const isBusinessHidden = isBusinessSuspended && !showSubscriptionBanner;
```

**Regla clave:** El banner amarillo "Oculto" y el SubscriptionBanner **nunca se muestran al mismo tiempo**. Cuando la suspension es por falta de pago (trial o suscripcion vencida), `daysUntilExpiry` tiene un valor negativo (siempre <= 5) y el SubscriptionBanner lo cubre. El banner amarillo solo aparece cuando el negocio fue suspendido manualmente por el admin sin relacion con la suscripcion.

### SubscriptionBanner (subscription-banner.tsx)

Cubre **tanto trial como suscripcion pagada**. Se basa en `daysUntilExpiry` que se calcula desde `subscription.end_date` o `business.trial_ends_at`.

| Condicion | Color | Icono | Mensaje | CTA |
|-----------|-------|-------|---------|-----|
| Trial, 6-20 dias restantes | Azul (`bg-blue-500`) | Info | "Estas en tu periodo de prueba. Te quedan {X} dias." | Ver planes → checkout |
| 1-5 dias antes de vencer | Amber (`bg-amber-500`) | Clock | "Tu plan {plan} vence en {X} dias. Renueva para mantener tus funcionalidades." | Renovar → checkout |
| Dia de vencimiento (0 dias) | Rojo (`bg-red-500`) | AlertTriangle | "Tu plan {plan} vence hoy. Renueva ahora para no perder acceso." | Renovar → checkout |
| Vencido (dias negativos) | Rojo oscuro (`bg-red-600`) | AlertTriangle | "Tu plan {plan} vencio hace {X} dias. Tu negocio no aparece para usuarios hasta que renueves." | Renovar → checkout |

El banner azul informativo aparece a partir del dia 5 del trial (con 20 dias restantes, asumiendo trial de 25 dias). A partir de 5 dias restantes cambia a los colores de urgencia (amber/rojo).

El banner completo es un `<Link>` clickeable a `/dashboard/subscription/checkout`.

### Banner Amarillo "Oculto" (layout.tsx)

| Condicion | Mensaje | CTA |
|-----------|---------|-----|
| Negocio `suspended` sin datos de expiracion de suscripcion/trial | "Tu negocio esta oculto y no aparece para usuarios." | Boton "Renovar suscripcion" → checkout |

Este caso solo ocurre cuando:
- El admin suspendio manualmente el negocio desde ActiveAdmin (batch action o accion individual)
- El negocio no tiene `trial_ends_at` ni suscripcion activa/expirada con fecha

### Tabla resumen de escenarios

| Escenario | Status negocio | Banner visible | Color |
|-----------|---------------|---------------|-------|
| Trial activo, >20 dias restantes | `active` | Ninguno | — |
| Trial activo, 6-20 dias restantes | `active` | SubscriptionBanner | Azul (info) |
| Trial activo, 3 dias restantes | `active` | SubscriptionBanner | Amber |
| Trial vence hoy | `active` | SubscriptionBanner | Rojo |
| Trial vencio hace 1 dia (gracia) | `active` | SubscriptionBanner | Rojo oscuro |
| Trial vencio hace 2+ dias (job suspendio) | `suspended` | SubscriptionBanner | Rojo oscuro |
| Trial vencio hace 30 dias | `suspended` | SubscriptionBanner | Rojo oscuro |
| Suscripcion activa, 5 dias para vencer | `active` | SubscriptionBanner | Amber |
| Suscripcion vencio, negocio suspendido | `suspended` | SubscriptionBanner | Rojo oscuro |
| Suspendido manualmente por admin | `suspended` | Banner Oculto | Amarillo |
| Negocio `inactive` (stage 4) | `inactive` | Dashboard bloqueado (pantalla completa "Cuenta desactivada") | — |

### Mailer adicional: trial_ended_thank_you

En el **stage 2** del trial (dia que termina), ademas de la notificacion in-app, se envia un email especial de agradecimiento con los planes y datos de pago:

```ruby
BusinessMailer.trial_ended_thank_you(business)
# Incluye: lista de planes con precios, datos de pago (Nequi/Bancolombia/Daviplata)
# Leidos desde SiteConfig
```

Esto es diferente al `trial_expiry_alert(business, stage: 2)` que tambien existe para la notificacion in-app.

---

---

## 3. Configuracion de Sidekiq

### sidekiq.yml

```yaml
# config/sidekiq.yml
---
:concurrency: 5
:queues:
  - default
  - notifications
  - intelligence
  - mailers
```

Los jobs de alertas de suscripcion y trial usan la cola `default`.

### sidekiq-cron (initializer)

```ruby
# config/initializers/sidekiq_cron.rb
if Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash!(
    "trial_expiry_alerts" => {
      "class" => "TrialExpiryAlertJob",
      "cron"  => "0 8 * * *",    # Daily at 8:00 AM
      "queue" => "default",
      "description" => "Alertas de trial (5d antes, dia de, +2d suspension, +10d inactivar)"
    },
    "subscription_expiry_alerts" => {
      "class" => "SubscriptionExpiryAlertJob",
      "cron"  => "0 8 * * *",    # Daily at 8:00 AM
      "queue" => "default",
      "description" => "Alertas de suscripcion (5d antes, dia de, +2d suspension, +7d inactivar)"
    }
    # ... mas jobs en config/initializers/sidekiq_cron.rb
  )
end
```

Ver el doc completo de todos los jobs en [sidekiq-jobs.md](sidekiq-jobs.md).

### Monitoreo

- `/admin/sidekiq` — panel de Sidekiq Web (queues, retries, stats)
- `/admin/sidekiq/cron` — listado de jobs recurrentes con ultima ejecucion y estado

---

## Archivos clave

### Backend (agendity-api)
- `app/jobs/subscription_expiry_alert_job.rb` — Job de alertas de suscripcion (4 stages)
- `app/jobs/trial_expiry_alert_job.rb` — Job de alertas de trial (4 stages)
- `app/jobs/check_expired_subscriptions_job.rb` — Downgrade automatico a Basico
- `app/mailers/business_mailer.rb` — Emails de alertas, renovacion, agradecimiento
- `app/models/subscription.rb` — Scopes `expiring_in`, `expired_since` + `process_renewal!`
- `app/models/business.rb` — Campos `trial_ends_at`, `trial_alert_stage`, enum `status`
- `app/views/business_mailer/subscription_expiry_alert_stage_*.html.erb`
- `app/views/business_mailer/trial_expiry_alert_stage_*.html.erb`
- `config/initializers/sidekiq_cron.rb` — Schedule de jobs recurrentes

### Frontend (agendity-web)
- `src/app/dashboard/layout.tsx` — Logica de visibilidad y apilamiento de banners
- `src/components/layout/subscription-banner.tsx` — Componente SubscriptionBanner (trial + suscripcion)
- `src/lib/hooks/use-subscription.ts` — Hook `useCurrentSubscription()` que calcula `daysUntilExpiry`
- `src/app/dashboard/subscription/checkout/page.tsx` — Pagina de checkout con planes detallados
