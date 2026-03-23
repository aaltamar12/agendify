# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: "Dashboard"

  content title: "Dashboard — Agendity" do
    # CDN scripts for Chartkick (ActiveAdmin uses Sprockets, CDN is simplest)
    text_node '<script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>'.html_safe
    text_node '<script src="https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3"></script>'.html_safe
    text_node '<script src="https://cdn.jsdelivr.net/npm/chartkick@5"></script>'.html_safe

    # -- Summary cards --
    columns do
      column do
        panel "Negocios Activos" do
          h2 Business.active.count, style: "font-size: 2.5em; color: #7C3AED; margin: 0;"
          para "#{Business.where('created_at > ?', 7.days.ago).count} nuevos esta semana"
        end
      end
      column do
        panel "Citas del Mes" do
          h2 Appointment.where("created_at > ?", 30.days.ago).count, style: "font-size: 2.5em; color: #10B981; margin: 0;"
          para "#{Appointment.where('created_at > ?', 7.days.ago).count} esta semana"
        end
      end
      column do
        panel "Ingresos del Mes" do
          total = Payment.where(status: :approved).where("approved_at >= ?", 30.days.ago).sum(:amount)
          h2 "$#{number_with_delimiter(total.to_i)}", style: "font-size: 2.5em; color: #F59E0B; margin: 0;"
          para "COP — últimos 30 días"
        end
      end
      column do
        panel "Usuarios Registrados" do
          h2 User.count, style: "font-size: 2.5em; color: #3B82F6; margin: 0;"
          para "#{User.where('created_at > ?', 7.days.ago).count} nuevos esta semana"
        end
      end
    end

    # -- Charts row 1: Citas & Ingresos por día --
    columns do
      column do
        panel "Citas por día (últimos 30 días)" do
          data = Appointment.where("created_at > ?", 30.days.ago)
            .group_by_day(:created_at)
            .count
          line_chart data, colors: ["#7C3AED"], library: { scales: { y: { beginAtZero: true } } }
        end
      end
      column do
        panel "Ingresos por día (últimos 30 días)" do
          data = Payment.where(status: :approved).where("approved_at > ?", 30.days.ago)
            .group_by_day(:approved_at)
            .sum(:amount)
          area_chart data, colors: ["#10B981"], prefix: "$", library: { scales: { y: { beginAtZero: true } } }
        end
      end
    end

    # -- Charts row 2: Status & types --
    columns do
      column do
        panel "Citas por estado" do
          data = Appointment.group(:status).count
          pie_chart data, colors: ["#F59E0B", "#3B82F6", "#10B981", "#7C3AED", "#EF4444", "#6B7280"], donut: true
        end
      end
      column do
        panel "Negocios por tipo" do
          data = Business.group(:business_type).count
          pie_chart data, colors: ["#7C3AED", "#EC4899", "#14B8A6", "#F97316", "#6B7280"]
        end
      end
      column do
        panel "Top 5 negocios por citas" do
          data = Business.joins(:appointments)
            .group("businesses.name")
            .order("count_all DESC")
            .limit(5)
            .count
          bar_chart data, colors: ["#7C3AED"]
        end
      end
    end

    # -- Charts row 3: Registros & Suscripciones --
    columns do
      column do
        panel "Nuevos negocios por semana (últimos 3 meses)" do
          data = Business.where("created_at > ?", 3.months.ago)
            .group_by_week(:created_at)
            .count
          column_chart data, colors: ["#3B82F6"]
        end
      end
      column do
        panel "Suscripciones por plan" do
          data = Subscription.joins(:plan)
            .where(status: :active)
            .group("plans.name")
            .count
          pie_chart data, colors: ["#6B7280", "#7C3AED", "#F59E0B"], donut: true
        end
      end
    end

    # -- Request volume (kept from original) --
    columns do
      column do
        panel "Request Volume (Last 24h)" do
          total_24h = RequestLog.where("created_at >= ?", 24.hours.ago).count
          errors_24h = RequestLog.errors.where("created_at >= ?", 24.hours.ago).count
          server_errors_24h = RequestLog.server_errors.where("created_at >= ?", 24.hours.ago).count
          avg_duration = RequestLog.where("created_at >= ?", 24.hours.ago).average(:duration_ms)&.round(1) || 0

          ul do
            li "Total Requests: #{total_24h}"
            li "Client Errors (4xx): #{errors_24h - server_errors_24h}"
            li "Server Errors (5xx): #{server_errors_24h}"
            li "Avg Duration: #{avg_duration}ms"
          end
        end
      end
    end

    # -- Recent activity tables --
    columns do
      column do
        panel "Últimas reservas" do
          table_for Appointment.includes(:business, :customer, :service).order(created_at: :desc).limit(10) do
            column(:business) { |a| link_to a.business.name, admin_business_path(a.business) }
            column("Cliente") { |a| a.customer&.name }
            column("Servicio") { |a| a.service&.name }
            column :status
            column :created_at
          end
        end
      end
      column do
        panel "Errores recientes (5xx)" do
          table_for RequestLog.server_errors.recent.includes(:business).limit(10) do
            column(:id) { |log| link_to log.id, admin_request_log_path(log) }
            column(:business) { |log| log.business&.name || "N/A" }
            column(:path) { |log| truncate(log.path, length: 40) }
            column("Error") { |log| truncate(log.error_message.to_s, length: 50) }
            column :created_at
          end
        end
      end
    end

    # -- Recent signups (kept from original) --
    columns do
      column do
        panel "Negocios registrados (últimos 7 días)" do
          table_for Business.includes(:owner).order(created_at: :desc).where("created_at >= ?", 7.days.ago).limit(10) do
            column(:name) { |b| link_to b.name, admin_business_path(b) }
            column :business_type
            column :city
            column :status
            column :created_at
          end
        end
      end
    end
  end
end
