# Sistema de Notificaciones — Agendity

> Ultima actualizacion: 2026-03-22

## Principio fundamental

**Agendity es el intermediario.** Las notificaciones al usuario final (customer) se envian siempre por **email + WhatsApp**. El negocio (cliente de Agendity) **NO configura ni elige** los canales de notificacion. Agendity opera como plataforma que garantiza la comunicacion automatica.

Las notificaciones al negocio (in-app, email) son un canal separado que opera directamente via mailers y modelo Notification.

---

## Canales

| Canal | Destinatario | Estado | Tecnologia |
|---|---|---|---|
| **In-app** (campanita) | Negocio | Implementado | PostgreSQL + polling 30s + NATS WebSocket |
| **Email** | Negocio + Usuario final | Implementado | Action Mailer (ApplicationMailer) |
| **WhatsApp** | Usuario final | Stub (pendiente) | WhatsApp Business API de Meta (directo) |
| **Push** | Futuro | No implementado | Capacitor/FCM (fase futura) |

---

## Arquitectura multicanal (usuario final)

```
                    CompleteAppointmentsJob (cada 15 min)
                              |
                    SendRatingRequestJob
                              |
                  MultiChannelService.call(
                    recipient: customer,
                    template: :rating_request,
                    data: { ... }
                  )
                    /                 \
            EmailChannel          WhatsAppChannel
                |                       |
          CustomerMailer          WhatsApp Business API
          .deliver_now            (Meta Cloud API)
```

### Archivos clave

```
app/services/notifications/
  multi_channel_service.rb    # Orquestador — siempre envia por TODOS los canales
  email_channel.rb            # Despacha al mailer correspondiente segun template
  whatsapp_channel.rb         # Envia via WhatsApp Business API (stub actual)

app/jobs/
  complete_appointments_job.rb     # Marca citas como completed, dispara rating request
  send_rating_request_job.rb       # Usa MultiChannelService para notificar al customer

app/mailers/
  customer_mailer.rb               # Emails al usuario final (rating_request, etc.)
  appointment_mailer.rb            # Emails transaccionales (booking_confirmed, reminder, etc.)
```

### MultiChannelService

Siempre envia por **todos** los canales definidos en `CHANNELS`:

```ruby
CHANNELS = [:email, :whatsapp].freeze
```

- No depende de configuracion del negocio
- Si un canal falla, loguea el error y continua con el siguiente
- Retorna hash con resultado por canal: `{ email: true, whatsapp: false }`

### Templates soportados

| Template | Descripcion | EmailChannel | WhatsAppChannel |
|---|---|---|---|
| `:rating_request` | Solicitud de calificacion post-servicio | CustomerMailer.rating_request | Pendiente |

> **Nota:** A medida que se migren los jobs existentes (booking_confirmed, reminder, cancelled) al MultiChannelService, se agregaran mas templates.

---

## Notificaciones al usuario final — Eventos

| Evento | Job actual | Canales actuales | Canales objetivo |
|---|---|---|---|
| Cita confirmada (pago aprobado) | SendBookingConfirmedJob | Email | Email + WhatsApp |
| Recordatorio 24h antes | SendReminderJob | Email | Email + WhatsApp |
| Cita cancelada | SendBookingCancelledJob | Email | Email + WhatsApp |
| Solicitud de calificacion | SendRatingRequestJob | Email + WhatsApp (via MultiChannelService) | Email + WhatsApp |

> **TODO:** Migrar SendBookingConfirmedJob, SendReminderJob y SendBookingCancelledJob para que usen MultiChannelService en vez de llamar directamente a AppointmentMailer.

---

## Notificaciones al negocio (in-app)

### Modelo de datos

```sql
CREATE TABLE notifications (
  id bigint PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses(id),
  title varchar NOT NULL,
  body text,
  notification_type varchar NOT NULL,
  link varchar,
  read boolean DEFAULT false,
  created_at timestamp,
  updated_at timestamp
);
```

**Tipos:** `new_booking`, `payment_submitted`, `booking_cancelled`, `payment_approved`, `reminder`

### API Endpoints

```bash
GET  /api/v1/notifications?page=1         # Listar (paginadas)
GET  /api/v1/notifications/unread_count    # Contar no leidas
POST /api/v1/notifications/:id/mark_read  # Marcar una como leida
POST /api/v1/notifications/mark_all_read  # Marcar todas como leidas
```

### Frontend
- Campanita en topbar con badge rojo (polling 30s)
- Dropdown con las 5 mas recientes
- Pagina `/dashboard/notifications` con lista completa

---

## Email (Action Mailer)

### Mailers

**`AppointmentMailer`** (al negocio y/o usuario final):
| Metodo | Destinatario | Evento |
|---|---|---|
| `new_booking` | Negocio | Nueva reserva creada |
| `booking_confirmed` | Usuario final | Pago aprobado + ticket |
| `booking_cancelled` | Ambos | Cita cancelada |
| `reminder` | Usuario final | 24h antes de la cita |
| `payment_reminder` | Usuario final | Recordatorio de pago (manual) |
| `payment_rejected` | Usuario final | Comprobante rechazado |

**`CustomerMailer`** (solo usuario final, via MultiChannelService):
| Metodo | Destinatario | Evento |
|---|---|---|
| `rating_request` | Usuario final | Post-servicio completado |

**`UserMailer`** (cuenta de usuario):
| Metodo | Destinatario | Evento |
|---|---|---|
| `reset_password` | Usuario | Olvide mi contrasena |

### Diseno de emails
- Layout HTML con header violeta + branding Agendity (`views/layouts/mailer.html.erb`)
- Version texto plano para cada email
- Todos los textos en espanol

---

## WhatsApp Business API — Integracion pendiente

### Configuracion requerida en Meta

**Variables de entorno necesarias:**
```env
WHATSAPP_API_TOKEN=           # Token de acceso permanente de la app de Meta
WHATSAPP_PHONE_NUMBER_ID=     # ID del numero de telefono de WhatsApp Business
```

### Pasos para configurar en Meta Business Manager

1. Crear una **Meta App** en [developers.facebook.com](https://developers.facebook.com)
2. Agregar el producto **WhatsApp** a la app
3. Configurar un **numero de telefono de WhatsApp Business** (puede ser el de Agendity)
4. Generar un **System User Token** permanente con permisos `whatsapp_business_messaging`
5. Crear los **Message Templates** (ver seccion siguiente)
6. Verificar el negocio en Meta Business Manager para produccion

### Templates de WhatsApp requeridos

Cada mensaje a un usuario que no ha iniciado conversacion en las ultimas 24h requiere un **template aprobado por Meta**. Los templates se crean en el WhatsApp Manager de Meta.

#### Template: `rating_request`
- **Categoria:** MARKETING
- **Idioma:** es
- **Cuerpo sugerido:**
  ```
  Hola {{1}}, gracias por visitarnos en {{2}}.

  Nos encantaria saber como fue tu experiencia con el servicio {{3}}.

  Califica tu visita aqui: {{4}}
  ```
- **Variables:**
  - `{{1}}` = customer.name
  - `{{2}}` = business.name
  - `{{3}}` = service.name
  - `{{4}}` = review_url
- **Botones:** 1 boton URL "Calificar ahora" apuntando a `{{4}}`

#### Template: `booking_confirmed` (futuro)
- **Categoria:** UTILITY
- **Idioma:** es
- **Cuerpo sugerido:**
  ```
  Tu cita en {{1}} esta confirmada.

  Servicio: {{2}}
  Profesional: {{3}}
  Fecha: {{4}}
  Hora: {{5}}

  Tu codigo de ticket: {{6}}

  Presenta este codigo al llegar al negocio.
  ```

#### Template: `appointment_reminder` (futuro)
- **Categoria:** UTILITY
- **Idioma:** es
- **Cuerpo sugerido:**
  ```
  Recordatorio: tu cita en {{1}} es manana.

  Servicio: {{2}}
  Hora: {{3}}

  Te esperamos!
  ```

#### Template: `booking_cancelled` (futuro)
- **Categoria:** UTILITY
- **Idioma:** es
- **Cuerpo sugerido:**
  ```
  Tu cita en {{1}} ha sido cancelada.

  Servicio: {{2}}
  Fecha: {{3}}

  Si tienes preguntas, contacta al negocio directamente.
  ```

### Implementacion del WhatsAppChannel

Cuando se configure la API, el `WhatsAppChannel` debe:

1. Formatear el payload segun la API de Meta Cloud:
```ruby
# POST https://graph.facebook.com/v21.0/{PHONE_NUMBER_ID}/messages
{
  messaging_product: "whatsapp",
  to: recipient.phone,  # formato internacional: 573001234567
  type: "template",
  template: {
    name: "rating_request",  # nombre del template aprobado
    language: { code: "es" },
    components: [
      {
        type: "body",
        parameters: [
          { type: "text", text: data[:customer_name] },
          { type: "text", text: data[:business_name] },
          { type: "text", text: data[:service_name] },
          { type: "text", text: data[:review_url] }
        ]
      }
    ]
  }
}
```

2. Normalizar el telefono del customer al formato internacional de Colombia (57XXXXXXXXXX)
3. Manejar errores de la API (rate limits, numeros invalidos, template rechazado)
4. Loguear el resultado para trazabilidad

### Formato de telefono

Los telefonos en la BD pueden estar en formato local (3001234567) o con indicativo (573001234567). El WhatsAppChannel debe normalizar:

```ruby
def normalize_phone(phone)
  cleaned = phone.gsub(/\D/, '')  # solo digitos
  cleaned = "57#{cleaned}" if cleaned.length == 10  # agregar indicativo Colombia
  cleaned
end
```

---

## Background Jobs

| Job | Trigger | Que hace |
|---|---|---|
| `SendNewBookingNotificationJob` | Booking creado | Email al negocio + notificacion in-app |
| `SendPaymentSubmittedJob` | Comprobante subido | Email al negocio + notificacion in-app |
| `SendBookingConfirmedJob` | Pago aprobado | Email al usuario final con ticket |
| `SendBookingCancelledJob` | Cita cancelada | Email a ambos + notificacion in-app |
| `SendReminderJob` | Scheduler diario | Email recordatorio al usuario final |
| `AppointmentReminderSchedulerJob` | Cron 8am diario | Encola reminders para citas de manana |
| `CompleteAppointmentsJob` | Cron cada 15 min | Marca checked_in como completed + rating request |
| `SendRatingRequestJob` | Post-completion | MultiChannelService: email + WhatsApp al usuario final |

### Scheduled Jobs (`config/recurring.yml`)

```yaml
complete_appointments:
  class: CompleteAppointmentsJob
  schedule: every 15 minutes

reminder_scheduler:
  class: AppointmentReminderSchedulerJob
  schedule: every day at 8am

token_cleanup:
  class: CleanupExpiredTokensJob
  schedule: every sunday at 3am
```
