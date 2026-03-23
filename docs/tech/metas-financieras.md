# Metas Financieras (Business Goals)

## Descripcion

Sistema de metas financieras disponible exclusivamente en el **Plan Inteligente**. Permite al negocio establecer objetivos de ingresos y ver el progreso en tiempo real.

## Tipos de meta

| Tipo | Descripcion |
|------|------------|
| `monthly_revenue` | Meta de ingresos mensuales |
| `break_even` | Punto de equilibrio (costos fijos vs ingresos) |
| `daily_average` | Promedio de ingresos diarios |
| `custom` | Meta personalizada con nombre libre |

## Modelo

```ruby
# app/models/business_goal.rb
class BusinessGoal < ApplicationRecord
  belongs_to :business

  # Campos: goal_type, target_value, period (YYYY-MM), name, description
end
```

## Endpoints

```
GET    /api/v1/goals           # Listar metas del negocio
POST   /api/v1/goals           # Crear meta
DELETE /api/v1/goals/:id       # Eliminar meta
GET    /api/v1/goals/progress  # Progreso de todas las metas
```

## Respuesta de progreso

```json
{
  "data": [
    {
      "id": 1,
      "goal_type": "monthly_revenue",
      "target_value": 5000000,
      "current_value": 3200000,
      "percentage": 64,
      "remaining": 1800000,
      "period": "2026-03",
      "suggestion": "Necesitas $1.800.000 mas para cumplir tu meta. Faltan 8 dias."
    }
  ]
}
```

## Plan restriction

Solo `Plan Inteligente` (`ai_features: true`). Basico y Profesional ven upgrade banner.

## Frontend

- Pagina: `/dashboard/goals`
- Hook: `src/lib/hooks/use-goals.ts` (no existe aun, usa fetch directo)

## Archivos clave

- `app/models/business_goal.rb`
- `app/controllers/api/v1/goals_controller.rb`
- `app/services/goals/progress_service.rb`
- `agendity-web/src/app/dashboard/goals/page.tsx`
