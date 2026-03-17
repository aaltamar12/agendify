# SEO — Agendity Landing Page

> **Fecha:** 2026-03-17
> **Estado:** Implementado

---

## Resumen

Se implementaron mejoras de SEO en la landing page y configuración general del sitio para mejorar la indexación en Google y la visibilidad en redes sociales.

---

## Problema detectado

Un audit con Seobility reveló que los crawlers veían la página **completamente vacía** (0 palabras, sin H1, sin headings, sin links internos). La causa raíz era que `AppProviders` inicializaba `demoReady = false` y solo lo cambiaba a `true` en un `useEffect`, que no se ejecuta en el servidor. Esto hacía que el SSR renderizara `null` — Google y los crawlers no veían contenido.

---

## Cambios realizados

### 1. Fix crítico: SSR renderiza contenido (AppProviders)

**Archivo:** `src/providers/app-providers.tsx`

- `demoReady` ahora se inicializa como `true` en servidor y en modo no-demo
- Solo se bloquea el rendering cuando el modo demo necesita carga async
- Esto asegura que el HTML del servidor incluye todo el contenido de la página

### 2. Metadata completa (Root Layout)

**Archivo:** `src/app/layout.tsx`

| Campo | Antes | Después |
|---|---|---|
| Title | `"Agendity"` (1 palabra, 78px) | `"Agendity — Agenda de citas para barberías y salones"` (con template `%s \| Agendity`) |
| Description | `"Plataforma de gestión de citas..."` (genérica) | Descripción con keywords: reservas online, agenda digital, control de ingresos |
| themeColor | En `metadata` (deprecado en Next.js 16) | Movido a `viewport` export |
| Open Graph | No existía | Completo: title, description, image, locale `es_CO` |
| Twitter Card | No existía | `summary_large_image` con imagen |
| Robots | No existía | `index: true, follow: true` con configuración de GoogleBot |
| Keywords | No existían | 9 keywords relevantes para el mercado |
| Canonical | No existía | URL canónica configurada |
| Apple touch icon | No existía | `/icons/apple-touch-icon.png` (180x180) |
| Favicon | No existía | `/favicon.ico` (32x32) |

### 3. Landing page optimizada

**Archivo:** `src/app/page.tsx`

- **Metadata específica** con keywords long-tail ("agenda de citas barbería", "sistema de citas online", "app para salón de belleza")
- **JSON-LD structured data** (`SoftwareApplication`) para rich snippets en Google
- **Navbar sticky** con links internos a secciones (Funciones, FAQ, Explorar)
- **Badge** de "30 días gratis" en el hero
- **6 features** (antes 4): se agregaron "Recordatorios automáticos" y "Pagos y depósitos"
- **Sección de testimonios** con social proof (3 clientes con estrellas)
- **Sección FAQ** con `<details>` nativo (Google indexa FAQs como rich results)
- **Footer expandido** con 2 columnas de navegación (7 links internos)
- **IDs en secciones** (`#funciones`, `#como-funciona`, `#testimonios`, `#preguntas`)
- HTML semántico: `<article>`, `<blockquote>`, `<nav>`, `<section>`

### 4. robots.txt

**Archivo:** `src/app/robots.ts`

```
User-agent: *
Allow: /
Disallow: /dashboard/
Disallow: /api/
Sitemap: https://agendity.co/sitemap.xml
```

### 5. sitemap.xml (dinámico)

**Archivo:** `src/app/sitemap.ts`

- Páginas estáticas: `/`, `/explore`, `/login`, `/register`
- Páginas dinámicas: consulta la API para obtener los slugs de cada negocio (`/barberia-elite`, `/studio-bella`, etc.)
- Revalidación cada hora
- Prioridades: landing (1.0) > explore (0.8) > negocios (0.7) > register (0.5) > login (0.3)

### 6. Suspense boundary (Agenda)

**Archivo:** `src/app/dashboard/agenda/page.tsx`

- `useSearchParams()` envuelto en `<Suspense>` para evitar error de prerendering en Next.js 16

### 7. Redirect para usuarios autenticados

**Archivo:** `src/middleware.ts`

- Si un usuario con sesión activa visita `/login` o `/register`, se redirige a `/dashboard/agenda`

---

## Pendientes

- [ ] Reemplazar `favicon.ico` y `apple-touch-icon.png` con el logo real de Agendity
- [ ] Crear imagen OG (`/public/og-image.png`, 1200x630px) para compartir en redes sociales
- [ ] Agregar links externos (Instagram, redes sociales) cuando existan
- [ ] Registrar sitemap en Google Search Console
- [ ] Configurar Google Analytics o similar

---

## Keywords objetivo

| Keyword | Volumen estimado | Dificultad |
|---|---|---|
| agenda de citas barbería | Alto (local) | Baja |
| reservas online salón de belleza | Alto (local) | Media |
| software barbería Colombia | Medio | Baja |
| sistema de citas online | Alto | Alta |
| app para salón de belleza | Medio | Media |
| gestión barbería | Bajo | Baja |

---

## Herramientas de validación

- [Seobility](https://www.seobility.net/en/seocheck/) — Audit general
- [Google Rich Results Test](https://search.google.com/test/rich-results) — Validar JSON-LD
- [Meta Tags Preview](https://metatags.io/) — Preview de Open Graph y Twitter Cards
- [Google Search Console](https://search.google.com/search-console) — Indexación y rendimiento
