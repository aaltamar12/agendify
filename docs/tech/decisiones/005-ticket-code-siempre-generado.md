# ADR 005 — ticket_code siempre generado (independiente del plan)

> **Fecha:** 2026-03-16
> **Estado:** Aceptada
> **Contexto:** El `ticket_code` se usaba originalmente solo para el ticket digital VIP (Pro+), pero se necesita como identificador universal de citas

## Problema

El `ticket_code` se generaba condicionalmente segun el plan del negocio. Solo los negocios con plan Profesional+ recibian un codigo de ticket. Esto causaba problemas porque:

1. **Check-in:** El negocio necesita un codigo para verificar la llegada del cliente, independientemente del plan.
2. **Pagos:** El codigo identifica la cita en el flujo de comprobantes y aprobacion.
3. **Busqueda:** El superadmin y el negocio necesitan buscar citas por codigo.
4. **Soporte:** Sin codigo, no hay forma rapida de referenciar una cita especifica.

## Decision

El `ticket_code` se genera **siempre** al crear la cita en `CreateAppointmentService`, sin importar el plan del negocio.

Lo que se restringe por plan (Pro+) es la **visualizacion VIP del ticket**:
- Diseno premium estilo boarding pass
- Codigo QR para check-in
- Descarga como imagen PNG
- Opcion de compartir (Web Share API)

Para plan Basico, el usuario ve una version simplificada del ticket con los datos de la cita y el codigo, pero sin el diseno VIP.

### Implementacion

```ruby
# app/services/appointments/create_appointment_service.rb
appointment = @business.appointments.create!(
  # ... otros campos ...
  ticket_code: generate_ticket_code  # SIEMPRE se genera
)
```

```ruby
def generate_ticket_code
  loop do
    code = SecureRandom.hex(6).upcase
    return code unless Appointment.exists?(ticket_code: code)
  end
end
```

## Alternativas consideradas

### Generar ticket_code solo para Pro+

- **Rechazada:** Rompe el flujo de check-in y pagos para negocios Basico. El codigo es un identificador operativo, no una feature premium.

### Usar el ID de la cita como identificador

- **Rechazada:** IDs secuenciales son predecibles y no son user-friendly para comunicar por telefono o WhatsApp.

## Consecuencias

### Positivas

- **Identificador universal:** Cada cita tiene un codigo unico desde el momento de creacion.
- **Check-in funcional para todos:** Cualquier negocio puede verificar clientes por codigo.
- **Busqueda por codigo:** Funciona en ActiveAdmin y en los endpoints de la API.
- **Separacion clara:** El codigo es operativo; el ticket VIP es visual/premium.

### Negativas

- **Ninguna significativa:** Generar un hex de 6 bytes es trivial en costo computacional.

## Archivos relevantes

- `agendify-api/app/services/appointments/create_appointment_service.rb` — Genera `ticket_code` siempre
- `agendify-api/app/models/appointment.rb` — Modelo con campo `ticket_code`
- `agendify-web` — Componente de ticket con vista condicional por plan (VIP vs simplificada)
