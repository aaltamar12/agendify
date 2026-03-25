# Costos Operativos — Agendity

> Ultima actualizacion: 2026-03-23

---

## 1. Inventario completo de notificaciones

### 1.1 Notificaciones al usuario final (quien reserva)

| # | Evento | Email | WhatsApp (Pro+) | Trigger |
|---|--------|:-----:|:----------------:|---------|
| 1 | Cita confirmada (pago aprobado) | Si | Si (MultiChannel) | Negocio aprueba comprobante |
| 2 | Recordatorio 24h antes | Si | Si (MultiChannel) | Job diario 8am |
| 3 | Cita cancelada | Si | Si (MultiChannel) | Negocio o usuario cancela |
| 4 | Solicitud de calificacion | Si | Si (MultiChannel) | 15 min despues de completar cita |
| 5 | Recordatorio de pago (manual) | Si | Si (MultiChannel) | Negocio envia manualmente |
| 6 | Comprobante rechazado | Si | Si (MultiChannel) | Negocio rechaza comprobante |
| 7 | Cashback ganado | Si | No (solo email) | Al completar cita con cashback activo |

**WhatsApp al usuario final:** Solo planes Profesional e Inteligente (`plan.whatsapp_notifications?`). Plan Basico solo email.
**Cashback:** Se notifica solo por email para no gastar conversaciones WhatsApp adicionales. La info de cashback se puede anadir al template WhatsApp de booking_confirmed en el futuro.

### 1.2 Notificaciones al negocio (cliente de Agendity)

| # | Evento | Email | In-app | NATS (real-time) | WhatsApp (Pro+) | Trigger |
|---|--------|:-----:|:------:|:----------------:|:---------------:|---------|
| 1 | Nueva reserva | Si | Si | Si | No | Usuario crea reserva |
| 2 | Comprobante recibido | Si | Si | Si | No | Usuario sube comprobante |
| 3 | Cita cancelada | Si | Si | Si | No | Usuario o negocio cancela |
| 4 | Alerta suscripcion (5 dias antes) | Si | Si | Si | Si | Job diario 8am |
| 5 | Alerta suscripcion (dia de vencimiento) | Si | Si | Si | Si | Job diario 8am |
| 6 | Alerta suscripcion (2 dias despues + suspension) | Si | Si | Si | Si | Job diario 8am |
| 7 | Suscripcion renovada | Si | Si | Si | Si | Admin confirma pago |
| 8 | Suscripcion expirada (downgrade) | Si | Si | No | No | Job diario 12:05am |
| 9 | Recordatorio pago suscripcion (3 dias antes) | Si | Si | No | No | Job diario 9am |
| 10 | Aviso renovacion (7 dias antes) | No | Si | No | No | Job diario 1am |
| 11 | Sugerencia tarifas dinamicas (IA) | No | Si | Si | No | Job 1ro y 15 de cada mes |

### 1.3 Notificaciones de cuenta

| # | Evento | Email | Trigger |
|---|--------|:-----:|---------|
| 1 | Reset de contrasena | Si | Usuario solicita |
| 2 | Invitacion de empleado | Si | Dueno invita empleado |

### 1.4 Conteo por cita completada (happy path)

```
FLUJO: Reserva → Comprobante → Aprobacion → Recordatorio → Check-in → Completada → Rating

Emails (costo externo):
  → Al negocio: nueva reserva (1) + comprobante recibido (1) = 2
  → Al usuario: confirmacion (1) + recordatorio 24h (1) + rating request (1) + cashback ganado (1) = 4
  TOTAL: 6 emails

WhatsApp (costo externo, SOLO negocios Pro+):
  → Al usuario: confirmacion (1) + recordatorio (1) + rating (1) = 3
  TOTAL: 3 WhatsApp (plan Basico = 0)

In-app + NATS (costo interno — consume CPU/RAM/DB del VPS):
  → nueva reserva: 1 insert Notification + 1 publish NATS
  → comprobante recibido: 1 insert Notification + 1 publish NATS
  → confirmacion: 1 publish NATS
  → cita completada: 1 publish NATS
  TOTAL: 2 inserts DB + 4 publishes NATS por cita
```

### 1.5 Conteo por cita cancelada

Solo cuenta lo que ocurre al momento de cancelar (la nueva reserva ya se envio antes).

```
Emails (costo externo):
  → Al negocio: cancelacion (1)
  → Al usuario: cancelacion via MultiChannel (1)
  TOTAL: 2 emails

WhatsApp (costo externo, SOLO Pro+):
  → Al usuario: cancelacion (1)
  TOTAL: 1 WhatsApp

In-app + NATS (costo interno):
  → 1 insert Notification + 1 publish NATS
```

### 1.6 Conteo por ciclo de suscripcion (mensual, por negocio)

```
Happy path (paga a tiempo):
  Emails: renovada (1) = 1 email
  WhatsApp (Pro+): renovada (1) = 1
  In-app: aviso renovacion 7d (1) + renovada (1) = 2 inserts + 1 NATS

Pago tardio (pasa por las 3 alertas):
  Emails: recordatorio 3d (1) + alerta 5d (1) + alerta dia 0 (1) + alerta +2d (1) + expirada (1) = 5 emails
  WhatsApp (Pro+): alerta 5d (1) + alerta dia 0 (1) + alerta +2d (1) = 3
  In-app: 5 inserts + 3 NATS publishes
```

### 1.7 Carga interna del VPS por notificaciones (in-app + NATS)

Las notificaciones in-app y NATS no tienen costo externo pero consumen recursos del servidor:

- **Notification insert:** 1 write a PostgreSQL por notificacion in-app
- **NATS publish:** 1 mensaje WebSocket al navegador del negocio (~pocos KB)
- **Polling frontend:** Cada sesion activa hace GET /notifications/unread_count cada 30s

**Carga estimada por escala:**

| Negocios | Citas/mes | Inserts Notification/mes | NATS publishes/mes | Sesiones activas (polling) |
|----------|-----------|--------------------------|--------------------|-----------------------------|
| 30 | 7,200 | ~16,000 | ~30,000 | ~15-30 simultaneas |
| 100 | 24,000 | ~53,000 | ~100,000 | ~50-100 simultaneas |
| 300 | 72,000 | ~160,000 | ~300,000 | ~150-300 simultaneas |
| 1,000 | 240,000 | ~530,000 | ~1,000,000 | ~500-1,000 simultaneas |

**Impacto en recursos:**
- PostgreSQL: ~530 inserts/dia (30 negocios) es trivial. A 1,000 negocios (~17,600/dia) sigue siendo bajo
- NATS: Extremadamente liviano, soporta millones de mensajes/s con <100 MB RAM
- Polling: Cada sesion = 1 query SELECT COUNT cada 30s. 300 sesiones = 10 queries/s → negligible
- **Cuello de botella real:** No son las notificaciones — es el volumen de ActiveStorage (disco) y WhatsApp (costo)

---

## 2. Infraestructura base

### 2.1 VPS OVH — $12 USD/mes

**Specs:** 6 vCPU, 12 GB RAM, 100 GB SSD NVMe

Servicios en Docker Compose:

| Servicio | RAM base | RAM bajo carga | CPU |
|----------|----------|----------------|-----|
| PostgreSQL 16 | 200 MB | 1-2 GB | Bajo |
| Redis 7 | 50 MB | 100-500 MB | Minimo |
| NATS | 30 MB | 50-100 MB | Minimo |
| Rails API (Puma, 2-4 workers) | 400 MB | 500 MB - 1 GB | Medio |
| Sidekiq (1 proceso, 5 threads) | 250 MB | 300-500 MB | Bajo |
| Nginx | 20 MB | 50 MB | Minimo |
| SO Linux | 400 MB | 500 MB | — |
| **TOTAL** | **~1.4 GB** | **~3-5 GB** | — |

**RAM:** 7-9 GB libres. Suficiente hasta ~300 negocios activos por CPU/RAM.

**Disco (100 GB) — el cuello de botella real:**
- SO + Docker images + DB + Redis + logs: ~10-15 GB base
- Queda ~85 GB utiles para archivos subidos

**Inventario completo de archivos en ActiveStorage (con limites enforced):**

Todos los attachments tienen validacion de tamano maximo y content type (solo JPG, PNG, WebP) via `AttachmentValidations` concern.

| Modelo | Attachment | Limite maximo | Tamano promedio | Quien sube | Frecuencia | Acumulativo |
|--------|-----------|---------------|-----------------|------------|------------|-------------|
| `Appointment` | `proof_image` | **2 MB** | ~1 MB | Usuario final | ~70% de citas | Si |
| `EmployeePayment` | `proof` | **2 MB** | ~1 MB | Negocio (cierre caja) | ~50% de pagos a empleados | Si |
| `SubscriptionPaymentOrder` | `proof` | **2 MB** | ~1 MB | Negocio | 1 por renovacion mensual | Si |
| `Employee` | `avatar` | **5 MB** | ~1-3 MB | Negocio | 1 por empleado (se reemplaza) | No |
| `Business` | `logo` | **5 MB** | ~1-3 MB | Negocio | 1 por negocio (se reemplaza) | No |
| `Business` | `cover_image` | **5 MB** | ~1-3 MB | Negocio o Pexels | 1 por negocio (se reemplaza) | No |
| `AdBanner` | `image` | **5 MB** | ~1-3 MB | SuperAdmin | Pocos banners | No |

**Storage fijo (no crece) por negocio:**
- Logo (~3 MB) + portada (~3 MB) + ~3 avatares empleados (~9 MB) = **~15 MB por negocio**
- 300 negocios = ~4.5 GB

**Storage acumulativo (crece cada mes):**

Supuestos por negocio/mes (peor caso con archivos al limite de 2 MB):
- 240 citas × 70% con comprobante = 168 comprobantes × 2 MB = **336 MB maximo**
- ~3 empleados × 50% transferencia × 26 dias = 39 comprobantes cierre × 2 MB = **78 MB maximo**
- 1 comprobante de suscripcion × 2 MB = **2 MB**
- **Maximo por negocio/mes: ~416 MB**

Supuestos por negocio/mes (caso realista, promedio ~1 MB):
- 168 comprobantes cita × 1 MB = **168 MB**
- 39 comprobantes cierre × 1 MB = **39 MB**
- 1 comprobante suscripcion × 1 MB = **1 MB**
- **Promedio por negocio/mes: ~208 MB**

**Calculo de storage por escala:**

| Negocios | Storage acumulativo/mes | Storage fijo (unico) | Meses hasta llenar 85 GB |
|----------|------------------------|---------------------|--------------------------|
| 30 | ~6.1 GB | ~60 MB | 14 meses |
| 50 | ~10.2 GB | ~100 MB | 8 meses |
| 100 | ~20.3 GB | ~200 MB | 4 meses |
| 200 | ~40.6 GB | ~400 MB | 2 meses |
| 300 | ~60.9 GB | ~600 MB | <1.5 meses |

**Nota:** Con 30 negocios tienes mas de 1 ano tranquilo. Con 100+ necesitas storage externo (Supabase S3-compatible) o cleanup job de comprobantes antiguos (>90 dias).

### 2.1.1 Upgrade futuro — VPS OVH 8 cores / 24 GB / 200 GB (~$24 USD/mes)

**Specs:** 8 vCPU, 24 GB RAM, 200 GB SSD NVMe

**Cuando migrar:** Al acercarse a 200-300 negocios activos o cuando el disco pase de 70 GB usados.

**Que cambia con el upgrade:**

| Recurso | VPS actual ($12) | VPS upgrade ($24) | Mejora |
|---------|------------------|-------------------|--------|
| vCPU | 6 | 8 | +33% — mas Puma workers y Sidekiq threads |
| RAM | 12 GB | 24 GB | +100% — Puma 6 workers, Sidekiq 10 threads, PostgreSQL con mas shared_buffers |
| Disco | 100 GB | 200 GB | +100% — duplica la vida util del storage |

**Capacidad estimada con el upgrade:**

Incluye todas las fuentes: comprobantes de citas, cierre de caja, suscripciones, avatares, logos, portadas.

| Negocios | Storage acumulativo/mes | Meses hasta llenar 185 GB* |
|----------|------------------------|----------------------------|
| 100 | ~20.3 GB | 9 meses |
| 200 | ~40.6 GB | 4.5 meses |
| 300 | ~60.9 GB | 3 meses |
| 500 | ~101.5 GB | <2 meses |

*185 GB = 200 GB - 15 GB base del sistema

**RAM disponible para servicios:**

| Configuracion | RAM usada | RAM libre |
|---------------|-----------|-----------|
| Puma 4 workers + Sidekiq 5 threads (actual) | ~3-5 GB | ~19 GB |
| Puma 6 workers + Sidekiq 10 threads (upgrade) | ~5-8 GB | ~16 GB |
| Puma 8 workers + Sidekiq 15 threads (maximo) | ~7-11 GB | ~13 GB |

Con 24 GB puedes escalar confortablemente hasta **500-800 negocios** antes de necesitar separar servicios (DB dedicada, segundo servidor). El disco sigue siendo el limite — a 300+ negocios sin cleanup, Supabase Storage es obligatorio.

### 2.2 Frontend — Opciones de hosting

**3 opciones para servir el frontend Next.js:**

| Opcion | Costo/mes | Bandwidth | Pros | Contras |
|--------|-----------|-----------|------|---------|
| **A. Self-hosted en VPS** | $0 | Ilimitado (BW del VPS) | Sin costo extra, sin limites, control total | Consume RAM (~300-500 MB), sin CDN global |
| **B. Vercel Hobby (free)** | $0 | 100 GB/mes | CDN global, deploys automaticos | TOS prohibe uso comercial, limites bajos (ver abajo) |
| **C. Vercel Pro** | $20 + uso | 1 TB/mes | CDN global, analytics, sin riesgo TOS | Costo fijo + excedentes posibles |

**Analisis del proyecto real (agendity-web):**

| Caracteristica | Estado actual | Impacto en Vercel |
|----------------|---------------|-------------------|
| Paginas `'use client'` (CSR) | 30 de 31 | Bajo consumo serverless — el navegador hace todo |
| Paginas SSG/ISR | 1 (landing + sitemap ISR 1h) | Minimo |
| `next/image` | **0 usos** | 0 Image Transformations — no aplica |
| API Route Handlers | **0** | 0 Function Invocations |
| Middleware | 1 (auth cookies) | 1 Edge Request por request |
| Fetch server-side | Solo sitemap.ts (1 vez/hora) | Active CPU despreciable |
| Assets en public/ | ~4.5 KB total | Despreciable |

**El frontend es casi 100% CSR.** TanStack Query hace todos los fetches al backend Rails desde el navegador. Vercel solo sirve el HTML shell + JS bundles.

**Limites de Vercel Hobby vs uso real de Agendity:**

| Recurso | Limite Hobby | Uso real de Agendity | Veredicto |
|---------|-------------|---------------------|-----------|
| Fast Data Transfer | 100 GB/mes | Unico limite relevante. ~3,300 visitas/dia si ~1 MB por pagina | Aguanta hasta ~50-80 negocios |
| Edge Requests | 1M/mes | 1 por request (middleware auth). ~33k/dia disponibles | OK hasta escala media |
| Function Invocations | 1M/mes | **0** — no hay Route Handlers | No aplica |
| Active CPU | 4 horas/mes | **~minutos** — solo sitemap ISR 1 vez/hora | No aplica |
| Image Transformations | 5,000/mes | **0** — no usa next/image, imagenes desde Rails | No aplica |
| Developer Seats | 1 | Solo 1 dev | OK |
| **Uso comercial** | **NO permitido** | **Agendity es comercial** | **Riesgo de suspension** |

**Self-hosted ya esta configurado:** El `docker-compose.yml` incluye el servicio `web` (Next.js) con Nginx como reverse proxy. No requiere configuracion adicional.

**Estrategia recomendada:**
1. **Lanzamiento:** Self-hosted en VPS como produccion principal. Vercel Hobby como entorno de preview/staging (gratis, sin riesgo TOS porque no es produccion)
2. **Crecimiento:** Seguir self-hosted. El VPS de 12 GB aguanta Next.js + API + DB hasta 300 negocios
3. **Escala LATAM:** Self-hosted + Cloudflare free (CDN global gratis). Vercel Pro solo si se necesita algo especifico de Vercel

### 2.3 Almacenamiento adicional — Supabase Storage (solo si 200 GB no alcanza)

**Comparacion: upgrade VPS vs agregar Supabase al VPS actual:**

| Opcion | Costo/mes | Storage total | CPU/RAM | Veredicto |
|--------|-----------|---------------|---------|-----------|
| VPS $12 + Supabase Pro | $37 | 100 GB local + 100 GB externo | 6 CPU / 12 GB | Mas caro, mas complejo |
| **VPS upgrade $24** | **$24** | **200 GB local** | **8 CPU / 24 GB** | **Mas barato, mas simple, mas potente** |

**Recomendacion:** Siempre hacer upgrade del VPS primero. Supabase solo tiene sentido cuando los 200 GB del VPS upgrade tambien se queden cortos (~200+ negocios sin cleanup).

| Tier Supabase | Costo/mes | Storage | Bandwidth |
|---------------|-----------|---------|-----------|
| Free | $0 | 1 GB | 2 GB |
| Pro | $25 | 100 GB | 250 GB |

**Cuando necesitar Supabase (con VPS de 200 GB):**
- A ~200 negocios sin cleanup de comprobantes antiguos
- O si se decide no implementar cleanup y se acumulan >185 GB

**Alternativa mas barata:** Implementar un job de cleanup de comprobantes >90 dias. Los comprobantes de citas ya no se necesitan despues de ser aprobados/rechazados. Esto puede extender la vida util del disco indefinidamente sin costo adicional.

---

## 3. Servicios externos

### 3.1 Dominio

| Concepto | Costo/ano (COP) | Costo/ano (USD) | Costo/mes (USD) |
|----------|-----------------|-----------------|-----------------|
| agendity.co (GoDaddy) — Ano 1 | $69,999 | ~$16 | ~$1.3 |
| agendity.co (GoDaddy) — Renovacion | $179,999 | ~$42 | ~$3.5 |

### 3.2 SSL — Let's Encrypt

Gratis. Certbot renueva automaticamente.

### 3.3 Email transaccional — Spacemail SMTP (principal) + Resend (escala grande)

**Fase 1: Spacemail SMTP (ya contratado)**

Spacemail de Spaceship, plan Pro: $9.88 USD/ano (~$1/mes). Contratacion aparte del dominio.

| Limite | Valor |
|--------|-------|
| Emails por hora (por buzon) | 500 |
| Emails por dia (por buzon) | ~12,000 |
| Emails por mes (por buzon) | ~360,000 |
| Buzones (plan Pro) | 1 |
| Aliases | 10 (comparten cuota del buzon) |
| Costo | $10/ano (~$1/mes) |

**Capacidad por escala:**

| Negocios | Emails/mes necesarios | Spacemail (360k/mes) | Veredicto |
|----------|----------------------|----------------------|-----------|
| 10 | ~10,700 | 3% de capacidad | OK |
| 30 | ~32,120 | 9% de capacidad | OK |
| 100 | ~107,000 | 30% de capacidad | OK |
| 200 | ~214,000 | 59% de capacidad | OK |
| 300 | ~320,900 | 89% de capacidad | Limite, migrar a Resend |

**Riesgo:** Spaceship podria bloquear la cuenta si detecta envio masivo programatico. Monitorear deliverability y tener Resend como plan B.

**Fase 2: Resend (cuando Spacemail no alcance o bloquee)**

| Tier | Costo/mes | Emails/mes |
|------|-----------|------------|
| Free | $0 | 3,000 |
| Pro | $20 | 50,000 |
| Business | $75 | 150,000 |
| Enterprise | A medida | Ilimitado |

**Cuando migrar a Resend:**
- Si Spacemail bloquea la cuenta por envio programatico
- Al superar 300 negocios (~320k emails/mes)
- Si la tasa de entrega (deliverability) baja significativamente

### 3.4 Pexels API

Gratis. Sin limite practico para el uso que le damos (fotos de portada).

### 3.5 WhatsApp Business API (Meta Cloud API)

**Modelo de cobro:** Por conversacion (ventana de 24h). No se cobra por mensajes dentro de la misma ventana.

**Tipo de mensaje de Agendity:** UTILITY (confirmaciones, recordatorios, cancelaciones) + MARKETING (rating request)

**Costos por conversacion por pais (USD):**

| Pais | Utility | Marketing | Service (gratis) |
|------|---------|-----------|------------------|
| Colombia | $0.0080 | $0.0164 | 1,000/mes gratis |
| Mexico | $0.0113 | $0.0226 | 1,000/mes gratis |
| Brasil | $0.0080 | $0.0165 | 1,000/mes gratis |
| Argentina | $0.0072 | $0.0147 | 1,000/mes gratis |
| Chile | $0.0100 | $0.0193 | 1,000/mes gratis |
| Peru | $0.0053 | $0.0130 | 1,000/mes gratis |
| Resto LATAM | $0.0053-$0.0113 | $0.0100-$0.0226 | 1,000/mes gratis |

**Importante:**
- WhatsApp es solo notificaciones one-way (no conversacional)
- Solo planes Profesional e Inteligente
- Rating request = MARKETING (mas caro). El resto = UTILITY
- Meta cobra por conversacion, no por mensaje. Si 2 mensajes caen en la misma ventana de 24h del mismo usuario, solo se cobra 1

### 3.6 Costo WhatsApp por cita (Pro+)

Todas las notificaciones al usuario final en negocios Pro+ pasan por MultiChannelService: email + WhatsApp.

```
Por cita completada (negocio Pro+):
  - booking_confirmed = 1 UTILITY
  - reminder_24h = 1 UTILITY (es el dia anterior, ventana separada)
  - rating_request = 1 MARKETING
  Total: 2 UTILITY + 1 MARKETING = $0.0080×2 + $0.0164 = $0.0324 por cita (Colombia)

Por cita cancelada (negocio Pro+):
  - booking_cancelled = 1 UTILITY = $0.0080 (Colombia)

Negocios plan Basico: $0 WhatsApp (solo email)
```

---

## 4. Escalas de operacion

### Supuestos generales

- Promedio 8 citas/dia por negocio (240/mes)
- 85% de citas se completan, 10% se cancelan, 5% no-show
- 60% de negocios en plan Profesional o Inteligente (con WhatsApp)
- Distribucion plan promedio: 30% Basico ($8), 50% Profesional ($17), 20% Inteligente ($23)
- Ingreso promedio por negocio: $16.3 USD/mes
- Tasa de cancelacion WhatsApp: cada cita cancelada = 1 conversacion extra

---

### 4.1 Pequena escala — Lanzamiento Barranquilla

**30 negocios activos | Solo Colombia | Meses 1-3**

| Metrica | Valor |
|---------|-------|
| Citas/mes | 7,200 |
| Citas completadas | 6,120 |
| Citas canceladas | 720 |
| Negocios con WhatsApp (60%) | 18 |
| Citas con WhatsApp | 4,320 completadas + 432 canceladas |

**Emails/mes:**
| Tipo | Cantidad |
|------|----------|
| Citas completadas × 5 emails | 30,600 |
| Citas canceladas × 2 emails | 1,440 |
| Suscripciones (30 negocios × 1) | 30 |
| Password resets + invitaciones | ~50 |
| **TOTAL** | **~32,120 emails/mes** |

**WhatsApp/mes (SOLO negocios Profesional e Inteligente = 60%):**

Todos los WhatsApp a usuario final aplican unicamente si el negocio tiene plan Pro+. Plan Basico = solo email, nunca WhatsApp.

| Tipo | Cantidad | Costo unitario | Subtotal |
|------|----------|----------------|----------|
| Rating request (MARKETING) | 4,320 | $0.0164 | $70.85 |
| Confirmed (UTILITY) | 4,320 | $0.0080 | $34.56 |
| Reminder 24h (UTILITY) | 4,320 | $0.0080 | $34.56 |
| Cancelled (UTILITY) | 432 | $0.0080 | $3.46 |
| Suscripcion al negocio (UTILITY) | 18 | $0.0080 | $0.14 |
| **TOTAL** | **13,410** | | **$143.57** |

**Costos iniciales — Mes 1 (incluye pagos anuales):**

| Concepto | Costo | Periodo | Nota |
|----------|-------|---------|------|
| VPS OVH | $12 | Mensual | |
| Dominio agendity.co | **$16** | **Anual** | GoDaddy, primer ano |
| Spacemail SMTP Pro | **$10** | **Anual** | Spaceship, 1 buzon + 10 aliases |
| WhatsApp API | $144 | Mensual | Solo si ya hay negocios Pro+ |
| **TOTAL Mes 1** | **$182** | | Incluye $26 de pagos anuales |

**Sin WhatsApp (mes 1 real):** $38 (VPS + dominio + email anuales)

**Resumen mensual — Meses 2-12 (30 negocios, ya pagados anuales):**

| Concepto | Self-hosted | Vercel Hobby | Vercel Pro |
|----------|------------|--------------|------------|
| VPS OVH | $12 | $12 | $12 |
| Frontend | $0 (en VPS) | $0 (free) | $20 |
| Dominio agendity.co | $0 (ya pagado) | $0 | $0 |
| Email (Spacemail SMTP) | $0 (ya pagado) | $0 | $0 |
| WhatsApp API | $144 | $144 | $144 |
| **TOTAL/mes** | **$156** | **$156** | **$176** |

| | Self-hosted | Vercel Hobby | Vercel Pro |
|---|------------|--------------|------------|
| Ingresos | $489/mes | $489/mes | $489/mes |
| Margen | +$333 (68%) | +$333 (68%) | +$313 (64%) |

**Sin WhatsApp (meses 2-12):** $12/mes (solo VPS)

**Costo total Ano 1 (self-hosted, con WhatsApp):**

| Concepto | Costo |
|----------|-------|
| VPS OVH (12 × $12) | $144 |
| Dominio (anual) | $16 |
| Spacemail (anual) | $10 |
| WhatsApp API (11 × $144, desde mes 2) | $1,584 |
| **TOTAL Ano 1** | **$1,754** |

**Costo total Ano 2+ (renovacion):**

| Concepto | Costo |
|----------|-------|
| VPS OVH (12 × $12) | $144 |
| Dominio renovacion (anual) | **$42** |
| Spacemail renovacion (anual) | $10 |
| WhatsApp API (12 × $144) | $1,728 |
| **TOTAL Ano 2** | **$1,924** |
| **Costo mensual promedio Ano 2** | **~$160/mes** |

---

### 4.2 Mediana escala — Colombia consolidado

**300 negocios activos | Solo Colombia | Meses 6-12**

| Metrica | Valor |
|---------|-------|
| Citas/mes | 72,000 |
| Citas completadas | 61,200 |
| Citas canceladas | 7,200 |
| Negocios con WhatsApp (60%) | 180 |
| Citas con WhatsApp | 43,200 completadas + 4,320 canceladas |

**Emails/mes:**
| Tipo | Cantidad |
|------|----------|
| Citas completadas × 5 | 306,000 |
| Citas canceladas × 2 | 14,400 |
| Suscripciones + otros | ~500 |
| **TOTAL** | **~320,900 emails/mes** |

**WhatsApp/mes (SOLO negocios Pro+, todo migrado a MultiChannel):**

| Tipo | Cantidad | Costo unitario | Subtotal |
|------|----------|----------------|----------|
| Rating (MARKETING) | 43,200 | $0.0164 | $708.48 |
| Confirmed (UTILITY) | 43,200 | $0.0080 | $345.60 |
| Reminder 24h (UTILITY) | 43,200 | $0.0080 | $345.60 |
| Cancelled (UTILITY) | 4,320 | $0.0080 | $34.56 |
| Suscripcion al negocio (UTILITY) | ~180 | $0.0080 | $1.44 |
| **TOTAL** | **134,100** | | **$1,435.68** |

**Resumen mensual — Mediana escala (300 negocios):**

A esta escala Vercel Hobby es riesgoso por trafico alto. Self-hosted es la opcion mas rentable.

| Concepto | Self-hosted | Vercel Pro |
|----------|------------|------------|
| VPS OVH (upgrade 200GB) | $24 | $24 |
| Frontend | $0 (en VPS) | $20 |
| Dominio agendity.co | $4 | $4 |
| Email (Spacemail $1, o Resend $75 si al limite) | $1 - $75 | $1 - $75 |
| WhatsApp API | $1,436 | $1,436 |
| **TOTAL/mes** | **$1,465 - $1,539** | **$1,485 - $1,559** |

| | Self-hosted | Vercel Pro |
|---|------------|------------|
| Ingresos | $4,890/mes | $4,890/mes |
| Margen | +$3,351 - $3,425 (69-70%) | +$3,331 - $3,405 (68-70%) |

---

### 4.3 Gran escala — Expansion LATAM

**5,000 negocios | 5 paises | Ano 2+**

**Distribucion estimada:**

| Pais | Negocios | % | WhatsApp Utility | WhatsApp Marketing |
|------|----------|---|------------------|--------------------|
| Colombia | 2,000 | 40% | $0.0080 | $0.0164 |
| Mexico | 1,500 | 30% | $0.0113 | $0.0226 |
| Brasil | 500 | 10% | $0.0080 | $0.0165 |
| Argentina | 500 | 10% | $0.0072 | $0.0147 |
| Chile/Peru/otros | 500 | 10% | $0.0080 | $0.0160 |

**Metricas globales:**

| Metrica | Valor |
|---------|-------|
| Citas/mes | 1,200,000 |
| Citas completadas | 1,020,000 |
| Citas canceladas | 120,000 |
| Negocios con WhatsApp (60%) | 3,000 |
| Citas con WhatsApp | 720,000 completadas + 72,000 canceladas |

**Emails/mes:**

| Tipo | Cantidad |
|------|----------|
| Citas completadas × 5 | 5,100,000 |
| Citas canceladas × 2 | 240,000 |
| Suscripciones + otros | ~10,000 |
| **TOTAL** | **~5,350,000 emails/mes** |

**WhatsApp/mes (MultiChannel completo):**

Calculo por pais (solo negocios Pro+, 60%):

| Pais | Negocios WA | Citas WA/mes | Rating (MKT) | Confirmed+Reminder (UTL×2) | Cancelled (UTL) | Suscripcion (UTL) | Total pais |
|------|-------------|--------------|--------------|---------------------------|-----------------|-------------------|------------|
| Colombia | 1,200 | 345,600 comp + 34,560 canc | $5,667.84 | $5,529.60 | $276.48 | $9.60 | **$11,483.52** |
| Mexico | 900 | 259,200 comp + 25,920 canc | $5,857.92 | $5,857.92 | $292.90 | $10.17 | **$12,018.91** |
| Brasil | 300 | 86,400 comp + 8,640 canc | $1,425.60 | $1,382.40 | $69.12 | $2.40 | **$2,879.52** |
| Argentina | 300 | 86,400 comp + 8,640 canc | $1,270.08 | $1,244.16 | $62.21 | $2.16 | **$2,578.61** |
| Chile/Peru/otros | 300 | 86,400 comp + 8,640 canc | $1,382.40 | $1,382.40 | $69.12 | $2.40 | **$2,836.32** |
| **TOTAL** | **3,000** | **864,000 + 77,760** | **$15,603.84** | **$15,396.48** | **$769.83** | **$26.73** | **$31,796.88** |

**Infraestructura a esta escala:**

| Componente | Self-hosted | Con Vercel Pro |
|------------|------------|----------------|
| Servidor principal (VPS dedicado 32GB) | $50-80 | $50-80 |
| Frontend | $0 (en servidor, Nginx + cache) | $20 (Vercel Pro, CDN global) |
| Dominio agendity.co | $4 | $4 |
| Email — Amazon SES (~5.35M) | $535 | $535 |
| WhatsApp API | $31,797 | $31,797 |
| Storage (Supabase Pro + cleanup) | $25-50 | $25-50 |
| Monitoreo | $0-30 | $0-30 |
| **TOTAL** | **$32,411 - $32,496** | **$32,431 - $32,516** |

**Alternativa email a escala: Amazon SES**

| Volumen | Costo SES | vs Resend |
|---------|-----------|-----------|
| 5M emails/mes | ~$500 (0.10/1000) | Mas barato que Enterprise |
| 10M emails/mes | ~$1,000 | Mucho mas barato |

**A esta escala Vercel Pro ($20) es irrelevante** — representa <0.1% del costo total. La decision es puramente tecnica: CDN global multi-pais (Vercel) vs control total (self-hosted con Nginx + Cloudflare free).

**Ingresos:** 5,000 × $16.3 = **$81,500/mes**
**Margen self-hosted:** +$49,004 - $49,089/mes (60%)
**Margen Vercel Pro:** +$48,984 - $49,069/mes (60%)

---

### 4.4 Escala agresiva — Lider LATAM

**20,000 negocios | 8+ paises | Ano 3+**

| Concepto | Costo/mes |
|----------|-----------|
| Concepto | Self-hosted | Con Vercel Pro |
|----------|------------|----------------|
| Infra (2-3 servidores + DB dedicada) | $200-400 | $200-400 |
| Frontend | $0 (Nginx + Cloudflare free) | $20 |
| Dominio agendity.co | $4 | $4 |
| Email — Amazon SES (~22M) | $2,200 | $2,200 |
| WhatsApp API (×4 de gran escala) | ~$127,000 | ~$127,000 |
| Storage (S3/Supabase) | $50-100 | $50-100 |
| Monitoreo + CDN | $50-100 | $50-100 |
| **TOTAL** | **$129,504 - $129,804** | **$129,524 - $129,824** |

**Ingresos:** 20,000 × $16.3 = **$326,000/mes**
**Margen self-hosted:** ~$196,200 - $196,500/mes (60%)

---

## 5. Resumen comparativo por escala

Todas las notificaciones al usuario final en Pro+ pasan por MultiChannelService (email + WhatsApp).

**Escenario mas rentable: Self-hosted (front en VPS) + Spacemail SMTP**

Frontend, email y dominio ya estan pagos/incluidos. Los unicos costos variables son VPS y WhatsApp.

| Escala | Negocios | Self-hosted | +Vercel Pro | Ingreso/mes | Margen (self) | % |
|--------|----------|------------|-------------|-------------|---------------|---|
| Lanzamiento (sin WA) | 30 | **$17** | $37 | $489 | +$472 | 97% |
| Lanzamiento (con WA) | 30 | **$161** | $181 | $489 | +$328 | 67% |
| Colombia consolidado | 300 | **$1,465** | $1,485 | $4,890 | +$3,425 | 70% |
| LATAM (5 paises) | 5,000 | **$32,412** | $32,432 | $81,500 | +$49,088 | 60% |
| LATAM lider | 20,000 | **$129,505** | $129,525 | $326,000 | +$196,495 | 60% |

Vercel Hobby (free) se puede usar como entorno de preview/staging sin costo adicional. No como produccion (TOS comercial).

---

## 6. WhatsApp: el costo dominante

WhatsApp representa entre el **57% y 98%** del costo operativo total dependiendo de la escala. Esto es normal para plataformas B2B2C en LATAM donde WhatsApp es el canal principal.

### 6.1 Estrategias de optimizacion

**A. Aprovechar ventanas de 24h:**
Si booking_confirmed y reminder caen dentro de la misma ventana de 24h con el mismo usuario, Meta solo cobra 1 conversacion. En la practica, el reminder es el dia anterior, asi que son conversaciones separadas.

**B. Agrupar notificaciones:**
En vez de enviar 3 WhatsApp separados por cita (confirmed + reminder + rating), enviar un solo mensaje utility con toda la info. Reduce de 3 a 2 conversaciones (1 utility + 1 marketing).

**C. Migrar rating_request de MARKETING a UTILITY:**
Si el template no tiene contenido promocional (solo "califica tu visita"), Meta podria aprobarlo como UTILITY. Ahorro: ~50% del costo de WhatsApp por rating.
- Utility Colombia: $0.0080 vs Marketing: $0.0164

**D. WhatsApp solo para recordatorios (alto impacto):**
Priorizar solo el reminder 24h (reduce no-shows) y confirmacion. El rating por email es suficiente. Reduce a 2 UTILITY por cita.

**E. Free tier de Service conversations:**
Las primeras 1,000 conversaciones Service (respuestas del usuario) son gratis/mes. No aplica para nuestro caso (solo enviamos, no conversamos).

### 6.2 Escenario optimizado (sin rating por WA, solo UTILITY)

Si se envia el rating_request solo por email y WhatsApp se reserva para confirmed + reminder (2 UTILITY por cita):

| Escala | WhatsApp completo | WhatsApp sin rating | Ahorro |
|--------|-------------------|---------------------|--------|
| 30 negocios | $144 | $73 | 49% |
| 300 negocios | $1,436 | $727 | 49% |
| 5,000 LATAM | $31,797 | $15,423 | 51% |
| 20,000 LATAM | $127,000 | $61,700 | 51% |

---

## 7. Hoja de ruta de costos — Primer ano

WhatsApp incluye MultiChannel completo (confirmed + reminder + rating + cancelled) para negocios Pro+.
Email via Spacemail SMTP ($1/mes = $10/ano) durante todo el primer ano.

**Escenario optimo: Self-hosted (front en VPS) + Spacemail SMTP**

Costo fijo = VPS ($12) + Dominio ($4) + Spacemail ($1) = $17/mes. Sin Vercel, sin Resend.

| Mes | Negocios | Costo fijo | WhatsApp | Total | Ingresos | Margen |
|-----|----------|------------|----------|-------|----------|--------|
| 1 | 10 | $17 | $0 (sin WA) | **$17** | $163 | +$146 |
| 2 | 20 | $17 | $0 | **$17** | $326 | +$309 |
| 3 | 30 | $17 | $144 (activa WA) | **$161** | $489 | +$328 |
| 4 | 50 | $17 | $240 | **$257** | $815 | +$558 |
| 5 | 80 | $17 | $383 | **$400** | $1,304 | +$904 |
| 6 | 120 | $17 | $575 | **$592** | $1,956 | +$1,364 |
| 7-12 | 120→300 | $29* | $575→1,436 | **$604→1,465** | $1,956→4,890 | +$1,352→3,425 |

*Meses 7-12: upgrade VPS a $24 si disco >70 GB. Costo fijo = $24 + $4 + $1 = $29/mes.

**Acumulado mes 6:** ~$1,444 gastados, ~$5,053 facturados = **+$3,609 neto**
**Acumulado mes 12:** ~$7,250 gastados, ~$24,000 facturados = **+$16,750 neto**

**Escenario con Vercel Hobby (free):** Mismos numeros ($0 adicional). Util como entorno de preview/staging sin costo.

**Escenario con Vercel Pro:** Sumar $20/mes a cada fila. Acumulado ano 1: ~$9,650 gastados → +$14,350 neto.

---

## 8. Infraestructura: cuando escalar

Base: VPS $12 + Dominio $4 + Spacemail $1 = $17/mes (self-hosted). Sin Vercel.

| Umbral | Accion | Costo nuevo | Costo total infra |
|--------|--------|-------------|-------------------|
| 70 GB disco o ~200 negocios | Upgrade VPS a 8 cores / 24 GB / 200 GB | $24/mes | $29 |
| 200 GB disco usado | Supabase Storage Pro o cleanup policy | +$25/mes | $53 |
| ~300 negocios (320k emails/mes) | Migrar email a Resend Business | +$75/mes | $128 |
| 500-800 negocios | Separar DB a segundo VPS | +$24-40/mes | $152-168 |
| 5,000 negocios | 2-3 servidores + DB dedicada + Amazon SES | +$100-200/mes | $300-450 |
| 20,000 negocios | Cluster dedicado + DB managed + Redis managed | +$300-500/mes | $600-950 |

Vercel Pro ($20/mes) es opcional en cualquier etapa. Solo agrega CDN global — no es necesario para Colombia.

La infra nunca sera el cuello de botella financiero. **WhatsApp siempre sera el costo dominante.**

---

## 9. Costos que NO tenemos

Ventajas del stack self-hosted:

| Servicio | Alternativa managed | Ahorro/mes |
|----------|-------------------|------------|
| PostgreSQL (en VPS) | RDS/Supabase DB | $25-100 |
| Redis (en VPS) | ElastiCache/Upstash | $10-30 |
| NATS (en VPS) | Ably/Pusher | $20-100 |
| Sidekiq (en VPS) | Cloud Functions | $10-50 |
| SSL (Let's Encrypt) | Certificados pagos | $10-50/ano |

**Ahorro estimado por ser self-hosted: $75-330/mes** vs cloud managed.
