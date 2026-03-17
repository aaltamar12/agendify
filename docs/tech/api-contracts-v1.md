# API Contracts v1

> **Estado:** Pre-lanzamiento
> **Ultima actualizacion:** 2026-03-16

Documentacion de todos los endpoints de la API REST de Agendity.

> **Terminologia:** **Cliente** = el negocio (barberia/salon) que paga suscripcion a Agendity. **Usuario final** = la persona que reserva citas.

---

## Convenciones generales

| Concepto | Detalle |
|---|---|
| Base URL | `/api/v1` |
| Formato | JSON (`Content-Type: application/json`) |
| Autenticacion | JWT via header `Authorization: Bearer <token>` |
| Paginacion | Query params `page` y `per_page`. Respuesta incluye objeto `meta` |
| Timestamps | ISO 8601 (`2026-03-16T10:30:00Z`) |
| IDs | `bigint` |
| Moneda | COP (pesos colombianos) por defecto |

### Estructura de respuesta estandar

```json
{
  "data": { ... },
  "message": "Operacion exitosa"
}
```

### Estructura de respuesta paginada

```json
{
  "data": [ ... ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 48,
    "per_page": 10
  }
}
```

### Estructura de error

```json
{
  "error": "Mensaje descriptivo del error",
  "details": { ... }
}
```

### Codigos de estado comunes

| Codigo | Significado |
|---|---|
| `200` | OK |
| `201` | Recurso creado |
| `204` | Sin contenido (delete exitoso) |
| `400` | Bad request / validacion fallida |
| `401` | No autenticado |
| `403` | No autorizado (sin permisos) |
| `404` | Recurso no encontrado |
| `422` | Entidad no procesable (errores de validacion) |
| `500` | Error interno del servidor |

---

## 1. Authentication

Endpoints para registro, login y gestion de sesion JWT.

---

### POST `/api/v1/auth/login`

Iniciar sesion y obtener token JWT.

- **Auth:** Publica
- **Request body:**

```json
{
  "email": "carlos@barberia-elite.com",
  "password": "secreto123"
}
```

- **Response `200`:**

```json
{
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "abc123def456...",
    "user": {
      "id": 1,
      "email": "carlos@barberia-elite.com",
      "name": "Carlos Mendez",
      "phone": "+573001234567",
      "role": "owner",
      "avatar_url": null,
      "business_id": 1,
      "created_at": "2026-03-01T10:00:00Z",
      "updated_at": "2026-03-01T10:00:00Z"
    }
  }
}
```

- **Response `401`:**

```json
{
  "error": "Credenciales invalidas"
}
```

---

### POST `/api/v1/auth/register`

Registrar un nuevo usuario (owner) y crear su negocio.

- **Auth:** Publica
- **Request body:**

```json
{
  "name": "Carlos Mendez",
  "email": "carlos@barberia-elite.com",
  "password": "secreto123",
  "password_confirmation": "secreto123",
  "phone": "+573001234567"
}
```

- **Response `201`:**

```json
{
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "abc123def456...",
    "user": {
      "id": 1,
      "email": "carlos@barberia-elite.com",
      "name": "Carlos Mendez",
      "phone": "+573001234567",
      "role": "owner",
      "avatar_url": null,
      "business_id": 1,
      "created_at": "2026-03-16T10:00:00Z",
      "updated_at": "2026-03-16T10:00:00Z"
    }
  }
}
```

- **Response `422`:**

```json
{
  "error": "Error de validacion",
  "details": {
    "email": ["ya esta en uso"],
    "password": ["debe tener al menos 8 caracteres"]
  }
}
```

---

### POST `/api/v1/auth/refresh`

Renovar el token JWT usando el refresh token.

- **Auth:** Publica (usa refresh_token)
- **Request body:**

```json
{
  "refresh_token": "abc123def456..."
}
```

- **Response `200`:**

```json
{
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "xyz789..."
  }
}
```

- **Response `401`:**

```json
{
  "error": "Refresh token invalido o expirado"
}
```

---

### GET `/api/v1/auth/me`

Obtener datos del usuario autenticado.

- **Auth:** JWT
- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "email": "carlos@barberia-elite.com",
    "name": "Carlos Mendez",
    "phone": "+573001234567",
    "role": "owner",
    "avatar_url": null,
    "business_id": 1,
    "created_at": "2026-03-01T10:00:00Z",
    "updated_at": "2026-03-01T10:00:00Z"
  }
}
```

---

### DELETE `/api/v1/auth/logout`

Cerrar sesion e invalidar el token.

- **Auth:** JWT
- **Response `200`:**

```json
{
  "message": "Sesion cerrada exitosamente"
}
```

---

## 2. Business

Endpoints para gestionar el negocio del usuario autenticado. Cada usuario owner tiene un solo negocio.

---

### GET `/api/v1/business`

Obtener datos del negocio actual del usuario autenticado.

- **Auth:** JWT
- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "name": "Barberia Elite",
    "slug": "barberia-elite",
    "description": "La mejor barberia de Barranquilla",
    "business_type": "barbershop",
    "phone": "+573001234567",
    "email": "info@barberia-elite.com",
    "address": "Calle 84 #53-120, Local 2",
    "city": "Barranquilla",
    "state": "Atlantico",
    "country": "CO",
    "latitude": 10.9878,
    "longitude": -74.7889,
    "logo_url": "https://storage.agendity.com/logos/barberia-elite.png",
    "cover_url": "https://storage.agendity.com/covers/barberia-elite.jpg",
    "primary_color": "#1E3A5F",
    "secondary_color": "#F5A623",
    "currency": "COP",
    "timezone": "America/Bogota",
    "status": "active",
    "onboarding_completed": true,
    "nequi_phone": "+573001234567",
    "daviplata_phone": null,
    "bancolombia_account": null,
    "owner_id": 1,
    "created_at": "2026-03-01T10:00:00Z",
    "updated_at": "2026-03-15T14:30:00Z"
  }
}
```

---

### PUT `/api/v1/business`

Actualizar datos del negocio actual.

- **Auth:** JWT (owner/admin)
- **Request body** (campos parciales permitidos):

```json
{
  "name": "Barberia Elite Premium",
  "description": "La mejor barberia de Barranquilla, ahora con servicio VIP",
  "phone": "+573009876543",
  "address": "Calle 84 #53-120, Local 3",
  "city": "Barranquilla",
  "state": "Atlantico",
  "primary_color": "#2C3E50",
  "nequi_phone": "+573009876543",
  "daviplata_phone": "+573001112233",
  "bancolombia_account": "12345678901"
}
```

- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "name": "Barberia Elite Premium",
    "slug": "barberia-elite",
    "description": "La mejor barberia de Barranquilla, ahora con servicio VIP",
    "business_type": "barbershop",
    "phone": "+573009876543",
    "email": "info@barberia-elite.com",
    "address": "Calle 84 #53-120, Local 3",
    "city": "Barranquilla",
    "state": "Atlantico",
    "country": "CO",
    "latitude": 10.9878,
    "longitude": -74.7889,
    "logo_url": "https://storage.agendity.com/logos/barberia-elite.png",
    "cover_url": "https://storage.agendity.com/covers/barberia-elite.jpg",
    "primary_color": "#2C3E50",
    "secondary_color": "#F5A623",
    "currency": "COP",
    "timezone": "America/Bogota",
    "status": "active",
    "onboarding_completed": true,
    "nequi_phone": "+573009876543",
    "daviplata_phone": "+573001112233",
    "bancolombia_account": "12345678901",
    "owner_id": 1,
    "created_at": "2026-03-01T10:00:00Z",
    "updated_at": "2026-03-16T11:00:00Z"
  }
}
```

---

### POST `/api/v1/business/onboarding`

Completar el wizard de onboarding. Marca `onboarding_completed: true` y configura datos iniciales del negocio.

- **Auth:** JWT (owner)
- **Request body:**

```json
{
  "name": "Barberia Elite",
  "business_type": "barbershop",
  "phone": "+573001234567",
  "address": "Calle 84 #53-120, Local 2",
  "city": "Barranquilla",
  "state": "Atlantico",
  "timezone": "America/Bogota",
  "nequi_phone": "+573001234567"
}
```

- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "name": "Barberia Elite",
    "slug": "barberia-elite",
    "business_type": "barbershop",
    "onboarding_completed": true,
    "status": "active"
  },
  "message": "Onboarding completado exitosamente"
}
```

---

### POST `/api/v1/business/upload_logo`

Subir o reemplazar el logo del negocio via ActiveStorage.

- **Auth:** JWT (owner)
- **Content-Type:** `multipart/form-data`
- **Request body:**

| Campo | Tipo | Requerido | Descripcion |
|---|---|---|---|
| `logo` | File | Si | Archivo de imagen (jpg, png, webp) |

- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "name": "Barberia Elite",
    "slug": "barberia-elite",
    "logo_url": "http://localhost:3001/rails/active_storage/blobs/.../logo.png"
  }
}
```

- **Response `422`:**

```json
{
  "error": "No se envio ningun archivo"
}
```

---

## 3. Services

CRUD completo de servicios del negocio.

---

### GET `/api/v1/services`

Listar todos los servicios del negocio.

- **Auth:** JWT
- **Response `200`:**

```json
{
  "data": [
    {
      "id": 1,
      "business_id": 1,
      "name": "Corte clasico",
      "description": "Corte de cabello tradicional con tijera y maquina",
      "duration_minutes": 30,
      "price": 25000,
      "active": true,
      "category": "cortes",
      "image_url": null,
      "created_at": "2026-03-01T10:00:00Z",
      "updated_at": "2026-03-01T10:00:00Z"
    },
    {
      "id": 2,
      "business_id": 1,
      "name": "Barba completa",
      "description": "Afeitado y perfilado de barba con navaja",
      "duration_minutes": 20,
      "price": 15000,
      "active": true,
      "category": "barba",
      "image_url": null,
      "created_at": "2026-03-01T10:00:00Z",
      "updated_at": "2026-03-01T10:00:00Z"
    }
  ]
}
```

---

### POST `/api/v1/services`

Crear un nuevo servicio.

- **Auth:** JWT (owner/admin)
- **Request body:**

```json
{
  "name": "Corte + Barba",
  "description": "Combo corte de cabello y arreglo de barba",
  "duration_minutes": 45,
  "price": 35000,
  "active": true,
  "category": "combos"
}
```

- **Response `201`:**

```json
{
  "data": {
    "id": 3,
    "business_id": 1,
    "name": "Corte + Barba",
    "description": "Combo corte de cabello y arreglo de barba",
    "duration_minutes": 45,
    "price": 35000,
    "active": true,
    "category": "combos",
    "image_url": null,
    "created_at": "2026-03-16T11:00:00Z",
    "updated_at": "2026-03-16T11:00:00Z"
  }
}
```

- **Response `422`:**

```json
{
  "error": "Error de validacion",
  "details": {
    "name": ["no puede estar vacio"],
    "duration_minutes": ["debe ser mayor a 0"],
    "price": ["debe ser mayor o igual a 0"]
  }
}
```

---

### GET `/api/v1/services/:id`

Obtener un servicio por ID.

- **Auth:** JWT
- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "business_id": 1,
    "name": "Corte clasico",
    "description": "Corte de cabello tradicional con tijera y maquina",
    "duration_minutes": 30,
    "price": 25000,
    "active": true,
    "category": "cortes",
    "image_url": null,
    "created_at": "2026-03-01T10:00:00Z",
    "updated_at": "2026-03-01T10:00:00Z"
  }
}
```

- **Response `404`:**

```json
{
  "error": "Servicio no encontrado"
}
```

---

### PUT `/api/v1/services/:id`

Actualizar un servicio existente.

- **Auth:** JWT (owner/admin)
- **Request body** (campos parciales permitidos):

```json
{
  "price": 28000,
  "duration_minutes": 35
}
```

- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "business_id": 1,
    "name": "Corte clasico",
    "description": "Corte de cabello tradicional con tijera y maquina",
    "duration_minutes": 35,
    "price": 28000,
    "active": true,
    "category": "cortes",
    "image_url": null,
    "created_at": "2026-03-01T10:00:00Z",
    "updated_at": "2026-03-16T11:30:00Z"
  }
}
```

---

### DELETE `/api/v1/services/:id`

Eliminar un servicio (soft delete o desactivacion).

- **Auth:** JWT (owner/admin)
- **Response `204`:** Sin contenido

- **Response `404`:**

```json
{
  "error": "Servicio no encontrado"
}
```

---

## 4. Employees

CRUD completo de empleados del negocio, incluyendo asignacion de servicios.

---

### GET `/api/v1/employees`

Listar todos los empleados del negocio.

- **Auth:** JWT
- **Response `200`:**

```json
{
  "data": [
    {
      "id": 1,
      "business_id": 1,
      "user_id": null,
      "name": "Miguel Torres",
      "email": "miguel@barberia-elite.com",
      "phone": "+573005551234",
      "avatar_url": null,
      "bio": "Barbero con 10 anios de experiencia",
      "active": true,
      "commission_percentage": 40,
      "created_at": "2026-03-01T10:00:00Z",
      "updated_at": "2026-03-01T10:00:00Z"
    },
    {
      "id": 2,
      "business_id": 1,
      "user_id": null,
      "name": "Andres Lopez",
      "email": "andres@barberia-elite.com",
      "phone": "+573005555678",
      "avatar_url": null,
      "bio": "Especialista en fades y disenos",
      "active": true,
      "commission_percentage": 35,
      "created_at": "2026-03-02T10:00:00Z",
      "updated_at": "2026-03-02T10:00:00Z"
    }
  ]
}
```

---

### POST `/api/v1/employees`

Crear un nuevo empleado. Se puede incluir `service_ids` para asignar servicios al crearlo.

- **Auth:** JWT (owner/admin)
- **Request body:**

```json
{
  "name": "Pedro Ramirez",
  "email": "pedro@barberia-elite.com",
  "phone": "+573005559999",
  "bio": "Nuevo integrante del equipo",
  "commission_percentage": 30,
  "service_ids": [1, 2, 3]
}
```

- **Response `201`:**

```json
{
  "data": {
    "id": 3,
    "business_id": 1,
    "user_id": null,
    "name": "Pedro Ramirez",
    "email": "pedro@barberia-elite.com",
    "phone": "+573005559999",
    "avatar_url": null,
    "bio": "Nuevo integrante del equipo",
    "active": true,
    "commission_percentage": 30,
    "created_at": "2026-03-16T12:00:00Z",
    "updated_at": "2026-03-16T12:00:00Z"
  }
}
```

---

### GET `/api/v1/employees/:id`

Obtener un empleado por ID, incluyendo sus servicios asignados.

- **Auth:** JWT
- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "business_id": 1,
    "user_id": null,
    "name": "Miguel Torres",
    "email": "miguel@barberia-elite.com",
    "phone": "+573005551234",
    "avatar_url": null,
    "bio": "Barbero con 10 anios de experiencia",
    "active": true,
    "commission_percentage": 40,
    "services": [
      {
        "id": 1,
        "service_id": 1,
        "employee_id": 1,
        "custom_duration": null,
        "custom_price": null,
        "created_at": "2026-03-01T10:00:00Z",
        "updated_at": "2026-03-01T10:00:00Z"
      }
    ],
    "created_at": "2026-03-01T10:00:00Z",
    "updated_at": "2026-03-01T10:00:00Z"
  }
}
```

---

### PUT `/api/v1/employees/:id`

Actualizar un empleado. Se puede actualizar `service_ids` para reasignar servicios.

- **Auth:** JWT (owner/admin)
- **Request body** (campos parciales permitidos):

```json
{
  "bio": "Barbero senior con 10 anios de experiencia",
  "commission_percentage": 45,
  "service_ids": [1, 2, 3]
}
```

- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "business_id": 1,
    "user_id": null,
    "name": "Miguel Torres",
    "email": "miguel@barberia-elite.com",
    "phone": "+573005551234",
    "avatar_url": null,
    "bio": "Barbero senior con 10 anios de experiencia",
    "active": true,
    "commission_percentage": 45,
    "created_at": "2026-03-01T10:00:00Z",
    "updated_at": "2026-03-16T12:30:00Z"
  }
}
```

---

### DELETE `/api/v1/employees/:id`

Eliminar un empleado (soft delete o desactivacion).

- **Auth:** JWT (owner/admin)
- **Response `204`:** Sin contenido

---

## 5. Appointments

CRUD de citas + acciones de cambio de estado (confirmar, check-in, cancelar, completar).

---

### GET `/api/v1/appointments`

Listar citas del negocio. Soporta filtros por query params.

- **Auth:** JWT
- **Query params opcionales:**
  - `date` — filtrar por fecha (`2026-03-16`)
  - `status` — filtrar por estado (`pending_payment`, `confirmed`, etc.)
  - `employee_id` — filtrar por empleado
  - `page` y `per_page` — paginacion

- **Response `200`:**

```json
{
  "data": [
    {
      "id": 1,
      "business_id": 1,
      "employee_id": 1,
      "service_id": 1,
      "customer_id": 1,
      "date": "2026-03-16",
      "start_time": "10:00",
      "end_time": "10:30",
      "status": "confirmed",
      "price": 25000,
      "notes": null,
      "cancellation_reason": null,
      "ticket_code": "AGF-20260316-A1B2",
      "created_at": "2026-03-15T20:00:00Z",
      "updated_at": "2026-03-15T21:00:00Z",
      "employee": {
        "id": 1,
        "name": "Miguel Torres",
        "avatar_url": null
      },
      "service": {
        "id": 1,
        "name": "Corte clasico",
        "duration_minutes": 30,
        "price": 25000
      },
      "customer": {
        "id": 1,
        "name": "Juan Perez",
        "phone": "+573001112233"
      },
      "payment": {
        "id": 1,
        "amount": 25000,
        "status": "approved",
        "payment_method": "transfer",
        "proof_url": "https://storage.agendity.com/proofs/proof-001.jpg"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 3,
    "total_count": 28,
    "per_page": 10
  }
}
```

---

### POST `/api/v1/appointments`

Crear una cita manualmente (desde el dashboard del negocio).

- **Auth:** JWT (owner/admin/employee)
- **Request body:**

```json
{
  "employee_id": 1,
  "service_id": 1,
  "customer_id": 1,
  "date": "2026-03-17",
  "start_time": "14:00",
  "notes": "Cliente prefiere corte con tijera"
}
```

- **Response `201`:**

```json
{
  "data": {
    "id": 5,
    "business_id": 1,
    "employee_id": 1,
    "service_id": 1,
    "customer_id": 1,
    "date": "2026-03-17",
    "start_time": "14:00",
    "end_time": "14:30",
    "status": "pending_payment",
    "price": 25000,
    "notes": "Cliente prefiere corte con tijera",
    "cancellation_reason": null,
    "ticket_code": "AGF-20260317-C3D4",
    "created_at": "2026-03-16T13:00:00Z",
    "updated_at": "2026-03-16T13:00:00Z"
  }
}
```

- **Response `422`:**

```json
{
  "error": "Error de validacion",
  "details": {
    "start_time": ["el horario ya esta ocupado para este empleado"]
  }
}
```

---

### GET `/api/v1/appointments/:id`

Obtener detalle de una cita con relaciones expandidas.

- **Auth:** JWT
- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "business_id": 1,
    "employee_id": 1,
    "service_id": 1,
    "customer_id": 1,
    "date": "2026-03-16",
    "start_time": "10:00",
    "end_time": "10:30",
    "status": "confirmed",
    "price": 25000,
    "notes": null,
    "cancellation_reason": null,
    "ticket_code": "AGF-20260316-A1B2",
    "created_at": "2026-03-15T20:00:00Z",
    "updated_at": "2026-03-15T21:00:00Z",
    "employee": {
      "id": 1,
      "name": "Miguel Torres",
      "avatar_url": null
    },
    "service": {
      "id": 1,
      "name": "Corte clasico",
      "duration_minutes": 30,
      "price": 25000
    },
    "customer": {
      "id": 1,
      "name": "Juan Perez",
      "phone": "+573001112233",
      "email": "juan@email.com"
    },
    "payment": {
      "id": 1,
      "amount": 25000,
      "status": "approved",
      "payment_method": "transfer",
      "reference": null,
      "proof_url": "https://storage.agendity.com/proofs/proof-001.jpg",
      "submitted_at": "2026-03-15T20:15:00Z",
      "approved_at": "2026-03-15T21:00:00Z",
      "rejected_at": null,
      "rejection_reason": null
    }
  }
}
```

---

### PUT `/api/v1/appointments/:id`

Actualizar datos de una cita (reprogramar, cambiar notas, etc.).

- **Auth:** JWT (owner/admin)
- **Request body** (campos parciales permitidos):

```json
{
  "date": "2026-03-18",
  "start_time": "15:00",
  "employee_id": 2,
  "notes": "Reprogramada por solicitud del cliente"
}
```

- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "business_id": 1,
    "employee_id": 2,
    "service_id": 1,
    "customer_id": 1,
    "date": "2026-03-18",
    "start_time": "15:00",
    "end_time": "15:30",
    "status": "confirmed",
    "price": 25000,
    "notes": "Reprogramada por solicitud del cliente",
    "cancellation_reason": null,
    "ticket_code": "AGF-20260316-A1B2",
    "created_at": "2026-03-15T20:00:00Z",
    "updated_at": "2026-03-16T14:00:00Z"
  }
}
```

---

### DELETE `/api/v1/appointments/:id`

Eliminar una cita.

- **Auth:** JWT (owner/admin)
- **Response `204`:** Sin contenido

---

### POST `/api/v1/appointments/:id/confirm`

Confirmar una cita despues de aprobar el pago. Cambia estado a `confirmed` y genera el ticket digital.

- **Auth:** JWT (owner/admin)
- **Request body:** Ninguno

- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "status": "confirmed",
    "ticket_code": "AGF-20260316-A1B2"
  },
  "message": "Cita confirmada exitosamente"
}
```

- **Response `422`:**

```json
{
  "error": "La cita no puede ser confirmada en su estado actual"
}
```

---

### POST `/api/v1/appointments/:id/checkin`

Registrar check-in del usuario final (escaneo de QR al llegar). Cambia estado a `checked_in`.

- **Auth:** JWT (owner/admin/employee)
- **Request body:** Ninguno

- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "status": "checked_in"
  },
  "message": "Check-in registrado exitosamente"
}
```

---

### POST `/api/v1/appointments/:id/cancel`

Cancelar una cita. Se puede incluir razon de cancelacion.

- **Auth:** JWT (owner/admin)
- **Request body:**

```json
{
  "cancellation_reason": "El cliente solicito cancelar"
}
```

- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "status": "cancelled",
    "cancellation_reason": "El cliente solicito cancelar"
  },
  "message": "Cita cancelada exitosamente"
}
```

---

### POST `/api/v1/appointments/:id/complete`

Marcar una cita como completada despues del servicio. Cambia estado a `completed`.

- **Auth:** JWT (owner/admin/employee)
- **Request body:** Ninguno

- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "status": "completed"
  },
  "message": "Cita completada exitosamente"
}
```

---

## 6. Customers

Consulta de usuarios finales del negocio. Los customers se crean automaticamente al hacer una reserva.

---

### GET `/api/v1/customers`

Listar usuarios finales del negocio con paginacion y busqueda.

- **Auth:** JWT
- **Query params opcionales:**
  - `search` — buscar por nombre, telefono o email
  - `page` y `per_page` — paginacion

- **Response `200`:**

```json
{
  "data": [
    {
      "id": 1,
      "business_id": 1,
      "name": "Juan Perez",
      "phone": "+573001112233",
      "email": "juan@email.com",
      "notes": "Prefiere cortes clasicos",
      "total_visits": 5,
      "last_visit_at": "2026-03-10T10:30:00Z",
      "created_at": "2026-01-15T10:00:00Z",
      "updated_at": "2026-03-10T10:30:00Z"
    },
    {
      "id": 2,
      "business_id": 1,
      "name": "Pedro Gomez",
      "phone": "+573004445566",
      "email": "pedro@email.com",
      "notes": null,
      "total_visits": 2,
      "last_visit_at": "2026-03-05T14:00:00Z",
      "created_at": "2026-02-20T10:00:00Z",
      "updated_at": "2026-03-05T14:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 2,
    "total_count": 15,
    "per_page": 10
  }
}
```

---

### GET `/api/v1/customers/:id`

Obtener detalle de un usuario final.

- **Auth:** JWT
- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "business_id": 1,
    "name": "Juan Perez",
    "phone": "+573001112233",
    "email": "juan@email.com",
    "notes": "Prefiere cortes clasicos",
    "total_visits": 5,
    "last_visit_at": "2026-03-10T10:30:00Z",
    "created_at": "2026-01-15T10:00:00Z",
    "updated_at": "2026-03-10T10:30:00Z"
  }
}
```

---

## 7. Payments

Gestion de pagos P2P. El usuario final sube comprobante, el negocio aprueba o rechaza.

---

### POST `/api/v1/appointments/:appointmentId/payments/submit`

Enviar comprobante de pago para una cita. Cambia estado del pago a `submitted` y de la cita a `payment_sent`.

- **Auth:** JWT o Publica (dependiendo del flujo)
- **Request body** (`multipart/form-data`):

```json
{
  "payment_method": "transfer",
  "amount": 25000,
  "reference": "REF-123456",
  "proof": "(archivo imagen: jpg/png)"
}
```

- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "appointment_id": 1,
    "amount": 25000,
    "status": "submitted",
    "payment_method": "transfer",
    "reference": "REF-123456",
    "proof_url": "https://storage.agendity.com/proofs/proof-001.jpg",
    "submitted_at": "2026-03-16T15:00:00Z",
    "approved_at": null,
    "rejected_at": null,
    "rejection_reason": null,
    "created_at": "2026-03-16T15:00:00Z",
    "updated_at": "2026-03-16T15:00:00Z"
  },
  "message": "Comprobante enviado exitosamente"
}
```

---

### POST `/api/v1/payments/:paymentId/approve`

Aprobar un pago. Cambia estado del pago a `approved` y de la cita a `confirmed`.

- **Auth:** JWT (owner/admin)
- **Request body:** Ninguno

- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "appointment_id": 1,
    "amount": 25000,
    "status": "approved",
    "payment_method": "transfer",
    "reference": "REF-123456",
    "proof_url": "https://storage.agendity.com/proofs/proof-001.jpg",
    "submitted_at": "2026-03-16T15:00:00Z",
    "approved_at": "2026-03-16T15:30:00Z",
    "rejected_at": null,
    "rejection_reason": null,
    "created_at": "2026-03-16T15:00:00Z",
    "updated_at": "2026-03-16T15:30:00Z"
  },
  "message": "Pago aprobado exitosamente"
}
```

---

### POST `/api/v1/payments/:paymentId/reject`

Rechazar un pago. Cambia estado del pago a `rejected` y de la cita de vuelta a `pending_payment`.

- **Auth:** JWT (owner/admin)
- **Request body:**

```json
{
  "rejection_reason": "El comprobante no corresponde al monto correcto"
}
```

- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "appointment_id": 1,
    "amount": 25000,
    "status": "rejected",
    "payment_method": "transfer",
    "reference": "REF-123456",
    "proof_url": "https://storage.agendity.com/proofs/proof-001.jpg",
    "submitted_at": "2026-03-16T15:00:00Z",
    "approved_at": null,
    "rejected_at": "2026-03-16T15:30:00Z",
    "rejection_reason": "El comprobante no corresponde al monto correcto",
    "created_at": "2026-03-16T15:00:00Z",
    "updated_at": "2026-03-16T15:30:00Z"
  },
  "message": "Pago rechazado"
}
```

---

## 8. Reviews

Consulta de resenias del negocio. Las resenias se crean desde el flujo publico despues de una cita completada.

---

### GET `/api/v1/reviews`

Listar resenias del negocio con paginacion.

- **Auth:** JWT
- **Query params opcionales:**
  - `page` y `per_page` — paginacion

- **Response `200`:**

```json
{
  "data": [
    {
      "id": 1,
      "appointment_id": 1,
      "customer_id": 1,
      "business_id": 1,
      "employee_id": 1,
      "rating": 5,
      "comment": "Excelente servicio, muy recomendado",
      "created_at": "2026-03-10T11:00:00Z",
      "updated_at": "2026-03-10T11:00:00Z",
      "customer": {
        "id": 1,
        "name": "Juan Perez",
        "phone": "+573001112233"
      }
    },
    {
      "id": 2,
      "appointment_id": 3,
      "customer_id": 2,
      "business_id": 1,
      "employee_id": 2,
      "rating": 4,
      "comment": "Buen corte, pero hubo algo de espera",
      "created_at": "2026-03-12T16:00:00Z",
      "updated_at": "2026-03-12T16:00:00Z",
      "customer": {
        "id": 2,
        "name": "Pedro Gomez",
        "phone": "+573004445566"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 1,
    "total_count": 2,
    "per_page": 10
  }
}
```

---

## 9. Business Hours

Horarios de operacion del negocio. Cada dia de la semana tiene su horario.

---

### GET `/api/v1/business_hours`

Obtener todos los horarios de operacion del negocio (7 registros, uno por dia).

- **Auth:** JWT
- **Response `200`:**

```json
{
  "data": [
    {
      "id": 1,
      "business_id": 1,
      "day_of_week": 0,
      "open_time": "00:00",
      "close_time": "00:00",
      "closed": true,
      "created_at": "2026-03-01T10:00:00Z",
      "updated_at": "2026-03-01T10:00:00Z"
    },
    {
      "id": 2,
      "business_id": 1,
      "day_of_week": 1,
      "open_time": "08:00",
      "close_time": "19:00",
      "closed": false,
      "created_at": "2026-03-01T10:00:00Z",
      "updated_at": "2026-03-01T10:00:00Z"
    },
    {
      "id": 3,
      "business_id": 1,
      "day_of_week": 2,
      "open_time": "08:00",
      "close_time": "19:00",
      "closed": false,
      "created_at": "2026-03-01T10:00:00Z",
      "updated_at": "2026-03-01T10:00:00Z"
    },
    {
      "id": 4,
      "business_id": 1,
      "day_of_week": 3,
      "open_time": "08:00",
      "close_time": "19:00",
      "closed": false,
      "created_at": "2026-03-01T10:00:00Z",
      "updated_at": "2026-03-01T10:00:00Z"
    },
    {
      "id": 5,
      "business_id": 1,
      "day_of_week": 4,
      "open_time": "08:00",
      "close_time": "19:00",
      "closed": false,
      "created_at": "2026-03-01T10:00:00Z",
      "updated_at": "2026-03-01T10:00:00Z"
    },
    {
      "id": 6,
      "business_id": 1,
      "day_of_week": 5,
      "open_time": "08:00",
      "close_time": "19:00",
      "closed": false,
      "created_at": "2026-03-01T10:00:00Z",
      "updated_at": "2026-03-01T10:00:00Z"
    },
    {
      "id": 7,
      "business_id": 1,
      "day_of_week": 6,
      "open_time": "09:00",
      "close_time": "17:00",
      "closed": false,
      "created_at": "2026-03-01T10:00:00Z",
      "updated_at": "2026-03-01T10:00:00Z"
    }
  ]
}
```

> **Nota:** `day_of_week`: 0 = domingo, 1 = lunes, ..., 6 = sabado

---

### PUT `/api/v1/business_hours`

Actualizar todos los horarios de operacion de una vez (bulk update).

- **Auth:** JWT (owner/admin)
- **Request body:**

```json
{
  "business_hours": [
    { "day_of_week": 0, "open_time": "00:00", "close_time": "00:00", "closed": true },
    { "day_of_week": 1, "open_time": "08:00", "close_time": "20:00", "closed": false },
    { "day_of_week": 2, "open_time": "08:00", "close_time": "20:00", "closed": false },
    { "day_of_week": 3, "open_time": "08:00", "close_time": "20:00", "closed": false },
    { "day_of_week": 4, "open_time": "08:00", "close_time": "20:00", "closed": false },
    { "day_of_week": 5, "open_time": "08:00", "close_time": "20:00", "closed": false },
    { "day_of_week": 6, "open_time": "09:00", "close_time": "17:00", "closed": false }
  ]
}
```

- **Response `200`:**

```json
{
  "data": [
    {
      "id": 1,
      "business_id": 1,
      "day_of_week": 0,
      "open_time": "00:00",
      "close_time": "00:00",
      "closed": true,
      "created_at": "2026-03-01T10:00:00Z",
      "updated_at": "2026-03-16T16:00:00Z"
    }
  ],
  "message": "Horarios actualizados exitosamente"
}
```

---

## 10. Blocked Slots

CRUD de bloqueos manuales en la agenda (almuerzo, vacaciones, dia libre, etc.).

---

### GET `/api/v1/blocked_slots`

Listar todos los bloqueos del negocio.

- **Auth:** JWT
- **Query params opcionales:**
  - `employee_id` — filtrar por empleado
  - `date` — filtrar por fecha

- **Response `200`:**

```json
{
  "data": [
    {
      "id": 1,
      "business_id": 1,
      "employee_id": 1,
      "date": "2026-03-20",
      "start_time": "12:00",
      "end_time": "13:00",
      "reason": "Almuerzo",
      "all_day": false,
      "created_at": "2026-03-16T10:00:00Z",
      "updated_at": "2026-03-16T10:00:00Z"
    },
    {
      "id": 2,
      "business_id": 1,
      "employee_id": null,
      "date": "2026-03-25",
      "start_time": "00:00",
      "end_time": "23:59",
      "reason": "Dia festivo - negocio cerrado",
      "all_day": true,
      "created_at": "2026-03-16T10:00:00Z",
      "updated_at": "2026-03-16T10:00:00Z"
    }
  ]
}
```

---

### POST `/api/v1/blocked_slots`

Crear un nuevo bloqueo. Si `employee_id` es `null`, aplica a todo el negocio.

- **Auth:** JWT (owner/admin)
- **Request body:**

```json
{
  "employee_id": 1,
  "date": "2026-03-22",
  "start_time": "12:00",
  "end_time": "13:00",
  "reason": "Almuerzo",
  "all_day": false
}
```

- **Response `201`:**

```json
{
  "data": {
    "id": 3,
    "business_id": 1,
    "employee_id": 1,
    "date": "2026-03-22",
    "start_time": "12:00",
    "end_time": "13:00",
    "reason": "Almuerzo",
    "all_day": false,
    "created_at": "2026-03-16T16:30:00Z",
    "updated_at": "2026-03-16T16:30:00Z"
  }
}
```

---

### GET `/api/v1/blocked_slots/:id`

Obtener un bloqueo por ID.

- **Auth:** JWT
- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "business_id": 1,
    "employee_id": 1,
    "date": "2026-03-20",
    "start_time": "12:00",
    "end_time": "13:00",
    "reason": "Almuerzo",
    "all_day": false,
    "created_at": "2026-03-16T10:00:00Z",
    "updated_at": "2026-03-16T10:00:00Z"
  }
}
```

---

### PUT `/api/v1/blocked_slots/:id`

Actualizar un bloqueo existente.

- **Auth:** JWT (owner/admin)
- **Request body** (campos parciales permitidos):

```json
{
  "end_time": "14:00",
  "reason": "Almuerzo extendido"
}
```

- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "business_id": 1,
    "employee_id": 1,
    "date": "2026-03-20",
    "start_time": "12:00",
    "end_time": "14:00",
    "reason": "Almuerzo extendido",
    "all_day": false,
    "created_at": "2026-03-16T10:00:00Z",
    "updated_at": "2026-03-16T17:00:00Z"
  }
}
```

---

### DELETE `/api/v1/blocked_slots/:id`

Eliminar un bloqueo.

- **Auth:** JWT (owner/admin)
- **Response `204`:** Sin contenido

---

## 11. Reports

Endpoints de reportes y analiticas del negocio. Todos requieren autenticacion.

---

### GET `/api/v1/reports/summary`

Resumen general del negocio (dashboard principal).

- **Auth:** JWT
- **Query params opcionales:**
  - `period` — `today`, `week`, `month`, `year`
  - `start_date` y `end_date` — rango personalizado

- **Response `200`:**

```json
{
  "data": {
    "total_appointments": 128,
    "completed_appointments": 95,
    "cancelled_appointments": 12,
    "pending_appointments": 21,
    "total_revenue": 3250000,
    "total_customers": 67,
    "new_customers": 15,
    "average_rating": 4.6,
    "occupancy_rate": 74.5
  }
}
```

---

### GET `/api/v1/reports/revenue`

Reporte de ingresos desglosado por periodo.

- **Auth:** JWT
- **Query params opcionales:**
  - `period` — `day`, `week`, `month`
  - `start_date` y `end_date`

- **Response `200`:**

```json
{
  "data": [
    { "date": "2026-03-01", "revenue": 450000, "appointments_count": 18 },
    { "date": "2026-03-02", "revenue": 375000, "appointments_count": 15 },
    { "date": "2026-03-03", "revenue": 0, "appointments_count": 0 },
    { "date": "2026-03-04", "revenue": 525000, "appointments_count": 21 }
  ]
}
```

---

### GET `/api/v1/reports/top_services`

Servicios mas populares del negocio.

- **Auth:** JWT
- **Query params opcionales:**
  - `start_date` y `end_date`
  - `limit` — cantidad de resultados (default: 5)

- **Response `200`:**

```json
{
  "data": [
    { "service_id": 1, "service_name": "Corte clasico", "total_bookings": 45, "total_revenue": 1125000 },
    { "service_id": 3, "service_name": "Corte + Barba", "total_bookings": 32, "total_revenue": 1120000 },
    { "service_id": 2, "service_name": "Barba completa", "total_bookings": 28, "total_revenue": 420000 }
  ]
}
```

---

### GET `/api/v1/reports/top_employees`

Empleados con mejor rendimiento.

- **Auth:** JWT
- **Query params opcionales:**
  - `start_date` y `end_date`
  - `limit` — cantidad de resultados (default: 5)

- **Response `200`:**

```json
{
  "data": [
    { "employee_id": 1, "employee_name": "Miguel Torres", "total_appointments": 52, "total_revenue": 1560000, "average_rating": 4.8 },
    { "employee_id": 2, "employee_name": "Andres Lopez", "total_appointments": 43, "total_revenue": 1290000, "average_rating": 4.5 }
  ]
}
```

---

### GET `/api/v1/reports/frequent_customers`

Usuarios finales mas frecuentes del negocio.

- **Auth:** JWT
- **Query params opcionales:**
  - `start_date` y `end_date`
  - `limit` — cantidad de resultados (default: 10)

- **Response `200`:**

```json
{
  "data": [
    { "customer_id": 1, "customer_name": "Juan Perez", "total_visits": 8, "total_spent": 240000, "last_visit_at": "2026-03-14T10:00:00Z" },
    { "customer_id": 5, "customer_name": "Luis Rodriguez", "total_visits": 6, "total_spent": 210000, "last_visit_at": "2026-03-12T15:00:00Z" }
  ]
}
```

---

## 12. QR

Generacion de codigo QR del negocio para reservas.

---

### POST `/api/v1/qr/generate`

Generar o regenerar el codigo QR del negocio. El QR apunta a la pagina publica de reservas.

- **Auth:** JWT (owner/admin)
- **Request body:** Ninguno

- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "business_id": 1,
    "qr_url": "https://storage.agendity.com/qr/barberia-elite.png",
    "short_url": "https://agendity.com/barberia-elite",
    "scan_count": 0,
    "created_at": "2026-03-16T17:00:00Z",
    "updated_at": "2026-03-16T17:00:00Z"
  },
  "message": "Codigo QR generado exitosamente"
}
```

---

## 13. Notifications

Notificaciones in-app del negocio. Polling desde el frontend cada 30 segundos.

---

### GET `/api/v1/notifications`

Listar notificaciones del negocio con paginacion.

- **Auth:** JWT
- **Query params opcionales:**
  - `page` y `per_page` — paginacion (default: 20)

- **Response `200`:**

```json
{
  "data": [
    {
      "id": 1,
      "title": "Nueva reserva",
      "body": "Juan Perez reservo Corte clasico para el 17 de marzo a las 10:30",
      "notification_type": "new_booking",
      "link": "/dashboard/agenda",
      "read": false,
      "created_at": "2026-03-16T18:00:00Z"
    },
    {
      "id": 2,
      "title": "Comprobante de pago recibido",
      "body": "Juan Perez subio un comprobante para la cita #10",
      "notification_type": "payment_submitted",
      "link": "/dashboard/payments",
      "read": true,
      "created_at": "2026-03-16T17:30:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 2,
    "total_count": 25,
    "per_page": 20
  }
}
```

**Tipos de notificacion:**
- `new_booking` — Nueva reserva creada
- `payment_submitted` — Comprobante de pago subido
- `payment_approved` — Pago aprobado
- `booking_cancelled` — Cita cancelada
- `reminder` — Recordatorio

---

### GET `/api/v1/notifications/unread_count`

Obtener la cantidad de notificaciones no leidas (usado por la campanita en topbar).

- **Auth:** JWT
- **Response `200`:**

```json
{
  "data": {
    "unread_count": 3
  }
}
```

---

### POST `/api/v1/notifications/:id/mark_read`

Marcar una notificacion individual como leida.

- **Auth:** JWT
- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "title": "Nueva reserva",
    "body": "Juan Perez reservo Corte clasico para el 17 de marzo",
    "notification_type": "new_booking",
    "link": "/dashboard/agenda",
    "read": true,
    "created_at": "2026-03-16T18:00:00Z"
  }
}
```

---

### POST `/api/v1/notifications/mark_all_read`

Marcar todas las notificaciones del negocio como leidas.

- **Auth:** JWT
- **Response `200`:**

```json
{
  "data": {
    "message": "All notifications marked as read"
  }
}
```

---

## 14. Public (sin autenticacion)

Endpoints publicos para la experiencia del usuario final. No requieren JWT.

---

### GET `/api/v1/public/:slug`

Obtener informacion publica de un negocio por su slug.

- **Auth:** Publica
- **Response `200`:**

```json
{
  "data": {
    "id": 1,
    "name": "Barberia Elite",
    "slug": "barberia-elite",
    "description": "La mejor barberia de Barranquilla",
    "business_type": "barbershop",
    "phone": "+573001234567",
    "address": "Calle 84 #53-120, Local 2",
    "city": "Barranquilla",
    "state": "Atlantico",
    "country": "CO",
    "latitude": 10.9878,
    "longitude": -74.7889,
    "logo_url": "https://storage.agendity.com/logos/barberia-elite.png",
    "cover_url": "https://storage.agendity.com/covers/barberia-elite.jpg",
    "primary_color": "#1E3A5F",
    "secondary_color": "#F5A623",
    "currency": "COP",
    "timezone": "America/Bogota",
    "services": [
      {
        "id": 1,
        "name": "Corte clasico",
        "description": "Corte de cabello tradicional",
        "duration_minutes": 30,
        "price": 25000,
        "category": "cortes"
      },
      {
        "id": 2,
        "name": "Barba completa",
        "description": "Afeitado y perfilado de barba",
        "duration_minutes": 20,
        "price": 15000,
        "category": "barba"
      }
    ],
    "employees": [
      {
        "id": 1,
        "name": "Miguel Torres",
        "avatar_url": null,
        "bio": "Barbero con 10 anios de experiencia"
      },
      {
        "id": 2,
        "name": "Andres Lopez",
        "avatar_url": null,
        "bio": "Especialista en fades y disenos"
      }
    ],
    "business_hours": [
      { "day_of_week": 0, "open_time": "00:00", "close_time": "00:00", "closed": true },
      { "day_of_week": 1, "open_time": "08:00", "close_time": "19:00", "closed": false },
      { "day_of_week": 2, "open_time": "08:00", "close_time": "19:00", "closed": false },
      { "day_of_week": 3, "open_time": "08:00", "close_time": "19:00", "closed": false },
      { "day_of_week": 4, "open_time": "08:00", "close_time": "19:00", "closed": false },
      { "day_of_week": 5, "open_time": "08:00", "close_time": "19:00", "closed": false },
      { "day_of_week": 6, "open_time": "09:00", "close_time": "17:00", "closed": false }
    ]
  }
}
```

- **Response `404`:**

```json
{
  "error": "Negocio no encontrado"
}
```

---

### GET `/api/v1/public/:slug/availability`

Consultar disponibilidad de horarios para una fecha, servicio y empleado.

- **Auth:** Publica
- **Query params requeridos:**
  - `date` — fecha (`2026-03-17`)
  - `service_id` — ID del servicio
- **Query params opcionales:**
  - `employee_id` — filtrar por empleado (si no se envia, retorna todos)

- **Response `200`:**

```json
{
  "data": {
    "date": "2026-03-17",
    "service_id": 1,
    "available_slots": [
      {
        "employee_id": 1,
        "employee_name": "Miguel Torres",
        "slots": ["08:00", "08:30", "09:00", "09:30", "10:30", "11:00", "14:00", "14:30", "15:00"]
      },
      {
        "employee_id": 2,
        "employee_name": "Andres Lopez",
        "slots": ["08:00", "08:30", "09:00", "10:00", "10:30", "11:00", "11:30", "14:00", "15:30", "16:00"]
      }
    ]
  }
}
```

---

### POST `/api/v1/public/:slug/book`

Crear una reserva como usuario final (sin cuenta). Crea o reutiliza un customer por telefono+email.

- **Auth:** Publica
- **Request body:**

```json
{
  "service_id": 1,
  "employee_id": 1,
  "date": "2026-03-17",
  "start_time": "10:30",
  "customer_name": "Juan Perez",
  "customer_phone": "+573001112233",
  "customer_email": "juan@email.com",
  "notes": "Primera vez, me recomendaron el corte clasico"
}
```

- **Response `201`:**

```json
{
  "data": {
    "id": 10,
    "business_id": 1,
    "employee_id": 1,
    "service_id": 1,
    "customer_id": 1,
    "date": "2026-03-17",
    "start_time": "10:30",
    "end_time": "11:00",
    "status": "pending_payment",
    "price": 25000,
    "notes": "Primera vez, me recomendaron el corte clasico",
    "ticket_code": "AGF-20260317-E5F6",
    "created_at": "2026-03-16T18:00:00Z",
    "updated_at": "2026-03-16T18:00:00Z",
    "payment_info": {
      "nequi_phone": "+573001234567",
      "daviplata_phone": null,
      "bancolombia_account": null
    }
  },
  "message": "Reserva creada exitosamente. Realiza el pago para confirmar."
}
```

- **Response `422`:**

```json
{
  "error": "Error de validacion",
  "details": {
    "start_time": ["el horario ya no esta disponible"],
    "customer_phone": ["es obligatorio"]
  }
}
```

---

### GET `/api/v1/public/tickets/:code`

Obtener informacion de un ticket digital por su codigo. Usado para verificar citas y hacer check-in.

- **Auth:** Publica
- **Response `200`:**

```json
{
  "data": {
    "ticket_code": "AGF-20260317-E5F6",
    "status": "confirmed",
    "date": "2026-03-17",
    "start_time": "10:30",
    "end_time": "11:00",
    "business": {
      "name": "Barberia Elite",
      "address": "Calle 84 #53-120, Local 2",
      "phone": "+573001234567",
      "logo_url": "https://storage.agendity.com/logos/barberia-elite.png"
    },
    "service": {
      "name": "Corte clasico",
      "duration_minutes": 30,
      "price": 25000
    },
    "employee": {
      "name": "Miguel Torres"
    },
    "customer": {
      "name": "Juan Perez"
    }
  }
}
```

- **Response `404`:**

```json
{
  "error": "Ticket no encontrado"
}
```

---

### GET `/api/v1/public/explore`

Listar negocios activos para la pagina de exploracion. Soporta busqueda y filtros.

- **Auth:** Publica
- **Query params opcionales:**
  - `search` — buscar por nombre de negocio
  - `city` — filtrar por ciudad
  - `business_type` — filtrar por tipo (`barbershop`, `salon`, `spa`, `nails`, `other`)
  - `latitude` y `longitude` — ordenar por cercania
  - `page` y `per_page` — paginacion

- **Response `200`:**

```json
{
  "data": [
    {
      "id": 1,
      "name": "Barberia Elite",
      "slug": "barberia-elite",
      "description": "La mejor barberia de Barranquilla",
      "business_type": "barbershop",
      "address": "Calle 84 #53-120, Local 2",
      "city": "Barranquilla",
      "latitude": 10.9878,
      "longitude": -74.7889,
      "logo_url": "https://storage.agendity.com/logos/barberia-elite.png",
      "cover_url": "https://storage.agendity.com/covers/barberia-elite.jpg",
      "primary_color": "#1E3A5F"
    },
    {
      "id": 2,
      "name": "Salon Glamour",
      "slug": "salon-glamour",
      "description": "Salon de belleza con los mejores profesionales",
      "business_type": "salon",
      "address": "Carrera 51B #79-50",
      "city": "Barranquilla",
      "latitude": 10.9932,
      "longitude": -74.7920,
      "logo_url": "https://storage.agendity.com/logos/salon-glamour.png",
      "cover_url": null,
      "primary_color": "#8E44AD"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 3,
    "total_count": 24,
    "per_page": 10
  }
}
```

---

### GET `/api/v1/public/customer_lookup`

Buscar datos de un usuario final por email. Usado para precargar el formulario de reserva cuando el usuario ya ha reservado antes (persistencia de datos del cliente).

- **Auth:** Publica
- **Query params requeridos:**
  - `email` — correo electronico del usuario final

- **Response `200` (encontrado):**

```json
{
  "data": {
    "name": "Juan Perez",
    "phone": "+573001112233",
    "email": "juan@email.com"
  }
}
```

- **Response `404` (no encontrado):**

```json
{
  "error": "Cliente no encontrado"
}
```

> **Nota:** Este endpoint no requiere autenticacion. Solo devuelve nombre, telefono y email — datos minimos para precargar el formulario. No expone historial, IDs ni datos internos.

---

### GET `/api/v1/public/cities`

Obtener lista de ciudades con negocios activos registrados. Usado para el dropdown de ciudades en la pagina de exploracion.

- **Auth:** Publica
- **Response `200`:**

```json
{
  "data": [
    { "city": "Barranquilla", "business_count": 12 },
    { "city": "Bogota", "business_count": 5 },
    { "city": "Medellin", "business_count": 3 }
  ]
}
```

> **Nota:** Retorna ciudades distintas (`DISTINCT`) de negocios activos con onboarding completado, ordenadas por cantidad de negocios (descendente).

---

### POST `/api/v1/public/checkin_by_code`

Hacer check-in de una cita usando el codigo del ticket. Alternativa al endpoint `POST /api/v1/appointments/:id/checkin` que requiere JWT. Este endpoint permite check-in desde la pagina publica `/dashboard/checkin` usando solo el codigo.

- **Auth:** JWT (owner/admin/employee)
- **Request body:**

```json
{
  "code": "AGF-20260317-E5F6"
}
```

- **Response `200`:**

```json
{
  "data": {
    "id": 10,
    "status": "checked_in",
    "ticket_code": "AGF-20260317-E5F6",
    "customer": {
      "name": "Juan Perez"
    },
    "service": {
      "name": "Corte clasico"
    },
    "employee": {
      "name": "Miguel Torres"
    },
    "date": "2026-03-17",
    "start_time": "10:30",
    "end_time": "11:00"
  },
  "message": "Check-in registrado exitosamente"
}
```

- **Response `404`:**

```json
{
  "error": "Ticket no encontrado"
}
```

- **Response `422`:**

```json
{
  "error": "La cita no puede hacer check-in en su estado actual"
}
```

---

### POST `/api/v1/public/:slug/lock_slot`

Bloquear temporalmente un slot mientras el usuario final completa el formulario de reserva. El lock dura **5 minutos** y se auto-libera si expira.

- **Auth:** Publica
- **Request body:**

```json
{
  "employee_id": 1,
  "date": "2026-03-17",
  "time": "10:00"
}
```

- **Response `200`:**

```json
{
  "data": {
    "lock_token": "a1b2c3d4e5f6...",
    "expires_in": 300
  }
}
```

- **Response `409` (Conflict):**

```json
{
  "error": "Este horario esta siendo reservado por otra persona. Intenta con otro horario."
}
```

---

### POST `/api/v1/public/:slug/unlock_slot`

Liberar un slot bloqueado previamente (cuando el usuario cancela o vuelve atras). Solo el portador del `lock_token` puede liberar.

- **Auth:** Publica
- **Request body:**

```json
{
  "employee_id": 1,
  "date": "2026-03-17",
  "time": "10:00",
  "lock_token": "a1b2c3d4e5f6..."
}
```

- **Response `200`:**

```json
{
  "data": {
    "released": true
  }
}
```

---

### GET `/api/v1/public/:slug/check_slot`

Verificar disponibilidad de un slot justo antes de confirmar la reserva (ultima validacion).

- **Auth:** Publica
- **Query params requeridos:**
  - `employee_id` — ID del empleado
  - `date` — fecha (`2026-03-17`)
  - `time` — hora (`10:00`)
  - `service_id` — ID del servicio

- **Response `200`:**

```json
{
  "data": {
    "available": true
  }
}
```

- **Response `200` (no disponible):**

```json
{
  "data": {
    "available": false,
    "reason": "El empleado no tiene disponibilidad en esa fecha"
  }
}
```

---

## Resumen de endpoints

| # | Metodo | Endpoint | Auth | Descripcion |
|---|--------|----------|------|-------------|
| 1 | POST | `/api/v1/auth/login` | Publica | Iniciar sesion |
| 2 | POST | `/api/v1/auth/register` | Publica | Registrar usuario |
| 3 | POST | `/api/v1/auth/refresh` | Publica | Renovar token |
| 4 | GET | `/api/v1/auth/me` | JWT | Obtener usuario actual |
| 5 | DELETE | `/api/v1/auth/logout` | JWT | Cerrar sesion |
| 6 | GET | `/api/v1/business` | JWT | Obtener negocio actual |
| 7 | PUT | `/api/v1/business` | JWT | Actualizar negocio |
| 8 | POST | `/api/v1/business/onboarding` | JWT | Completar onboarding |
| 9 | POST | `/api/v1/business/upload_logo` | JWT | Subir logo (multipart) |
| 10 | GET | `/api/v1/services` | JWT | Listar servicios |
| 11 | POST | `/api/v1/services` | JWT | Crear servicio |
| 12 | GET | `/api/v1/services/:id` | JWT | Ver servicio |
| 13 | PUT | `/api/v1/services/:id` | JWT | Actualizar servicio |
| 14 | DELETE | `/api/v1/services/:id` | JWT | Eliminar servicio |
| 15 | GET | `/api/v1/employees` | JWT | Listar empleados |
| 16 | POST | `/api/v1/employees` | JWT | Crear empleado |
| 17 | GET | `/api/v1/employees/:id` | JWT | Ver empleado |
| 18 | PUT | `/api/v1/employees/:id` | JWT | Actualizar empleado |
| 19 | DELETE | `/api/v1/employees/:id` | JWT | Eliminar empleado |
| 20 | GET | `/api/v1/appointments` | JWT | Listar citas |
| 21 | POST | `/api/v1/appointments` | JWT | Crear cita |
| 22 | GET | `/api/v1/appointments/:id` | JWT | Ver cita |
| 23 | PUT | `/api/v1/appointments/:id` | JWT | Actualizar cita |
| 24 | DELETE | `/api/v1/appointments/:id` | JWT | Eliminar cita |
| 25 | POST | `/api/v1/appointments/:id/confirm` | JWT | Confirmar cita |
| 26 | POST | `/api/v1/appointments/:id/checkin` | JWT | Check-in cita |
| 27 | POST | `/api/v1/appointments/:id/cancel` | JWT | Cancelar cita |
| 28 | POST | `/api/v1/appointments/:id/complete` | JWT | Completar cita |
| 29 | GET | `/api/v1/customers` | JWT | Listar usuarios finales |
| 30 | GET | `/api/v1/customers/:id` | JWT | Ver usuario final |
| 31 | POST | `/api/v1/appointments/:id/payments/submit` | JWT/Publica | Enviar comprobante |
| 32 | POST | `/api/v1/payments/:id/approve` | JWT | Aprobar pago |
| 33 | POST | `/api/v1/payments/:id/reject` | JWT | Rechazar pago |
| 34 | GET | `/api/v1/reviews` | JWT | Listar resenias |
| 35 | GET | `/api/v1/business_hours` | JWT | Ver horarios |
| 36 | PUT | `/api/v1/business_hours` | JWT | Actualizar horarios |
| 37 | GET | `/api/v1/blocked_slots` | JWT | Listar bloqueos |
| 38 | POST | `/api/v1/blocked_slots` | JWT | Crear bloqueo |
| 39 | GET | `/api/v1/blocked_slots/:id` | JWT | Ver bloqueo |
| 40 | PUT | `/api/v1/blocked_slots/:id` | JWT | Actualizar bloqueo |
| 41 | DELETE | `/api/v1/blocked_slots/:id` | JWT | Eliminar bloqueo |
| 42 | GET | `/api/v1/reports/summary` | JWT | Resumen general |
| 43 | GET | `/api/v1/reports/revenue` | JWT | Reporte ingresos |
| 44 | GET | `/api/v1/reports/top_services` | JWT | Top servicios |
| 45 | GET | `/api/v1/reports/top_employees` | JWT | Top empleados |
| 46 | GET | `/api/v1/reports/frequent_customers` | JWT | Usuarios frecuentes |
| 47 | POST | `/api/v1/qr/generate` | JWT | Generar QR |
| 48 | GET | `/api/v1/notifications` | JWT | Listar notificaciones |
| 49 | GET | `/api/v1/notifications/unread_count` | JWT | Contar no leidas |
| 50 | POST | `/api/v1/notifications/:id/mark_read` | JWT | Marcar como leida |
| 51 | POST | `/api/v1/notifications/mark_all_read` | JWT | Marcar todas como leidas |
| 52 | GET | `/api/v1/public/:slug` | Publica | Ver negocio publico |
| 53 | GET | `/api/v1/public/:slug/availability` | Publica | Consultar disponibilidad |
| 54 | POST | `/api/v1/public/:slug/book` | Publica | Crear reserva publica |
| 55 | POST | `/api/v1/public/:slug/lock_slot` | Publica | Bloquear slot temporalmente (5 min) |
| 56 | POST | `/api/v1/public/:slug/unlock_slot` | Publica | Liberar slot bloqueado |
| 57 | GET | `/api/v1/public/:slug/check_slot` | Publica | Verificar disponibilidad de slot |
| 58 | GET | `/api/v1/public/tickets/:code` | Publica | Ver ticket digital |
| 59 | GET | `/api/v1/public/explore` | Publica | Explorar negocios |
| 60 | GET | `/api/v1/public/customer_lookup` | Publica | Buscar datos de usuario final por email |
| 61 | GET | `/api/v1/public/cities` | Publica | Listar ciudades con negocios activos |
| 62 | POST | `/api/v1/public/checkin_by_code` | JWT | Check-in por codigo de ticket |
