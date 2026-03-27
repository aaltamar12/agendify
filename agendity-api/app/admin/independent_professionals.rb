# frozen_string_literal: true

ActiveAdmin.register_page "Independent Professionals" do
  menu parent: "Negocios", priority: 2, label: "Profesionales Independientes"

  content do
    # Show list of existing independent professionals
    panel "Profesionales Independientes Existentes" do
      table_for Business.independent.includes(:owner).order(created_at: :desc) do
        column(:id) { |b| link_to b.id, admin_business_path(b) }
        column :name
        column :slug
        column(:owner) { |b| link_to b.owner.name, admin_user_path(b.owner) }
        column(:status) do |b|
          color = case b.status
                  when "active" then "#22c55e"
                  when "suspended" then "#eab308"
                  when "inactive" then "#ef4444"
                  end
          status_tag(b.status.capitalize, class: "", style: "background: #{color}; color: white; border-radius: 9999px; padding: 2px 10px; font-size: 11px;")
        end
        column(:employee) { |b| b.employees.first&.name || "N/A" }
        column :created_at
      end
    end

    panel "Crear Profesional Independiente" do
      active_admin_form_for(:independent_professional, url: admin_independent_professionals_create_path, method: :post) do |f|
        f.inputs "Datos del profesional" do
          f.input :name, label: "Nombre completo", required: true
          f.input :email, label: "Email", required: true
          f.input :phone, label: "Teléfono"
          f.input :document_type, label: "Tipo de documento", as: :select,
            collection: [["CC", "CC"], ["CE", "CE"], ["Pasaporte", "passport"]],
            include_blank: "Seleccionar..."
          f.input :document_number, label: "Número de documento"
          f.input :fiscal_address, label: "Dirección fiscal"
          f.input :business_type, label: "Tipo de negocio", as: :select,
            collection: Business.business_types.keys.map { |k| [k.capitalize, k] },
            selected: "barbershop"
        end
        f.actions do
          f.action :submit, label: "Crear Profesional", button_html: { style: "background: #8b5cf6; border: none; color: white; padding: 10px 20px; border-radius: 6px; cursor: pointer;" }
          f.action :cancel, label: "Cancelar", wrapper_html: { class: "cancel" }
        end
      end
    end

    # Show recently created setup links
    if flash[:setup_link].present?
      panel "Link de Configuración Generado" do
        div style: "padding: 20px; background: #f0fdf4; border: 1px solid #86efac; border-radius: 8px;" do
          para strong("El profesional independiente fue creado exitosamente.")
          para "Link de configuración (compartir con el profesional):"
          div style: "margin: 10px 0; padding: 10px; background: white; border: 1px solid #d1d5db; border-radius: 4px; font-family: monospace; word-break: break-all;" do
            text_node flash[:setup_link]
          end
          para strong("Credenciales temporales:")
          ul do
            li "Email: #{flash[:created_email]}"
            li "Password: #{flash[:temp_password]}"
          end
          para em("Importante: el profesional debe cambiar su contraseña al iniciar sesión.")
        end
      end
    end
  end

  page_action :create, method: :post do
    name = params[:independent_professional][:name]
    email = params[:independent_professional][:email]
    phone = params[:independent_professional][:phone]
    document_type = params[:independent_professional][:document_type]
    document_number = params[:independent_professional][:document_number]
    fiscal_address = params[:independent_professional][:fiscal_address]
    business_type = params[:independent_professional][:business_type] || "barbershop"

    temp_password = SecureRandom.hex(6) # 12 char random password

    ActiveRecord::Base.transaction do
      # 1. Create user with role :owner
      user = User.create!(
        name: name,
        email: email,
        phone: phone,
        password: temp_password,
        role: :owner
      )

      # 2. Create business with independent: true
      business = Business.create!(
        owner: user,
        name: name,
        business_type: business_type,
        independent: true,
        status: :active,
        onboarding_completed: false,
        timezone: "America/Bogota",
        currency: "COP",
        country: "CO",
        cancellation_policy_pct: 0,
        cancellation_deadline_hours: 24,
        trial_ends_at: 30.days.from_now
      )

      # 3. Create employee (the professional themselves)
      Employee.create!(
        business: business,
        user: user,
        name: name,
        phone: phone,
        email: email,
        document_type: document_type,
        document_number: document_number,
        fiscal_address: fiscal_address,
        active: true
      )

      # 4. Create trial subscription
      plan = Plan.find_by(name: "Básico") || Plan.first
      Subscription.create!(
        business: business,
        plan: plan,
        status: :active,
        start_date: Date.current,
        end_date: Date.current + 30.days
      )

      # Generate setup link
      setup_link = "#{ENV.fetch('FRONTEND_URL', 'https://agendity.com')}/login"

      flash[:setup_link] = setup_link
      flash[:created_email] = email
      flash[:temp_password] = temp_password
    end

    redirect_to admin_independent_professionals_path, notice: "Profesional independiente '#{name}' creado exitosamente."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_independent_professionals_path, alert: "Error al crear: #{e.message}"
  end
end
