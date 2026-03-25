# Proyecto: AGENDITY

Plataforma SaaS de gestión de citas para negocios que trabajan por reservas.

---

## 1. Contexto del proyecto

Agendity es una plataforma de gestión de citas para negocios que trabajan por reservas.

### Enfoque inicial
- Barberías
- Salones de belleza

### Expansión futura
- Spa, estética, uñas, cosmetología, masajes
- Cualquier negocio que funcione con citas

---

## 2. Tipo de aplicación

**Web App PWA** (Progressive Web App) con Next.js.

- Funciona en Android, iPhone y computadora
- Instalable desde el navegador (Add to Home Screen)
- Offline básico con service worker
- **Fase futura:** Capacitor para publicar en App Store / Play Store sin reescribir código

---

## 3. Arquitectura tecnológica

### Frontend — Next.js (PWA)
| Tecnología | Uso |
|---|---|
| **Next.js (App Router)** | Framework principal, routing, layouts, SSG para páginas públicas |
| **Zustand** | Estado local/UI (modales, sidebar, filtros) |
| **TanStack Query (React Query)** | Cache del servidor, sincronización, optimistic updates |
| **Tailwind CSS** | Estilos |
| **React Hook Form + Zod** | Formularios y validación |
| **dayjs** | Manejo de fechas/horarios y timezones |
| **FullCalendar** | Componente de calendario para la agenda |
| **next-pwa** | Service worker y manifest PWA |
| **Vitest + React Testing Library** | Testing |

### Backend — Rails API
| Tecnología | Uso |
|---|---|
| **Rails 8 (API mode)** | Framework principal |
| **ActiveAdmin** | Panel interno para el dev/superusuario |
| **Devise + devise-jwt** | Autenticación con JWT |
| **Pundit** | Autorización por roles |
| **ActiveStorage** | Subida de archivos (comprobantes, fotos) |
| **Action Cable** | WebSockets para tiempo real |
| **Sidekiq + Redis** | Jobs en background (emails, notificaciones, WhatsApp) |
| **rack-cors** | CORS para comunicación frontend ↔ API |
| **Geocoder** | Geolocalización de negocios |
| **friendly_id** | Slugs para URLs públicas (`agendity.com/barberia-elite`) |
| **Pagy** | Paginación |
| **Grover** | Generación de tickets digitales (HTML/CSS → PDF/imagen via Chromium) |
| **RSpec** | Testing |

### Base de datos
- **PostgreSQL** — base de datos principal
- **Redis** — cache, Sidekiq, Action Cable

### Repositorios
Dos repos separados en GitHub:
- `agendity-api` — Backend Rails API
- `agendity-web` — Frontend Next.js PWA

### Multi-tenancy
Enfoque por `business_id` en cada tabla. Cada negocio solo accede a sus propios datos. Se implementa con scopes de Rails y políticas de Pundit.

---

## 4. Terminología y tipos de usuarios

> **Importante:** En Agendity distinguimos claramente entre:
> - **Cliente** = el negocio que paga la suscripción (barbería, salón, consultorio, estudio, etc.). Es el cliente de Agendity.
> - **Usuario final** = la persona que reserva citas en un negocio. No paga suscripción, no necesita cuenta.

### 4.1 Usuario final (quien reserva)
- Buscar negocios
- Ver servicios y precios
- Reservar citas (sin necesidad de crear cuenta)
- Subir comprobante de pago
- Ver mapa de negocios
- Calificar negocios y escribir reseñas

**Identificación:** El usuario reserva con email + nombre + teléfono. No necesita cuenta. El sistema lo reconoce por email en visitas futuras y precarga sus datos.

### 4.2 Cliente (negocio: cualquier negocio con citas)
- Administrar agenda
- Crear servicios y empleados
- Ver reservas
- Confirmar pagos
- Ver reportes
- Generar QR
- Compartir link de reservas
- Configurar políticas de cancelación

### 4.3 Superusuario (administrador de la plataforma)
Gestión vía ActiveAdmin + endpoints API:
- Ver/aprobar/suspender negocios
- Modificar planes de suscripción y precios
- Crear códigos de descuento
- Posicionar negocios destacados
- Ver métricas globales del sistema
- Gestionar códigos de referido y panel de referidos (mark_as_paid)
- Aprobar/rechazar comprobantes de pago de suscripción
- Editar configuración de plataforma (SiteConfig: emails, datos de pago, WhatsApp soporte)

---

## 5. Registro y onboarding de negocios

### Datos de registro
- Nombre del negocio
- Correo
- Contraseña
- Tipo de negocio (barbería, salón, spa, estudio de uñas, consultorio, masajes, cosmetología, etc.)
- Código de referido (opcional, via `?ref=CODE` en la URL — se guarda en localStorage y se envía al crear la cuenta)

### Wizard de onboarding (post-registro)
Después de registrarse, el negocio pasa por un wizard de configuración:

1. **Perfil del negocio** — logo, dirección, teléfono, descripción, redes sociales
2. **Horarios de operación** — días y horas de apertura/cierre
3. **Servicios** — crear al menos un servicio (nombre, precio, duración)
4. **Empleados** — agregar al menos un empleado (puede ser el dueño)
5. **Métodos de pago** — configurar instrucciones de pago (cuenta bancaria, efectivo)
6. **Política de cancelación** — definir porcentaje de penalización

El negocio puede saltar pasos y completarlos después desde el dashboard.

Dependiendo del tipo de negocio, la interfaz cambia de estilo y colores.

---

## 6. Dashboard del negocio

### 6.1 Agenda
Calendario principal del negocio.

**Vistas:** diaria, semanal, por empleado

**Acciones:** crear cita, mover cita, cancelar cita, bloquear horarios

**Cada cita incluye:** cliente, servicio, empleado, precio, estado

**Estados de cita:**
- Pendiente de pago
- Comprobante enviado
- Pago confirmado (se genera ticket digital)
- Check-in (cliente llegó, escanearon QR del ticket)
- Cancelada
- Completada

### 6.2 Empleados
Cada empleado tiene:
- Nombre y foto
- Servicios que realiza
- Horario de trabajo
- Agenda propia

### 6.3 Servicios
Cada servicio tiene:
- Nombre
- Precio
- Duración
- Empleados que pueden realizarlo

### 6.4 Clientes
Base de datos automática (se crea al recibir reservas).
- Nombre, teléfono, email
- Historial de citas
- Servicios utilizados

### 6.5 Reportes
- Ingresos por período
- Servicios más solicitados
- Empleados más ocupados
- Clientes frecuentes

---

## 7. Sistema de reservas públicas

Cada negocio tiene una página pública: `agendity.com/barberia-elite`

**Páginas públicas renderizadas con SSG** (Static Site Generation) en Next.js para SEO y velocidad.

### Flujo de reserva
1. Elegir servicio
2. Elegir empleado
3. Elegir fecha y horario disponible
4. Ingresar email, nombre y teléfono
5. Confirmar reserva

### Protección contra abuso
- Rate limiting en endpoints de reserva
- Job de Sidekiq para validar que no se lancen reservas duplicadas simultáneas del mismo horario
- Bloqueo temporal del slot mientras el cliente completa el formulario (5 min)

---

## 8. Sistema de pagos (modelo P2P)

En la primera fase NO se implementa pasarela de pago.

### Flujo
1. El cliente reserva un servicio
2. El sistema muestra instrucciones de pago del negocio
3. El cliente paga directamente al negocio (transferencia o efectivo)
4. El cliente sube comprobante de pago (foto/captura)
5. El negocio recibe notificación
6. El negocio confirma el pago
7. La cita queda confirmada en la agenda
8. **El cliente recibe un Ticket de Confirmación Digital**

### Ticket de Confirmación Digital

Cuando una cita queda confirmada, el cliente recibe un **ticket digital premium** estilo pase de abordar / entrada VIP.

**Diseño:** Violeta + negro, minimalista, estética de lujo.

**Contenido del ticket:**
- Nombre del cliente
- Servicio reservado
- Empleado asignado
- Fecha y hora
- Dirección del negocio
- Código QR único (para check-in al llegar)

**Distribución:**
- Se envía por WhatsApp y Email
- Se puede visualizar en la app/web
- Fase futura: guardable en Apple Wallet / Google Wallet

**Check-in:** Cuando el cliente llega, el negocio escanea el QR del ticket. La cita pasa a estado `checked_in`.

**Impacto de marca:** El ticket es tan visual que el cliente lo comparte en redes sociales → marketing orgánico gratuito.

### Métodos de pago
- Efectivo
- Transferencia bancaria

### Políticas de cancelación
Cada negocio configura su política:
- Porcentaje de penalización por no-show: 30%, 50% o 100%
- Tiempo límite para cancelar sin penalización

---

## 9. Notificaciones

### Canales
- **WhatsApp** (principal) — vía WhatsApp Business API de Meta (directo, sin intermediarios)
- **Email** — vía Action Mailer + proveedor SMTP (Resend, Postmark, etc.)
- **Push notifications** — fase futura con Capacitor

### Eventos que disparan notificaciones
| Evento | Destinatario | Canal |
|---|---|---|
| Nueva reserva | Negocio | WhatsApp + Email |
| Comprobante subido | Negocio | WhatsApp |
| Pago confirmado + Ticket Digital | Cliente | WhatsApp + Email |
| Recordatorio de cita (24h antes) | Cliente | WhatsApp |
| Cita cancelada | Ambos | WhatsApp + Email |

---

## 10. Generador de QR

Cada negocio puede generar:
- QR de su página de reservas
- QR de su perfil

Para colocar en: el local, redes sociales, publicidad.

---

## 11. Sistema de reseñas

- Calificación de 1 a 5 estrellas
- Reseñas escritas
- Ranking de negocios basado en calificaciones

---

## 12. Mapa de negocios

Los clientes pueden:
- Ver negocios registrados en un mapa
- Filtrar por cercanía, tipo, calificación
- Entrar al perfil del negocio y reservar

**Implementación:** Mapbox o Google Maps API + Geocoder en backend.

---

## 13. Timezone handling

- Cada negocio almacena su zona horaria (`timezone` en la tabla de negocios)
- Los horarios se guardan en UTC en la base de datos
- El frontend convierte a la zona horaria del negocio para mostrar la agenda
- El cliente ve los horarios en la zona horaria del negocio donde reserva
- dayjs con plugin de timezone para las conversiones en frontend

---

## 14. Autenticación y autorización

### Autenticación
- **JWT** (devise-jwt) para la comunicación frontend ↔ API
- Token en header `Authorization: Bearer <token>`
- Refresh token para mantener sesión

### Roles
| Rol | Acceso |
|---|---|
| Cliente | Reservas públicas, perfil propio, reseñas |
| Negocio (owner) | Dashboard completo de su negocio |
| Empleado | Vista limitada de su agenda |
| Superusuario | ActiveAdmin + API de gestión global |

### Autorización
Pundit policies por cada recurso. Cada request valida rol + pertenencia al negocio.

---

## 15. API

- Versionada: `/api/v1/`
- Formato JSON
- Autenticación JWT
- Rate limiting en endpoints públicos (rack-attack)
- Paginación con Pagy

---

## 16. Deploy e infraestructura

### Arquitectura
Un **VPS** con Docker Compose corriendo todos los servicios:

| Servicio | Puerto |
|---|---|
| Nginx (reverse proxy + SSL) | 80, 443 |
| Next.js (`next start`) | 3000 |
| Rails API (Puma) | 3001 |
| PostgreSQL | 5432 |
| Redis | 6379 |
| Sidekiq | — (worker) |

### Ventajas del VPS único
- Costo predecible y fijo
- Sin sorpresas de facturación por tráfico
- Control total sobre la infraestructura
- Un solo lugar para monitorear

### SSL
Let's Encrypt con Certbot (automático).

### CI/CD
GitHub Actions para:
- Correr tests (RSpec + Vitest)
- Build de la imagen Docker
- Deploy automático al VPS vía SSH

---

## 17. Testing

| Capa | Herramienta |
|---|---|
| Backend unit/integration | RSpec |
| Backend API tests | RSpec + request specs |
| Frontend unit | Vitest + React Testing Library |
| Frontend E2E | Playwright (fase futura) |

---

## 18. Inteligencia artificial (fase futura)

El sistema debe estar preparado para incluir IA.

### Funciones planificadas
- **Análisis de horarios** — detectar horarios más/menos ocupados, sugerir promociones
- **Análisis de clientes** — detectar clientes frecuentes y los que dejaron de venir
- **Proyección de ingresos** — calcular ingresos estimados según reservas actuales
- **Recomendaciones de precios** — sugerir ajustes según demanda

---

## 19. Planes de suscripción

**Trial:** 7 días gratis con acceso completo al Plan Profesional. Después elige un plan y paga via checkout P2P.

**Estrategia de pricing:** El plan Inteligente debe ser el más atractivo. La diferencia de solo $6 USD ($24k COP) con el Profesional incentiva a elegir el plan con IA.

| | **Básico** | **Profesional** | **Inteligente** |
|---|---|---|---|
| **Precio/mes (USD)** | $8 | $17 | $23 |
| **Precio/mes (COP)** | $37,000 | $75,000 | $99,000 |
| Agenda y calendario | Si | Si | Si |
| Servicios | Hasta 5 | Ilimitados | Ilimitados |
| Empleados | Hasta 3 | Hasta 10 | Ilimitados |
| Múltiples servicios por cita | Si | Si | Si |
| Reservas online | Si | Si | Si |
| Clientes en BD | Ilimitados | Ilimitados | Ilimitados |
| Página pública del negocio | Si | Si | Si |
| Portada del negocio (upload/Pexels) | Si | Si | Si |
| QR de reservas + scanner cámara | Si | Si | Si |
| Duración visible al usuario | Si | Si | Si |
| Notificaciones Email | Si | Si | Si |
| Notificaciones WhatsApp | No | Si | Si |
| Ticket digital VIP | No | Si | Si |
| Reportes básicos | Si | Si | Si |
| Reportes avanzados + ganancias netas | No | Si | Si |
| Cierre de caja (comisiones, deuda) | No | Si | Si |
| Créditos / Cashback | No | Si (configurable por SuperAdmin) | Si (configurable por SuperAdmin) |
| Aplicar créditos en reserva | No | Si | Si |
| Personalización de marca | No | Si (logo, colores) | Si (logo, colores) |
| Mapa de negocios | Listado | Listado + destacado | Listado + destacado + verificado |
| Badge verificado (azul) en Explore | No | No | Si |
| Bloqueo de slots | Si | Si | Si |
| Bloqueo de días cerrados | Si | Si | Si |
| Políticas de cancelación | Básica | Configurable | Configurable |
| Preview de cancelación con penalización | Si | Si | Si |
| Tarifas dinámicas | No | Manual (fijo/progresivo) | Manual + sugerencias IA |
| Precios dinámicos visibles al usuario | No | Si | Si |
| Metas financieras | No | No | Si |
| Reconciliación contable | No | No | Si |
| Análisis inteligente (IA) | No | No | Si |
| Predicción de ingresos | No | No | Si (futuro) |
| Recomendaciones de precios | No | No | Si |
| Alertas de clientes inactivos | No | No | Si (futuro) |
| Portal del empleado | Si | Si | Si |
| Banners publicitarios en reserva | Si | Si | Si |
| Soporte | Email | Email + WhatsApp | Email + WhatsApp + prioritario |

El superusuario puede modificar precios, límites y características desde ActiveAdmin.

---

## 20. Escalabilidad futura

- Integración de pasarelas de pago (Stripe, MercadoPago)
- Apps móviles vía Capacitor
- Multi idioma (i18n)
- Multi moneda
- Expansión a varios países
- Política de datos / GDPR
- Playwright para E2E testing

---

## 21. Estado del proyecto

**Fase actual: Pre-lanzamiento**

El producto está funcional de punta a punta. Todas las features core están implementadas e integradas (frontend + backend). El sistema es usable en su totalidad.

### Frontend (agendity-web) — Next.js 16 PWA
- [x] Registro de negocio + wizard de onboarding (6 pasos)
- [x] Creación de servicios (CRUD con modal)
- [x] Creación de empleados (CRUD con modal + asignación de servicios + horarios)
- [x] Agenda / calendario (FullCalendar, vistas día/semana, drag-and-drop, auto-refresh 15s)
- [x] Reservas públicas con página SSG por negocio
- [x] Flujo de reserva multi-paso (servicio + adicionales → empleado → fecha/hora → datos → confirmación con QR)
- [x] Gestión de pagos/comprobantes (página dedicada con aprobar/rechazar, viewer de comprobantes)
- [x] Check-in de clientes (página con input de código de ticket)
- [x] Mapas con Leaflet (LocationPicker en settings, ExploreMap con marcadores en /explore) + botón "Cómo llegar"
- [x] Explorar negocios (búsqueda + filtros + vista lista/mapa + badge "Destacado" para Pro+)
- [x] Reseñas (lista con estrellas, restringida por plan)
- [x] Generador de QR (descarga PNG)
- [x] Dashboard del negocio (sidebar con lock icons por plan + topbar con badge de plan + mobile nav)
- [x] Reportes y métricas (recharts: ingresos, top servicios, top empleados)
- [x] Ticket digital VIP (estilo boarding pass con QR, solo para Pro+)
- [x] Landing page (hero + features + how-it-works + CTA para negocios)
- [x] Clientes (lista paginada con historial de citas)
- [x] Settings (perfil, logo upload, ubicación con mapa, horarios, pagos, cancelación, colores Pro+, notificaciones con toggle de sonido)
- [x] Sistema de planes (badge en topbar, lock features en sidebar, upgrade banner, enforcement en backend)
- [x] Notificaciones in-app (campanita con badge, dropdown, página completa, polling 30s)
- [x] Notificaciones del navegador (Notification API nativa + sonido Web Audio API configurable)
- [x] Tiempo real (NATS WebSocket + fallback a polling)
- [x] Prevención de slots pasados (no se puede agendar en horas que ya pasaron hoy)
- [x] Bloqueo temporal de slots (Redis lock 5min mientras el usuario completa el formulario)
- [x] Persistencia de datos del cliente (localStorage + lookup por email para precargar formulario de reserva)
- [x] Dropdown de ciudades en explore (endpoint `/api/v1/public/cities` con conteo de negocios)
- [x] Descarga de ticket como imagen (html-to-image → PNG + Web Share API)
- [x] Instrucciones de pago post-booking (Nequi/Daviplata/Bancolombia con botones de copiar)
- [x] Ticket con vistas por estado (pending_payment → instrucciones, payment_sent → en revisión, confirmed → QR ticket VIP, etc.)
- [x] QR en pantalla de confirmación de reserva
- [x] Componentes UI (14 primitivos + LocationPicker, ExploreMap, NotificationBell, UpgradeBanner, ImageViewerModal, MapEmbed, StarRating, QRCodeDisplay)
- [x] Middleware de protección de rutas (JWT cookie sync)
- [x] 18 hooks (TanStack Query): auth, appointments, services, employees, customers, business, onboarding, reports, reviews, blocked-slots, public, explore, payments, notifications, subscription, realtime, event-notifications, locations

### Backend (agendity-api) — Rails 8 API
- [x] 18+ modelos + 25 migraciones (PostgreSQL)
- [x] 18+ controllers (v1 + public + admin, CRUD + state machines + check-in)
- [x] 22+ service objects (SOLID: BaseService + ServiceResult + NatsPublisher + SlotLockService)
- [x] 13 serializers (Blueprinter con views + campo `featured`)
- [x] 8 Pundit policies
- [x] Auth JWT (Devise + refresh tokens + denylist)
- [x] Validación de planes en backend (PlanEnforcement concern: límites empleados/servicios, brand customization Pro+, ticket VIP Pro+)
- [x] 60+ specs (RSpec + shoulda-matchers + FactoryBot)
- [x] Seed data (5 negocios en 3 ciudades, 248+ citas, 23 reviews, 3 planes con límites)
- [x] CORS + Rack::Attack (rate limiting)
- [x] Panel de superusuario (ActiveAdmin)
- [x] Notificaciones in-app (modelo + controller + creación desde jobs)
- [x] Email (Action Mailer: AppointmentMailer + BusinessMailer, templates HTML)
- [x] Background jobs (7 Sidekiq jobs + NATS publish en cada job)
- [x] Scheduled jobs (reminder 8am diario, token cleanup domingo 3am)
- [x] Upload de logo (ActiveStorage)
- [x] Protección de concurrencia de slots (3 capas: Redis lock + SELECT FOR UPDATE + unique index)
- [x] Tiempo real (NATS publisher en jobs → WebSocket al frontend)
- [x] Encriptación de datos de pago (Rails `encrypts`: nequi_phone, daviplata_phone, bancolombia_account + filtrado en logs)
- [x] 3 vistas de serializer para Business (public=sin pago, with_payment=instrucciones, default=completo)
- [x] Customer lookup por email (`GET /api/v1/public/customer_lookup`)
- [x] Endpoint de ciudades (`GET /api/v1/public/cities` con DISTINCT + conteo)
- [x] Check-in por código de ticket (`POST /api/v1/public/checkin_by_code`)
- [x] Negocio destacado en explore (featured_listing del plan, ordenamiento preferente, badge "Destacado")
- [x] Ticket VIP condicionado al plan (solo Pro+)
- [x] Prevención de reservas en horarios pasados
- [x] Índices de DB (customers.email, businesses.city)
- [x] Impersonación de negocios (ImpersonationController: token swap para que SuperAdmin observe como cualquier negocio)
- [x] Request logging (modelo RequestLog + concern RequestLogging + CleanupOldRequestLogsJob + panel ActiveAdmin)
- [x] Activity Log (modelo ActivityLog con log de cada acción de negocio, ciclo de vida por recurso, request_id para trazabilidad)
- [x] Órdenes de pago de suscripción (modelo SubscriptionPaymentOrder + 3 jobs automatizados + recurso ActiveAdmin)
- [x] Upload de comprobantes con ActiveStorage (URLs absolutas, Content-Type correcto para multipart)
- [x] Sistema de referidos (ReferralCode + Referral con estados pending→activated→paid, link ?ref=CODE, activación al aprobar pago)
- [x] Checkout de suscripción P2P (/dashboard/subscription/checkout: elegir plan → ver datos de pago → subir comprobante)
- [x] CheckoutService + ApprovePaymentService (crea Subscription, activa referral, reactiva business)
- [x] SiteConfig (modelo key/value para datos de contacto y pago; editable desde ActiveAdmin > Configuración)
- [x] Mailers usan SiteConfig.get() en vez de valores hardcoded
- [x] Trial de 7 días (antes 30) — Business#trial_ends_at = 7.days.from_now al registrar
- [x] TrialExpiryAlertJob (diario 8am, 3 stages: aviso 2 días antes, día de fin, suspensión 2 días después)
- [x] trial_alert_stage en Business para anti-duplicados de alertas de trial (0=ninguna, 1=2d aviso, 2=dia fin, 3=suspendido, 4=inactivo)
- [x] Tipo de pago de empleado: payment_type (manual/commission/fixed_daily) + fixed_daily_pay; cierre de caja calcula según tipo; alerta naranja en formulario para empleados manuales
- [x] Error codes en API: ServiceResult con error_code, render_error con code: param; códigos definidos en appointments, auth, bookings, cash register, credits, invitations
- [x] Copys industry-agnostic: landing, SEO, registro y explore ya no dicen "barberías y salones" sino "negocios que trabajan con citas"; nuevos tipos de negocio en registro (spa, estudio de uñas, consultorio, masajes, etc.)
- [x] Email de bienvenida (BusinessMailer#welcome) con mini-onboarding, se dispara en RegisterService vía deliver_later
- [x] QR en email de confirmación de reserva (rqrcode gem, QrCodeHelper, imagen inline con attachments.inline)
- [x] Códigos de descuento (DiscountCode: percentage/fixed, max_uses, vigencia, source manual/birthday, ligado a cliente opcional)
- [x] Campañas de cumpleaños (BirthdayCampaignJob diario 8am, birth_date en Customer, configuración por negocio)
- [x] Employee checkin endpoint (POST /api/v1/employee/checkin_by_code con lógica de sustituto)
- [x] formatCurrency con Intl.NumberFormat('es-CO') en frontend (separadores de miles, sin decimales)
- [x] DemandAnalysisService mejorado: meses bajos generan descuento, meses altos generan incremento; meses en español (MONTH_NAMES_ES)
- [x] Subscription banner en dashboard (SubscriptionBanner, estados amarillo/rojo/rojo oscuro para suscripción y trial)

### Infraestructura
- [x] Docker Compose (7 servicios: PostgreSQL, Redis, NATS, Rails API, Sidekiq, Next.js, Nginx)
- [x] Dockerfiles (API multi-stage + Web multi-stage)
- [x] Nginx reverse proxy (API + Web + NATS WebSocket + ActiveStorage)
- [x] Script de deploy (`scripts/deploy.sh`)
- [x] NATS server config con WebSocket + auth token

### Cambios recientes — nuevas features (marzo 2026)
- [x] Sistema de referidos (ReferralCode + Referral, link ?ref=CODE → localStorage → registro → activación al aprobar pago, panel ActiveAdmin)
- [x] Trial reducido a 7 días + TrialExpiryAlertJob con 4 stages (2d aviso, dia fin, +2d suspension, +7d inactive) + trial_alert_stage en Business
- [x] Checkout de suscripción P2P (página /dashboard/subscription/checkout, CheckoutService, ApprovePaymentService)
- [x] SiteConfig: configuración de plataforma en DB (key/value, 7 claves), seeds con datos de contacto, pago y app_url, editable desde ActiveAdmin
- [x] Tipo de pago de empleado (payment_type: manual/commission/fixed_daily, fixed_daily_pay, cierre de caja adaptado)
- [x] Error codes en API (ServiceResult#error_code, render_error con code:)
- [x] Copys industry-agnostic en landing, SEO, registro y explore; nuevos tipos de negocio (spa, estudio de uñas, consultorio, masajes, cosmetología)

### Cambios recientes (marzo 2026 — segunda iteración)
- [x] Sistema de cancelaciones completo (cancelled_by: business/customer, penalización por deadline, pending_penalty en customer, endpoint público, botón en ticket)
- [x] Filtrado de empleados por servicio (EmployeeSelector filtra según servicio seleccionado, `service_ids` en EmployeeSerializer)
- [x] Modales mejorados (tamaños md→lg, lg→2xl, nuevo tamaño `xl`, scroll con `max-h-[90vh] overflow-y-auto`)
- [x] Fix en job de notificación de nueva reserva (`.date` → `.appointment_date` en SendNewBookingNotificationJob)
- [x] Fix en instrucciones de pago post-booking (BookingConfirmation usa `activeBusiness` de la respuesta de booking con vista `with_payment`)
- [x] Cuerpo de notificación de cancelación diferenciado ("Cancelada por [negocio]" vs "El cliente canceló" según `cancelled_by`)
- [x] Sidekiq downgrade a 7.x por compatibilidad con Redis 6
- [x] Impersonación de negocios (SuperAdmin puede "Observar como" cualquier negocio: token swap + sessionStorage, banner amarillo, endpoint start/stop con audit logging)
- [x] Request logging (modelo RequestLog, concern RequestLogging en BaseController, cleanup job diario, panel en ActiveAdmin con filtros y detalle)
- [x] Órdenes de pago de suscripción (modelo SubscriptionPaymentOrder con estados pending/paid/overdue/cancelled, 3 jobs: GenerateSubscriptionPaymentOrdersJob, SendSubscriptionReminderJob, CheckExpiredSubscriptionsJob, recurso en ActiveAdmin)
- [x] Activity Log como transacciones (index muestra solo eventos primarios, detalle muestra ciclo de vida completo del recurso + request logs relacionados)
- [x] Fix en upload de comprobantes (Content-Type: undefined para multipart FormData, URLs de ActiveStorage ahora absolutas)
- [x] Default URL options configurado en development.rb para generación correcta de URLs de ActiveStorage
- [x] Payment serializer genera URLs absolutas para imágenes de comprobantes (ActiveStorage attachment + ENV['API_HOST'] fallback)
- [x] Flowchart simplificado (Diagrama 1A) agregado a flujos-completos.md
- [x] Sistema de ubicaciones geográficas (gema `city-state`, API `/api/v1/locations/*`, cascading selects en frontend y ActiveAdmin)
- [x] `activeadmin_addons` v1.10.2 (Select2, date pickers, toggle booleans) + `chartjs-adapter-date-fns` para dashboard
- [x] Guard `require_business!` en BaseController (403 si usuario sin business, admins exentos)
- [x] Agenda lee `?date=` param de URL para navegación desde notificaciones
- [x] Fix hydration SSR en NotificationSection (useEffect para Notification.permission)
- [x] Seeds: Barbería La 93 (Bogotá) y Studio 70 (Medellín) con servicios, empleados, citas, reviews
- [x] Batch actions en RequestLogs de ActiveAdmin
- [x] Ubicación estandarizada: country/state como códigos ISO, city como nombre
- [x] Semántica de estados de negocio definida (active=normal, suspended=oculto del público, inactive=desactivado total)
- [x] Página pública bloqueada para negocios suspended/inactive (403)
- [x] Dashboard bloqueado para negocios inactive (pantalla "Cuenta desactivada")
- [x] Banner "Oculto" en dashboard para negocios suspended
- [x] Seeds de ejemplo: Barber King (suspended) y Glamour Studio (inactive)

### Notas técnicas importantes
- El `ticket_code` se genera SIEMPRE al crear la cita (no al aprobar el pago). Permite identificar la cita en todo el flujo. La visualización VIP (boarding pass + QR + descarga PNG) es exclusiva del plan Profesional+.
- Activity Logs y Request Logs están disponibles en el panel de SuperAdmin para auditoría completa.
- Las órdenes de pago de suscripción se generan automáticamente y el superadmin las confirma manualmente.
- El trial dura 7 días. Al vencer, el negocio debe pagar via checkout P2P. `ApprovePaymentService` reactiva el negocio y activa el referral si corresponde.
- `SiteConfig` centraliza todos los datos de contacto y pago de la plataforma (7 claves: support_email, support_whatsapp, admin_email, payment_nequi, payment_bancolombia, payment_daviplata, app_url); los mailers no tienen valores hardcoded.
- Los error codes en API permiten que el frontend maneje errores específicos sin depender solo del mensaje de texto.
- `BusinessMailer#welcome` se dispara en `RegisterService` con mini-onboarding y datos de contacto desde SiteConfig.
- El email de confirmación de reserva incluye QR del ticket como imagen inline (rqrcode gem + `QrCodeHelper#ticket_qr_png`).
- Los codigos de descuento (DiscountCode) se aplican en el booking flow: después de tarifa dinámica, antes de créditos. Los birthday codes son de un solo uso y están ligados al cliente.
- `BirthdayCampaignJob` corre diario a las 8am y genera códigos de descuento para clientes con cumpleaños hoy.
- `formatCurrency` usa `Intl.NumberFormat('es-CO')` — separadores de miles con punto, sin decimales.
- `DemandAnalysisService` genera sugerencias en español (MONTH_NAMES_ES) para meses de alta demanda (incremento) y baja demanda (descuento), ademas de fines de semana y temporada navideña.
- Ver `docs/tech/flujos-completos.md` para diagramas detallados de todos los flujos del sistema.
- Ver `docs/tech/sistema-referidos.md` para el flujo técnico del sistema de referidos y checkout de suscripción.
- Ver `docs/tech/codigos-descuento-cumpleanos.md` para la documentación técnica de códigos de descuento y campañas de cumpleaños.
- Ver `docs/tech/sidekiq-jobs.md` para la lista completa de jobs, queues, schedules y config de sidekiq-cron.
- Ver `docs/tech/email-bienvenida.md` para el email de bienvenida post-registro (BusinessMailer#welcome).
- Ver `docs/tech/alertas-suscripcion.md` para el flujo de alertas de trial y suscripción con los 4 stages (incluyendo Stage 4: inactive en día +7).

### Pendiente para lanzamiento
- [ ] CI/CD (GitHub Actions) — nice to have
- [ ] WhatsApp Business API (notificaciones) — se puede lanzar sin esto, comunicar como "próximamente"
- [ ] Tests E2E (Playwright) — nice to have
- [ ] Definir qué es "reportes avanzados" vs "básicos" y restringir contenido real

### Pendiente post-lanzamiento
- [ ] Features IA (Plan Inteligente): análisis, predicciones, recomendaciones, alertas
- [ ] Capacitor para app móvil nativa
- [ ] Push notifications
- [ ] Pasarela de pago (Stripe/MercadoPago)
- [ ] Multi-idioma (i18n)
- [ ] Notificaciones WhatsApp completas
