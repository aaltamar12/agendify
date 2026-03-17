# Flujos Completos — Agendify

> Ultima actualizacion: 2026-03-16
> **Fase del proyecto:** Pre-lanzamiento

Este documento contiene diagramas Mermaid detallados de todos los flujos del sistema Agendify, incluyendo todos los actores, estados, jobs en background, y comunicacion en tiempo real.

---

## Tabla de contenido

1. [Diagrama 1: Ciclo de vida completo de una reserva (end-to-end)](#diagrama-1-ciclo-de-vida-completo-de-una-reserva)
2. [Diagrama 2: Mapa de acciones por actor](#diagrama-2-mapa-de-acciones-por-actor)
3. [Diagrama 3: Maquina de estados de una cita (Appointment)](#diagrama-3-maquina-de-estados-de-una-cita)
4. [Diagrama 4: Flujo de cancelacion](#diagrama-4-flujo-de-cancelacion)
5. [Diagrama 5: Flujo de pagos con ciclo de rechazo](#diagrama-5-flujo-de-pagos-con-ciclo-de-rechazo)
6. [Notas tecnicas importantes](#notas-tecnicas-importantes)

---

## Diagrama 1: Ciclo de vida completo de una reserva

### 1A. Versión simplificada (Flowchart)

Flujo visual del ciclo de vida de una reserva con decisiones y actores.

```mermaid
flowchart TD
    START([Usuario visita pagina]) --> SEL[Selecciona servicio y profesional]
    SEL --> DATOS[Ingresa datos personales]
    DATOS --> CONFIRMA[Confirma reserva]
    CONFIRMA --> CITA[Cita creada]

    CITA --> NOTIF[Notificacion al negocio]
    CITA --> INSTR[Instrucciones de pago]

    INSTR --> D1{El cliente paga}
    D1 -->|Si| SUBE[Sube comprobante]
    D1 -->|No 15min| REC[Negocio envia recordatorio]
    REC --> D1
    D1 -->|Cancela| D4{Dentro del plazo}

    SUBE --> D2{Email valido}
    D2 -->|No| ERR[Identidad no verificada]
    D2 -->|Si| COMP[Comprobante enviado]

    COMP --> NOTIF2[Notificacion al negocio]
    COMP --> D3{Negocio revisa}

    D3 -->|Aprueba| CONF[Cita confirmada]
    D3 -->|Rechaza| RECH[Comprobante rechazado]
    RECH --> EMAILR[Email al cliente]
    EMAILR --> SUBE

    CONF --> D5{Plan Pro}
    D5 -->|Si| VIP[Ticket VIP con QR]
    D5 -->|No| BAS[Ticket basico]
    CONF --> EMAILC[Email confirmacion]
    CONF --> REC24[Recordatorio 24h antes]

    CONF --> LLEGA[Cliente llega]
    LLEGA --> CHK[Check-in con codigo]
    CHK --> SERV[Se realiza el servicio]
    SERV --> DONE[Completado]

    D4 -->|Si| CANC1[Sin penalizacion]
    D4 -->|No| CANC2[Con penalizacion]

    style CITA fill:#FEF3C7,stroke:#F59E0B
    style COMP fill:#DBEAFE,stroke:#3B82F6
    style CONF fill:#D1FAE5,stroke:#10B981
    style CHK fill:#EDE9FE,stroke:#7C3AED
    style DONE fill:#D1FAE5,stroke:#10B981
    style RECH fill:#FEE2E2,stroke:#EF4444
    style CANC1 fill:#FEE2E2,stroke:#EF4444
    style CANC2 fill:#FEE2E2,stroke:#EF4444
    style VIP fill:#EDE9FE,stroke:#7C3AED
    style ERR fill:#FEE2E2,stroke:#EF4444
    style ERROR_ID fill:#FEE2E2,stroke:#EF4444
```

### 1B. Versión detallada (Sequence Diagram)

Diagrama de secuencia que muestra CADA paso desde que un usuario final visita la pagina del negocio hasta el check-in y completado del servicio. Incluye todos los actores del sistema.

```mermaid
sequenceDiagram
    participant UF as Usuario Final
    participant FE as Frontend (Next.js)
    participant API as Backend (Rails)
    participant RD as Redis
    participant PG as PostgreSQL
    participant SK as Sidekiq Jobs
    participant NATS as NATS Server
    participant NEG as Negocio (Dashboard)
    participant SA as SuperAdmin (ActiveAdmin)

    Note over UF,SA: FASE 1 — Reserva

    UF->>FE: Visita /{slug}
    FE->>API: GET /api/v1/public/businesses/{slug}
    API->>PG: SELECT business + services + employees
    API-->>FE: Business + services + employees + horarios

    UF->>FE: Selecciona servicio(s) (principal + adicionales)
    UF->>FE: Selecciona profesional (filtrado por servicio)
    UF->>FE: Selecciona fecha y hora disponible

    Note over FE,RD: Proteccion de concurrencia — Capa 1: Redis Lock

    FE->>API: POST /{slug}/lock_slot (employee_id, date, time)
    API->>RD: SET NX slot_lock:biz:emp:date:time (TTL 5min)
    RD-->>API: OK (o FAIL si ya esta bloqueado)
    API-->>FE: { lock_token: "abc123" }

    UF->>FE: Ingresa datos personales (nombre, email, telefono)
    Note over FE: localStorage precarga datos si el email ya se uso antes

    UF->>FE: Confirma reserva

    FE->>API: POST /{slug}/book (lock_token, service_ids, employee_id, date, time, customer_data)

    Note over API,PG: Proteccion de concurrencia — Capa 2: SELECT FOR UPDATE
    API->>PG: BEGIN TRANSACTION
    API->>PG: SELECT FOR UPDATE appointments WHERE employee+date
    API->>API: Valida disponibilidad (no overlap)
    API->>API: Verifica pending_penalty del customer
    API->>PG: INSERT appointment (status: pending_payment)
    API->>API: Genera ticket_code (SIEMPRE, independiente del plan)
    API->>PG: INSERT/FIND customer por email
    API->>PG: COMMIT
    Note over PG: Capa 3: unique index impide duplicados como ultimo recurso

    API->>RD: DEL slot_lock (libera el lock)
    API-->>FE: { appointment, ticket_code, business (vista with_payment) }

    API->>SK: SendNewBookingNotificationJob.perform_async(appointment_id)
    SK->>PG: Crea Notification in-app (tipo: new_booking)
    SK->>SK: AppointmentMailer.new_booking → email al negocio
    SK->>NATS: Publica evento "new_booking" en canal del negocio
    NATS->>NEG: WebSocket → actualiza calendario en tiempo real
    NEG->>NEG: Notificacion del navegador (Notification API) + sonido (Web Audio API)

    FE->>FE: Muestra confirmacion + instrucciones de pago + QR del ticket_code

    Note over SA: El SuperAdmin ve en ActivityLog: "booking_created" + "notification_sent"

    Note over UF,SA: FASE 2 — Pago (modelo P2P)

    UF->>FE: Abre pagina del ticket /{slug}/ticket/{code}
    FE->>API: GET /api/v1/public/tickets/{code}
    API-->>FE: Appointment + Business (con datos de pago: Nequi, Daviplata, Bancolombia)

    Note over UF: El usuario ve instrucciones de pago con botones de copiar para cada metodo
    UF->>UF: Realiza transferencia desde su app bancaria (Nequi/Daviplata/Bancolombia)
    UF->>FE: Sube comprobante (imagen, max 5MB)
    FE->>API: POST /api/v1/public/tickets/{code}/payment (multipart: proof + payment_method + customer_email)
    API->>API: Valida identidad (customer_email debe coincidir con el email de la reserva)
    API->>API: ActiveStorage guarda la imagen del comprobante
    API->>PG: INSERT Payment (status: submitted)
    API->>PG: UPDATE Appointment (status: payment_sent)
    API-->>FE: OK — Ticket cambia a vista "Comprobante en revision"

    API->>SK: SendPaymentSubmittedJob.perform_async(payment_id)
    SK->>PG: Crea Notification in-app (tipo: payment_submitted)
    SK->>SK: BusinessMailer.payment_submitted → email al negocio
    SK->>NATS: Publica evento "payment_submitted"
    NATS->>NEG: Actualiza pagina de pagos en tiempo real
    NEG->>NEG: Notificacion: "Comprobante recibido de {cliente}"

    Note over NEG: Si el cliente no sube comprobante en 15 min:
    NEG->>FE: Ve cita en tab "Sin comprobante" con boton "Notificar al cliente"
    NEG->>API: POST /api/v1/appointments/{id}/remind_payment
    API->>API: Valida: cita en pending_payment + cliente tiene email
    API->>SK: AppointmentMailer.payment_reminder → email recordatorio al cliente

    Note over UF,SA: FASE 3 — Aprobacion del pago

    NEG->>FE: Abre /dashboard/payments → Tab "Pendientes"
    NEG->>FE: Ve comprobante (thumbnail + modal con zoom via ImageViewerModal)

    alt Negocio aprueba el comprobante
        NEG->>API: POST /api/v1/payments/{id}/approve
        API->>PG: UPDATE Payment (status: approved)
        API->>PG: UPDATE Appointment (status: confirmed)
        API-->>NEG: OK

        API->>SK: SendBookingConfirmedJob.perform_async(appointment_id)
        SK->>SK: AppointmentMailer.booking_confirmed → email al cliente con ticket_code
        SK->>NATS: Publica evento "booking_confirmed"
        NATS->>NEG: WebSocket → actualiza calendario

        Note over UF: El cliente ve el ticket VIP (si plan Pro+) o ticket simplificado (plan Basico)
    else Negocio rechaza el comprobante
        NEG->>FE: Clic en "Rechazar" → Modal pide motivo (opcional)
        NEG->>API: POST /api/v1/payments/{id}/reject { rejection_reason: "..." }
        API->>PG: UPDATE Payment (status: rejected, rejection_reason, rejected_at)
        API->>PG: UPDATE Appointment (status: pending_payment)
        API->>SK: AppointmentMailer.payment_rejected → email al cliente con motivo
        API-->>NEG: OK

        Note over UF: El cliente ve alerta roja en ticket: "Comprobante rechazado. Motivo: ..."
        UF->>FE: Sube nuevo comprobante (se repite el ciclo desde Fase 2)
    end

    Note over UF,SA: FASE 4 — Recordatorio (24h antes)

    Note over SK: Cron: AppointmentReminderSchedulerJob (8am diario)
    SK->>PG: SELECT citas confirmed de manana
    SK->>SK: Encola SendReminderJob por cada cita
    SK->>SK: AppointmentMailer.reminder → email al cliente (solo si sigue confirmed)

    Note over UF,SA: FASE 5 — Check-in

    UF->>NEG: Llega al negocio, muestra ticket con QR o codigo
    NEG->>FE: Abre /dashboard/checkin
    NEG->>FE: Ingresa codigo del ticket (manual o escaneo QR)
    FE->>API: POST /api/v1/public/checkin_by_code { code: "ABC123" }
    API->>PG: UPDATE Appointment (status: checked_in, checked_in_at: Time.current)
    API-->>FE: OK — Muestra confirmacion verde con datos de la cita

    Note over UF,SA: FASE 6 — Completado

    NEG->>API: POST /api/v1/appointments/{id}/complete
    API->>PG: UPDATE Appointment (status: completed)
    API-->>NEG: OK

    Note over SA: SuperAdmin ve el ciclo completo en ActivityLog y Request Logs
```

---

## Diagrama 2: Mapa de acciones por actor

Diagrama que muestra lo que cada actor puede hacer en el sistema.

```mermaid
flowchart TB
    subgraph UF["Usuario Final (sin cuenta)"]
        UF1[Buscar negocios en /explore]
        UF2[Ver pagina publica del negocio]
        UF3[Reservar cita - 5 pasos]
        UF4[Ver ticket con instrucciones de pago]
        UF5[Subir comprobante de pago]
        UF6[Ver estado del ticket en tiempo real]
        UF7[Descargar ticket como PNG]
        UF8[Compartir ticket via Web Share API]
        UF9[Cancelar cita desde ticket]
        UF10[Escribir resena del negocio]
        UF11[Ver mapa de negocios]
    end

    subgraph NEG["Negocio - Dashboard"]
        N1[Ver agenda dia/semana con FullCalendar]
        N2[Crear cita manual]
        N3[Mover cita con drag-and-drop]
        N4[Bloquear horarios]
        N5[Aprobar comprobante de pago]
        N6[Rechazar comprobante con motivo]
        N7[Notificar cliente sin comprobante - 15min]
        N8[Check-in con codigo de ticket]
        N9[Completar servicio]
        N10[Cancelar cita - sin penalizacion]
        N11[Ver reportes e ingresos]
        N12[Gestionar servicios - CRUD]
        N13[Gestionar empleados - CRUD]
        N14[Ver base de datos de clientes]
        N15[Configurar perfil y logo]
        N16[Configurar horarios de operacion]
        N17[Configurar metodos de pago]
        N18[Configurar politica de cancelacion]
        N19[Personalizar colores - Pro+]
        N20[Generar y descargar QR de reservas]
        N21[Ver resenas - Pro+]
        N22[Gestionar notificaciones]
        N23[Toggle sonido de notificaciones]
    end

    subgraph NEG2["Negocio - Configuracion de agenda"]
        NC1[Configurar hora de almuerzo - toggle + inicio/fin]
        NC2[Configurar intervalo de slots - 15/20/30/45/60 min]
        NC3[Configurar descanso entre citas - 0/5/10/15 min]
        NC4[Seleccionar ubicacion con mapa interactivo - Leaflet]
    end

    subgraph SA["SuperAdmin - ActiveAdmin"]
        SA1[Ver dashboard con metricas globales]
        SA2[Gestionar negocios - CRUD + aprobar/suspender/activar]
        SA3[Gestionar usuarios - CRUD con roles]
        SA4[Gestionar planes - precios, limites, features]
        SA5[Gestionar suscripciones - cambiar plan o estado]
        SA6[Ver citas - solo lectura]
        SA7[Ver resenas - solo lectura]
        SA8[Ver clientes - solo lectura + historial]
        SA9[Ver Activity Logs - ciclo de vida completo por recurso]
        SA10[Ver Request Logs - monitoreo API + errores 5xx]
        SA11[Gestionar ordenes de pago de suscripcion]
        SA12[Marcar pagos de suscripcion como recibidos]
        SA13[Observar como negocio - impersonation]
        SA14[Ver documentacion tecnica renderizada]
        SA15[Eliminar activity logs]
    end

    subgraph SYS["Sistema - Automatico"]
        S1[SendNewBookingNotificationJob — email + in-app + NATS al crear reserva]
        S2[SendPaymentSubmittedJob — email + in-app + NATS al subir comprobante]
        S3[SendBookingConfirmedJob — email al cliente + NATS al aprobar pago]
        S4[SendBookingCancelledJob — email a ambos + in-app + NATS al cancelar]
        S5[SendReminderJob — email recordatorio 24h antes]
        S6[AppointmentReminderSchedulerJob — cron 8am, encola reminders]
        S7[CleanupExpiredTokensJob — cron domingo 3am, limpia tokens]
        S8[CleanupOldRequestLogsJob — cron domingo 4am, limpia logs viejos]
        S9[GenerateSubscriptionPaymentOrdersJob — cron 1am, genera ordenes 7 dias antes]
        S10[CheckExpiredSubscriptionsJob — cron 12:05am, expira y downgrade a Basico]
        S11[SendSubscriptionReminderJob — cron 9am, recordatorio 3 dias antes]
        S12[Notificaciones del navegador via Notification API + sonido Web Audio API]
        S13[Tiempo real via NATS WebSocket + fallback polling 15s/30s]
        S14[Almuerzo automatico en disponibilidad segun config del negocio]
        S15[Gap entre citas segun config del negocio]
    end
```

---

## Diagrama 3: Maquina de estados de una cita

Diagrama de estados que muestra todas las transiciones posibles de una cita (`Appointment`).

```mermaid
stateDiagram-v2
    [*] --> pending_payment: Reserva creada (ticket_code generado)

    pending_payment --> payment_sent: Cliente sube comprobante
    pending_payment --> cancelled: Cancelacion (negocio o cliente)

    payment_sent --> confirmed: Negocio aprueba comprobante
    payment_sent --> pending_payment: Negocio rechaza comprobante (ciclo de reintento)
    payment_sent --> cancelled: Cancelacion (negocio o cliente)

    confirmed --> checked_in: Check-in (negocio ingresa codigo/QR)
    confirmed --> cancelled: Cancelacion (negocio o cliente)

    checked_in --> completed: Negocio marca servicio como terminado

    cancelled --> [*]
    completed --> [*]

    note right of pending_payment
        ticket_code ya existe (siempre se genera)
        15 min sin comprobante: negocio puede notificar
        Si hubo rechazo previo: alerta roja en ticket
    end note

    note right of payment_sent
        Negocio ve comprobante en tab "Pendientes"
        Puede aprobar o rechazar con motivo
    end note

    note right of confirmed
        Recordatorio automatico 24h antes (email)
        Ticket VIP visible (solo plan Pro+)
    end note

    note right of cancelled
        cancelled_by: 'business' o 'customer'
        Si cliente cancela fuera de plazo: penalizacion
        Penalizacion se suma a customer.pending_penalty
        Slot liberado inmediatamente
    end note

    note right of checked_in
        checked_in_at registrado
        Solo falta marcar como completado
    end note
```

### Tabla resumen de estados

| Estado | Valor enum | Significado | Quien lo cambia |
|---|---|---|---|
| `pending_payment` | 0 | Reservada, esperando pago | Sistema (al crear cita) |
| `payment_sent` | 1 | Comprobante subido, en revision | Usuario final |
| `confirmed` | 2 | Pago aprobado, cita confirmada | Negocio (dashboard) |
| `checked_in` | 3 | Cliente llego, QR escaneado | Negocio (checkin) |
| `cancelled` | 4 | Cita cancelada | Negocio o usuario |
| `completed` | 5 | Servicio realizado | Negocio |

### Tabla resumen de estados del pago (Payment)

| Estado | Significado |
|---|---|
| `submitted` | Comprobante subido, esperando revision |
| `approved` | Negocio confirmo el pago |
| `rejected` | Comprobante rechazado (con motivo opcional) |

---

## Diagrama 4: Flujo de cancelacion

Diagrama que muestra la logica de cancelacion diferenciada por actor, con calculo de penalizacion.

```mermaid
flowchart TD
    A[Solicitud de cancelacion] --> B{Quien cancela?}

    B -->|Negocio| C[Cancelacion sin penalizacion]
    C --> C1[cancelled_by: 'business']

    B -->|Cliente / Usuario final| D{Dentro del plazo?}
    D -->|"Si: faltan mas horas que<br/>cancellation_deadline_hours"| E[Cancelacion sin penalizacion]
    E --> E1[cancelled_by: 'customer']

    D -->|"No: faltan menos horas<br/>que el deadline"| F[Cancelacion con penalizacion]
    F --> F1["Calcula: precio x (cancellation_policy_pct / 100)"]
    F1 --> F2[Suma monto a customer.pending_penalty]
    F2 --> F3[cancelled_by: 'customer']

    C1 --> G[Appointment → cancelled]
    E1 --> G
    F3 --> G

    G --> H[Slot liberado inmediatamente]
    G --> I[Redis lock eliminado si existe]
    G --> J[SendBookingCancelledJob encolado]

    J --> K[Email al negocio + Email al cliente]
    J --> L["Notificacion in-app diferenciada:<br/>'Cancelada por Negocio' vs 'El cliente cancelo'"]
    J --> M[NATS: booking_cancelled → actualiza dashboard]
    J --> N[ActivityLog: cancelled + cancelled_by]

    style A fill:#7c3aed,color:#fff
    style C fill:#22c55e,color:#fff
    style E fill:#22c55e,color:#fff
    style F fill:#ef4444,color:#fff
    style G fill:#6b7280,color:#fff
```

### Cobro de penalizacion en proxima reserva

```mermaid
flowchart TD
    K[Cliente hace nueva reserva] --> L{customer.pending_penalty > 0?}
    L -->|Si| M["Precio total = precio servicio + pending_penalty"]
    M --> N[Se muestra desglose en confirmacion]
    N --> O[Se crea cita con precio total]
    O --> P[Se resetea pending_penalty a 0]
    L -->|No| Q[Precio normal del servicio]
    Q --> O

    style K fill:#7c3aed,color:#fff
    style M fill:#f59e0b,color:#fff
    style Q fill:#22c55e,color:#fff
```

### Casos especiales de cancelacion

- Si `cancellation_policy_pct` es `0`: nunca se genera penalizacion (politica desactivada)
- Si la cita esta en `pending_payment` (no pagada): no se aplica penalizacion
- Las penalizaciones se **acumulan**: si el usuario cancela dos citas tarde, ambas se suman en `pending_penalty`
- Cada negocio configura su politica desde Settings > Cancelacion

---

## Diagrama 5: Flujo de pagos con ciclo de rechazo

Diagrama detallado del flujo de pagos P2P, incluyendo el ciclo completo de rechazo y reintento.

```mermaid
flowchart TD
    A["Cita creada<br/>status: pending_payment<br/>ticket_code: generado"] --> B[Cliente ve instrucciones de pago en ticket]
    B --> B1["Muestra datos de Nequi / Daviplata / Bancolombia<br/>con botones de copiar para cada numero/cuenta"]
    B1 --> C[Cliente paga desde su app bancaria]
    C --> D["Cliente sube comprobante (imagen, max 5MB)"]
    D --> E{Validacion de identidad}
    E -->|"customer_email coincide<br/>con email de la reserva"| F["Payment creado (status: submitted)"]
    E -->|"Email NO coincide"| G["Error 403<br/>'No tienes permiso para subir comprobante en esta cita'"]

    F --> H["Appointment → payment_sent"]
    H --> H1[SendPaymentSubmittedJob]
    H1 --> H2["Email + in-app + NATS al negocio"]

    H --> I["Negocio ve en tab 'Pendientes'"]
    I --> I1["Abre ImageViewerModal para ver comprobante con zoom"]
    I1 --> J{Negocio revisa comprobante}

    J -->|Aprobar| K["Payment → approved"]
    K --> L["Appointment → confirmed"]
    L --> L1[SendBookingConfirmedJob]
    L1 --> L2["Email al cliente con ticket_code"]
    L2 --> M{Plan del negocio?}
    M -->|"Profesional o Inteligente"| M1["Cliente ve Ticket VIP<br/>(boarding pass + QR + descargar PNG + compartir)"]
    M -->|"Basico"| M2["Cliente ve ticket simplificado<br/>(datos de la cita + codigo)"]

    J -->|"Rechazar + motivo"| N["Payment → rejected<br/>rejection_reason guardado<br/>rejected_at registrado"]
    N --> O["Appointment → pending_payment"]
    O --> P["AppointmentMailer.payment_rejected<br/>Email al cliente: 'Comprobante rechazado. Motivo: ...'"]
    P --> Q["Cliente ve alerta roja en ticket:<br/>'Tu comprobante fue rechazado'"]
    Q --> D

    A -->|"15 min sin comprobante"| R["Negocio ve en tab 'Sin comprobante'"]
    R --> S["Boton 'Notificar al cliente'"]
    S --> T["POST /appointments/{id}/remind_payment"]
    T --> U["AppointmentMailer.payment_reminder<br/>Email recordatorio al cliente"]

    style A fill:#7c3aed,color:#fff
    style F fill:#3b82f6,color:#fff
    style K fill:#22c55e,color:#fff
    style N fill:#ef4444,color:#fff
    style G fill:#ef4444,color:#fff
    style M1 fill:#7c3aed,color:#fff
    style M2 fill:#6b7280,color:#fff
```

### Emails del sistema de pagos

| Email | Mailer method | Destinatario | Cuando se envia |
|---|---|---|---|
| Recordatorio de pago | `AppointmentMailer#payment_reminder` | Cliente | Negocio hace clic en "Notificar" (despues de 15 min) |
| Comprobante rechazado | `AppointmentMailer#payment_rejected` | Cliente | Negocio rechaza un comprobante (incluye motivo) |
| Cita confirmada | `AppointmentMailer#booking_confirmed` | Cliente | Negocio aprueba el pago |
| Comprobante recibido | `BusinessMailer#payment_submitted` | Negocio | Cliente sube comprobante |

---

## Notas tecnicas importantes

### ticket_code: siempre se genera

El `ticket_code` se genera **al momento de crear la cita** (`CreateAppointmentService`), no al aprobar el pago. Esto es independiente del plan del negocio. El codigo permite:
- Identificar la cita en el tab "Sin comprobante" del dashboard de pagos
- Que el negocio busque pagos por codigo de ticket
- Check-in por codigo (el negocio ingresa el codigo)
- URLs del ticket: `/{slug}/ticket/{code}`

Lo que es **exclusivo del plan Profesional+** es la visualizacion VIP del ticket: diseno boarding pass, QR visible, descarga como PNG, compartir via Web Share API.

### Background jobs: Sidekiq + Redis

Todos los jobs se procesan con Sidekiq (colas: `default` y `low`). Cada job que afecta la UI del dashboard publica un evento en NATS para actualizar en tiempo real.

### Tiempo real: NATS + fallback polling

- **Canal primario:** NATS WebSocket (actualizacion instantanea del calendario y pagos)
- **Fallback:** Polling automatico (calendario cada 15s, notificaciones cada 30s)
- Las notificaciones del navegador usan la Notification API nativa + sonido configurable con Web Audio API

### Datos de pago: encriptados

Los datos de pago del negocio (`nequi_phone`, `daviplata_phone`, `bancolombia_account`) estan encriptados en la base de datos con `Rails.encrypts` y filtrados en logs.

### Proteccion de concurrencia: 3 capas

| Capa | Mecanismo | Protege contra | Efectividad |
|---|---|---|---|
| 1 | Redis SETNX (lock 5min) | Dos usuarios en el formulario al mismo tiempo | ~99.9% |
| 2 | SELECT FOR UPDATE (transaccion) | Race condition entre SELECT e INSERT | ~99.99% |
| 3 | Unique index parcial (PostgreSQL) | Cualquier edge case restante | 100% |

### Penalizaciones por cancelacion

Las penalizaciones se rastrean en `customer.pending_penalty` y se cobran automaticamente en la siguiente reserva del cliente. Cada negocio configura:
- `cancellation_policy_pct`: 0%, 30%, 50%, 100%
- `cancellation_deadline_hours`: horas minimas antes de la cita para cancelar sin penalizacion

### SuperAdmin: visibilidad completa

El SuperAdmin (ActiveAdmin) tiene acceso a:
- **Activity Logs:** auditoria de todas las acciones del sistema (booking_created, payment_approved, business_suspended, etc.)
- **Request Logs:** registro de todas las peticiones HTTP a la API (metodo, path, status, duracion, IP)
- **Ordenes de pago de suscripcion:** gestion manual de pagos de suscripcion de negocios (modelo P2P)
- **Dashboard de metricas:** totales de negocios, usuarios, citas, ingresos
