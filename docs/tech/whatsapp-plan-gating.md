# WhatsApp Notifications — Plan Gating

## Descripcion

Las notificaciones por WhatsApp al usuario final solo se envian si el plan del negocio lo permite. Email siempre se envia.

## Configuracion por plan

| Plan | Email | WhatsApp |
|------|:-----:|:--------:|
| Basico | Si | No |
| Profesional | Si | Si |
| Inteligente | Si | Si |

## Campo en plans

```ruby
# Migracion
add_column :plans, :whatsapp_notifications, :boolean, default: false, null: false
```

## MultiChannelService

```ruby
# app/services/notifications/multi_channel_service.rb
class MultiChannelService < BaseService
  def initialize(recipient:, template:, data:, business:)
    # ...
  end

  private

  def channels
    chs = [:email]
    chs << :whatsapp if @business.current_plan&.whatsapp_notifications?
    chs
  end
end
```

## WhatsApp Channel (stub)

```ruby
# app/services/notifications/whatsapp_channel.rb
# Actualmente es un stub que loguea. Se implementara con la API de Meta.
class WhatsAppChannel
  def self.deliver(recipient:, template:, data:)
    return false unless ENV["WHATSAPP_API_TOKEN"].present?
    Rails.logger.info("[WhatsAppChannel] Would send #{template} to #{recipient.phone}")
    true
  end
end
```

## Uso

Cualquier servicio que necesite notificar al usuario final debe usar `MultiChannelService` pasando el `business:`. El servicio automaticamente decide los canales segun el plan.

```ruby
Notifications::MultiChannelService.call(
  recipient: customer,
  template: :rating_request,
  business: business,
  data: { ... }
)
```
