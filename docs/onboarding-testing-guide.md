# Agendity — Guia Completa de Funcionamiento

Esta guia presenta TODAS las funcionalidades de Agendity siguiendo el flujo natural de uso de la plataforma. Sirve como referencia para demostraciones, onboarding de equipo, e inversores.

---

## Que es Agendity

Agendity es una plataforma SaaS de gestion de citas para barberias y salones de belleza. Permite a los negocios recibir reservas online, gestionar pagos, empleados, clientes y reportes desde un solo lugar. Los usuarios finales (clientes del negocio) reservan sin necesidad de crear cuenta.

**Actores principales:**
- **Cliente** = el negocio (barberia/salon) que paga suscripcion
- **Usuario final** = la persona que reserva citas (no paga, no necesita cuenta)
- **Empleado** = staff del negocio con portal propio
- **SuperAdmin** = equipo Agendity que gestiona la plataforma

---

## PARTE 1 — El negocio se registra y configura

### 1.1 Registro

El dueno del negocio entra a la landing page y se registra con su nombre, email, telefono, contrasena y tipo de negocio (barberia o salon). Al registrarse se crea automaticamente:
- Una cuenta de usuario (role: owner)
- Un negocio con slug unico (ej: `barberia-elite`)
- Una suscripcion trial de 30 dias

### 1.2 Onboarding (configuracion inicial)

Despues de registrarse, el sistema guia al dueno por 6 pasos:

1. **Perfil del negocio** — nombre, descripcion, telefono, direccion con mapa interactivo
2. **Horarios** — dias y horas de apertura/cierre para cada dia de la semana, opcion de almuerzo
3. **Servicios** — al menos 1 servicio con nombre, precio y duracion (ej: "Corte clasico - $25.000 - 30min")
4. **Empleados** — al menos 1 empleado con nombre, telefono, servicios que ofrece y horario individual
5. **Metodos de pago** — numeros de Nequi, Daviplata y/o Bancolombia donde recibir pagos
6. **Politica de cancelacion** — porcentaje de penalizacion (0-100%) y horas limite para cancelar

Al completar el onboarding, se desbloquea el dashboard completo.

### 1.3 Configuracion avanzada (Settings)

Desde `/dashboard/settings` el negocio puede en cualquier momento:

- **Logo y portada** — subir imagen propia o seleccionar del banco de imagenes (Pexels)
- **Ubicacion** — seleccionar en mapa interactivo con geocodificacion, link de Google Maps
- **Redes sociales** — Instagram, Facebook, sitio web
- **Datos legales** — NIT, representante legal, tipo y numero de documento
- **Configuracion de agenda** — intervalo de slots (15/30/60 min), gap entre citas
- **Notificaciones** — activar/desactivar sonido y notificaciones del navegador
- **Colores de marca** (Plan Profesional+) — color primario y secundario personalizados

---

## PARTE 2 — El negocio opera dia a dia

### 2.1 La agenda (calendario)

La pantalla principal del dashboard es la agenda. Muestra todas las citas en un calendario visual (FullCalendar) con vista de dia o semana.

**Colores por estado:**
- Naranja = pendiente de pago
- Azul = comprobante enviado
- Verde = confirmada
- Morado = en atencion (checked-in)
- Gris = completada
- Rojo = cancelada

**Acciones:**
- Filtrar por empleado
- Navegar entre dias/semanas
- Click en una cita para ver detalle completo
- Arrastrar una cita a otro horario para reprogramar
- Se actualiza en tiempo real (NATS WebSocket) — cuando llega una nueva reserva, aparece automaticamente

### 2.2 Crear cita manual

El negocio puede crear citas directamente desde la agenda:

1. Click "+ Nueva cita"
2. Seleccionar servicio(s)
3. Seleccionar empleado
4. Seleccionar fecha — el sistema muestra automaticamente los horarios disponibles
5. Buscar cliente existente (por nombre/telefono) o registrar uno nuevo
6. Confirmar — se crea la cita con codigo de ticket unico

### 2.3 Bloquear horarios

El negocio puede bloquear horarios para un empleado (vacaciones, capacitacion, etc). Los horarios bloqueados no aparecen como disponibles en las reservas publicas.

### 2.4 Gestion de servicios

CRUD completo de servicios con nombre, descripcion, precio (COP), duracion (minutos) y estado activo/inactivo. Solo los servicios activos aparecen en la pagina publica de reservas.

### 2.5 Gestion de empleados

CRUD completo de empleados con:
- Nombre, telefono, email, foto de perfil
- Servicios que ofrece (relacion many-to-many)
- Horario individual por dia de la semana
- Porcentaje de comision (para cierre de caja)
- Opcion de invitar al portal de empleado (ver Parte 5)

### 2.6 Gestion de clientes

Lista de todos los clientes que han reservado al menos una vez. Incluye busqueda por nombre/telefono, historial de citas, total gastado y balance de creditos. Los clientes se crean automaticamente cuando reservan — no necesitan cuenta.

---

## PARTE 3 — Un usuario final reserva una cita

### 3.1 Pagina publica del negocio

Cada negocio tiene una pagina publica en `agendity.co/{slug}`. Muestra:
- Portada y logo
- Descripcion, tipo de negocio, calificacion promedio
- Lista de servicios con precio y duracion
- Horarios de apertura
- Ubicacion con mapa embebido y boton "Como llegar"
- Resenas de clientes
- Redes sociales
- Boton "Reservar cita"

### 3.2 Flujo de reserva (5 pasos)

1. **Seleccionar servicio** — cards con nombre, precio y duracion. Puede seleccionar multiples servicios
2. **Seleccionar empleado** — foto, nombre, y opcion "cualquier disponible"
3. **Seleccionar fecha y hora** — calendario con dias disponibles, grid de horarios libres. Los dias cerrados y horarios bloqueados estan deshabilitados. Si hay tarifa dinamica activa, se muestra el precio ajustado
4. **Datos del cliente** — nombre, telefono, email. Si es cliente recurrente (mismo email/telefono), se detecta automaticamente y se muestra su balance de creditos disponibles. Puede aplicar creditos al pago
5. **Confirmacion** — resumen completo: servicio(s), empleado, fecha/hora, precio (con tarifa dinamica si aplica), creditos aplicados, instrucciones de pago (a que numero de Nequi/Daviplata/Bancolombia enviar)

Al confirmar:
- Se crea la cita con estado `pending_payment`
- Se genera un codigo de ticket unico (ej: `FE89E62168B5`)
- Se bloquea el slot para evitar doble reserva
- Se envia notificacion al negocio (in-app + browser notification + sonido)
- Se redirige al usuario a su ticket

### 3.3 Ticket del usuario

El usuario recibe un link a su ticket: `agendity.co/{slug}/ticket/{code}`. Desde aqui puede:

- **Ver detalle** — fecha, hora, servicio, empleado, precio, instrucciones de pago
- **Subir comprobante de pago** — foto del recibo de Nequi/Daviplata/Bancolombia
- **Descargar ticket** — como imagen PNG con QR code
- **Cancelar cita** — muestra preview de la penalizacion antes de confirmar (ej: "Se te cobrara 50% del precio como penalizacion. El resto se abona como credito")
- **QR code** — para presentar al llegar al local y hacer check-in

### 3.4 Explorar negocios

En `agendity.co/explore`, los usuarios pueden buscar negocios por nombre, filtrar por ciudad y tipo. Los negocios con Plan Profesional+ aparecen destacados. Los negocios con Plan Inteligente tienen badge de verificado.

---

## PARTE 4 — El negocio gestiona pagos y check-in

### 4.1 Pagos

Cuando un usuario sube comprobante de pago, aparece en `/dashboard/payments` en la tab "Pendientes". El negocio puede:

- **Ver comprobante** — imagen del recibo
- **Aprobar** — la cita pasa a "Confirmada", se notifica al usuario
- **Rechazar** — con razon (ej: "Monto incorrecto"), se notifica al usuario
- **Recordar pago** — envia email/WhatsApp al usuario pidiendo que pague

Los pagos se organizan en tabs: Pendientes, Sin comprobante, Aprobados, Rechazados.

Si el usuario aplico creditos, se muestra el precio original tachado y el nuevo precio.

### 4.2 Check-in

Cuando el usuario llega al local, presenta su ticket (QR en el celular o impreso). El negocio escanea el QR desde `/dashboard/checkin` usando la camara del dispositivo, o ingresa el codigo manualmente.

**Reglas:**
- Solo funciona 30 minutos antes de la hora de la cita
- Solo citas con estado "Confirmada" pueden hacer check-in
- Si un empleado diferente al asignado hace el check-in, se pide confirmacion y razon (cambio de turno, empleado ausente, etc.)
- La cita pasa a estado "En atencion" (`checked_in`)

### 4.3 Completar citas automaticamente

Un job automatico (`CompleteAppointmentsJob`) corre cada 15 minutos y marca como "Completada" las citas que:
- Estan en estado `checked_in`
- Ya paso la hora de fin del servicio

Al completarse:
- Si el plan tiene cashback, se otorgan creditos al cliente automaticamente
- Se envia email/WhatsApp al usuario pidiendo que califique su experiencia

---

## PARTE 5 — Portal del empleado

### 5.1 Invitacion

El negocio puede invitar empleados a tener su propia cuenta:
1. Desde `/dashboard/employees`, click "Invitar" junto al empleado
2. Se genera un link por email
3. El empleado abre el link, crea su contrasena y accede al portal

### 5.2 Dashboard del empleado

El empleado ve su rendimiento personal:
- **Score** (0-100) — basado en calificaciones de clientes (60%) y puntualidad en check-ins (40%)
- **Calificacion promedio** de reseñas
- **Citas de hoy** y del mes
- **Ingresos generados**

### 5.3 Check-in desde empleado

El empleado puede hacer check-in de sus propios clientes escaneando QR. Si intenta hacer check-in de una cita que no le corresponde, el sistema pide confirmacion de sustitucion con razon.

---

## PARTE 6 — Finanzas y reportes

### 6.1 Cierre de caja (Plan Profesional+)

Al final del dia, el negocio cierra caja desde `/dashboard/cash-register`:

1. Ver resumen del dia: ingresos totales, citas completadas
2. Desglose por empleado: citas atendidas, monto ganado, comision calculada
3. Para cada empleado: confirmar pago (efectivo o transferencia con comprobante)
4. Si se paga menos que la comision, la diferencia se acumula como deuda para el proximo cierre
5. Agregar notas opcionales
6. "Cerrar caja del dia"

El historial de cierres esta en `/dashboard/cash-register/history` con filtros por fecha.

### 6.2 Creditos y cashback

El sistema de creditos funciona como un monedero virtual por cliente:

**Como se generan creditos:**
- **Cashback** — al completar una cita, se otorga un % del precio como credito (configurado por SuperAdmin en el plan)
- **Reembolso por cancelacion** — si el usuario cancela dentro del plazo, el monto menos la penalizacion se devuelve como credito
- **Ajuste manual** — el negocio puede agregar o quitar creditos a cualquier cliente
- **Credito masivo** — dar creditos a multiples clientes a la vez (ej: promocion de apertura)

**Como se usan:**
- En el paso 4 de la reserva, si el cliente tiene creditos, se muestra el balance y puede aplicarlos al pago

**Donde se gestionan:**
- `/dashboard/credits` — ver resumen, historial por cliente, hacer ajustes

### 6.3 Tarifas dinamicas (Plan Profesional+)

Permite ajustar precios automaticamente segun la fecha:

**Manual (Profesional+):**
- Crear reglas con nombre, rango de fechas, % o COP de ajuste, modo (fijo o progresivo), dias de la semana
- Ejemplo: "Fin de semana +15%" para viernes y sabados

**IA (Inteligente):**
- El sistema analiza datos historicos y detecta periodos de alta demanda
- Genera sugerencias automaticas (ej: "Diciembre tiene 40% mas demanda — sugerimos +20%")
- El negocio acepta o rechaza cada sugerencia

Las tarifas activas se aplican automaticamente en el flujo de reserva publica. El usuario ve el precio ajustado con indicador de tarifa dinamica.

### 6.4 Metas financieras (Plan Inteligente)

El negocio establece objetivos y ve progreso en tiempo real:
- **Meta mensual** — "Quiero facturar $5.000.000 este mes" → barra de progreso + cuanto falta
- **Punto de equilibrio** — ingresar costos fijos, ver cuanto falta para cubrir gastos
- **Promedio diario** — meta de ingresos por dia
- **Meta personalizada** — cualquier objetivo con nombre libre

### 6.5 Reconciliacion contable (Plan Inteligente)

Verifica la consistencia de los datos financieros:
- Balance de empleados: comisiones acumuladas vs pagos realizados
- Creditos de clientes: suma de transacciones vs balance actual
- Si hay discrepancias, se muestran en tabla roja para corregir

### 6.6 Reportes (Plan Profesional+)

- **Resumen** — citas totales, ingresos, calificacion promedio (todos los planes)
- **Ingresos por periodo** — grafica de barras semanal/mensual/anual
- **Top servicios** — ranking por ingresos y cantidad de citas
- **Top empleados** — ranking por ingresos y citas atendidas
- **Clientes frecuentes** — ranking por visitas y total gastado
- **Ganancia neta** — ingresos menos comisiones de empleados

### 6.7 Resenas

Las resenas las dejan los usuarios finales despues de completar su cita (via email de solicitud). El negocio las ve en `/dashboard/reviews` con calificacion de estrellas, comentario y nombre del cliente. Tambien aparecen en la pagina publica.

---

## PARTE 7 — Herramientas adicionales

### 7.1 Codigo QR

En `/dashboard/qr` el negocio obtiene su link publico y un QR descargable para imprimir y colocar en el local. Los clientes escanean el QR → van directo a la pagina de reservas.

### 7.2 Notificaciones en tiempo real

El sistema envia notificaciones por multiples canales:

**Al negocio:**
- Notificacion in-app (campana en el dashboard)
- Notificacion del navegador (push notification)
- Sonido de alerta

**Al usuario final:**
- Email (todos los planes)
- WhatsApp (Plan Profesional+) — via WhatsApp Business API de Meta

**Eventos que generan notificacion:**
| Evento | Al negocio | Al usuario |
|--------|:----------:|:----------:|
| Nueva reserva | Si | Si |
| Comprobante enviado | Si | — |
| Pago aprobado | — | Si |
| Pago rechazado | — | Si |
| Cita cancelada | Si | Si |
| Recordatorio de pago | — | Si |
| Solicitud de calificacion | — | Si |
| Suscripcion por vencer | Si | — |

Las notificaciones llegan en tiempo real via NATS WebSocket — no hay que refrescar la pagina.

### 7.3 Banner de suscripcion

Cuando la suscripcion esta por vencer, aparece un banner en la parte superior del dashboard:

| Estado | Color | Mensaje |
|--------|-------|---------|
| 5 a 1 dias antes | Amarillo | "Tu plan Profesional vence en X dias" |
| Dia que vence | Rojo | "Tu plan Profesional vence hoy. Renueva ahora" |
| Despues de vencer | Rojo oscuro | "Tu plan vencio hace X dias. Renueva para evitar suspension" |
| 2 dias despues | — | Negocio suspendido automaticamente |

### 7.4 Profesional independiente

Agendity tambien soporta profesionales independientes (sin local fisico). Se crean desde el SuperAdmin y funcionan igual que un negocio pero:
- No tienen seccion de empleados (ellos mismos son el unico empleado)
- No tienen direccion fisica ni mapa
- El sidebar muestra "Profesional" en vez del tipo de negocio
- Tiene campos de documento de identidad en vez de NIT/representante legal

---

## PARTE 8 — SuperAdmin (equipo Agendity)

### 8.1 Panel de administracion

En `/admin` (ActiveAdmin) el equipo gestiona toda la plataforma:
- Ver y editar negocios, usuarios, planes, suscripciones
- Ver citas, pagos, resenas de cualquier negocio
- Dashboard con graficas de nuevos negocios, citas por estado
- Request logs para debugging

### 8.2 Observar como un negocio (impersonacion)

El admin puede ver el dashboard exactamente como lo ve un negocio:
1. Click "Observar como..." en el topbar
2. Buscar negocio por nombre (muestra plan y badge "Independiente" si aplica)
3. Click → ahora ves el dashboard del negocio
4. Banner amarillo indica que estas observando
5. Click "Dejar de observar" para volver

### 8.3 Crear profesional independiente

Desde ActiveAdmin > "Profesionales Independientes":
1. Llenar datos: nombre, email, telefono, tipo de documento
2. Se crea automaticamente: usuario + negocio + empleado + suscripcion trial
3. Se genera link de acceso con credenciales temporales

### 8.4 Enviar notificaciones

Desde "Enviar Notificacion" el admin puede enviar notificaciones manuales a uno o todos los negocios. Tipos disponibles: nueva reserva, pago, cancelacion, recordatorio, sugerencia IA, suscripcion por vencer.

### 8.5 Gestion de jobs

Desde "Jobs" el admin puede:
- Ver todos los jobs programados con su estado y ultima ejecucion
- Habilitar/deshabilitar jobs individuales
- Ejecutar un job manualmente ("Run now")
- Ver logs de ejecucion de las ultimas 24 horas

### 8.6 Renovar suscripcion

Desde ActiveAdmin > Subscriptions > detalle de suscripcion > "Renovar":
- Extiende 30 dias
- Reactiva el negocio si estaba suspendido
- Envia notificacion de confirmacion al negocio (email + in-app + WhatsApp)

### 8.7 Sidekiq

En `/admin/sidekiq` se monitorean los jobs en background: colas, ejecucion, programados, fallidos. Protegido por autenticacion basica con credenciales de admin.

---

## PARTE 9 — Alertas automaticas

### 9.1 Suscripcion por vencer

Job diario (`SubscriptionExpiryAlertJob`) a las 8am:

| Momento | Accion |
|---------|--------|
| 5 dias antes | Email + notificacion + WhatsApp (si aplica) |
| Dia que vence | Email + notificacion + WhatsApp + banner rojo |
| 2 dias despues | Email + notificacion + WhatsApp + **negocio suspendido** |

Anti-duplicados: campo `expiry_alert_stage` en la suscripcion (0→1→2→3). Se resetea al renovar.

### 9.2 Completar citas

Job cada 15 min (`CompleteAppointmentsJob`): busca citas en estado `checked_in` cuya hora de fin ya paso y las marca como `completed`. Dispara cashback y solicitud de calificacion.

### 9.3 Sugerencias de tarifa dinamica (Plan Inteligente)

Job quincenal (`Intelligence::PricingSuggestionJob`): analiza datos historicos de citas, detecta periodos de alta demanda y crea sugerencias de tarifa dinamica con estado `suggested`.

---

## RESTRICCIONES POR PLAN

| Feature | Trial/Basico | Profesional | Inteligente |
|---------|:---:|:---:|:---:|
| Agenda, servicios, empleados, clientes, pagos, check-in, QR, notificaciones | Si | Si | Si |
| Creditos (ver y ajustar) | Si | Si | Si |
| Reportes basicos (resumen) | Si | Si | Si |
| Reportes avanzados (graficas) | — | Si | Si |
| Resenas | — | Si | Si |
| Tarifas dinamicas (manual) | — | Si | Si |
| Cierre de caja | — | Si | Si |
| Personalizacion de marca (logo, colores) | — | Si | Si |
| WhatsApp al usuario final | — | Si | Si |
| Cashback automatico | — | Si | Si |
| Sugerencias IA (tarifas) | — | — | Si |
| Metas financieras | — | — | Si |
| Reconciliacion contable | — | — | Si |

---

## CICLO COMPLETO DE UNA CITA

```
1. Usuario entra a agendity.co/barberia-elite
2. Selecciona servicio "Corte clasico" ($25.000, 30min)
3. Selecciona al barbero "Juan"
4. Elige fecha: mierc 24 marzo, 10:00am
5. Ingresa sus datos: Pedro Lopez, +573001112233
6. Confirma la reserva
   → Se crea cita (pending_payment)
   → Negocio recibe notificacion en tiempo real
7. Pedro envia $25.000 por Nequi y sube captura en su ticket
   → Cita pasa a payment_sent
8. Negocio aprueba el comprobante
   → Cita pasa a confirmed
   → Pedro recibe email de confirmacion
9. Pedro llega a la barberia y muestra QR del ticket
10. Negocio escanea QR en /dashboard/checkin
    → Cita pasa a checked_in
11. 30 minutos despues, job automatico completa la cita
    → Cita pasa a completed
    → Pedro recibe $1.250 en creditos (5% cashback)
    → Pedro recibe email pidiendo calificacion
12. Pedro deja resena: 5 estrellas, "Excelente servicio"
13. Al final del dia, negocio cierra caja
    → Ve que Juan atendio 8 citas, gano $200.000
    → Comision 30% = $60.000 → confirma pago en efectivo
14. Siguiente visita, Pedro tiene $1.250 de credito disponible
```
