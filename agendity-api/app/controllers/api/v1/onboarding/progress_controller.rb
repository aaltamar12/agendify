# frozen_string_literal: true

module Api
  module V1
    module Onboarding
      class ProgressController < BaseController
        # GET /api/v1/onboarding/progress
        def show
          business = current_business

          steps = [
            {
              key: "profile",
              label: "Completa el perfil de tu negocio",
              completed: business.name.present? && business.phone.present? && business.address.present?,
              link: "/dashboard/settings"
            },
            {
              key: "hours",
              label: "Configura tus horarios",
              completed: business.business_hours.where(closed: false).exists?,
              link: "/dashboard/settings"
            },
            {
              key: "services",
              label: "Crea al menos un servicio",
              completed: business.services.where(active: true).exists?,
              link: "/dashboard/services"
            },
            {
              key: "employees",
              label: "Agrega al menos un empleado",
              completed: business.employees.where(active: true).exists?,
              link: "/dashboard/employees"
            },
            {
              key: "employee_services",
              label: "Asigna servicios a tus empleados",
              completed: EmployeeService.joins(:employee).where(employees: { business_id: business.id, active: true }).exists?,
              link: "/dashboard/employees"
            },
            {
              key: "payment_methods",
              label: "Configura tus métodos de pago",
              completed: business.nequi_phone.present? || business.daviplata_phone.present? || business.bancolombia_account.present? || business.breb_key.present?,
              link: "/dashboard/settings"
            }
          ]

          completed_count = steps.count { |s| s[:completed] }

          render_success({
            completed: completed_count,
            total: steps.size,
            all_complete: completed_count == steps.size,
            steps: steps
          })
        end
      end
    end
  end
end
