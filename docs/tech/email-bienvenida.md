# Email de Bienvenida

> Ultima actualizacion: 2026-03-25
> Mailer: `BusinessMailer#welcome`
> Disparado por: `RegisterService` via `deliver_later` (Sidekiq)

---

## Resumen

Inmediatamente despues de que un negocio se registra en Agendity, el sistema envia automaticamente un email de bienvenida al dueno. El email sirve como confirmacion del registro, recordatorio del trial y mini-onboarding con las funcionalidades clave.

---

## Cuando se envia

```ruby
# app/services/register_service.rb
class RegisterService < BaseService
  def call
    # ... crear User, Business, Subscription trial ...
    BusinessMailer.welcome(business).deliver_later  # encola via Sidekiq
  end
end
```

Se envia una sola vez, justo despues de crear el negocio. No tiene anti-duplicados porque `RegisterService` solo se ejecuta una vez por negocio.

---

## Implementacion

```ruby
# app/mailers/business_mailer.rb
def welcome(business)
  @business         = business
  @owner            = business.owner
  @trial_ends_at    = business.trial_ends_at
  @support_email    = SiteConfig.get("support_email")
  @support_whatsapp = SiteConfig.get("support_whatsapp")
  @app_url          = SiteConfig.get("app_url")

  mail(
    to:      @owner.email,
    subject: "Bienvenido a Agendity, #{@owner.name}! Tu negocio esta listo"
  )
end
```

---

## Contenido del email

| Seccion | Contenido |
|---------|-----------|
| Saludo | "Hola [Nombre], tu negocio [Nombre del negocio] ya esta en Agendity" |
| Trial | Recordatorio de que el trial dura 7 dias, con la fecha exacta de vencimiento (`trial_ends_at`) |
| Mini-onboarding | Lista de 7 funcionalidades clave: agenda, empleados, servicios, pagos, check-in, reportes, link publico de reservas |
| CTA principal | Boton "Ir al dashboard" → `{app_url}/dashboard` |
| Soporte | Email de soporte (`support_email`) y WhatsApp de soporte (`support_whatsapp`) leidos desde `SiteConfig` |

---

## Variables de plantilla

Todas las variables se leen desde `SiteConfig` — no hay valores hardcodeados:

| Variable | SiteConfig key | Descripcion |
|----------|---------------|-------------|
| `@app_url` | `app_url` | URL base del frontend (ej: `https://agendity.co`) |
| `@support_email` | `support_email` | Email de soporte de Agendity |
| `@support_whatsapp` | `support_whatsapp` | WhatsApp de soporte de Agendity |
| `@trial_ends_at` | — | Calculado: `business.trial_ends_at` (7 dias desde el registro) |

---

## Relacion con el flujo de registro

```
POST /api/v1/auth/register
  → RegisterService#call
      → Crear User (role: owner)
      → Crear Business (slug unico, trial_ends_at = 7.days.from_now)
      → Crear Subscription trial
      → Si hay codigo de referido: Referral { status: :pending }
      → BusinessMailer.welcome(business).deliver_later  ← este email
      → Retornar JWT tokens
```

El email se encola en Sidekiq (cola `default` heredada de `ApplicationMailer`) y se envia en segundos, pero de forma asincrona para no bloquear la respuesta del endpoint de registro.

---

## Template

```
app/views/business_mailer/welcome.html.erb
```

Usa el layout base de los mailers (`app/views/layouts/mailer.html.erb`) con el estilo visual de Agendity.

---

## Archivos clave

- `app/mailers/business_mailer.rb` — metodo `welcome`
- `app/services/register_service.rb` — dispara el mailer
- `app/views/business_mailer/welcome.html.erb` — template HTML
- `db/seeds.rb` — `SiteConfig` seeds con `support_email`, `support_whatsapp`, `app_url`
