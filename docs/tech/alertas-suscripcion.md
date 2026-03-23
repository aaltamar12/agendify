# Alertas de Suscripcion

## Descripcion

Sistema automatizado de alertas cuando la suscripcion de un negocio esta por vencer. Ejecuta un job diario que envia notificaciones por multiples canales y suspende negocios que no renuevan.

## Flujo de alertas

| Momento | Canales | Accion adicional |
|---------|---------|------------------|
| 5 dias antes | Email + In-app + NATS + WhatsApp* | Warning |
| Dia de vencimiento | Email + In-app + NATS + WhatsApp* | Urgencia |
| 2 dias despues | Email + In-app + NATS + WhatsApp* | **Negocio suspendido** |

*WhatsApp solo si el plan lo incluye (`plan.whatsapp_notifications?`)

## Modelo

Campo `expiry_alert_stage` en `subscriptions`:
- `0` = ninguna alerta enviada
- `1` = alerta de 5 dias enviada
- `2` = alerta de dia de vencimiento enviada
- `3` = alerta final + negocio suspendido

Se resetea a `0` cuando se renueva la suscripcion via `process_renewal!`.

## Job

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

## Scopes en Subscription

```ruby
scope :expiring_in, ->(days) { active.where(end_date: Date.current + days) }
scope :expired_since, ->(days) { active.where(end_date: Date.current - days) }
```

## Renovacion

```ruby
subscription.process_renewal!
# 1. Extiende end_date 30 dias
# 2. Resetea expiry_alert_stage a 0
# 3. Reactiva negocio si estaba suspendido
# 4. Envia notificaciones de confirmacion (email + in-app + NATS + WhatsApp)
```

Disponible desde ActiveAdmin > Subscriptions > "Renovar suscripcion"

## Mailer

```ruby
# app/mailers/business_mailer.rb
BusinessMailer.subscription_expiry_alert(business, subscription, stage)
BusinessMailer.subscription_renewed(business, subscription)
```

Templates en `app/views/business_mailer/subscription_expiry_alert_stage_{1,2,3}.html.erb`

## Banner en Frontend

`SubscriptionBanner` en `src/components/layout/subscription-banner.tsx`:
- Amarillo: 5 a 1 dias antes
- Rojo: dia de vencimiento
- Rojo oscuro: despues de vencer

Se muestra automaticamente basado en `subscription.end_date`.

## Archivos clave

- `app/jobs/subscription_expiry_alert_job.rb`
- `app/mailers/business_mailer.rb`
- `app/models/subscription.rb` (scopes + `process_renewal!`)
- `app/views/business_mailer/subscription_expiry_alert_stage_*.html.erb`
- `app/views/business_mailer/subscription_renewed.html.erb`
- `agendity-web/src/components/layout/subscription-banner.tsx`
- `config/recurring.yml` (schedule)
