# Agendity — Guia de Onboarding y Testing

Guia paso a paso para probar TODAS las funcionalidades de Agendity, tanto desde el frontend (navegador) como desde el backend (API/consola/admin).

---

## Requisitos previos

### Frontend (agendity-web)
```bash
cd agendity-web
cp .env.example .env.local   # Configurar NEXT_PUBLIC_API_URL
npm install && npm run dev    # http://localhost:3000
```

### Backend (agendity-api)
```bash
cd agendity-api
cp .env.example .env
bundle install
rails db:create db:migrate db:seed
bin/dev                       # http://localhost:3001
```

### Datos de prueba (seeds)
Los seeds crean:
- **Admin:** `admin@agendity.com` / `password123`
- **Negocio:** Barberia Demo (Carlos Mendez) — `demo@barberia.co` / `password123`
- **Negocio independiente:** Miguel Barrero — `miguel@barrero.co` / `password123`
- **3 planes:** Basico, Profesional, Inteligente
- **Empleados, servicios, citas, clientes, reviews** de ejemplo

---

## MODO DEMO (sin backend)

Si solo quieres probar el frontend sin levantar el backend:

1. En `.env.local` agrega: `NEXT_PUBLIC_DEMO_MODE=true`
2. Abre `http://localhost:3000/login` — entra automaticamente como "Carlos Mendoza" con Plan Profesional
3. Usa el boton **"Resetear datos"** en el banner naranja para volver al estado inicial
4. La cuenta demo vence hoy para mostrar el banner de expiracion

---

## 1. REGISTRO Y AUTENTICACION

### 1.1 Registrar un negocio nuevo

**Frontend:**
1. Ir a `/register`
2. Llenar: nombre, email, telefono, password, tipo de negocio (barberia/salon)
3. Click "Registrarse"
4. Redirige al onboarding

**Backend (curl):**
```bash
curl -X POST http://localhost:3001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@test.com","password":"password123","phone":"+573001234567","business_type":"barbershop"}'
```

### 1.2 Login

**Frontend:**
1. Ir a `/login`
2. Email + password
3. Redirige a `/dashboard/agenda`

**Backend:**
```bash
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@barberia.co","password":"password123"}'
# Guarda el token para las siguientes peticiones
export TOKEN="el_token_jwt"
```

### 1.3 Olvide mi contrasena

**Frontend:**
1. En `/login`, click "Olvidaste tu contrasena?"
2. Ingresar email en `/forgot-password`
3. Revisar email — contiene link a `/reset-password?token=XXX`
4. Ingresar nueva contrasena

**Backend:**
```bash
# Solicitar reset
curl -X POST http://localhost:3001/api/v1/auth/forgot_password \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@barberia.co"}'

# Resetear (el token viene del email)
curl -X POST http://localhost:3001/api/v1/auth/reset_password \
  -H "Content-Type: application/json" \
  -d '{"reset_password_token":"XXX","password":"newpass123","password_confirmation":"newpass123"}'
```

---

## 2. ONBOARDING (primer ingreso)

**Frontend:**
1. Despues de registrarse, redirige a `/dashboard/onboarding`
2. Paso 1: Perfil del negocio (nombre, descripcion, telefono, direccion)
3. Paso 2: Horarios (dias abiertos, hora apertura/cierre por dia)
4. Paso 3: Servicios (agregar al menos 1 servicio con precio y duracion)
5. Paso 4: Empleados (agregar al menos 1 empleado)
6. Paso 5: Metodos de pago (Nequi, Daviplata, Bancolombia)
7. Paso 6: Politica de cancelacion (% penalizacion, horas limite)
8. Al completar, redirige al dashboard

**Backend:**
```bash
curl -X POST http://localhost:3001/api/v1/business/onboarding \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Mi Barberia","business_type":"barbershop","phone":"+573001234567","services":[{"name":"Corte","duration_minutes":30,"price":25000}],"employees":[{"name":"Juan","phone":"+573009876543"}],"business_hours":[{"day_of_week":1,"open_time":"08:00","close_time":"18:00","closed":false}]}'
```

---

## 3. AGENDA (calendario)

### 3.1 Ver citas del dia/semana

**Frontend:**
1. Ir a `/dashboard/agenda`
2. Cambiar entre vista "Dia" y "Semana"
3. Navegar con flechas < > o click "Hoy"
4. Filtrar por empleado en el dropdown
5. Los colores indican estado (naranja=pendiente, azul=comprobante, verde=confirmada, morado=en atencion, gris=completada, rojo=cancelada)

### 3.2 Crear cita manual

**Frontend:**
1. Click "+ Nueva cita" (boton morado arriba a la derecha)
2. Seleccionar servicio
3. Seleccionar empleado
4. Seleccionar fecha
5. Se muestran los slots disponibles — seleccionar hora
6. Buscar cliente existente (por nombre/telefono) o crear nuevo
7. Click "Crear cita"

**Backend:**
```bash
curl -X POST http://localhost:3001/api/v1/appointments \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"service_id":1,"employee_id":1,"appointment_date":"2026-03-24","start_time":"10:00","customer_attributes":{"name":"Pedro Lopez","phone":"+573001112233"}}'
```

### 3.3 Confirmar cita

**Frontend:** Click en la cita en el calendario > "Confirmar"

**Backend:**
```bash
curl -X POST http://localhost:3001/api/v1/appointments/1/confirm \
  -H "Authorization: Bearer $TOKEN"
```

### 3.4 Cancelar cita

**Frontend:** Click en la cita > "Cancelar" > ingresar razon

**Backend:**
```bash
curl -X POST http://localhost:3001/api/v1/appointments/1/cancel \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"cancellation_reason":"No puede asistir"}'
```

### 3.5 Bloquear horario

**Frontend:**
1. Click "Bloquear" en la agenda
2. Seleccionar empleado, fecha, hora inicio y fin, razon
3. El bloque aparece en el calendario y ese horario no estara disponible para reservas

---

## 4. SERVICIOS

**Frontend:**
1. Ir a `/dashboard/services`
2. Click "+ Nuevo servicio"
3. Llenar: nombre, descripcion, precio (COP), duracion (minutos)
4. Guardar
5. Para editar: click en el servicio > editar > guardar
6. Para desactivar: toggle de activo/inactivo
7. Para eliminar: click eliminar (solo si no tiene citas asociadas)

**Backend:**
```bash
# Crear
curl -X POST http://localhost:3001/api/v1/services \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Barba completa","description":"Afeitado y perfilado","price":20000,"duration_minutes":20}'

# Listar
curl http://localhost:3001/api/v1/services -H "Authorization: Bearer $TOKEN"
```

---

## 5. EMPLEADOS

### 5.1 CRUD de empleados

**Frontend:**
1. Ir a `/dashboard/employees`
2. Click "+ Nuevo empleado"
3. Llenar: nombre, telefono, email, comision (%), servicios que ofrece, horario por dia
4. Guardar
5. Para editar: click en el empleado > editar

**Backend:**
```bash
curl -X POST http://localhost:3001/api/v1/employees \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Maria Garcia","phone":"+573005556666","email":"maria@test.co","commission_percentage":30,"service_ids":[1,2]}'
```

### 5.2 Invitar empleado al portal

**Frontend:**
1. En la lista de empleados, click "Invitar" junto al empleado
2. Se genera un link y se envia por email
3. El empleado abre el link > crea su contrasena > accede a `/employee`

**Backend:**
```bash
curl -X POST http://localhost:3001/api/v1/employees/1/invite \
  -H "Authorization: Bearer $TOKEN"
```

### 5.3 Subir foto de empleado

**Frontend:** En el modal de editar empleado, click en el area de foto > seleccionar imagen

**Backend:**
```bash
curl -X POST http://localhost:3001/api/v1/employees/1/upload_avatar \
  -H "Authorization: Bearer $TOKEN" \
  -F "avatar=@foto.jpg"
```

---

## 6. CLIENTES

**Frontend:**
1. Ir a `/dashboard/customers`
2. Ver lista de clientes con buscador
3. Click en un cliente para ver detalle: historial de citas, total gastado, creditos

**Backend:**
```bash
# Listar
curl http://localhost:3001/api/v1/customers -H "Authorization: Bearer $TOKEN"

# Detalle
curl http://localhost:3001/api/v1/customers/1 -H "Authorization: Bearer $TOKEN"
```

---

## 7. PAGOS

### 7.1 Revisar pagos pendientes

**Frontend:**
1. Ir a `/dashboard/payments`
2. Tab "Pendientes" — pagos con comprobante enviado
3. Click en un pago > ver comprobante (imagen) > "Aprobar" o "Rechazar"
4. Al aprobar, la cita pasa a "Confirmada"
5. Al rechazar, ingresar razon — se notifica al cliente

### 7.2 Enviar recordatorio de pago

**Frontend:** En el detalle de la cita > "Recordar pago" — envia email/WhatsApp al cliente

**Backend:**
```bash
# Aprobar pago
curl -X POST http://localhost:3001/api/v1/payments/1/approve \
  -H "Authorization: Bearer $TOKEN"

# Rechazar pago
curl -X POST http://localhost:3001/api/v1/payments/1/reject \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"rejection_reason":"Comprobante no coincide con el monto"}'
```

---

## 8. CHECK-IN

**Frontend:**
1. Ir a `/dashboard/checkin`
2. Escanear QR del ticket del cliente (usa la camara del dispositivo)
3. O ingresar el codigo del ticket manualmente (ej: `FE89E62168B5`)
4. Si la cita esta confirmada, pasa a "En atencion"
5. Se muestra resumen de la cita

**Backend:**
```bash
curl -X POST http://localhost:3001/api/v1/appointments/checkin_by_code \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"code":"FE89E62168B5"}'
```

**Nota:** El check-in solo funciona 30 minutos antes de la hora de la cita.

---

## 9. CREDITOS (cashback y reembolsos)

### 9.1 Ver creditos

**Frontend:**
1. Ir a `/dashboard/credits`
2. Ver resumen: total creditos en circulacion, numero de cuentas
3. Ver lista de clientes con balance de creditos
4. Click en un cliente > ver historial de transacciones

### 9.2 Ajustar creditos manualmente

**Frontend:**
1. En `/dashboard/credits`, click en un cliente
2. Click "Ajustar"
3. Ingresar monto (positivo = agregar, negativo = quitar) y descripcion
4. Guardar

### 9.3 Abrir credito masivo

**Frontend:**
1. Click "Abrir credito"
2. Seleccionar clientes especificos o "todos"
3. Ingresar monto y descripcion
4. Confirmar

**Backend:**
```bash
# Ver resumen
curl http://localhost:3001/api/v1/credits/summary -H "Authorization: Bearer $TOKEN"

# Ajuste individual
curl -X POST http://localhost:3001/api/v1/customers/1/credits/adjust \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount":5000,"description":"Bonificacion por fidelidad"}'

# Ajuste masivo
curl -X POST http://localhost:3001/api/v1/credits/bulk_adjust \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount":3000,"description":"Promocion de apertura","customer_ids":[1,2,3]}'
```

**Nota:** El cashback se otorga automaticamente cuando una cita se completa, si el plan del negocio lo incluye. El porcentaje lo configura el SuperAdmin.

---

## 10. TARIFAS DINAMICAS

### 10.1 Crear tarifa manual (Profesional+)

**Frontend:**
1. Ir a `/dashboard/dynamic-pricing`
2. Click "+ Nueva tarifa"
3. Llenar: nombre, servicio (o todos), fechas, tipo de ajuste (% o COP), valor, modo (fijo o progresivo), dias de la semana
4. Guardar

### 10.2 Aceptar/rechazar sugerencia IA (Inteligente)

**Frontend:**
1. En la seccion "Sugerencias", ver las tarfias sugeridas por el sistema
2. Click "Aceptar" para activar o "Rechazar" para descartar

**Backend:**
```bash
# Crear manual
curl -X POST http://localhost:3001/api/v1/dynamic_pricing \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Fin de semana","start_date":"2026-04-01","end_date":"2026-04-30","price_adjustment_type":"percentage","price_adjustment_value":15,"days_of_week":[5,6]}'

# Aceptar sugerencia
curl -X PATCH http://localhost:3001/api/v1/dynamic_pricing/1/accept \
  -H "Authorization: Bearer $TOKEN"
```

---

## 11. CIERRE DE CAJA (Profesional+)

### 11.1 Cerrar caja del dia

**Frontend:**
1. Ir a `/dashboard/cash-register`
2. Ver resumen del dia: ingresos totales, citas completadas, desglose por empleado
3. Click en cada empleado para ver detalle (citas, monto ganado, comision)
4. Para empleados con comision: confirmar pago (efectivo o transferencia)
5. Para empleados sin comision: ingresar monto pagado manualmente
6. Agregar notas opcionales
7. Click "Cerrar caja del dia"

### 11.2 Historial de cierres

**Frontend:**
1. Ir a `/dashboard/cash-register/history`
2. Filtrar por rango de fechas
3. Click en un cierre para ver detalle

**Backend:**
```bash
# Resumen del dia
curl http://localhost:3001/api/v1/cash_register/today -H "Authorization: Bearer $TOKEN"

# Cerrar
curl -X POST http://localhost:3001/api/v1/cash_register/close \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"date":"2026-03-23","notes":"Dia normal","employee_payments":[{"employee_id":1,"amount_paid":50000,"payment_method":"cash"}]}'

# Historial
curl "http://localhost:3001/api/v1/cash_register/history?from=2026-03-01&to=2026-03-31" \
  -H "Authorization: Bearer $TOKEN"
```

---

## 12. METAS FINANCIERAS (Inteligente)

**Frontend:**
1. Ir a `/dashboard/goals`
2. Click "Nueva meta"
3. Seleccionar tipo: meta mensual, punto de equilibrio, promedio diario, o personalizada
4. Ingresar valor objetivo y periodo
5. Ver progreso con barra y porcentaje
6. El sistema muestra cuanto falta para cumplir la meta

**Backend:**
```bash
curl -X POST http://localhost:3001/api/v1/goals \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"goal_type":"monthly_revenue","target_value":5000000,"period":"2026-03"}'

curl http://localhost:3001/api/v1/goals/progress -H "Authorization: Bearer $TOKEN"
```

---

## 13. RECONCILIACION (Inteligente)

**Frontend:**
1. Ir a `/dashboard/reconciliation`
2. Click "Verificar datos"
3. El sistema compara:
   - Balance de empleados: comisiones acumuladas vs pagos realizados
   - Creditos de clientes: suma de transacciones vs balance actual
4. Si hay discrepancias, se muestran en tabla roja
5. Si todo esta bien, muestra "Datos verificados"

**Backend:**
```bash
curl http://localhost:3001/api/v1/reconciliation/check -H "Authorization: Bearer $TOKEN"
```

---

## 14. REPORTES

**Frontend:**
1. Ir a `/dashboard/reports`
2. Ver tarjetas de resumen (citas, ingresos, calificacion promedio)
3. Seleccionar periodo (semana/mes/anio)
4. Graficas disponibles (Profesional+):
   - Ingresos por periodo
   - Top servicios
   - Top empleados
   - Clientes frecuentes
   - Ganancia neta (ingresos - comisiones)

**Backend:**
```bash
curl http://localhost:3001/api/v1/reports/summary -H "Authorization: Bearer $TOKEN"
curl "http://localhost:3001/api/v1/reports/revenue?period=month" -H "Authorization: Bearer $TOKEN"
curl http://localhost:3001/api/v1/reports/top_services -H "Authorization: Bearer $TOKEN"
curl http://localhost:3001/api/v1/reports/top_employees -H "Authorization: Bearer $TOKEN"
curl http://localhost:3001/api/v1/reports/frequent_customers -H "Authorization: Bearer $TOKEN"
curl "http://localhost:3001/api/v1/reports/profit?period=month" -H "Authorization: Bearer $TOKEN"
```

---

## 15. RESENAS

**Frontend:**
1. Ir a `/dashboard/reviews`
2. Ver calificacion promedio y lista de resenas
3. Cada resena muestra: estrellas, comentario, nombre del cliente, fecha

**Nota:** Las resenas se crean desde la pagina publica del ticket despues de que la cita se completa. El job `SendRatingRequestJob` envia un email/WhatsApp al cliente pidiendo calificacion.

---

## 16. CODIGO QR

**Frontend:**
1. Ir a `/dashboard/qr`
2. Ver tu URL publica de reservas: `agendity.co/{slug}`
3. Copiar link o descargar QR como imagen PNG
4. Imprimir y colocar en el local

---

## 17. NOTIFICACIONES

### 17.1 Ver notificaciones

**Frontend:**
1. Click en la campana (icono arriba a la derecha)
2. Ver lista de notificaciones con badge de no leidas
3. Click en una notificacion para marcarla como leida y navegar al recurso
4. "Marcar todas como leidas"

### 17.2 Configurar sonido

**Frontend:**
1. Ir a `/dashboard/settings`
2. Seccion "Notificaciones"
3. Toggle "Notificaciones del navegador" y "Sonido de notificaciones"

### 17.3 Notificaciones en tiempo real

Las notificaciones llegan en tiempo real via NATS WebSocket. Cuando llega una nueva reserva o pago:
- Suena un sonido (si esta habilitado)
- Aparece una notificacion del navegador (si esta permitido)
- El badge rojo en la campana se actualiza

---

## 18. CONFIGURACION

**Frontend:** Ir a `/dashboard/settings`

### Secciones:
1. **Logo** — subir imagen del negocio
2. **Portada** — subir imagen o seleccionar del banco de imagenes (Pexels)
3. **Perfil** — nombre, descripcion, telefono, direccion, ubicacion en mapa, redes sociales, datos legales (NIT, representante legal)
4. **Horarios** — dias y horas de apertura/cierre, almuerzo
5. **Configuracion de agenda** — intervalo de slots (15/30/60 min), gap entre citas, almuerzo
6. **Metodos de pago** — Nequi, Daviplata, Bancolombia
7. **Politica de cancelacion** — % penalizacion, horas limite
8. **Notificaciones** — sonido, browser notifications
9. **Personalizacion** (Profesional+) — colores primario/secundario

---

## 19. FLUJO PUBLICO DE RESERVA (usuario final)

### 19.1 Ver pagina del negocio

**Frontend:**
1. Ir a `/{slug}` (ej: `/barberia-demo`)
2. Ver portada, logo, descripcion, servicios con precio y duracion, horarios, resenas, mapa
3. Click "Reservar cita"

### 19.2 Reservar cita (5 pasos)

**Frontend:**
1. **Paso 1:** Seleccionar servicio(s)
2. **Paso 2:** Seleccionar empleado (o "cualquier disponible")
3. **Paso 3:** Seleccionar fecha en calendario > ver horarios disponibles > seleccionar
4. **Paso 4:** Ingresar datos (nombre, telefono, email) — si es cliente recurrente, se detecta y muestra creditos disponibles
5. **Paso 5:** Confirmar — ver resumen con precio (incluye tarifa dinamica si aplica), creditos aplicados, instrucciones de pago
6. Despues de confirmar, redirige al ticket

### 19.3 Ticket del usuario

**Frontend:**
1. Ir a `/{slug}/ticket/{code}`
2. Ver detalle de la cita: fecha, hora, servicio, empleado, precio
3. **Subir comprobante de pago** — seleccionar imagen del recibo
4. **Cancelar cita** — muestra preview de penalizacion antes de confirmar
5. **Descargar ticket** como imagen PNG
6. **QR code** para check-in en el local

### 19.4 Explorar negocios

**Frontend:**
1. Ir a `/explore`
2. Buscar por nombre, filtrar por ciudad o tipo de negocio
3. Ver tarjetas de negocios con calificacion y tipo
4. Click en un negocio para ir a su pagina publica

**Backend:**
```bash
# Explorar
curl http://localhost:3001/api/v1/public/explore

# Ver negocio
curl http://localhost:3001/api/v1/public/barberia-demo

# Disponibilidad
curl "http://localhost:3001/api/v1/public/barberia-demo/availability?date=2026-03-24&service_id=1&employee_id=1"

# Reservar
curl -X POST http://localhost:3001/api/v1/public/barberia-demo/book \
  -H "Content-Type: application/json" \
  -d '{"service_id":1,"employee_id":1,"date":"2026-03-24","start_time":"10:00","customer":{"name":"Pedro","phone":"+573001112233","email":"pedro@test.co"}}'
```

---

## 20. PORTAL DEL EMPLEADO

### 20.1 Registrarse como empleado

**Frontend:**
1. El negocio envia invitacion por email
2. El empleado abre el link: `/employee/register?token=XXX`
3. Crea su contrasena
4. Inicia sesion y accede a `/employee`

### 20.2 Dashboard del empleado

**Frontend:**
1. Ver score de rendimiento (0-100)
2. Calificacion promedio de clientes
3. Citas de hoy y del mes
4. Ingresos generados

### 20.3 Check-in desde empleado

**Frontend:**
1. Ir a `/employee/checkin`
2. Escanear QR o ingresar codigo
3. Si la cita no es del empleado logueado, se pide confirmacion (sustitucion)

**Backend:**
```bash
# Login como empleado
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"empleado@test.co","password":"password123"}'

# Dashboard
curl http://localhost:3001/api/v1/employee/dashboard -H "Authorization: Bearer $EMP_TOKEN"

# Score
curl http://localhost:3001/api/v1/employee/score -H "Authorization: Bearer $EMP_TOKEN"
```

---

## 21. SUPERADMIN

### 21.1 Panel de ActiveAdmin

1. Ir a `http://localhost:3001/admin`
2. Login con `admin@agendity.com` / `password123`
3. Gestionar: negocios, usuarios, planes, suscripciones, citas, pagos, resenas, jobs

### 21.2 Crear profesional independiente

1. En ActiveAdmin > "Profesionales Independientes"
2. Llenar datos: nombre, email, telefono, tipo de documento
3. Se crea usuario + negocio (independent=true) + empleado + suscripcion trial

### 21.3 Impersonar un negocio

**Frontend:**
1. Login como admin
2. En el topbar, click "Observar como..." (icono de ojo)
3. Buscar negocio por nombre
4. Click en el negocio — ahora ves el dashboard como si fueras el dueno
5. Para salir, click "Dejar de observar" en el banner amarillo

### 21.4 Enviar notificacion manual

1. En ActiveAdmin > "Enviar Notificacion"
2. Seleccionar tipo (new_booking, subscription_expiry, etc.)
3. Seleccionar negocios (todos o especificos)
4. Opcional: titulo y cuerpo personalizados
5. Enviar — crea notificacion in-app + evento NATS

### 21.5 Gestionar jobs

1. En ActiveAdmin > "Jobs"
2. Ver lista de jobs con estado (habilitado/deshabilitado), ultima ejecucion, resultado
3. Toggle habilitado/deshabilitado
4. Click "Run now" para ejecutar manualmente
5. Ver logs de ejecucion en el detalle del job

### 21.6 Renovar suscripcion

1. En ActiveAdmin > Subscriptions > seleccionar suscripcion
2. Click "Renovar suscripcion"
3. Se extiende 30 dias, se reactiva el negocio si estaba suspendido, y se envian notificaciones

### 21.7 Sidekiq (jobs en background)

1. Ir a `http://localhost:3001/admin/sidekiq`
2. Login con credenciales de admin
3. Ver colas, jobs en ejecucion, programados, fallidos

---

## 22. ALERTAS DE SUSCRIPCION

### Flujo automatico (job diario a las 8am):

| Dias | Accion |
|------|--------|
| **5 dias antes** | Email + notificacion in-app + WhatsApp (si el plan lo incluye) |
| **Dia que vence** | Email + notificacion in-app + WhatsApp + **banner rojo en el dashboard** |
| **2 dias despues** | Email + notificacion + WhatsApp + **negocio suspendido** |

### Banner en el dashboard:
- **Amarillo:** "Tu plan vence en X dias"
- **Rojo:** "Tu plan vence hoy"
- **Rojo oscuro:** "Tu plan vencio hace X dias"

### Simular desde backend:
```bash
# Ejecutar job manualmente desde consola Rails
rails runner "SubscriptionExpiryAlertJob.perform_now"

# O desde ActiveAdmin > Jobs > "Alertas de expiracion" > Run now
```

---

## 23. BANNERS PUBLICITARIOS

Los banners aparecen en la pagina de Explore (`/explore`). Se gestionan desde ActiveAdmin.

1. ActiveAdmin > Ad Banners > crear banner con imagen, link, posicion
2. El sistema trackea impresiones y clicks automaticamente

---

## FLUJO COMPLETO DE UNA CITA (end-to-end)

Para probar el ciclo completo:

1. **Usuario final** va a `/{slug}` y reserva una cita
2. **Negocio** ve la cita en la agenda (status: `pending_payment`)
3. **Usuario** sube comprobante de pago desde su ticket
4. **Negocio** aprueba el pago en `/dashboard/payments` (status: `confirmed`)
5. **Usuario** llega al local con su ticket/QR
6. **Negocio** escanea el QR en `/dashboard/checkin` (status: `checked_in`)
7. **Job automatico** completa la cita cuando termina el horario (status: `completed`)
8. **Job automatico** envia email/WhatsApp al usuario pidiendo calificacion
9. **Usuario** deja una resena desde el link del email
10. **Negocio** ve la resena en `/dashboard/reviews`
11. **Negocio** cierra caja del dia en `/dashboard/cash-register`
12. Si el plan tiene cashback, el cliente recibe creditos automaticamente

---

## RESTRICCIONES POR PLAN

| Feature | Trial/Basico | Profesional | Inteligente |
|---------|:---:|:---:|:---:|
| Agenda, servicios, empleados, clientes, pagos, check-in, QR | Si | Si | Si |
| Creditos | Si | Si | Si |
| Notificaciones | Si | Si | Si |
| Reportes basicos (resumen) | Si | Si | Si |
| Reportes avanzados (graficas) | No | Si | Si |
| Resenas | No | Si | Si |
| Tarifas dinamicas (manual) | No | Si | Si |
| Cierre de caja | No | Si | Si |
| Personalizacion de marca | No | Si | Si |
| WhatsApp al usuario final | No | Si | Si |
| Sugerencias IA (tarifas) | No | No | Si |
| Metas financieras | No | No | Si |
| Reconciliacion contable | No | No | Si |
