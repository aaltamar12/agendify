# RESUMEN: Lo que tenemos y hacia dónde vamos

## Documentos del proyecto (10 archivos)

| Archivo | Propósito |
|---|---|
| `idea-de-negocio.md` | Visión, mercado, modelo SaaS, proyecciones, estrategia de crecimiento |
| `desarrollo.md` | Arquitectura técnica completa, stack, features, flujos, deploy |
| `docs/filosofia-de-marca.md` | Los 3 pilares (Prestigio, Eficiencia Silenciosa, Exclusividad), tono de voz, posicionamiento premium |
| `docs/copys/marca-y-posicionamiento.md` | Textos listos para usar: hero, propuesta de valor, frases de exclusividad |
| `docs/tech/base-de-datos-v1.md` | Esquema de BD v1 (19 tablas, ERD, estados, índices) — borrador |
| `CLAUDE.md` | Instrucciones para que Claude siempre tenga contexto del proyecto |
| `.claude/commands/` (4 skills) | `/marca`, `/docs`, `/tech`, `/copys` |

---

## Terminología

- **Cliente** = el negocio que paga la suscripción (barbería, salón, spa). Es el cliente de Agendify.
- **Usuario final** = la persona que reserva citas en un negocio. No paga suscripción, no necesita cuenta.

---

## Lo que es Agendify

Una plataforma SaaS **premium** de gestión de citas para negocios de servicios en LATAM. No es una agenda — es la **infraestructura tecnológica** que profesionaliza negocios informales con datos e IA. Arranca con barberías y salones en **Barranquilla**, escala a Colombia y luego LATAM.

---

## Los 3 pilares

1. **Prestigio de Marca** — interfaz limpia, sin ads, violeta+negro, el link de reserva eleva la imagen del negocio
2. **Eficiencia Silenciosa** — todo automatizado en background, recepcionista de guante blanco 24/7
3. **Filtro de Exclusividad** — depósitos, confirmación inteligente, ticket VIP digital, protección del tiempo del profesional

---

## Diferenciadores del producto

- **Ticket de Confirmación Digital** — pase estilo boarding pass (violeta+negro) con QR para check-in, compartible en redes → marketing orgánico
- **Diseño minimalista premium** — sin publicidad, sin distracciones, interfaz de alta gama
- **IA integrada** (fase futura) — análisis de demanda, predicción de ingresos, recomendaciones de precios

---

## Stack técnico definido

- **Frontend:** Next.js (PWA) + Zustand + TanStack Query + Tailwind + dayjs + FullCalendar
- **Backend:** Rails 8 API + ActiveAdmin + Devise JWT + Pundit + Sidekiq + Redis + Grover (tickets)
- **DB:** PostgreSQL + Redis
- **WhatsApp:** WhatsApp Business API de Meta (directo, sin intermediarios)
- **Deploy:** VPS único con Docker Compose (Nginx + Next + Rails + PG + Redis + Sidekiq)
- **Repos:** Separados → `agendify-api` (Rails) + `agendify-web` (Next.js)
- **Testing:** RSpec (backend) + Vitest + React Testing Library (frontend)
- **CI/CD:** GitHub Actions → tests → build Docker → deploy al VPS vía SSH

---

## BD diseñada (v1 borrador, 19 tablas)

| Tabla | Propósito |
|---|---|
| users | Dueños de negocio y superadmins |
| businesses | Negocios registrados (con payment_instructions, cancellation_policy, trial, status) |
| employees | Barberos/estilistas |
| services | Servicios del negocio |
| employee_services | Qué servicios hace cada empleado |
| customers | Usuarios finales (se crean al reservar) |
| appointments | Citas (con ticket_code, ticket_url, checked_in_at) |
| payments | Comprobantes de pago P2P |
| reviews | Reseñas (vinculadas a customer_id) |
| business_hours | Horarios del negocio |
| employee_schedules | Horarios por empleado |
| blocked_slots | Bloqueos manuales de agenda (almuerzo, vacaciones, etc.) |
| subscriptions | Suscripciones activas |
| plans | Planes de la plataforma |
| discount_codes | Códigos promocionales |
| business_qr | QR generados |
| analytics_events | Eventos para IA y reportes |
| ai_insights | Recomendaciones de IA (futuro) |
| ai_predictions | Proyecciones de IA (futuro) |

---

## Modelo de negocio

- SaaS por suscripción mensual (**30 días gratis** con acceso Profesional)
- **La suscripción la paga el cliente de Agendify (el negocio: barbería, salón, etc.)**. El usuario final (quien reserva citas) nunca paga a Agendify
- Pagos P2P en fase 1 (sin pasarela)
- Meta: 500 negocios → 15M COP/mes, 5000 → 150M COP/mes

### Planes y límites

> ⚠️ PENDIENTE: Definir precios de Profesional e Inteligente, y límites exactos de cada plan.

| | **Básico** | **Profesional** | **Inteligente** |
|---|---|---|---|
| **Precio/mes** | $30.000 COP | ⚠️ POR DEFINIR | ⚠️ POR DEFINIR |
| Servicios | ⚠️ POR DEFINIR | ⚠️ POR DEFINIR | ⚠️ POR DEFINIR |
| Empleados | ⚠️ POR DEFINIR | ⚠️ POR DEFINIR | ⚠️ POR DEFINIR |
| Reservas/mes | ⚠️ POR DEFINIR | ⚠️ POR DEFINIR | ⚠️ POR DEFINIR |
| Ticket digital VIP | No | Si | Si |
| Reportes avanzados | No | Si | Si |
| Personalización marca | No | Si | Si |
| IA (análisis, predicciones) | No | No | Si |
| Soporte prioritario | No | No | Si |

---

## MVP incluye

- Registro de negocio + wizard de onboarding (6 pasos)
- Creación de servicios y empleados
- Agenda/calendario (diaria, semanal, por empleado)
- Reservas públicas con página SSG por negocio
- Pago P2P (comprobante + confirmación)
- Ticket de Confirmación Digital premium (QR + check-in)
- Bloqueo de slots en agenda
- Mapa de negocios (geolocalización)
- Reseñas y calificaciones
- Generador de QR
- Dashboard del negocio con reportes
- Panel de superusuario (ActiveAdmin)
- Notificaciones: WhatsApp Business API (Meta) + Email

---

## Lo que falta por definir antes de escribir código

| # | Tema | Prioridad |
|---|---|---|
| 1 | **Precios de planes Profesional e Inteligente** — y límites exactos por plan (servicios, empleados, reservas, clientes, WhatsApp) | Alta |
| 2 | **Cobro de suscripción del negocio (cliente de Agendify)** — cómo paga su plan sin pasarela de pago | Alta |
| 3 | **Refinar esquema de BD** — v1 con sugerencias aplicadas, falta revisión final | Alta |
| 4 | **Identidad visual final** — paleta exacta, tipografía, logo | Media |
| 5 | **Landing page** — diseño y copys finales | Media |
| 6 | **Legales** — términos de servicio, privacidad | Media |
| 7 | **KPIs del MVP** — qué mide éxito | Media |
