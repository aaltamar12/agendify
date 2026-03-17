# Sistema de Soporte por Plan — Agendity

> Última actualización: 2026-03-17

## Resumen

Agendity ofrece canales de soporte diferenciados por plan. El botón de ayuda (?) en el topbar del dashboard muestra los canales disponibles según el plan del negocio.

---

## Canales por plan

| Canal | Básico | Profesional | Inteligente | Trial |
|---|---|---|---|---|
| **Email** | ✅ | ✅ | ✅ | ✅ |
| **WhatsApp** | 🔒 | ✅ | ✅ | ✅ |
| **Chat en vivo** | 🔒 | 🔒 | ✅ | 🔒 |

### Datos de contacto
- **Email:** soporte@agendity.com
- **WhatsApp:** +573001234567

---

## Implementación actual

### Frontend

**Componente:** `src/components/layout/help-button.tsx`
- Botón con ícono `HelpCircle` en el topbar
- Dropdown con lista de canales disponibles
- Canales no disponibles muestran ícono de candado + "Disponible en Plan [X]"
- Email abre `mailto:`, WhatsApp abre `wa.me/`

**Topbar layout:** `[🔔 Notif] [❓ Ayuda] | [Nombre + Plan] [Avatar]`

**Constantes:** `src/lib/constants.ts`
```typescript
SUPPORT_CONFIG = { email, whatsapp, whatsappUrl }
SUPPORT_CHANNELS_BY_PLAN = { basico: ['email'], profesional: ['email','whatsapp'], ... }
```

### Archivos relevantes
- `src/components/layout/help-button.tsx` — componente del dropdown
- `src/components/layout/topbar.tsx` — integración en el header
- `src/lib/constants.ts` — configuración de canales por plan

---

## Pendiente por implementar

### 1. Chat en vivo (Plan Inteligente) — PENDIENTE
- **Estado:** No implementado. Actualmente el canal "chat" abre WhatsApp con prefijo "Soporte prioritario"
- **Plan ideal:** Widget de chat real-time con el admin de Agendity
- **Opciones técnicas:**
  - **Crisp/Tawk.to** — widget embebido, gratis hasta cierto volumen, fácil de integrar con `<script>` tag
  - **Custom con NATS** — usar el servidor NATS existente para chat directo. Crear un canal `support.{business_id}` y un panel de admin para responder
  - **Intercom/Zendesk** — más profesional pero tiene costo mensual
- **Recomendación para post-lanzamiento:** Empezar con Crisp (gratis) y migrar a custom con NATS si el volumen lo justifica

### 2. Centro de ayuda / FAQ — PENDIENTE
- Página `/dashboard/help` con preguntas frecuentes
- Tutoriales en video (embeds de YouTube/Loom)
- Guías paso a paso para funcionalidades principales

### 3. Sistema de tickets de soporte — PENDIENTE
- Formulario de contacto que crea un ticket interno
- Historial de tickets del negocio
- Panel de admin (ActiveAdmin) para gestionar tickets
- Priorización por plan (Inteligente = prioritario)

### 4. Onboarding tour — PENDIENTE
- Tour guiado al iniciar sesión por primera vez
- Tooltips interactivos en features clave
- Biblioteca: `react-joyride` o `driver.js`

---

## Relación con otros sistemas

- **Planes:** `use-subscription.ts` determina qué canales mostrar
- **Pricing:** Documentado en `docs/pricing-detalle-planes.md` sección de soporte
- **ActiveAdmin:** En el futuro, los tickets de soporte se gestionarán desde `/admin`
