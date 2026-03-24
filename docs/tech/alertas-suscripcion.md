# Alertas de Suscripcion

## Descripcion

Sistema automatizado de alertas cuando la suscripcion de un negocio esta por vencer. Ejecuta un job diario que envia notificaciones por multiples canales y suspende negocios que no renuevan.

Adicionalmente, existe un job separado para el periodo de trial (`TrialExpiryAlertJob`) que gestiona el fin del periodo de prueba gratuita.

---

## 1. Alertas de suscripcion pagada (SubscriptionExpiryAlertJob)

### Flujo de alertas

| Momento | Canales | Accion adicional |
|---------|---------|------------------|
| 5 dias antes | Email + In-app + NATS + WhatsApp* | Warning |
| Dia de vencimiento | Email + In-app + NATS + WhatsApp* | Urgencia |
| 2 dias despues | Email + In-app + NATS + WhatsApp* | **Negocio suspendido** |

*WhatsApp solo si el plan lo incluye (`plan.whatsapp_notifications?`)

### Modelo

Campo `expiry_alert_stage` en `subscriptions`:
- `0` = ninguna alerta enviada
- `1` = alerta de 5 dias enviada
- `2` = alerta de dia de vencimiento enviada
- `3` = alerta final + negocio suspendido

Se resetea a `0` cuando se renueva la suscripcion via `process_renewal!`.

### Job

```ruby
# app/jobs/subscription_expiry_alert_job.rb
# Corre diario a las 8am (config/recurring.yml)
class SubscriptionExpiryAlertJob < ApplicationJob
  queue_as :default

  def perform
    # Stage 1: 5 dias antes
    Subscription.expiring_in(5).where(expiry_alert_stage: 0)

    # Stage 2: Dia de vencimiento
    Subscription.active.where(end_date: Date.current, expiry_alert_stage: 1)

    # Stage 3: 2 dias despues (gracia)
    Subscription.expired_since(2).where(expiry_alert_stage: 2)
  end
end
```

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

El trial dura **7 dias** (antes eran 30). Al registrarse, `Business#trial_ends_at` se fija en `7.days.from_now`. Cuando el trial termina, el negocio debe elegir un plan y subir comprobante de pago para continuar.

### Flujo de alertas

| Momento | Stage | Canales | Accion |
|---------|-------|---------|--------|
| 2 dias antes del fin del trial | 1 | Email + In-app + WhatsApp* | Aviso: "Tu trial termina en 2 dias, elige tu plan" |
| Dia que termina el trial | 2 | Email + In-app + WhatsApp* | Email de agradecimiento + enlace a elegir plan |
| 2 dias despues del fin del trial | 3 | Email + In-app + WhatsApp* | **Negocio suspendido automaticamente** |

*WhatsApp solo si el plan del trial lo incluye.

### Modelo

Campo `trial_alert_stage` en `businesses`:
- `0` = ninguna alerta enviada
- `1` = alerta de 2 dias antes enviada
- `2` = alerta del dia de fin enviada
- `3` = alerta final + negocio suspendido

Sirve como anti-duplicados: cada stage se envia una sola vez.

### Job

```ruby
# app/jobs/trial_expiry_alert_job.rb
# Corre diario a las 8am (config/recurring.yml)
class TrialExpiryAlertJob < ApplicationJob
  queue_as :default

  def perform
    # Stage 1: 2 dias antes
    Business.on_trial.where(trial_ends_at: 2.days.from_now.beginning_of_day..2.days.from_now.end_of_day)
             .where(trial_alert_stage: 0)

    # Stage 2: Dia que termina el trial
    Business.on_trial.where(trial_ends_at: Date.current.beginning_of_day..Date.current.end_of_day)
             .where(trial_alert_stage: 1)

    # Stage 3: 2 dias despues (suspender)
    Business.on_trial.where(trial_ends_at: ..2.days.ago.end_of_day)
             .where(trial_alert_stage: 2)
  end
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

## Banner en Frontend

`SubscriptionBanner` en `src/components/layout/subscription-banner.tsx`.

Aparece en la parte superior del dashboard (debajo del topbar) para todos los negocios con suscripcion por vencer o trial activo.

### Estados para suscripcion paga

| Condicion | Color | Mensaje ejemplo |
|-----------|-------|-----------------|
| 5 a 1 dias antes de vencer | Amarillo | "Tu plan Profesional vence en X dias. Renueva ahora." |
| Dia de vencimiento | Rojo | "Tu plan Profesional vence hoy. Renueva ahora." |
| Despues de vencer | Rojo oscuro | "Tu plan vencio hace X dias. Renueva para evitar suspension." |

### Estados para trial

| Condicion | Color | Mensaje ejemplo |
|-----------|-------|-----------------|
| Trial activo (>2 dias restantes) | Azul/informativo | "Estas en tu periodo de prueba. X dias restantes." |
| 2 dias o menos | Amarillo | "Tu periodo de prueba termina en X dias. Elige tu plan." |
| Trial vencido (sin suspension) | Rojo | "Tu periodo de prueba termino. Elige tu plan para continuar." |

Se muestra automaticamente basado en `subscription.end_date` o `business.trial_ends_at`. El boton CTA lleva a `/dashboard/subscription/checkout`.

### Mailer adicional: trial_ended_thank_you

En el **stage 2** del trial (dia que termina), ademas de la notificacion in-app, se envia un email especial de agradecimiento con los planes y datos de pago:

```ruby
BusinessMailer.trial_ended_thank_you(business)
# Incluye: lista de planes con precios, datos de pago (Nequi/Bancolombia/Daviplata)
# Leidos desde SiteConfig
```

Esto es diferente al `trial_expiry_alert(business, stage: 2)` que tambien existe para la notificacion in-app.

---

## Archivos clave

- `app/jobs/subscription_expiry_alert_job.rb`
- `app/jobs/trial_expiry_alert_job.rb`
- `app/mailers/business_mailer.rb`
- `app/models/subscription.rb` (scopes + `process_renewal!`)
- `app/models/business.rb` (campo `trial_ends_at` + `trial_alert_stage`)
- `app/views/business_mailer/subscription_expiry_alert_stage_*.html.erb`
- `app/views/business_mailer/subscription_renewed.html.erb`
- `app/views/business_mailer/trial_expiry_alert_stage_*.html.erb`
- `agendity-web/src/components/layout/subscription-banner.tsx`
- `config/recurring.yml` (schedule)
