# Agendity — Instrucciones del proyecto

## Archivos obligatorios
SIEMPRE lee estos archivos al inicio de cada conversación antes de responder:
- `idea-de-negocio.md` — visión, modelo de negocio, estrategia
- `desarrollo.md` — arquitectura técnica, features, stack

## Terminología obligatoria
- **Cliente** = el negocio (barbería, salón) que paga suscripción a Agendity
- **Usuario final** = la persona que reserva citas. No paga suscripción, no necesita cuenta
- Nunca confundir estos términos en código, documentación ni copys

## Stack del proyecto
- **Frontend:** Next.js (PWA) + Zustand + TanStack Query + Tailwind CSS + dayjs + FullCalendar
- **Backend:** Rails 8 API + ActiveAdmin + Devise JWT + Pundit + Sidekiq + Redis + Grover (tickets)
- **DB:** PostgreSQL + Redis
- **WhatsApp:** WhatsApp Business API de Meta (directo, sin intermediarios)
- **Deploy:** VPS con Docker Compose (Nginx + Next.js + Rails + PostgreSQL + Redis + Sidekiq)
- **Repos:** `agendity-api` (Rails) + `agendity-web` (Next.js) — repos separados

## Idioma
- Responde siempre en español
- Código y nombres técnicos en inglés
- Comentarios en código en inglés

## Skills disponibles — Úsalas proactivamente
Cuando la conversación toque estos temas, sugiere o usa la skill correspondiente:

- `/marca` — Cualquier tema sobre: identidad, branding, tono de voz, nombre de features, tagline, misión, visión, valores, paleta de colores, personalidad de marca, cómo se ve Agendity, cómo se comunica
- `/docs` — Cualquier tema sobre: documentar decisiones, flujos de usuario, reglas de negocio, pricing, planes, roadmap, procesos, estrategia, modelo de negocio, competencia, métricas, KPIs
- `/tech` — Cualquier tema sobre: documentar arquitectura, API, endpoints, base de datos, modelos, migraciones, setup, deploy, decisiones técnicas, diagramas, ERD, convenciones de código
- `/copys` — Cualquier tema sobre: textos de la app, landing page, emails, mensajes de WhatsApp, notificaciones, onboarding, botones, CTAs, marketing, redes sociales, descripciones
- `/seo` — Cualquier tema sobre: SEO, keywords, metadata, structured data, sitemap, robots.txt, indexación, Core Web Vitals, posicionamiento en Google, auditoría SEO

## Principios de desarrollo
- MVP first: lanzar rápido, iterar después
- No over-engineer: solo lo necesario para la tarea actual
- El mercado inicial es Barranquilla, Colombia
- Target: barberías y salones de belleza
