# frozen_string_literal: true

# Seed data for Agendify — realistic demo simulating barbershops and salons in Barranquilla.
# Run with: rails db:seed
# Idempotent: safe to run multiple times.

puts "=" * 60
puts "🌱 Seeding Agendify database..."
puts "=" * 60

# ============================================================================
# 1. PLANS
# ============================================================================
puts "\n📋 Creating plans..."

plan_basico = Plan.find_or_create_by!(name: "Básico") do |p|
  p.price_monthly = 30_000
  p.max_employees = 3
  p.max_services = 5
  p.max_reservations_month = nil
  p.max_customers = nil
  p.ai_features = false
  p.ticket_digital = false
  p.advanced_reports = false
  p.brand_customization = false
  p.featured_listing = false
  p.priority_support = false
end

plan_profesional = Plan.find_or_create_by!(name: "Profesional") do |p|
  p.price_monthly = 59_900
  p.max_employees = 10
  p.max_services = nil # unlimited
  p.max_reservations_month = nil
  p.max_customers = nil
  p.ai_features = false
  p.ticket_digital = true
  p.advanced_reports = true
  p.brand_customization = true
  p.featured_listing = true
  p.priority_support = false
end

plan_inteligente = Plan.find_or_create_by!(name: "Inteligente") do |p|
  p.price_monthly = 99_900
  p.max_employees = nil # unlimited
  p.max_services = nil
  p.max_reservations_month = nil
  p.max_customers = nil
  p.ai_features = true
  p.ticket_digital = true
  p.advanced_reports = true
  p.brand_customization = true
  p.featured_listing = true
  p.priority_support = true
end

puts "  ✅ Plans: #{Plan.count} (Básico, Profesional, Inteligente)"

# ============================================================================
# 2. ADMIN USER
# ============================================================================
puts "\n👤 Creating admin user..."

admin = User.find_or_create_by!(email: "admin@agendify.com") do |u|
  u.name = "Admin Agendify"
  u.password = "password123"
  u.role = :admin
end

puts "  ✅ Admin: #{admin.email}"

# ============================================================================
# 3. BUSINESS 1 — Barbería Elite (main demo)
# ============================================================================
puts "\n💈 Creating Business 1: Barbería Elite..."

carlos_user = User.find_or_create_by!(email: "carlos@barberia-elite.com") do |u|
  u.name = "Carlos Méndez"
  u.password = "password123"
  u.role = :owner
  u.phone = "+573001234567"
end

barberia_elite = Business.find_or_create_by!(slug: "barberia-elite") do |b|
  b.owner = carlos_user
  b.name = "Barbería Elite"
  b.business_type = :barbershop
  b.description = "La mejor barbería de Barranquilla. Cortes clásicos y modernos con los mejores profesionales."
  b.phone = "+573001234567"
  b.email = "info@barberia-elite.com"
  b.address = "Calle 84 #53-120"
  b.city = "Barranquilla"
  b.state = "ATL"
  b.country = "CO"
  b.timezone = "America/Bogota"
  b.currency = "COP"
  b.payment_instructions = "Puedes pagar por Nequi, Daviplata o transferencia Bancolombia."
  b.nequi_phone = "+573001234567"
  b.daviplata_phone = "+573001234567"
  b.bancolombia_account = "12345678901"
  b.cancellation_policy_pct = 50
  b.cancellation_deadline_hours = 24
  b.trial_ends_at = 30.days.from_now
  b.status = :active
  b.onboarding_completed = true
  b.primary_color = "#6C3BF5"
  b.secondary_color = "#1A1A2E"
  b.instagram_url = "https://instagram.com/barberiaelite"
  b.latitude = 10.9878
  b.longitude = -74.7889
  b.lunch_enabled = true
  b.lunch_start_time = "12:00"
  b.lunch_end_time = "13:00"
  b.slot_interval_minutes = 30
  b.gap_between_appointments_minutes = 5
end

puts "  ✅ Barbería Elite created (owner: #{carlos_user.email})"

# --- Business Hours (Mon-Sat 8:00-19:00, Sun closed) ---
puts "  📅 Creating business hours..."

# day_of_week: 0=Sunday, 1=Monday, ..., 6=Saturday
(0..6).each do |day|
  BusinessHour.find_or_create_by!(business: barberia_elite, day_of_week: day) do |bh|
    if day == 0 # Sunday
      bh.open_time = "08:00"
      bh.close_time = "19:00"
      bh.closed = true
    else
      bh.open_time = "08:00"
      bh.close_time = "19:00"
      bh.closed = false
    end
  end
end

puts "  ✅ Business hours: Mon-Sat 8:00-19:00, Sun closed"

# --- Services ---
puts "  ✂️ Creating services..."

services_data = [
  { name: "Corte clásico", description: "Corte de cabello tradicional con tijera y máquina", price: 25_000, duration_minutes: 30, category: "corte" },
  { name: "Corte + barba", description: "Corte de cabello completo con arreglo de barba", price: 40_000, duration_minutes: 45, category: "combo" },
  { name: "Barba completa", description: "Perfilado y arreglo completo de barba con navaja", price: 18_000, duration_minutes: 20, category: "barba" },
  { name: "Corte degradado (fade)", description: "Degradado moderno con diferentes niveles", price: 30_000, duration_minutes: 40, category: "corte" },
  { name: "Cejas", description: "Diseño y perfilado de cejas", price: 8_000, duration_minutes: 10, category: "adicional" },
  { name: "Tratamiento capilar", description: "Tratamiento hidratante y nutritivo para el cabello", price: 45_000, duration_minutes: 50, category: "tratamiento" }
]

elite_services = services_data.map do |sdata|
  Service.find_or_create_by!(business: barberia_elite, name: sdata[:name]) do |s|
    s.description = sdata[:description]
    s.price = sdata[:price]
    s.duration_minutes = sdata[:duration_minutes]
    s.category = sdata[:category]
    s.active = true
  end
end

svc_corte_clasico, svc_corte_barba, svc_barba, svc_fade, svc_cejas, svc_tratamiento = elite_services

puts "  ✅ Services: #{elite_services.size} created"

# --- Employees ---
puts "  👥 Creating employees..."

emp_carlos = Employee.find_or_create_by!(business: barberia_elite, name: "Carlos Méndez") do |e|
  e.phone = "+573001234567"
  e.email = "carlos@barberia-elite.com"
  e.active = true
end

emp_andres = Employee.find_or_create_by!(business: barberia_elite, name: "Andrés López") do |e|
  e.phone = "+573009876543"
  e.email = "andres@barberia-elite.com"
  e.active = true
end

emp_maria = Employee.find_or_create_by!(business: barberia_elite, name: "María García") do |e|
  e.phone = "+573005551234"
  e.email = "maria@barberia-elite.com"
  e.active = true
end

elite_employees = [emp_carlos, emp_andres, emp_maria]
puts "  ✅ Employees: #{elite_employees.size} created"

# --- Employee Services ---
puts "  🔗 Linking employee services..."

# Carlos does all services
elite_services.each do |svc|
  EmployeeService.find_or_create_by!(employee: emp_carlos, service: svc)
end

# Andrés does cortes + barba
[svc_corte_clasico, svc_corte_barba, svc_barba, svc_fade].each do |svc|
  EmployeeService.find_or_create_by!(employee: emp_andres, service: svc)
end

# María does tratamiento + cejas
[svc_tratamiento, svc_cejas].each do |svc|
  EmployeeService.find_or_create_by!(employee: emp_maria, service: svc)
end

puts "  ✅ Employee services linked"

# --- Employee Schedules (Mon-Sat 8:00-19:00) ---
puts "  🕐 Creating employee schedules..."

elite_employees.each do |emp|
  (1..6).each do |day| # Monday=1 to Saturday=6
    EmployeeSchedule.find_or_create_by!(employee: emp, day_of_week: day) do |es|
      es.start_time = "08:00"
      es.end_time = "19:00"
    end
  end
end

puts "  ✅ Employee schedules: Mon-Sat for all employees"

# --- Customers ---
puts "  👤 Creating customers..."

customers_data = [
  { name: "Juan Herrera", phone: "+573101112233", email: "juan.herrera@gmail.com" },
  { name: "Pedro Martínez", phone: "+573102223344", email: "pedro.martinez@gmail.com" },
  { name: "Luis Rodríguez", phone: "+573103334455", email: "luis.rodriguez@hotmail.com" },
  { name: "Diego Ramírez", phone: "+573104445566", email: "diego.ramirez@gmail.com" },
  { name: "Sebastián Díaz", phone: "+573105556677", email: "sebastian.diaz@outlook.com" },
  { name: "Alejandro Gómez", phone: "+573106667788", email: "alejandro.gomez@gmail.com" },
  { name: "Daniel Morales", phone: "+573107778899", email: "daniel.morales@hotmail.com" },
  { name: "Santiago Vargas", phone: "+573108889900", email: "santiago.vargas@gmail.com" },
  { name: "Mateo Castillo", phone: "+573109990011", email: "mateo.castillo@gmail.com" },
  { name: "Nicolás Jiménez", phone: "+573100001122", email: "nicolas.jimenez@outlook.com" }
]

elite_customers = customers_data.map do |cdata|
  Customer.find_or_create_by!(business: barberia_elite, email: cdata[:email]) do |c|
    c.name = cdata[:name]
    c.phone = cdata[:phone]
  end
end

puts "  ✅ Customers: #{elite_customers.size} created"

# --- Appointments ---
puts "  📅 Creating appointments..."

today = Date.current
appointment_count = 0

# 15 COMPLETED appointments (past 30 days)
15.times do |i|
  date = today - rand(1..30)
  hour = rand(8..16)
  minute = [0, 15, 30].sample
  start_time = "%02d:%02d" % [hour, minute]

  service = elite_services.sample
  end_hour = hour + (service.duration_minutes / 60)
  end_minute = minute + (service.duration_minutes % 60)
  if end_minute >= 60
    end_hour += 1
    end_minute -= 60
  end
  end_time = "%02d:%02d" % [end_hour, end_minute]

  # Pick an employee that can do this service
  eligible_employees = service.employees.to_a
  employee = eligible_employees.sample || emp_carlos

  customer = elite_customers.sample

  appt = Appointment.find_or_create_by!(
    business: barberia_elite,
    customer: customer,
    appointment_date: date,
    start_time: start_time,
    employee: employee
  ) do |a|
    a.service = service
    a.end_time = end_time
    a.price = service.price
    a.status = :completed
    a.ticket_code = "ELITE-#{SecureRandom.hex(4).upcase}"
    a.notes = nil
  end

  appointment_count += 1
end

puts "  ✅ 15 completed appointments (past)"

# 5 CONFIRMED appointments (next 7 days)
5.times do |i|
  date = today + rand(1..7)
  # Skip Sunday
  date += 1 if date.wday == 0
  hour = rand(8..16)
  minute = [0, 15, 30].sample
  start_time = "%02d:%02d" % [hour, minute]

  service = elite_services.sample
  end_hour = hour + (service.duration_minutes / 60)
  end_minute = minute + (service.duration_minutes % 60)
  if end_minute >= 60
    end_hour += 1
    end_minute -= 60
  end
  end_time = "%02d:%02d" % [end_hour, end_minute]

  eligible_employees = service.employees.to_a
  employee = eligible_employees.sample || emp_carlos
  customer = elite_customers.sample

  Appointment.find_or_create_by!(
    business: barberia_elite,
    customer: customer,
    appointment_date: date,
    start_time: start_time,
    employee: employee
  ) do |a|
    a.service = service
    a.end_time = end_time
    a.price = service.price
    a.status = :confirmed
    a.ticket_code = "ELITE-#{SecureRandom.hex(4).upcase}"
  end

  appointment_count += 1
end

puts "  ✅ 5 confirmed appointments (upcoming)"

# 3 PENDING_PAYMENT appointments (upcoming)
3.times do |i|
  date = today + rand(1..5)
  date += 1 if date.wday == 0
  hour = rand(9..15)
  minute = [0, 30].sample
  start_time = "%02d:%02d" % [hour, minute]

  service = elite_services.sample
  end_hour = hour + (service.duration_minutes / 60)
  end_minute = minute + (service.duration_minutes % 60)
  if end_minute >= 60
    end_hour += 1
    end_minute -= 60
  end
  end_time = "%02d:%02d" % [end_hour, end_minute]

  eligible_employees = service.employees.to_a
  employee = eligible_employees.sample || emp_carlos
  customer = elite_customers.sample

  Appointment.find_or_create_by!(
    business: barberia_elite,
    customer: customer,
    appointment_date: date,
    start_time: start_time,
    employee: employee
  ) do |a|
    a.service = service
    a.end_time = end_time
    a.price = service.price
    a.status = :pending_payment
  end

  appointment_count += 1
end

puts "  ✅ 3 pending_payment appointments"

# 2 CHECKED_IN appointments (today)
2.times do |i|
  hour = 9 + (i * 2)
  minute = 0
  start_time = "%02d:%02d" % [hour, minute]

  service = [svc_corte_clasico, svc_fade].sample
  end_hour = hour + (service.duration_minutes / 60)
  end_minute = minute + (service.duration_minutes % 60)
  if end_minute >= 60
    end_hour += 1
    end_minute -= 60
  end
  end_time = "%02d:%02d" % [end_hour, end_minute]

  employee = [emp_carlos, emp_andres][i]
  customer = elite_customers[i]

  Appointment.find_or_create_by!(
    business: barberia_elite,
    customer: customer,
    appointment_date: today,
    start_time: start_time,
    employee: employee
  ) do |a|
    a.service = service
    a.end_time = end_time
    a.price = service.price
    a.status = :checked_in
    a.ticket_code = "ELITE-#{SecureRandom.hex(4).upcase}"
    a.checked_in_at = Time.current
  end

  appointment_count += 1
end

puts "  ✅ 2 checked_in appointments (today)"

# 2 CANCELLED appointments
2.times do |i|
  date = today - rand(1..15)
  hour = rand(10..16)
  start_time = "%02d:00" % hour

  service = elite_services.sample
  end_hour = hour + (service.duration_minutes / 60)
  end_minute = service.duration_minutes % 60
  end_time = "%02d:%02d" % [end_hour, end_minute]

  eligible_employees = service.employees.to_a
  employee = eligible_employees.sample || emp_carlos
  customer = elite_customers[8 + i]

  Appointment.find_or_create_by!(
    business: barberia_elite,
    customer: customer,
    appointment_date: date,
    start_time: start_time,
    employee: employee
  ) do |a|
    a.service = service
    a.end_time = end_time
    a.price = service.price
    a.status = :cancelled
    a.notes = "Cancelado por el cliente"
  end

  appointment_count += 1
end

puts "  ✅ 2 cancelled appointments"

# 3 PAYMENT_SENT appointments (upcoming)
3.times do |i|
  date = today + rand(1..4)
  date += 1 if date.wday == 0
  hour = rand(10..16)
  minute = [0, 30].sample
  start_time = "%02d:%02d" % [hour, minute]

  service = elite_services.sample
  end_hour = hour + (service.duration_minutes / 60)
  end_minute = minute + (service.duration_minutes % 60)
  if end_minute >= 60
    end_hour += 1
    end_minute -= 60
  end
  end_time = "%02d:%02d" % [end_hour, end_minute]

  eligible_employees = service.employees.to_a
  employee = eligible_employees.sample || emp_carlos
  customer = elite_customers.sample

  Appointment.find_or_create_by!(
    business: barberia_elite,
    customer: customer,
    appointment_date: date,
    start_time: start_time,
    employee: employee
  ) do |a|
    a.service = service
    a.end_time = end_time
    a.price = service.price
    a.status = :payment_sent
    a.ticket_code = "ELITE-#{SecureRandom.hex(4).upcase}"
  end

  appointment_count += 1
end

puts "  ✅ 3 payment_sent appointments"
puts "  📊 Total appointments for Barbería Elite: #{barberia_elite.appointments.count}"

# --- Payments ---
puts "  💰 Creating payments..."

payment_count = 0

# Payments for completed appointments
barberia_elite.appointments.completed.each do |appt|
  Payment.find_or_create_by!(appointment: appt) do |p|
    p.amount = appt.price
    p.payment_method = [:cash, :transfer].sample
    p.status = :approved
  end
  payment_count += 1
end

# Payments for confirmed appointments
barberia_elite.appointments.confirmed.each do |appt|
  Payment.find_or_create_by!(appointment: appt) do |p|
    p.amount = appt.price
    p.payment_method = :transfer
    p.status = :approved
  end
  payment_count += 1
end

# Payments for payment_sent appointments
barberia_elite.appointments.payment_sent.each do |appt|
  Payment.find_or_create_by!(appointment: appt) do |p|
    p.amount = appt.price
    p.payment_method = :transfer
    p.status = :submitted
  end
  payment_count += 1
end

# Payments for checked_in appointments
barberia_elite.appointments.checked_in.each do |appt|
  Payment.find_or_create_by!(appointment: appt) do |p|
    p.amount = appt.price
    p.payment_method = [:cash, :transfer].sample
    p.status = :approved
  end
  payment_count += 1
end

puts "  ✅ Payments: #{payment_count} created"

# --- Reviews ---
puts "  ⭐ Creating reviews..."

reviews_data = [
  { rating: 5, comment: "Excelente servicio. Carlos es un crack con las tijeras. Siempre salgo contento.", customer_name: "Juan Herrera" },
  { rating: 5, comment: "La mejor barbería de Barranquilla sin duda. El ambiente es genial y el corte queda perfecto.", customer_name: "Pedro Martínez" },
  { rating: 4, comment: "Muy buen corte, el degradado quedó brutal. Solo que a veces toca esperar un poco.", customer_name: "Diego Ramírez" },
  { rating: 5, comment: "Llevo más de un año viniendo y nunca me han fallado. Recomendado al 100%.", customer_name: "Luis Rodríguez" },
  { rating: 4, comment: "El tratamiento capilar de María es increíble. Se nota la diferencia desde la primera sesión.", customer_name: "Sebastián Díaz" },
  { rating: 5, comment: "Precio justo, excelente atención y el lugar está muy bien decorado. Top.", customer_name: "Alejandro Gómez" },
  { rating: 4, comment: "Andrés hace unos fades espectaculares. Muy recomendado para cortes modernos.", customer_name: "Daniel Morales" },
  { rating: 5, comment: "Reservé por primera vez y la experiencia fue de 10. Fácil de agendar y el servicio impecable.", customer_name: "Santiago Vargas" }
]

reviews_data.each_with_index do |rdata, idx|
  customer = elite_customers[idx]
  Review.find_or_create_by!(business: barberia_elite, customer: customer) do |r|
    r.rating = rdata[:rating]
    r.comment = rdata[:comment]
    r.customer_name = rdata[:customer_name]
  end
end

puts "  ✅ Reviews: #{barberia_elite.reviews.count} created"

# --- Blocked Slots ---
puts "  🚫 Creating blocked slots..."

tomorrow = today + 1
tomorrow += 1 if tomorrow.wday == 0 # skip Sunday

# Lunch block for tomorrow 12:00-13:00 (business-wide)
BlockedSlot.find_or_create_by!(
  business: barberia_elite,
  employee: nil,
  date: tomorrow,
  start_time: "12:00"
) do |bs|
  bs.end_time = "13:00"
  bs.reason = "Hora de almuerzo"
end

# Vacation day next week for Andrés (full day block)
next_wednesday = today + ((3 - today.wday) % 7)
next_wednesday += 7 if next_wednesday <= today

BlockedSlot.find_or_create_by!(
  business: barberia_elite,
  employee: emp_andres,
  date: next_wednesday,
  start_time: "08:00"
) do |bs|
  bs.end_time = "19:00"
  bs.reason = "Día libre de Andrés"
end

puts "  ✅ Blocked slots: 2 created (lunch + vacation)"

# --- Subscription ---
puts "  📋 Creating subscription..."

Subscription.find_or_create_by!(business: barberia_elite, plan: plan_profesional, status: :active) do |s|
  s.start_date = Date.current
  s.end_date = Date.current + 30.days
end

puts "  ✅ Subscription: Plan Profesional (active)"

puts "\n✅ Barbería Elite fully seeded!"

# ============================================================================
# 4. BUSINESS 2 — Salón Bella (secondary demo)
# ============================================================================
puts "\n💅 Creating Business 2: Salón Bella..."

ana_user = User.find_or_create_by!(email: "ana@salon-bella.com") do |u|
  u.name = "Ana Torres"
  u.password = "password123"
  u.role = :owner
  u.phone = "+573012345678"
end

salon_bella = Business.find_or_create_by!(slug: "salon-bella") do |b|
  b.owner = ana_user
  b.name = "Salón Bella"
  b.business_type = :salon
  b.description = "Salón de belleza especializado en manicure, pedicure, tintes y cortes para damas."
  b.phone = "+573012345678"
  b.email = "info@salon-bella.com"
  b.address = "Carrera 53 #72-100"
  b.city = "Barranquilla"
  b.state = "ATL"
  b.country = "CO"
  b.timezone = "America/Bogota"
  b.currency = "COP"
  b.payment_instructions = "Pago por Nequi o en efectivo al llegar."
  b.nequi_phone = "+573012345678"
  b.cancellation_policy_pct = 30
  b.cancellation_deadline_hours = 12
  b.trial_ends_at = 30.days.from_now
  b.status = :active
  b.onboarding_completed = true
  b.primary_color = "#E91E90"
  b.secondary_color = "#FFF0F5"
  b.latitude = 10.9750
  b.longitude = -74.7850
  b.lunch_enabled = true
  b.lunch_start_time = "12:30"
  b.lunch_end_time = "13:30"
  b.slot_interval_minutes = 30
  b.gap_between_appointments_minutes = 0
end

puts "  ✅ Salón Bella created (owner: #{ana_user.email})"

# Business hours Mon-Sat 9:00-18:00
(0..6).each do |day|
  BusinessHour.find_or_create_by!(business: salon_bella, day_of_week: day) do |bh|
    if day == 0
      bh.open_time = "09:00"
      bh.close_time = "18:00"
      bh.closed = true
    else
      bh.open_time = "09:00"
      bh.close_time = "18:00"
      bh.closed = false
    end
  end
end

# Services
bella_services_data = [
  { name: "Manicure", description: "Manicure completo con esmaltado", price: 25_000, duration_minutes: 40, category: "uñas" },
  { name: "Pedicure", description: "Pedicure completo con exfoliación", price: 35_000, duration_minutes: 50, category: "uñas" },
  { name: "Tinte completo", description: "Coloración completa del cabello", price: 80_000, duration_minutes: 90, category: "color" },
  { name: "Corte dama", description: "Corte de cabello para damas con secado", price: 35_000, duration_minutes: 45, category: "corte" }
]

bella_services = bella_services_data.map do |sdata|
  Service.find_or_create_by!(business: salon_bella, name: sdata[:name]) do |s|
    s.description = sdata[:description]
    s.price = sdata[:price]
    s.duration_minutes = sdata[:duration_minutes]
    s.category = sdata[:category]
    s.active = true
  end
end

puts "  ✅ Services: #{bella_services.size}"

# Employees
emp_ana = Employee.find_or_create_by!(business: salon_bella, name: "Ana Torres") do |e|
  e.phone = "+573012345678"
  e.email = "ana@salon-bella.com"
  e.active = true
end

emp_lucia = Employee.find_or_create_by!(business: salon_bella, name: "Lucía Restrepo") do |e|
  e.phone = "+573019876543"
  e.email = "lucia@salon-bella.com"
  e.active = true
end

bella_employees = [emp_ana, emp_lucia]

# Employee services — both do all services
bella_employees.each do |emp|
  bella_services.each do |svc|
    EmployeeService.find_or_create_by!(employee: emp, service: svc)
  end
end

# Employee schedules Mon-Sat
bella_employees.each do |emp|
  (1..6).each do |day|
    EmployeeSchedule.find_or_create_by!(employee: emp, day_of_week: day) do |es|
      es.start_time = "09:00"
      es.end_time = "18:00"
    end
  end
end

puts "  ✅ Employees: #{bella_employees.size} with schedules"

# Customers
bella_customers_data = [
  { name: "Valentina Herrera", phone: "+573201112233", email: "valentina.herrera@gmail.com" },
  { name: "Camila Ospina", phone: "+573202223344", email: "camila.ospina@gmail.com" },
  { name: "Isabella Ruiz", phone: "+573203334455", email: "isabella.ruiz@hotmail.com" },
  { name: "Sofía Acosta", phone: "+573204445566", email: "sofia.acosta@gmail.com" },
  { name: "Mariana Pérez", phone: "+573205556677", email: "mariana.perez@outlook.com" }
]

bella_customers = bella_customers_data.map do |cdata|
  Customer.find_or_create_by!(business: salon_bella, email: cdata[:email]) do |c|
    c.name = cdata[:name]
    c.phone = cdata[:phone]
  end
end

puts "  ✅ Customers: #{bella_customers.size}"

# Appointments for Salón Bella (10 total)
puts "  📅 Creating appointments..."

# 5 completed
5.times do |i|
  date = today - rand(1..20)
  hour = rand(9..15)
  start_time = "%02d:00" % hour

  service = bella_services.sample
  end_hour = hour + (service.duration_minutes / 60)
  end_minute = service.duration_minutes % 60
  end_time = "%02d:%02d" % [end_hour, end_minute]

  employee = bella_employees.sample
  customer = bella_customers.sample

  appt = Appointment.find_or_create_by!(
    business: salon_bella,
    customer: customer,
    appointment_date: date,
    start_time: start_time,
    employee: employee
  ) do |a|
    a.service = service
    a.end_time = end_time
    a.price = service.price
    a.status = :completed
    a.ticket_code = "BELLA-#{SecureRandom.hex(4).upcase}"
  end

  Payment.find_or_create_by!(appointment: appt) do |p|
    p.amount = appt.price
    p.payment_method = [:cash, :transfer].sample
    p.status = :approved
  end
end

# 3 confirmed
3.times do |i|
  date = today + rand(1..7)
  date += 1 if date.wday == 0
  hour = rand(9..15)
  start_time = "%02d:30" % hour

  service = bella_services.sample
  end_hour = hour + (service.duration_minutes / 60)
  end_minute = 30 + (service.duration_minutes % 60)
  if end_minute >= 60
    end_hour += 1
    end_minute -= 60
  end
  end_time = "%02d:%02d" % [end_hour, end_minute]

  employee = bella_employees.sample
  customer = bella_customers.sample

  appt = Appointment.find_or_create_by!(
    business: salon_bella,
    customer: customer,
    appointment_date: date,
    start_time: start_time,
    employee: employee
  ) do |a|
    a.service = service
    a.end_time = end_time
    a.price = service.price
    a.status = :confirmed
    a.ticket_code = "BELLA-#{SecureRandom.hex(4).upcase}"
  end

  Payment.find_or_create_by!(appointment: appt) do |p|
    p.amount = appt.price
    p.payment_method = :transfer
    p.status = :approved
  end
end

# 2 pending_payment
2.times do |i|
  date = today + rand(1..5)
  date += 1 if date.wday == 0
  hour = rand(10..14)
  start_time = "%02d:00" % hour

  service = bella_services.sample
  end_hour = hour + (service.duration_minutes / 60)
  end_minute = service.duration_minutes % 60
  end_time = "%02d:%02d" % [end_hour, end_minute]

  employee = bella_employees.sample
  customer = bella_customers.sample

  Appointment.find_or_create_by!(
    business: salon_bella,
    customer: customer,
    appointment_date: date,
    start_time: start_time,
    employee: employee
  ) do |a|
    a.service = service
    a.end_time = end_time
    a.price = service.price
    a.status = :pending_payment
  end
end

puts "  ✅ Appointments: #{salon_bella.appointments.count}"

# Reviews for Salón Bella
bella_reviews_data = [
  { rating: 5, comment: "Las uñas me quedaron hermosas. Ana es una artista. Volveré pronto.", customer_name: "Valentina Herrera" },
  { rating: 4, comment: "El tinte quedó exactamente como quería. Muy profesionales.", customer_name: "Camila Ospina" },
  { rating: 5, comment: "Mejor salón de Barranquilla. Ambiente súper agradable y el servicio es impecable.", customer_name: "Isabella Ruiz" },
  { rating: 5, comment: "Lucía es excelente con el pedicure. Siempre atenta a los detalles.", customer_name: "Sofía Acosta" }
]

bella_reviews_data.each_with_index do |rdata, idx|
  customer = bella_customers[idx]
  Review.find_or_create_by!(business: salon_bella, customer: customer) do |r|
    r.rating = rdata[:rating]
    r.comment = rdata[:comment]
    r.customer_name = rdata[:customer_name]
  end
end

# Subscription for Salón Bella
Subscription.find_or_create_by!(business: salon_bella, plan: plan_basico, status: :active) do |s|
  s.start_date = Date.current
  s.end_date = Date.current + 30.days
end

puts "  ✅ Reviews: #{salon_bella.reviews.count}"
puts "  ✅ Subscription: Plan Básico (active)"
puts "\n✅ Salón Bella fully seeded!"

# ============================================================================
# 5. BUSINESS 3 — Fresh Cuts (not onboarded)
# ============================================================================
puts "\n✂️ Creating Business 3: Fresh Cuts (not onboarded)..."

miguel_user = User.find_or_create_by!(email: "miguel@freshcuts.com") do |u|
  u.name = "Miguel Ríos"
  u.password = "password123"
  u.role = :owner
  u.phone = "+573023456789"
end

Business.find_or_create_by!(slug: "fresh-cuts") do |b|
  b.owner = miguel_user
  b.name = "Fresh Cuts"
  b.business_type = :barbershop
  b.phone = "+573023456789"
  b.email = "info@freshcuts.com"
  b.address = "Carrera 46 #82-45"
  b.city = "Barranquilla"
  b.state = "ATL"
  b.country = "CO"
  b.timezone = "America/Bogota"
  b.currency = "COP"
  b.trial_ends_at = 30.days.from_now
  b.status = :active
  b.onboarding_completed = false
  b.cancellation_policy_pct = 0
  b.cancellation_deadline_hours = 24
  b.latitude = 10.9800
  b.longitude = -74.7900
  b.lunch_enabled = false
  b.slot_interval_minutes = 30
  b.gap_between_appointments_minutes = 0
end

puts "  ✅ Fresh Cuts created (owner: #{miguel_user.email}) — NOT onboarded"

# ============================================================================
# 4. BUSINESS 4 — Barbería La 93 (Bogotá)
# ============================================================================
puts "\n💈 Creating Business 4: Barbería La 93 (Bogotá)..."

ricardo_user = User.find_or_create_by!(email: "ricardo@barberiala93.com") do |u|
  u.name = "Ricardo Parra"
  u.password = "password123"
  u.role = :owner
  u.phone = "+573114567890"
end

barberia_93 = Business.find_or_create_by!(slug: "barberia-la-93") do |b|
  b.owner = ricardo_user
  b.name = "Barbería La 93"
  b.business_type = :barbershop
  b.description = "Barbería premium en el corazón de la Zona T. Cortes ejecutivos, fades y grooming masculino."
  b.phone = "+573114567890"
  b.email = "info@barberiala93.com"
  b.address = "Calle 93 #13-45"
  b.city = "Bogota D.C."
  b.state = "DC"
  b.country = "CO"
  b.timezone = "America/Bogota"
  b.currency = "COP"
  b.payment_instructions = "Acepta Nequi, Daviplata o pago en efectivo."
  b.nequi_phone = "+573114567890"
  b.daviplata_phone = "+573114567890"
  b.cancellation_policy_pct = 30
  b.cancellation_deadline_hours = 12
  b.trial_ends_at = 30.days.from_now
  b.status = :active
  b.onboarding_completed = true
  b.primary_color = "#1A1A2E"
  b.secondary_color = "#E2E2E2"
  b.instagram_url = "https://instagram.com/barberiala93"
  b.latitude = 4.6782
  b.longitude = -74.0485
  b.lunch_enabled = true
  b.lunch_start_time = "12:00"
  b.lunch_end_time = "13:00"
  b.slot_interval_minutes = 30
  b.gap_between_appointments_minutes = 10
end

# Business hours Tue-Sat 9:00-20:00
(0..6).each do |day|
  BusinessHour.find_or_create_by!(business: barberia_93, day_of_week: day) do |bh|
    if [0, 1].include?(day) # Sun & Mon closed
      bh.open_time = "09:00"
      bh.close_time = "20:00"
      bh.closed = true
    else
      bh.open_time = "09:00"
      bh.close_time = "20:00"
      bh.closed = false
    end
  end
end

# Services
bogota_services_data = [
  { name: "Corte ejecutivo", description: "Corte clásico para el hombre profesional", price: 35_000, duration_minutes: 30, category: "corte" },
  { name: "Corte + barba premium", description: "Corte con arreglo de barba con toalla caliente", price: 55_000, duration_minutes: 50, category: "combo" },
  { name: "Fade artístico", description: "Degradado con diseño personalizado", price: 40_000, duration_minutes: 45, category: "corte" },
  { name: "Black mask facial", description: "Limpieza facial con mascarilla de carbón activado", price: 30_000, duration_minutes: 25, category: "tratamiento" }
]

bogota_services = bogota_services_data.map do |sdata|
  Service.find_or_create_by!(business: barberia_93, name: sdata[:name]) do |s|
    s.description = sdata[:description]
    s.price = sdata[:price]
    s.duration_minutes = sdata[:duration_minutes]
    s.category = sdata[:category]
    s.active = true
  end
end

# Employees
emp_ricardo = Employee.find_or_create_by!(business: barberia_93, name: "Ricardo Parra") do |e|
  e.phone = "+573114567890"
  e.email = "ricardo@barberiala93.com"
  e.active = true
end

emp_julian = Employee.find_or_create_by!(business: barberia_93, name: "Julián Bermúdez") do |e|
  e.phone = "+573115678901"
  e.email = "julian@barberiala93.com"
  e.active = true
end

bogota_employees = [emp_ricardo, emp_julian]

bogota_employees.each do |emp|
  bogota_services.each { |svc| EmployeeService.find_or_create_by!(employee: emp, service: svc) }
  (2..6).each do |day|
    EmployeeSchedule.find_or_create_by!(employee: emp, day_of_week: day) do |es|
      es.start_time = "09:00"
      es.end_time = "20:00"
    end
  end
end

# Customers
bogota_customers = [
  { name: "Andrés Felipe Rojas", phone: "+573111223344", email: "andres.rojas@gmail.com" },
  { name: "David Gutiérrez", phone: "+573112334455", email: "david.gutierrez@gmail.com" },
  { name: "Camilo Suárez", phone: "+573113445566", email: "camilo.suarez@outlook.com" },
  { name: "Felipe Castaño", phone: "+573114556677", email: "felipe.castano@gmail.com" },
  { name: "Tomás Arango", phone: "+573115667788", email: "tomas.arango@hotmail.com" }
].map do |cdata|
  Customer.find_or_create_by!(business: barberia_93, email: cdata[:email]) do |c|
    c.name = cdata[:name]
    c.phone = cdata[:phone]
  end
end

# Appointments (8 completed, 3 confirmed, 2 pending)
8.times do |i|
  date = today - rand(1..25)
  hour = rand(9..18)
  service = bogota_services.sample
  employee = bogota_employees.sample
  customer = bogota_customers.sample
  start_time = "%02d:00" % hour
  end_min = service.duration_minutes
  end_time = "%02d:%02d" % [hour + end_min / 60, end_min % 60]

  appt = Appointment.find_or_create_by!(business: barberia_93, customer: customer, appointment_date: date, start_time: start_time, employee: employee) do |a|
    a.service = service
    a.end_time = end_time
    a.price = service.price
    a.status = :completed
    a.ticket_code = "LA93-#{SecureRandom.hex(4).upcase}"
  end
  Payment.find_or_create_by!(appointment: appt) { |p| p.amount = appt.price; p.payment_method = [:cash, :transfer].sample; p.status = :approved }
end

3.times do |i|
  date = today + rand(1..7)
  date += 1 if date.wday == 0
  hour = rand(9..17)
  service = bogota_services.sample
  employee = bogota_employees.sample
  customer = bogota_customers.sample
  start_time = "%02d:30" % hour
  end_min = 30 + service.duration_minutes
  eh = hour + end_min / 60
  em = end_min % 60
  end_time = "%02d:%02d" % [eh, em]

  appt = Appointment.find_or_create_by!(business: barberia_93, customer: customer, appointment_date: date, start_time: start_time, employee: employee) do |a|
    a.service = service
    a.end_time = end_time
    a.price = service.price
    a.status = :confirmed
    a.ticket_code = "LA93-#{SecureRandom.hex(4).upcase}"
  end
  Payment.find_or_create_by!(appointment: appt) { |p| p.amount = appt.price; p.payment_method = :transfer; p.status = :approved }
end

# Reviews
[
  { rating: 5, comment: "La mejor barbería de la Zona T. Ricardo es un maestro con la navaja.", customer_name: "Andrés Felipe Rojas" },
  { rating: 5, comment: "Ambiente increíble, corte perfecto y excelente atención. 10/10.", customer_name: "David Gutiérrez" },
  { rating: 4, comment: "Muy buena experiencia, el black mask facial es top. Recomendado.", customer_name: "Camilo Suárez" }
].each_with_index do |rdata, idx|
  Review.find_or_create_by!(business: barberia_93, customer: bogota_customers[idx]) do |r|
    r.rating = rdata[:rating]
    r.comment = rdata[:comment]
    r.customer_name = rdata[:customer_name]
  end
end

Subscription.find_or_create_by!(business: barberia_93, plan: plan_profesional, status: :active) do |s|
  s.start_date = Date.current
  s.end_date = Date.current + 30.days
end

puts "  ✅ Barbería La 93 fully seeded (Bogotá, #{barberia_93.appointments.count} appointments)"

# ============================================================================
# 5. BUSINESS 5 — Studio 70 (Medellín)
# ============================================================================
puts "\n💇 Creating Business 5: Studio 70 (Medellín)..."

laura_user = User.find_or_create_by!(email: "laura@studio70.com") do |u|
  u.name = "Laura Montoya"
  u.password = "password123"
  u.role = :owner
  u.phone = "+573046789012"
end

studio_70 = Business.find_or_create_by!(slug: "studio-70") do |b|
  b.owner = laura_user
  b.name = "Studio 70"
  b.business_type = :salon
  b.description = "Salón unisex en El Poblado. Especializados en colorimetría, alisados y cortes de tendencia."
  b.phone = "+573046789012"
  b.email = "hola@studio70.com"
  b.address = "Carrera 43A #7-50, El Poblado"
  b.city = "Medellín"
  b.state = "ANT"
  b.country = "CO"
  b.timezone = "America/Bogota"
  b.currency = "COP"
  b.payment_instructions = "Nequi o efectivo. Transferencia Bancolombia para servicios mayores a $100.000."
  b.nequi_phone = "+573046789012"
  b.bancolombia_account = "98765432109"
  b.cancellation_policy_pct = 50
  b.cancellation_deadline_hours = 24
  b.trial_ends_at = 30.days.from_now
  b.status = :active
  b.onboarding_completed = true
  b.primary_color = "#FF6B6B"
  b.secondary_color = "#2D2D2D"
  b.instagram_url = "https://instagram.com/studio70mde"
  b.latitude = 6.2087
  b.longitude = -75.5700
  b.lunch_enabled = false
  b.slot_interval_minutes = 30
  b.gap_between_appointments_minutes = 5
end

# Business hours Mon-Sat 10:00-20:00
(0..6).each do |day|
  BusinessHour.find_or_create_by!(business: studio_70, day_of_week: day) do |bh|
    if day == 0
      bh.open_time = "10:00"
      bh.close_time = "20:00"
      bh.closed = true
    else
      bh.open_time = "10:00"
      bh.close_time = "20:00"
      bh.closed = false
    end
  end
end

# Services
mde_services_data = [
  { name: "Corte unisex", description: "Corte con consulta de estilo y secado", price: 40_000, duration_minutes: 40, category: "corte" },
  { name: "Balayage", description: "Técnica de iluminación para un look natural", price: 180_000, duration_minutes: 150, category: "color" },
  { name: "Alisado keratina", description: "Alisado brasileño con keratina profesional", price: 150_000, duration_minutes: 120, category: "tratamiento" },
  { name: "Manicure semipermanente", description: "Manicure con esmalte gel de larga duración", price: 35_000, duration_minutes: 45, category: "uñas" },
  { name: "Tinte raíz", description: "Retoque de raíces con color personalizado", price: 70_000, duration_minutes: 60, category: "color" }
]

mde_services = mde_services_data.map do |sdata|
  Service.find_or_create_by!(business: studio_70, name: sdata[:name]) do |s|
    s.description = sdata[:description]
    s.price = sdata[:price]
    s.duration_minutes = sdata[:duration_minutes]
    s.category = sdata[:category]
    s.active = true
  end
end

# Employees
emp_laura = Employee.find_or_create_by!(business: studio_70, name: "Laura Montoya") do |e|
  e.phone = "+573046789012"
  e.email = "laura@studio70.com"
  e.active = true
end

emp_daniela = Employee.find_or_create_by!(business: studio_70, name: "Daniela Velásquez") do |e|
  e.phone = "+573047890123"
  e.email = "daniela@studio70.com"
  e.active = true
end

emp_santiago = Employee.find_or_create_by!(business: studio_70, name: "Santiago Ríos") do |e|
  e.phone = "+573048901234"
  e.email = "santiago@studio70.com"
  e.active = true
end

mde_employees = [emp_laura, emp_daniela, emp_santiago]

mde_employees.each do |emp|
  mde_services.each { |svc| EmployeeService.find_or_create_by!(employee: emp, service: svc) }
  (1..6).each do |day|
    EmployeeSchedule.find_or_create_by!(employee: emp, day_of_week: day) do |es|
      es.start_time = "10:00"
      es.end_time = "20:00"
    end
  end
end

# Customers
mde_customers = [
  { name: "Manuela Restrepo", phone: "+573041112233", email: "manuela.restrepo@gmail.com" },
  { name: "Juliana Zapata", phone: "+573042223344", email: "juliana.zapata@gmail.com" },
  { name: "Carolina Mejía", phone: "+573043334455", email: "carolina.mejia@hotmail.com" },
  { name: "Natalia Ossa", phone: "+573044445566", email: "natalia.ossa@gmail.com" },
  { name: "Alejandra Ochoa", phone: "+573045556677", email: "alejandra.ochoa@outlook.com" },
  { name: "Simón Arango", phone: "+573046667788", email: "simon.arango@gmail.com" }
].map do |cdata|
  Customer.find_or_create_by!(business: studio_70, email: cdata[:email]) do |c|
    c.name = cdata[:name]
    c.phone = cdata[:phone]
  end
end

# Appointments
10.times do |i|
  date = today - rand(1..30)
  hour = rand(10..18)
  service = mde_services.sample
  employee = mde_employees.sample
  customer = mde_customers.sample
  start_time = "%02d:00" % hour
  end_min = service.duration_minutes
  end_time = "%02d:%02d" % [hour + end_min / 60, end_min % 60]

  appt = Appointment.find_or_create_by!(business: studio_70, customer: customer, appointment_date: date, start_time: start_time, employee: employee) do |a|
    a.service = service
    a.end_time = end_time
    a.price = service.price
    a.status = :completed
    a.ticket_code = "S70-#{SecureRandom.hex(4).upcase}"
  end
  Payment.find_or_create_by!(appointment: appt) { |p| p.amount = appt.price; p.payment_method = [:cash, :transfer].sample; p.status = :approved }
end

4.times do |i|
  date = today + rand(1..7)
  date += 1 if date.wday == 0
  hour = rand(10..17)
  service = mde_services.sample
  employee = mde_employees.sample
  customer = mde_customers.sample
  start_time = "%02d:00" % hour
  end_min = service.duration_minutes
  end_time = "%02d:%02d" % [hour + end_min / 60, end_min % 60]

  appt = Appointment.find_or_create_by!(business: studio_70, customer: customer, appointment_date: date, start_time: start_time, employee: employee) do |a|
    a.service = service
    a.end_time = end_time
    a.price = service.price
    a.status = :confirmed
    a.ticket_code = "S70-#{SecureRandom.hex(4).upcase}"
  end
  Payment.find_or_create_by!(appointment: appt) { |p| p.amount = appt.price; p.payment_method = :transfer; p.status = :approved }
end

# Reviews
[
  { rating: 5, comment: "El balayage me quedó divino. Laura tiene un ojo increíble para el color.", customer_name: "Manuela Restrepo" },
  { rating: 5, comment: "Mejor salón de El Poblado. El alisado de keratina duró 4 meses perfectos.", customer_name: "Juliana Zapata" },
  { rating: 4, comment: "Excelente servicio. Santiago hizo un corte espectacular. Solo un poco de espera.", customer_name: "Simón Arango" },
  { rating: 5, comment: "Las uñas semipermanentes son lo máximo. Daniela es muy detallista.", customer_name: "Carolina Mejía" },
  { rating: 5, comment: "Desde que descubrí Studio 70 no voy a otro lado. Totalmente recomendado.", customer_name: "Natalia Ossa" }
].each_with_index do |rdata, idx|
  Review.find_or_create_by!(business: studio_70, customer: mde_customers[idx]) do |r|
    r.rating = rdata[:rating]
    r.comment = rdata[:comment]
    r.customer_name = rdata[:customer_name]
  end
end

Subscription.find_or_create_by!(business: studio_70, plan: plan_inteligente, status: :active) do |s|
  s.start_date = Date.current
  s.end_date = Date.current + 30.days
end

puts "  ✅ Studio 70 fully seeded (Medellín, #{studio_70.appointments.count} appointments)"

# ============================================================================
# SUSPENDED & INACTIVE BUSINESSES (status examples)
# ============================================================================
puts "\n🔒 Creating suspended & inactive businesses..."

# --- Negocio suspended (oculto del público) ---
user_suspended = User.find_or_create_by!(email: "suspended@example.com") do |u|
  u.name = "Carlos Ruiz"
  u.password = "password123"
  u.role = :owner
end

Business.find_or_create_by!(slug: "barber-king") do |b|
  b.name = "Barber King"
  b.owner = user_suspended
  b.business_type = :barbershop
  b.status = :suspended
  b.description = "Barbería cerrada temporalmente por remodelación"
  b.phone = "303 111 2222"
  b.email = "barberking@example.com"
  b.address = "Calle 72 #45-10"
  b.city = "Barranquilla"
  b.state = "ATL"
  b.country = "CO"
  b.latitude = 10.990
  b.longitude = -74.800
  b.timezone = "America/Bogota"
  b.currency = "COP"
  b.onboarding_completed = true
end

puts "  ✅ Barber King (suspended)"

# --- Negocio inactive (desactivado por admin) ---
user_inactive = User.find_or_create_by!(email: "inactive@example.com") do |u|
  u.name = "Ana Torres"
  u.password = "password123"
  u.role = :owner
end

Business.find_or_create_by!(slug: "glamour-studio") do |b|
  b.name = "Glamour Studio"
  b.owner = user_inactive
  b.business_type = :salon
  b.status = :inactive
  b.description = "Cuenta desactivada"
  b.phone = "305 333 4444"
  b.email = "glamour@example.com"
  b.address = "Carrera 50 #30-15"
  b.city = "Barranquilla"
  b.state = "ATL"
  b.country = "CO"
  b.latitude = 10.970
  b.longitude = -74.780
  b.timezone = "America/Bogota"
  b.currency = "COP"
  b.onboarding_completed = true
end

puts "  ✅ Glamour Studio (inactive)"

# ============================================================================
# SUMMARY
# ============================================================================
puts "\n" + "=" * 60
puts "🎉 Seed completed successfully!"
puts "=" * 60
puts ""
puts "📊 Database summary:"
puts "  Plans:          #{Plan.count}"
puts "  Users:          #{User.count}"
puts "  Businesses:     #{Business.count}"
puts "  Services:       #{Service.count}"
puts "  Employees:      #{Employee.count}"
puts "  Customers:      #{Customer.count}"
puts "  Appointments:   #{Appointment.count}"
puts "  Payments:       #{Payment.count}"
puts "  Reviews:        #{Review.count}"
puts "  Blocked Slots:  #{BlockedSlot.count}"
puts "  Subscriptions:  #{Subscription.count}"
puts ""
puts "🔑 Login credentials:"
puts "  Admin:           admin@agendify.com / password123"
puts "  Barbería Elite:  carlos@barberia-elite.com / password123  (Barranquilla)"
puts "  Salón Bella:     ana@salon-bella.com / password123        (Barranquilla)"
puts "  Fresh Cuts:      miguel@freshcuts.com / password123       (Barranquilla, no onboarded)"
puts "  Barbería La 93:  ricardo@barberiala93.com / password123   (Bogotá)"
puts "  Studio 70:       laura@studio70.com / password123         (Medellín)"
puts "  Barber King:     suspended@example.com / password123      (Barranquilla, suspended)"
puts "  Glamour Studio:  inactive@example.com / password123       (Barranquilla, inactive)"
puts ""
