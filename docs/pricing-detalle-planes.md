# Detalle de Funcionalidades por Plan — Agendify

> Generado: 2026-03-17
> Fuente: Análisis exhaustivo de `agendify-web` (110+ archivos TS/TSX) + `agendify-api` (120+ archivos Ruby) + documentación interna

---

## Resumen de planes

| | **Trial** | **Básico** | **Profesional** | **Inteligente** |
|---|---|---|---|---|
| **Precio/mes** | Gratis (30 días) | $30.000 COP | $59.900 COP | $99.900 COP |
| **Empleados** | 10 (nivel Pro) | 3 | 10 | Ilimitado |
| **Servicios** | Ilimitado (nivel Pro) | 5 | Ilimitado | Ilimitado |
| **Acceso durante trial** | Plan Profesional | — | — | — |
| Agenda y calendario | Si | Si | Si | Si |
| Reservas online | Si | Si | Si | Si |
| Página pública del negocio | Si | Si | Si | Si |
| QR de reservas | Si | Si | Si | Si |
| Gestión de clientes | Si | Si | Si | Si |
| Gestión de pagos/comprobantes | Si | Si | Si | Si |
| Check-in con código de ticket | Si | Si | Si | Si |
| Bloqueo de slots | Si | Si | Si | Si |
| Notificaciones in-app | Si | Si | Si | Si |
| Notificaciones email | Si | Si | Si | Si |
| Reportes básicos | Si | Si | Si | Si |
| **Reseñas (dashboard)** | Si | **No** | **Si** | **Si** |
| **Reportes avanzados** | Si | **No** | **Si** | **Si** |
| **Personalización de marca** | Si | **No** | **Si** | **Si** |
| **Ticket digital VIP** | Si | **No** | **Si** | **Si** |
| **Negocio destacado en mapa** | Si | **No** | **Si** | **Si** |
| **Análisis inteligente (IA)** | No | **No** | **No** | **Si** |
| **Predicción de ingresos (IA)** | No | **No** | **No** | **Si** |
| **Alertas clientes inactivos (IA)** | No | **No** | **No** | **Si** |
| **Soporte** | Email | Email | Email + WhatsApp | Email + WhatsApp + Chat en vivo |

---

## 1. Funcionalidades compartidas (todos los planes)

Estas funcionalidades están disponibles en todos los planes, incluido el trial y el plan Básico.

### 1.1 Funcionalidades visuales (UI)

#### Landing page pública
- **Descripción:** Página de marketing de Agendify con hero, features, "Cómo funciona", CTA de registro y footer.
- **Detalles:** Hero con tagline "Tu negocio, siempre lleno", 4 cards de features, sección de social proof, pasos 1-2-3, CTA de prueba gratis, footer con links.

#### Registro e inicio de sesión
- **Descripción:** Páginas de autenticación para que el cliente (negocio) cree su cuenta o inicie sesión.
- **Detalles:** Registro con nombre del negocio, correo, contraseña, tipo de negocio. Login con sesión persistente.

#### Onboarding wizard (6 pasos)
- **Descripción:** Wizard post-registro para configurar el negocio antes de empezar a recibir citas.
- **Pasos:**
  1. Perfil del negocio (nombre, dirección, teléfono, descripción, redes sociales)
  2. Horarios de operación (apertura/cierre por día)
  3. Servicios (crear al menos uno con nombre, precio, duración)
  4. Empleados (agregar al menos uno, asignar servicios y horario)
  5. Métodos de pago (Nequi, Daviplata, Bancolombia)
  6. Política de cancelación (porcentaje de penalización, plazo límite)
- **Nota:** Se puede saltar pasos y completar después desde Settings.

#### Dashboard layout (sidebar + topbar + mobile nav)
- **Descripción:** Layout principal del dashboard con navegación lateral en desktop y barra inferior en móvil.
- **Detalles:**
  - Sidebar con 10 items de navegación: Agenda, Servicios, Empleados, Clientes, Pagos, Check-in, Reportes, Reseñas, Código QR, Configuración.
  - Badge del plan actual en topbar (colores por plan).
  - Lock icon en sidebar para features restringidas por plan.
  - Campanita de notificaciones con badge de conteo.

#### Agenda / Calendario
- **Descripción:** Calendario principal del negocio. Vista diaria y semanal con eventos de citas y bloques.
- **Sub-funcionalidades:**
  - Navegación por fecha (anterior/siguiente/hoy)
  - Switch vista Día/Semana
  - Filtro por empleado
  - Crear cita manual (modal con selección de servicio, empleado, cliente, fecha/hora)
  - Ver detalle de cita (modal con info completa + acciones de estado)
  - Drag-and-drop para mover citas (reprogramar)
  - Click en slot vacío para crear cita
  - Bloquear horarios (modal)
  - FAB (floating action button) en móvil para nueva cita
  - Indicador "Se actualiza automáticamente" con dot verde animado
  - Colores por estado de cita (pendiente, confirmada, en atención, cancelada, completada)

#### Gestión de servicios (CRUD)
- **Descripción:** Página para crear, editar y eliminar servicios del negocio.
- **Detalles:** Grid de cards con nombre, descripción, precio (COP), duración (min), badge activo/inactivo. Modal para crear/editar con formulario. Botón eliminar.

#### Gestión de empleados (CRUD)
- **Descripción:** Página para crear, editar y eliminar empleados, asignarles servicios y horarios.
- **Detalles:** Grid de cards con avatar, nombre, teléfono, badge activo/inactivo. Modal con formulario que incluye asignación de servicios y horario semanal del empleado.

#### Gestión de clientes
- **Descripción:** Base de datos automática de clientes (se crean al recibir reservas).
- **Sub-funcionalidades:**
  - Tabla paginada (nombre, correo, teléfono, visitas, última visita)
  - Búsqueda por nombre, correo o teléfono (con debounce)
  - Modal de detalle del cliente con historial de citas
  - Paginación con conteo total

#### Gestión de pagos y comprobantes
- **Descripción:** Página dedicada para revisar, aprobar y rechazar comprobantes de pago enviados por usuarios finales.
- **Sub-funcionalidades:**
  - 4 tabs: Pendientes, Sin comprobante, Aprobados, Rechazados
  - Cards con info del cliente, servicio, precio, fecha/hora, método de pago
  - Ver comprobante (thumbnail + modal viewer de imagen completa)
  - Botones Aprobar/Rechazar
  - Badge de conteo de pendientes

#### Check-in con ticket
- **Descripción:** Página para que el negocio verifique el código del ticket y registre la llegada del cliente.
- **Detalles:** Input para código de ticket (ingreso manual o escaneo QR). Muestra confirmación verde con datos de la cita (cliente, servicio, empleado, fecha, hora).

#### Bloqueo de horarios
- **Descripción:** Permite al negocio bloquear slots específicos en el calendario (vacaciones, descansos, etc.).
- **Detalles:** Modal con selección de empleado, fecha, hora inicio/fin, motivo opcional.

#### Código QR de reservas
- **Descripción:** Generador de QR que apunta a la página pública del negocio.
- **Sub-funcionalidades:**
  - QR visible con opción de descarga
  - URL pública del negocio con botón copiar
  - Botón descargar como PNG
  - Instrucciones de uso (3 pasos)
  - Phone mockup preview (así lo ven tus clientes)

#### Configuración del negocio
- **Descripción:** Página con múltiples secciones de configuración.
- **Secciones:**
  1. **Logo** — Upload de imagen (max 5MB, JPG/PNG/WebP)
  2. **Perfil del negocio** — Nombre, descripción, teléfono, dirección, ciudad, departamento, país, redes sociales (Instagram, Facebook, sitio web), link Google Maps
  3. **Ubicación en mapa** — Mapa interactivo para ubicar el negocio, botón "Cómo llegar"
  4. **Horarios** — Configuración de apertura/cierre por día de la semana, toggle cerrado
  5. **Métodos de pago** — Nequi, Daviplata, Bancolombia
  6. **Política de cancelación** — Porcentaje (0%, 30%, 50%, 100%), plazo mínimo (1-72 horas)
  7. **Notificaciones** — Permisos de navegador, toggle de sonido
  8. **Personalización de marca** (solo Pro+, ver sección 3)

#### Notificaciones in-app
- **Descripción:** Sistema completo de notificaciones internas para el negocio.
- **Sub-funcionalidades:**
  - Campanita en topbar con badge de no leídas
  - Página de listado paginado con tipos: nueva reserva, pago enviado, pago aprobado, cita cancelada, recordatorio
  - Marcar como leída (individual y masiva)
  - Iconos y colores por tipo de notificación
  - Tiempo relativo ("Hace 5 min", "Hace 2h")
  - Click navega al recurso relacionado

#### Reportes básicos
- **Descripción:** Dashboard de métricas y gráficos del negocio (disponible para todos los planes).
- **Sub-funcionalidades:**
  - 4 tarjetas resumen: Ingresos totales, Citas totales, Clientes totales, Calificación promedio
  - Gráfico de ingresos por período (Semana/Mes/Año)
  - Top servicios más populares (gráfico)
  - Top empleados con más citas (gráfico)
  - Clientes frecuentes (tabla con visitas y total gastado)
- **Nota:** Para plan Básico se muestra banner de upgrade, pero actualmente todos los planes ven los mismos datos de reportes. Falta definir la distinción "básicos vs avanzados".

### 1.2 Funcionalidades públicas (usuario final — sin cuenta)

#### Página pública del negocio
- **Descripción:** Perfil público del negocio accesible en `agendify.com/[slug]`. Cualquier persona puede verlo.
- **Contenido:**
  - Cover/header con logo, nombre, tipo de negocio, calificación promedio
  - Botón "Reservar cita" (CTA principal)
  - Sección "Sobre nosotros" (descripción)
  - Mapa de ubicación + dirección + botón "Cómo llegar" (Google Maps)
  - Información de contacto (teléfono, Instagram, Facebook, sitio web)
  - Lista de servicios activos (nombre, descripción, precio, duración)
  - Horarios de operación
  - Últimas 5 reseñas con estrellas
  - CTA para que otros negocios se registren

#### Flujo de reserva pública (5 pasos)
- **Descripción:** Proceso multi-paso para que un usuario final reserve una cita sin necesidad de crear cuenta.
- **Pasos:**
  1. Seleccionar servicio (por categoría, 1 servicio por categoría, soporte multi-categoría)
  2. Seleccionar profesional (empleado)
  3. Seleccionar fecha y hora disponible
  4. Ingresar datos del cliente (nombre, email, teléfono)
  5. Confirmación con instrucciones de pago post-booking
- **Protecciones:**
  - Bloqueo temporal de slot (5 min) mientras completa el formulario
  - Protección contra reservas duplicadas (concurrencia)
  - Rate limiting en endpoints públicos
- **Persistencia de datos del cliente:** Los datos del usuario final se guardan en localStorage y se recuperan automáticamente por lookup de email, evitando re-ingreso en futuras reservas.

#### Sistema de cancelaciones diferenciado
- **Descripción:** Cancelación de citas con diferenciación entre cancelación por parte del negocio y cancelación por parte del cliente (usuario final), con penalización configurable.
- **Detalles:** El negocio configura porcentaje de penalización (0%-100%) y plazo mínimo para cancelar sin penalización (1-72 horas antes de la cita).

#### Descarga de ticket como imagen PNG
- **Descripción:** El usuario final puede descargar su ticket de confirmación como imagen PNG directamente desde la página del ticket.

#### Instrucciones de pago post-booking
- **Descripción:** Después de completar la reserva, se muestran las instrucciones de pago del negocio (Nequi, Daviplata, Bancolombia) para que el usuario final pueda pagar directamente.

#### Botón de ayuda con canales por plan
- **Descripción:** Botón de ayuda en el topbar del dashboard que muestra los canales de soporte disponibles según el plan del negocio. Los canales no disponibles aparecen con lock icon indicando en qué plan se desbloquean.

#### Ticket digital VIP
- **Descripción:** Página pública que muestra el ticket de confirmación de cita, estilo boarding pass.
- **Diseño:** Tarjeta estilo boarding pass con:
  - Header "AGENDIFY" en violeta
  - Nombre del negocio
  - Badge de estado de la cita
  - Datos: cliente, servicio, profesional, fecha, hora, dirección
  - Línea perforada divisoria
  - QR Code para check-in
  - Código de ticket monospace
  - Botón "Guardar"

#### Explorar negocios
- **Descripción:** Directorio público de negocios registrados en Agendify con búsqueda, filtros y mapa.
- **Sub-funcionalidades:**
  - Búsqueda por nombre y ciudad
  - Filtros por tipo (Todas, Barberías, Salones, Spa, Uñas)
  - Toggle vista Lista/Mapa
  - Vista lista: grid de tarjetas con logo, nombre, tipo, calificación, dirección
  - Vista mapa: lista lateral + mapa interactivo con marcadores
  - Paginación
  - CTA para registrar negocio

### 1.3 Funcionalidades funcionales (lógica de backend)

#### Autenticación segura
- **Descripción:** Sistema de autenticación con sesión persistente y cierre de sesión seguro.

#### Multi-tenancy
- **Descripción:** Cada negocio solo accede a sus propios datos. Aislamiento completo entre negocios.

#### Máquina de estados de citas
- **Descripción:** Las citas pasan por estados definidos con transiciones controladas.
- **Estados:** Pendiente de pago → Pago enviado → Confirmada → Check-in → Completada | Cancelada

#### Sistema de pagos P2P
- **Descripción:** Flujo de pago directo entre usuario final y negocio (sin pasarela).
- **Flujo:** Reserva → Instrucciones de pago → Cliente paga directamente → Sube comprobante → Negocio aprueba/rechaza → Cita confirmada

#### Notificaciones automáticas
- **Descripción:** Notificaciones automáticas por email y en la app para eventos clave.
- **Eventos:**
  - Nueva reserva (al negocio)
  - Confirmación de pago (al cliente)
  - Cancelación de cita
  - Recordatorio de cita (24h antes)

#### Geolocalización
- **Descripción:** Geocodificación automática de negocios + mapa interactivo con ubicación y botón "Cómo llegar".

#### Disponibilidad inteligente de slots
- **Descripción:** Sistema de disponibilidad que considera horarios del negocio, horarios de empleados, citas existentes y slots bloqueados. Protección contra reservas duplicadas.

#### Tiempo real
- **Descripción:** Actualizaciones en tiempo real en el dashboard: nuevas reservas, pagos, cancelaciones y confirmaciones se reflejan instantáneamente sin recargar la página.

### 1.4 Funcionalidades técnicas (infraestructura)

#### PWA (Progressive Web App)
- **Descripción:** Instalable desde el navegador en Android/iOS. Funciona como app nativa desde la pantalla de inicio.

#### Panel de superusuario
- **Descripción:** Panel de administración interno para el equipo de Agendify.
- **Funciones:** Dashboard global, gestión de negocios, usuarios, planes, suscripciones, citas, reseñas, clientes.

#### Protección contra abuso
- **Descripción:** Rate limiting en endpoints públicos para prevenir abuso.

#### Upload de archivos
- **Descripción:** Subida de logos de negocio y comprobantes de pago (max 5MB).

---

## 2. Plan Básico ($30.000 COP/mes)

### 2.1 Incluido

Todo lo listado en la sección 1 (funcionalidades compartidas), con las siguientes limitaciones:

| Recurso | Límite |
|---|---|
| Empleados | Máximo 3 |
| Servicios | Máximo 5 |

### 2.2 Restringido (NO incluido)

Las siguientes funcionalidades están bloqueadas para el plan Básico:

#### Reseñas (dashboard)
- **Restricción activa:** Si. Lock icon en sidebar + banner de upgrade en la página.
- **Nota:** La restricción es solo visual (frontend). El backend no bloquea el acceso aún.

#### Reportes avanzados
- **Restricción activa:** Parcial. Se muestra banner de upgrade pero los datos SI se muestran.
- **Pendiente:** Definir qué es "reportes avanzados" vs "reportes básicos" y bloquear el contenido real para plan Básico.

#### Personalización de marca (colores del negocio)
- **Restricción activa:** Si. Frontend y backend.
- **Detalles:** Si el plan no lo permite, se muestra banner de upgrade en lugar de la sección de colores. El backend también valida y rechaza cambios de color.

#### Ticket digital VIP
- **Restricción activa:** Si. Frontend y backend.
- **Detalles:** El `ticket_code` se genera SIEMPRE al crear la cita (para identificación en pagos, check-in, etc.). Lo que se restringe por plan es la **visualización VIP** del ticket: el diseño premium estilo boarding pass con QR, la descarga como PNG y la opción de compartir. Para plan Básico, el usuario ve una versión simplificada del ticket sin el diseño VIP.

#### Negocio destacado en mapa
- **Restricción activa:** Si. Frontend y backend.
- **Detalles:** Los negocios Pro+ aparecen con badge "Destacado" y con ordenamiento preferente en el directorio.

### 2.3 Soporte
- Solo email.
- El botón de ayuda muestra email como único canal. WhatsApp y Chat aparecen bloqueados indicando en qué plan se desbloquean.

---

## 3. Plan Profesional ($59.900 COP/mes)

### 3.1 Todo lo del plan Básico, más:

| Recurso | Límite |
|---|---|
| Empleados | Máximo 10 |
| Servicios | Ilimitado |

### 3.2 Funcionalidades exclusivas desbloqueadas

#### Reseñas (dashboard)
- **Descripción:** Acceso completo a la página de reseñas con listado paginado, calificación promedio, estrellas.
- **Detalles:** Lista de reseñas con avatar, nombre del cliente, estrellas (1-5), comentario, fecha. Calificación promedio en el header. Paginación.

#### Reportes avanzados
- **Descripción:** Acceso completo a todos los reportes sin banner de restricción.
- **Nota:** Actualmente todos los planes ven los mismos datos. La distinción "básicos vs avanzados" no está implementada a nivel de contenido.

#### Personalización de marca (colores)
- **Descripción:** Sección de personalización en Settings para elegir color primario y secundario del negocio.
- **Detalles:** Color picker para primario y secundario. Vista previa con círculos de color.
- **Restricción:** Bloqueado para plan Básico (frontend y backend).

#### Ticket digital VIP
- **Descripción:** Los clientes del negocio reciben un ticket digital premium estilo boarding pass con QR, descargable como imagen PNG y compartible.
- **Restricción:** Solo disponible para Pro+. Bloqueado en frontend y backend.
- **Vistas por estado:** Pendiente de pago (instrucciones), Pago en revisión, Confirmada (ticket VIP con QR), Check-in completado, Cancelada.

#### Negocio destacado en mapa
- **Descripción:** El negocio aparece destacado en el directorio/explorador de Agendify con badge "Destacado" y ordenamiento preferente.
- **Restricción:** Solo Pro+. Negocios Pro+ aparecen primero en resultados.

### 3.3 Soporte
- Email + WhatsApp.
- Chat en vivo aparece bloqueado con "Disponible en Plan Inteligente".

---

## 4. Plan Inteligente ($99.900 COP/mes)

### 4.1 Todo lo del plan Profesional, más:

| Recurso | Límite |
|---|---|
| Empleados | Ilimitado |
| Servicios | Ilimitado |

### 4.2 Funcionalidades exclusivas desbloqueadas

#### Análisis inteligente con IA
- **Estado:** No implementado. Reservado para plan Inteligente. Badge visual en sidebar pero sin funcionalidad aún.

#### Predicción de ingresos (IA)
- **Estado:** No implementado.

#### Recomendaciones de precios (IA)
- **Estado:** No implementado.

#### Alertas de clientes inactivos (IA)
- **Estado:** No implementado.

### 4.3 Soporte
- Email + WhatsApp + Chat en vivo (soporte prioritario).
- Los 3 canales están habilitados. El chat en vivo abre WhatsApp con mensaje prefijado de soporte prioritario.

---

## 5. Candidatas a restricción futura

Funcionalidades actualmente compartidas que PODRÍAN moverse a un plan superior para aumentar el valor percibido de los planes pagos.

### 5.1 Alta prioridad (alto valor, fáciles de restringir)

| Funcionalidad | Plan actual | Plan sugerido | Justificación |
|---|---|---|---|
| **Notificaciones WhatsApp** | No implementado | Profesional+ | Alto valor percibido. Las notificaciones por WhatsApp son el canal #1 en Colombia. |
| **Recordatorios automáticos** | Todos | Profesional+ | Los recordatorios reducen no-shows. Es una feature premium en competidores. |
| **Página pública personalizada** | Todos | Profesional+ | Logo y colores propios en la página pública (no solo en settings). |
| **Exportar datos (CSV/PDF)** | No implementado | Profesional+ | Reportes descargables como feature premium. |

### 5.2 Media prioridad (valor medio, requieren más trabajo)

| Funcionalidad | Plan actual | Plan sugerido | Justificación |
|---|---|---|---|
| **Número de clientes en BD** | Ilimitado | Básico: 100, Pro: Ilimitado | Limitar clientes fuerza al negocio a crecer de plan. |
| **Historial de citas del cliente** | Todos | Básico: últimas 10, Pro: Ilimitado | Limitar historial incentiva upgrade. |
| **Múltiples usuarios/empleados con acceso** | No implementado | Profesional+ | Actualmente solo el owner tiene acceso al dashboard. |
| **Integración Google Calendar** | No implementado | Profesional+ | Sincronización con calendario personal. |

### 5.3 Baja prioridad (mejor dejarlo compartido)

| Funcionalidad | Razón para NO restringir |
|---|---|
| Agenda y calendario | Feature core, todos deben tenerla para que el producto funcione |
| Reservas online | Feature core del valor del producto |
| Gestión de clientes (básica) | Se crea automáticamente, quitarla rompe la experiencia |
| QR de reservas | Bajo costo, alto impacto en adopción |
| Check-in | Complemento del ticket, no tiene sentido solo |
| Bloqueo de slots | Feature operativa básica |

---

## 6. Funcionalidades pendientes por plan

Features mencionadas en la documentación o tabla de planes que NO están implementadas aún.

### 6.1 Plan Básico — Pendientes

| Funcionalidad | Mencionada en | Estado |
|---|---|---|
| Límite de 3 empleados | `sistema-planes.md` | **Implementado** ✅ |
| Límite de 5 servicios | `sistema-planes.md` | **Implementado** ✅ |
| Políticas de cancelación "Básica" vs "Configurable" | `desarrollo.md` | **No diferenciado**. Todos los planes tienen la misma UI de configuración. |

### 6.2 Plan Profesional — Pendientes

| Funcionalidad | Mencionada en | Estado |
|---|---|---|
| Ticket digital VIP (restricción) | `sistema-planes.md` | **Implementado** ✅ |
| Negocio destacado en mapa | `sistema-planes.md` | **Implementado** ✅ |
| Reportes avanzados (diferenciación real) | `sistema-planes.md` | **No diferenciado**. Todos ven los mismos reportes. Falta definir qué es "avanzado". |
| Notificaciones WhatsApp | `desarrollo.md` | **No implementado**. Está en roadmap pre-lanzamiento. WhatsApp Business API no integrada. |

### 6.3 Plan Inteligente — Pendientes

| Funcionalidad | Mencionada en | Estado |
|---|---|---|
| Análisis inteligente (IA) | `sistema-planes.md`, `desarrollo.md`, `idea-de-negocio.md` | **No implementado**. Solo existe el badge visual en sidebar. |
| Predicción de ingresos (IA) | `sistema-planes.md` | **No implementado**. |
| Recomendaciones de precios (IA) | `desarrollo.md` | **No implementado**. |
| Alertas de clientes inactivos (IA) | `sistema-planes.md` | **No implementado**. |

### 6.4 Generales — Pendientes

| Funcionalidad | Mencionada en | Estado |
|---|---|---|
| Notificaciones WhatsApp (Business API) | `desarrollo.md` | No implementado. Pendiente pre-lanzamiento. |
| Push notifications | `desarrollo.md` | No implementado. Post-lanzamiento (Capacitor). |
| Pasarela de pago (Stripe/MercadoPago) | `desarrollo.md` | No implementado. Post-lanzamiento. |
| App móvil nativa (Capacitor) | `desarrollo.md` | No implementado. Post-lanzamiento. |
| Multi-idioma (i18n) | `desarrollo.md` | No implementado. Post-lanzamiento. |
| Tests E2E (Playwright) | `desarrollo.md` | No implementado. Pendiente pre-lanzamiento. |
| Deploy (Docker Compose + VPS) | `desarrollo.md` | **Implementado** ✅ |
| CI/CD (GitHub Actions) | `desarrollo.md` | No implementado. Pendiente pre-lanzamiento (nice to have). |

