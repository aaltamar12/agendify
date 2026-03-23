# Sistema de Notificaciones — Agendity

> Ultima actualizacion: 2026-03-23

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

Todas las notificaciones al usuario final pasan por MultiChannelService. Email siempre se envia. WhatsApp solo si el negocio tiene plan Profesional o Inteligente.

| Template | Descripcion | EmailChannel | WhatsAppChannel |
|---|---|---|---|
| `:rating_request` | Solicitud de calificacion post-servicio | CustomerMailer.rating_request | rating_request (MARKETING) |
| `:booking_confirmed` | Pago aprobado, ticket listo | AppointmentMailer.booking_confirmed | booking_confirmed (UTILITY) |
| `:appointment_reminder` | Recordatorio 24h antes de la cita | AppointmentMailer.reminder | appointment_reminder (UTILITY) |
| `:booking_cancelled` | Cita cancelada | AppointmentMailer.booking_cancelled_to_customer | booking_cancelled (UTILITY) |
| `:payment_reminder` | Recordatorio de pago pendiente | AppointmentMailer.payment_reminder | payment_reminder (UTILITY) |
| `:payment_rejected` | Comprobante de pago rechazado | AppointmentMailer.payment_rejected | payment_rejected (UTILITY) |

**Notificaciones solo email (no MultiChannel):**

| Notificacion | Mailer | Razon |
|---|---|---|
| Cashback ganado | CustomerMailer.cashback_credited | Ahorro de costos WhatsApp — la info de cashback se puede anadir al template WhatsApp de booking_confirmed |

---

## Notificaciones al usuario final — Eventos

| Evento | Job/Servicio | Canales (via MultiChannel) |
|---|---|---|
| Cita confirmada (pago aprobado) | SendBookingConfirmedJob | Email + WhatsApp (Pro+) |
| Recordatorio 24h antes | SendReminderJob | Email + WhatsApp (Pro+) |
| Cita cancelada | SendBookingCancelledJob | Email + WhatsApp (Pro+) |
| Solicitud de calificacion | SendRatingRequestJob | Email + WhatsApp (Pro+) |
| Recordatorio de pago (manual) | AppointmentsController#remind_payment | Email + WhatsApp (Pro+) |
| Comprobante rechazado | Payments::RejectPaymentService | Email + WhatsApp (Pro+) |
| Cashback ganado | SendCashbackNotificationJob | Email solo (no WhatsApp, para no gastar conversaciones extra) |

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

**`AppointmentMailer`**:
| Metodo | Destinatario | Evento | Invocado por |
|---|---|---|---|
| `new_booking` | Negocio | Nueva reserva creada | SendNewBookingNotificationJob (directo) |
| `booking_confirmed` | Usuario final | Pago aprobado + ticket | EmailChannel via MultiChannel |
| `booking_cancelled` | Negocio | Cita cancelada (al negocio) | SendBookingCancelledJob (directo) |
| `booking_cancelled_to_customer` | Usuario final | Cita cancelada (al cliente) | EmailChannel via MultiChannel |
| `reminder` | Usuario final | 24h antes de la cita | EmailChannel via MultiChannel |
| `payment_reminder` | Usuario final | Recordatorio de pago (manual) | EmailChannel via MultiChannel |
| `payment_rejected` | Usuario final | Comprobante rechazado | EmailChannel via MultiChannel |

**`CustomerMailer`** (solo usuario final):
| Metodo | Destinatario | Evento | Via |
|---|---|---|---|
| `rating_request` | Usuario final | Post-servicio completado | MultiChannelService (email + WA Pro+) |
| `cashback_credited` | Usuario final | Creditos ganados por cashback | Email directo (no WhatsApp) |

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
| `SendNewBookingNotificationJob` | Booking creado | Email al negocio + notificacion in-app (directo) |
| `SendPaymentSubmittedJob` | Comprobante subido | Email al negocio + notificacion in-app (directo) |
| `SendBookingConfirmedJob` | Pago aprobado | **MultiChannel** al usuario final (email + WA Pro+) |
| `SendBookingCancelledJob` | Cita cancelada | Email al negocio (directo) + **MultiChannel** al usuario final |
| `SendReminderJob` | Scheduler diario | **MultiChannel** al usuario final (email + WA Pro+) |
| `AppointmentReminderSchedulerJob` | Cron 8am diario | Encola reminders para citas de manana |
| `CompleteAppointmentsJob` | Cron cada 15 min | Marca checked_in como completed + cashback + rating request |
| `SendCashbackNotificationJob` | Post-completion (si cashback > 0) | Email al usuario final (solo email, no WhatsApp) |
| `SendRatingRequestJob` | Post-completion | **MultiChannel** al usuario final (email + WA Pro+) |

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

---

## Sistema de notificaciones configurables (Etapa 9)

> Agregado: 2026-03-22

El sistema de notificaciones del negocio (browser push, sonido, in-app) ahora es **configurable desde ActiveAdmin** mediante el modelo `NotificationEventConfig`. Esto permite al SuperAdmin activar/desactivar tipos de notificacion, cambiar textos y controlar canales sin deployar codigo.

### Modelo `NotificationEventConfig`

Tabla global (no pertenece a un negocio — la configuracion es igual para todos los clientes).

```sql
CREATE TABLE notification_event_configs (
  id bigint PRIMARY KEY,
  event_key varchar NOT NULL,       -- identificador unico del evento (ej: "new_booking")
  title varchar NOT NULL,           -- titulo mostrado en la notificacion del navegador
  body_template varchar,            -- template del cuerpo con variables {{variable}}
  browser_notification boolean DEFAULT true NOT NULL,  -- mostrar notificacion del navegador
  sound_enabled boolean DEFAULT true NOT NULL,         -- reproducir sonido
  in_app_notification boolean DEFAULT true NOT NULL,   -- mostrar en campanita in-app
  active boolean DEFAULT true NOT NULL,                -- si el evento esta activo
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL
);

-- Indice unico para evitar duplicados
CREATE UNIQUE INDEX index_notification_event_configs_on_event_key ON notification_event_configs (event_key);
```

**Validaciones del modelo:**
- `event_key`: presence + uniqueness
- `title`: presence
- Scope `active`: filtra solo registros con `active: true`

### Eventos configurados por defecto

Se crean via `db/seeds.rb` con `find_or_initialize_by(:event_key)` (idempotente):

| `event_key` | `title` | `body_template` | Browser | Sound | In-app |
|---|---|---|---|---|---|
| `new_booking` | Nueva reserva | `{{customer_name}} reservó {{service_name}}` | true | true | true |
| `payment_submitted` | Comprobante recibido | `{{customer_name}} envió un comprobante` | true | true | true |
| `booking_confirmed` | Pago confirmado | `Pago confirmado para {{customer_name}}` | true | true | true |
| `booking_cancelled` | Cita cancelada | `{{customer_name}} canceló su cita` | true | true | true |
| `appointment_completed` | Cita completada | `{{customer_name}} completó su cita` | false | false | true |
| `ai_suggestion` | Sugerencia inteligente | `Detectamos oportunidades para optimizar tus precios` | false | false | true |

### Interpolacion de variables (`body_template`)

El `body_template` soporta placeholders con sintaxis `{{variable}}`. El frontend reemplaza cada `{{key}}` con el valor correspondiente del payload del evento NATS.

**Variables disponibles** (dependen del evento):
- `{{customer_name}}` — nombre del usuario final
- `{{service_name}}` — nombre del servicio reservado

Funcion de interpolacion en el frontend:

```typescript
function renderTemplate(template: string, data: Record<string, unknown>): string {
  return template.replace(/\{\{(\w+)\}\}/g, (_, key) => String(data[key] || ''));
}
```

### API Endpoint

```
GET /api/v1/notification_config
```

**Publico, sin autenticacion.** La configuracion es global (no depende del negocio ni del usuario). Retorna solo los eventos activos, ordenados por `event_key`.

**Ejemplo con curl:**

```bash
curl -s https://api.agendity.com/api/v1/notification_config | jq
```

**Respuesta:**

```json
{
  "success": true,
  "data": [
    {
      "event_key": "ai_suggestion",
      "title": "Sugerencia inteligente",
      "body_template": "Detectamos oportunidades para optimizar tus precios",
      "browser_notification": false,
      "sound_enabled": false,
      "in_app_notification": true
    },
    {
      "event_key": "booking_cancelled",
      "title": "Cita cancelada",
      "body_template": "{{customer_name}} canceló su cita",
      "browser_notification": true,
      "sound_enabled": true,
      "in_app_notification": true
    }
  ]
}
```

**Archivos clave del endpoint:**
- Controller: `app/controllers/api/v1/notification_config_controller.rb`
- Ruta: `config/routes.rb` → `get "notification_config", to: "notification_config#index"`

### Frontend: `useEventNotifications`

El hook `useEventNotifications` (`agendity-web/src/lib/hooks/use-event-notifications.ts`) conecta la configuracion del servidor con el sistema de notificaciones en tiempo real.

**Flujo:**

1. Al montar, hace `GET /api/v1/notification_config` via TanStack Query (cache 5 min, `staleTime: 5 * 60 * 1000`)
2. Cuando llega un evento NATS, busca la config del servidor por `event_key`
3. Si no hay config del servidor, usa el **fallback hardcoded** (`FALLBACK_CONFIG`)
4. Segun la config:
   - Si `browser_notification: true` → muestra notificacion del navegador con titulo y body interpolado
   - Si `sound_enabled: true` **Y** el usuario tiene sonido habilitado en su UI → reproduce sonido
5. Siempre invalida las queries relevantes (appointments, payments, notifications, etc.)

**Prioridad de config:** server config > fallback hardcoded > desactivado

```
Evento NATS llega
       |
  ¿Existe config del servidor para este event_key?
     /          \
    Si           No
    |            |
  Usar config   ¿Existe FALLBACK_CONFIG?
  del servidor     /          \
                  Si           No
                  |            |
               Usar fallback  Ignorar (no notification)
```

### ActiveAdmin (SuperAdmin)

El CRUD esta registrado en `app/admin/notification_event_configs.rb`:

- **Menu:** Settings → Notification Events
- **Acciones:** listar, ver, crear, editar, eliminar
- **Filtros:** por `event_key`, `title`, y cada flag booleano
- **Formulario:** todos los campos editables, con hint en `body_template` mostrando las variables disponibles

Esto permite al SuperAdmin:
- Desactivar un tipo de notificacion (ej: desactivar `ai_suggestion`) sin tocar codigo
- Cambiar el texto de una notificacion (ej: mejorar el copy de `new_booking`)
- Activar/desactivar browser push o sonido por tipo de evento

### Como agregar un nuevo tipo de evento

1. **Seeds:** agregar un nuevo hash en el array `notification_events` en `db/seeds.rb`:
   ```ruby
   {
     event_key: "new_event_key",
     title: "Titulo visible",
     body_template: "{{variable1}} hizo algo con {{variable2}}",
     browser_notification: true,
     sound_enabled: true,
     in_app_notification: true,
     active: true
   }
   ```
   Ejecutar `rails db:seed` (es idempotente, no duplica registros existentes).

2. **Frontend fallback:** agregar la entrada correspondiente en `FALLBACK_CONFIG` dentro de `use-event-notifications.ts`:
   ```typescript
   new_event_key: {
     title: 'Titulo visible',
     body_template: '{{variable1}} hizo algo con {{variable2}}',
     browser_notification: true,
     sound_enabled: true,
   },
   ```

3. **Query invalidation:** en el `handleEvent` del mismo hook, agregar las invalidaciones de cache necesarias:
   ```typescript
   if (event === 'new_event_key') {
     queryClient.invalidateQueries({ queryKey: ['relevant-query'] });
   }
   ```

4. **Backend publish:** asegurarse de que el job o servicio que genera el evento publique al subject NATS correcto con los datos que el template necesita (ej: `customer_name`, `service_name`).

5. **ActiveAdmin:** no requiere cambios — el nuevo registro aparece automaticamente en el CRUD tras el seed.
