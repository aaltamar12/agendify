# Reportes y Ganancias Netas — Agendity

> Ultima actualizacion: 2026-03-22

## Resumen

El sistema de reportes incluye metricas basicas (todos los planes) y avanzadas (Profesional+). El reporte de ganancias netas cruza datos de citas, cierres de caja, creditos y penalizaciones para dar una vision completa de la salud financiera del negocio.

---

## Endpoints de reportes

| Endpoint | Plan | Descripcion |
|---|---|---|
| GET /api/v1/reports/summary | Todos | Revenue, appointments, customers, rating |
| GET /api/v1/reports/revenue?period=month | Todos | Ingresos agrupados por fecha |
| GET /api/v1/reports/top_services | Todos | Top 10 servicios por citas |
| GET /api/v1/reports/top_employees | Todos | Top 10 empleados por citas |
| GET /api/v1/reports/frequent_customers | Todos | Top 20 clientes frecuentes |
| GET /api/v1/reports/profit?period=month | **Profesional+** | Ganancias netas con desglose completo |

---

## Reporte de ganancias (GET /api/v1/reports/profit)

### Calculo

```
revenue             = SUM(price) de citas checked_in + completed
penalty_income      = SUM(price * cancellation_policy_pct / 100) de citas canceladas por cliente
total_income        = revenue + penalty_income
employee_payments   = SUM(amount_paid) de pagos en cierres de caja
net_profit          = total_income - employee_payments
```

### Ejemplo

```bash
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3001/api/v1/reports/profit?period=month"
```

**Respuesta:**
```json
{
  "data": {
    "period": "month",
    "from_date": "2026-02-22",
    "revenue": 1250000.0,
    "penalty_income": 45000.0,
    "total_income": 1295000.0,
    "employee_payments": 380000.0,
    "net_profit": 915000.0,
    "credits_issued": 62500.0,
    "credits_redeemed": 15000.0,
    "cash_register_closes": 22,
    "pending_employee_debt": 8500.0,
    "total_credits_in_circulation": 47500.0
  }
}
```

### Campos

| Campo | Descripcion |
|---|---|
| `revenue` | Ingresos por citas completadas/en atencion |
| `penalty_income` | **Retencion por cancelaciones** — % que el negocio se queda cuando un cliente cancela tarde |
| `total_income` | revenue + penalty_income |
| `employee_payments` | Total pagado a empleados en cierres de caja |
| `net_profit` | total_income - employee_payments |
| `credits_issued` | Cashback + reembolsos otorgados como creditos |
| `credits_redeemed` | Creditos usados por clientes en reservas |
| `cash_register_closes` | Cantidad de cierres de caja en el periodo |
| `pending_employee_debt` | Deuda total pendiente con empleados |
| `total_credits_in_circulation` | Saldo total de creditos de todos los clientes |

### Penalty income — por que importa

Cuando un cliente cancela despues del deadline, el negocio retiene un % del precio (segun `cancellation_policy_pct`). Este ingreso **no aparecia** en reportes antes porque las citas canceladas se excluian de todo calculo.

Ahora se calcula como:
```sql
SUM(price * cancellation_policy_pct / 100)
WHERE status = 'cancelled' AND cancelled_by != 'business'
```

Solo cuenta cancelaciones del cliente, no del negocio.

---

## Indicador de reconciliacion en reportes

Para negocios con **Plan Inteligente**, la pagina de reportes ejecuta automaticamente una verificacion de consistencia al cargar. Muestra:

- **Verde "Datos verificados"** — saldos de empleados y creditos cuadran
- **Rojo "Datos inconsistentes"** — link a /dashboard/reconciliation para corregir

---

## Validacion de consistencia en cierre de caja

Antes de cerrar caja, `CloseService` ejecuta `ReconciliationService`:

```ruby
recon = CashRegister::ReconciliationService.call(business: @business)
if recon.data.any?
  return failure("Hay inconsistencias en saldos de empleados (#{names})...")
end
```

Si hay discrepancias → **el cierre se rechaza**. El negocio debe resolver via reconciliacion primero.

---

## Panel financiero en ActiveAdmin

El SuperAdmin tiene 4 recursos bajo el menu **"Finanzas"**:

### Cuentas de Credito
- Lista: negocio, cliente, balance, cantidad de transacciones
- Detalle: historial completo de transacciones
- **Panel de verificacion:** compara balance vs suma de transacciones, marca discrepancias

### Transacciones de Credito
- Lista filtrable por tipo (cashback, refund, adjustment, redemption)
- Links a citas relacionadas

### Cierres de Caja
- Lista por negocio y fecha
- Detalle: tabla de pagos por empleado (comision, adeudado, pagado, deuda)
- **Resumen:** ingresos - pagos = ganancia neta del dia

### Pagos a Empleados
- Lista detallada con comprobantes adjuntos
- Filtrable por metodo de pago

---

## Bloqueo de dias cerrados (Etapa 8)

### Backend

`CreateAppointmentService` valida que el dia no este cerrado:

```ruby
def day_closed?
  date = @params[:appointment_date]
  parsed_date = date.is_a?(String) ? Date.parse(date) : date
  bh = @business.business_hours.find_by(day_of_week: parsed_date.wday)
  bh.nil? || bh.closed?
end
```

Si el dia esta cerrado → retorna error "El negocio no opera este dia."

`AvailabilityService` ya retornaba slots vacios para dias cerrados (existente).

### Frontend

- Date picker en modal de nueva cita valida contra dias cerrados
- Muestra error si se selecciona un dia cerrado
- Hint debajo del date picker lista los dias cerrados del negocio
- Tarifas dinamicas: selector de dias deshabilita dias cerrados
