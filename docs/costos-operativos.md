# Costos Operativos — Agendity

> Ultima actualizacion: 2026-03-23

---

## 1. Inventario completo de notificaciones

### 1.1 Notificaciones al usuario final (quien reserva)

| # | Evento | Email | WhatsApp (Pro+) | Trigger |
|---|--------|:-----:|:----------------:|---------|
| 1 | Cita confirmada (pago aprobado) | Si | Si (futuro) | Negocio aprueba comprobante |
| 2 | Recordatorio 24h antes | Si | Si (futuro) | Job diario 8am |
| 3 | Cita cancelada | Si | Si (futuro) | Negocio o usuario cancela |
| 4 | Solicitud de calificacion | Si | Si (MultiChannel) | 15 min despues de completar cita |
| 5 | Recordatorio de pago (manual) | Si | No | Negocio envia manualmente |
| 6 | Comprobante rechazado | Si | No | Negocio rechaza comprobante |

**WhatsApp al usuario final:** Solo planes Profesional e Inteligente (`plan.whatsapp_notifications?`). Plan Basico solo email.

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

Emails enviados:
  → Al negocio: nueva reserva (1) + comprobante recibido (1) = 2
  → Al usuario: confirmacion (1) + recordatorio 24h (1) + rating request (1) = 3
  TOTAL: 5 emails por cita completada

WhatsApp enviados (SOLO negocios Profesional o Inteligente):
  → Al usuario: confirmacion (1) + recordatorio (1) + rating (1) = 3 por cita
  → Al negocio: 0 (WhatsApp al negocio solo aplica para alertas de suscripcion)
  TOTAL: 3 WhatsApp por cita completada

  Todos pasan por MultiChannelService (email siempre + WhatsApp si Pro+).
  Negocios plan Basico: solo email, nunca WhatsApp.
```

### 1.5 Conteo por cita cancelada

```
Emails: nueva reserva (1) + cancelacion a ambos (2) = 3 emails
WhatsApp (Pro+): cancelacion al usuario (1*) = 0 actual / 1 futuro
```

### 1.6 Conteo por ciclo de suscripcion (mensual, por negocio)

```
Happy path (paga a tiempo):
  Emails: aviso renovacion (0, solo in-app) + renovada (1) = 1 email
  WhatsApp (Pro+): renovada (1) = 1

Pago tardio (pasa por las 3 alertas):
  Emails: recordatorio 3d (1) + alerta 5d (1) + alerta dia 0 (1) + alerta +2d (1) + expirada (1) = 5 emails
  WhatsApp (Pro+): alerta 5d (1) + alerta dia 0 (1) + alerta +2d (1) = 3
```

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

**Fuentes de storage (ActiveStorage):**

| Tipo de archivo | Tamano promedio | Quien sube | Frecuencia |
|-----------------|-----------------|------------|------------|
| Comprobante de pago (cita) | ~1 MB | Usuario final | ~70% de citas (resto es efectivo) |
| Comprobante de transferencia (cierre de caja) | ~1 MB | Negocio | 1 por empleado pagado por transferencia/dia |
| Logo del negocio | ~200 KB | Negocio | 1 vez |
| Portada del negocio (Pexels) | ~300 KB | Negocio | 1 vez |

**Calculo de storage mensual por escala:**

Supuestos: 240 citas/mes por negocio, 70% con comprobante de cita, 3 empleados promedio, 50% pagados por transferencia (15 comprobantes de cierre/mes por negocio)

| Negocios | Comprobantes cita/mes | Comprobantes cierre/mes | Storage total/mes | Meses hasta llenar 85 GB |
|----------|----------------------|------------------------|-------------------|--------------------------|
| 30 | ~5,000 | ~450 | ~5.5 GB | 15 meses |
| 50 | ~8,400 | ~750 | ~9.2 GB | 9 meses |
| 100 | ~16,800 | ~1,500 | ~18.3 GB | 4.5 meses |
| 200 | ~33,600 | ~3,000 | ~36.6 GB | 2 meses |
| 300 | ~50,400 | ~4,500 | ~54.9 GB | <1.5 meses |

**Nota:** Con 30 negocios tienes mas de 1 ano tranquilo. Con 100+ necesitas plan de storage externo o cleanup de comprobantes antiguos (>90 dias).

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

Incluye comprobantes de citas + comprobantes de cierre de caja (transferencias a empleados).

| Negocios | Storage total/mes | Meses hasta llenar 185 GB* |
|----------|-------------------|----------------------------|
| 100 | ~18.3 GB | 10 meses |
| 200 | ~36.6 GB | 5 meses |
| 300 | ~54.9 GB | 3 meses |
| 500 | ~91.5 GB | 2 meses |

*185 GB = 200 GB - 15 GB base del sistema

**RAM disponible para servicios:**

| Configuracion | RAM usada | RAM libre |
|---------------|-----------|-----------|
| Puma 4 workers + Sidekiq 5 threads (actual) | ~3-5 GB | ~19 GB |
| Puma 6 workers + Sidekiq 10 threads (upgrade) | ~5-8 GB | ~16 GB |
| Puma 8 workers + Sidekiq 15 threads (maximo) | ~7-11 GB | ~13 GB |

Con 24 GB puedes escalar confortablemente hasta **500-800 negocios** antes de necesitar separar servicios (DB dedicada, segundo servidor). El disco sigue siendo el limite — a 300+ negocios sin cleanup, Supabase Storage es obligatorio.

### 2.2 Frontend — Vercel

| Tier | Costo/mes | Limite bandwidth | Nota |
|------|-----------|-----------------|------|
| Hobby | $0 | 100 GB | NO permite uso comercial |
| **Pro** | **$20** | 1 TB | Necesario para produccion |

### 2.3 Almacenamiento adicional — Supabase Storage

Si los comprobantes + logos exceden los 100 GB del VPS:

| Tier | Costo/mes | Storage | Bandwidth |
|------|-----------|---------|-----------|
| Free | $0 | 1 GB | 2 GB |
| Pro | $25 | 100 GB | 250 GB |

**Calculo de storage:**
- Logo por negocio: ~200 KB
- Comprobante por cita: ~1 MB promedio
- 100 negocios × 240 citas/mes = 24,000 comprobantes = ~24 GB/mes (acumulativo)
- **A los 4 meses** con 100 negocios se llena el disco de 100 GB

**Recomendacion:** Configurar ActiveStorage con Supabase S3-compatible o limpiar comprobantes antiguos (>90 dias) con un job.

---

## 3. Servicios externos

### 3.1 Dominio

| Concepto | Costo/ano | Costo/mes |
|----------|-----------|-----------|
| agendity.com (.com) | ~$12 | ~$1 |

### 3.2 SSL — Let's Encrypt

Gratis. Certbot renueva automaticamente.

### 3.3 Email transaccional — Resend

| Tier | Costo/mes | Emails/mes | Emails/dia |
|------|-----------|------------|------------|
| Free | $0 | 3,000 | 100 |
| Pro | $20 | 50,000 | — |
| Business | $75 | 150,000 | — |
| Enterprise | A medida | Ilimitado | — |

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
| Citas canceladas × 3 emails | 2,160 |
| Suscripciones (30 negocios × 1) | 30 |
| Password resets + invitaciones | ~50 |
| **TOTAL** | **~32,840 emails/mes** |

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

**Resumen mensual — Pequena escala:**

| Concepto | Costo/mes |
|----------|-----------|
| VPS OVH | $12 |
| Vercel Pro | $20 |
| Dominio | $1 |
| Email — Resend Pro (32k emails) | $20 |
| WhatsApp API (todo migrado) | $144 |
| Supabase Storage | $0 (no necesario) |
| **TOTAL** | **$197/mes** |
| **TOTAL 6 meses** | **$1,182** |

**Ingresos:** 30 × $16.3 = **$489/mes**
**Margen:** +$292/mes (59.7%)

**Sin WhatsApp (mes 1 mientras se configura):** $53/mes

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
| Citas canceladas × 3 | 21,600 |
| Suscripciones + otros | ~500 |
| **TOTAL** | **~328,100 emails/mes** |

**WhatsApp/mes (SOLO negocios Pro+, todo migrado a MultiChannel):**

| Tipo | Cantidad | Costo unitario | Subtotal |
|------|----------|----------------|----------|
| Rating (MARKETING) | 43,200 | $0.0164 | $708.48 |
| Confirmed (UTILITY) | 43,200 | $0.0080 | $345.60 |
| Reminder 24h (UTILITY) | 43,200 | $0.0080 | $345.60 |
| Cancelled (UTILITY) | 4,320 | $0.0080 | $34.56 |
| Suscripcion al negocio (UTILITY) | ~180 | $0.0080 | $1.44 |
| **TOTAL** | **134,100** | | **$1,435.68** |

**Resumen mensual — Mediana escala:**

| Concepto | Costo/mes |
|----------|-----------|
| VPS OVH (upgrade posible) | $12-24 |
| Vercel Pro | $20 |
| Dominio | $1 |
| Email — Resend Enterprise (328k) | ~$200 |
| WhatsApp API (todo migrado) | $1,436 |
| Supabase Pro (storage) | $25 |
| **TOTAL** | **$1,694-1,706** |

**Ingresos:** 300 × $16.3 = **$4,890/mes**
**Margen:** +$3,184/mes (65%)

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
| Citas canceladas × 3 | 360,000 |
| Suscripciones + otros | ~10,000 |
| **TOTAL** | **~5,470,000 emails/mes** |

**WhatsApp/mes (futuro — MultiChannel completo):**

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

| Componente | Necesidad | Solucion | Costo/mes |
|------------|-----------|----------|-----------|
| Servidor principal | 5M+ emails, 1.2M citas | VPS dedicado OVH (32GB RAM, 8 CPU) | $50-80 |
| Base de datos | PostgreSQL con millones de registros | Mismo VPS o separado | (incluido) |
| Frontend | Alto trafico multi-pais | Vercel Pro (1TB BW) | $20 |
| Email | 5.4M emails/mes | Resend Enterprise o Amazon SES | $200-400 |
| Storage | ~1.2TB/ano en comprobantes | Supabase Pro + cleanup policy | $25-50 |
| CDN/Cache | Paginas publicas SSG | Vercel (incluido) | $0 |
| Monitoreo | Uptime, errores, metricas | Mejor Uptime (free) + Sentry (free tier) | $0-30 |
| **Subtotal infra** | | | **$295-580** |

**Alternativa email a escala: Amazon SES**

| Volumen | Costo SES | vs Resend |
|---------|-----------|-----------|
| 5M emails/mes | ~$500 (0.10/1000) | Mas barato que Enterprise |
| 10M emails/mes | ~$1,000 | Mucho mas barato |

**Resumen mensual — Gran escala LATAM:**

| Concepto | Costo/mes |
|----------|-----------|
| VPS dedicado OVH | $50-80 |
| Vercel Pro | $20 |
| Dominio | $1 |
| Email — Amazon SES (~5.5M) | $550 |
| WhatsApp API (todo migrado) | $31,797 |
| Supabase Pro (storage) | $25-50 |
| Monitoreo | $0-30 |
| **TOTAL** | **$32,443 - $32,528** |
| **TOTAL 6 meses** | **$194,658 - $195,168** |

**Ingresos:** 5,000 × $16.3 = **$81,500/mes**
**Margen:** +$48,972 - $49,057/mes (60%)

---

### 4.4 Escala agresiva — Lider LATAM

**20,000 negocios | 8+ paises | Ano 3+**

| Concepto | Costo/mes |
|----------|-----------|
| Infra (2-3 servidores + DB dedicada) | $200-400 |
| Vercel Pro | $20 |
| Dominio | $1 |
| Email — Amazon SES (~22M) | $2,200 |
| WhatsApp API (×4 de gran escala) | ~$127,000 |
| Storage (S3/Supabase) | $50-100 |
| Monitoreo + CDN | $50-100 |
| **TOTAL** | **~$129,521 - $129,821** |

**Ingresos:** 20,000 × $16.3 = **$326,000/mes**
**Margen:** ~$196,000/mes (60%)

---

## 5. Resumen comparativo por escala

Todas las notificaciones al usuario final en Pro+ pasan por MultiChannelService (email + WhatsApp).

| Escala | Negocios | Costo/mes | Ingreso/mes | Margen | Margen % |
|--------|----------|-----------|-------------|--------|----------|
| Lanzamiento (sin WA) | 30 | $53 | $489 | $436 | 89% |
| Lanzamiento (con WA) | 30 | $197 | $489 | $292 | 60% |
| Colombia consolidado | 300 | $1,706 | $4,890 | $3,184 | 65% |
| LATAM (5 paises) | 5,000 | $32,500 | $81,500 | $49,000 | 60% |
| LATAM lider | 20,000 | $130,000 | $326,000 | $196,000 | 60% |

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

| Mes | Negocios | Costo fijo | WhatsApp | Email | Total | Ingresos | Margen |
|-----|----------|------------|----------|-------|-------|----------|--------|
| 1 | 10 | $33 | $0 (sin WA) | $0 (free tier) | **$33** | $163 | +$130 |
| 2 | 20 | $33 | $0 | $0 | **$33** | $326 | +$293 |
| 3 | 30 | $53 | $144 (activa WA) | $20 | **$217** | $489 | +$272 |
| 4 | 50 | $53 | $240 | $20 | **$313** | $815 | +$502 |
| 5 | 80 | $53 | $383 | $20 | **$456** | $1,304 | +$848 |
| 6 | 120 | $53 | $575 | $20 | **$648** | $1,956 | +$1,308 |
| 7-12 | 120→300 | $58-83 | $575→1,436 | $20→200 | **$653→1,719** | $1,956→4,890 | +$1,303→3,171 |

**Acumulado mes 6:** ~$1,700 gastados, ~$5,053 facturados = **+$3,353 neto**
**Acumulado mes 12:** ~$8,800 gastados, ~$24,000 facturados = **+$15,200 neto**

---

## 8. Infraestructura: cuando escalar

| Umbral | Accion | Costo nuevo | Costo total infra |
|--------|--------|-------------|-------------------|
| 70 GB disco o ~200 negocios | Upgrade VPS a 8 cores / 24 GB / 200 GB | $24/mes | $24 |
| 200 GB disco usado | Supabase Storage Pro o cleanup policy | +$25/mes | $49 |
| 50,000 emails/mes | Resend Pro o Amazon SES | +$20-50/mes | $69-99 |
| 500-800 negocios | Separar DB a segundo VPS | +$24-40/mes | $93-139 |
| 5,000 negocios | 2-3 servidores + DB dedicada | +$100-200/mes | $200-350 |
| 20,000 negocios | Cluster dedicado + DB managed + Redis managed | +$300-500/mes | $500-850 |

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
