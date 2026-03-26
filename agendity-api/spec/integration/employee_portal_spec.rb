require "rails_helper"

RSpec.describe "Employee Portal", type: :model do
  include ActiveJob::TestHelper

  let(:business) { create(:business, :with_hours, timezone: "America/Bogota") }
  let(:service)  { create(:service, business: business, price: 30_000, duration_minutes: 30) }
  let(:employee) { create(:employee, business: business, user_id: nil) }
  let(:other_employee) { create(:employee, business: business, user_id: nil) }
  let(:customer) { create(:customer, business: business) }
  let(:tomorrow) { Date.tomorrow }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsappChannel).to receive(:deliver)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
    allow(SiteConfig).to receive(:get).and_return(nil)

    # Suppress invitation email
    allow(EmployeeMailer).to receive_message_chain(:invitation, :deliver_later)
  end

  it "invites employee, accepts invitation, does check-in, and substitute check-in" do
    # ============================================================
    # Step 1: Invite employee (no user_id yet)
    # ============================================================
    expect(employee.user_id).to be_nil

    invite_result = Employees::InviteService.call(
      employee: employee,
      email: "pedro@barberia.com",
      send_email: true
    )

    expect(invite_result).to be_success
    invitation = invite_result.data
    expect(invitation).to be_a(EmployeeInvitation)
    expect(invitation.token).to be_present
    expect(invitation.email).to eq("pedro@barberia.com")

    # ============================================================
    # Step 2: Accept invitation (creates User with role employee)
    # ============================================================
    accept_result = Employees::AcceptInvitationService.call(
      token: invitation.token,
      password: "securepass123",
      password_confirmation: "securepass123"
    )

    expect(accept_result).to be_success
    accept_data = accept_result.data

    expect(accept_data[:token]).to be_present
    expect(accept_data[:refresh_token]).to be_present
    expect(accept_data[:user][:role]).to eq("employee")

    employee.reload
    expect(employee.user_id).to be_present

    employee_user = User.find(employee.user_id)
    expect(employee_user.role).to eq("employee")
    expect(employee_user.email).to eq("pedro@barberia.com")

    invitation.reload
    expect(invitation.accepted_at).to be_present

    # ============================================================
    # Step 3: Create confirmed appointment for the employee
    # ============================================================
    appointment = create(:appointment, :confirmed,
      business: business,
      employee: employee,
      service: service,
      customer: customer,
      appointment_date: tomorrow,
      start_time: "10:00",
      end_time: "10:30",
      price: 30_000)

    # ============================================================
    # Step 4: Employee does check-in on own appointment
    # ============================================================
    checkin_time = Time.zone.parse("#{tomorrow} 09:45").in_time_zone("America/Bogota")

    travel_to checkin_time do
      checkin_result = Appointments::CheckinService.call(
        appointment: appointment,
        actor: employee_user
      )

      expect(checkin_result).to be_success
      appointment.reload
      expect(appointment.status).to eq("checked_in")
      expect(appointment.checked_in_by_type).to eq("employee")
      expect(appointment.checked_in_by_id).to eq(employee_user.id)
      expect(appointment.checkin_substitute).to be false
    end

    # ============================================================
    # Step 5: Create appointment for OTHER employee
    # ============================================================
    other_appointment = create(:appointment, :confirmed,
      business: business,
      employee: other_employee,
      service: service,
      customer: create(:customer, business: business),
      appointment_date: tomorrow,
      start_time: "11:00",
      end_time: "11:30",
      price: 30_000)

    # ============================================================
    # Step 6: Employee does substitute check-in (different employee's appointment)
    # ============================================================
    travel_to Time.zone.parse("#{tomorrow} 10:45").in_time_zone("America/Bogota") do
      # First attempt without confirmed flag — should require confirmation
      substitute_result = Appointments::CheckinService.call(
        appointment: other_appointment,
        actor: employee_user
      )

      expect(substitute_result).not_to be_success
      expect(substitute_result.data[:requires_confirmation]).to be true

      # Retry with confirmed: true and substitute reason
      confirmed_result = Appointments::CheckinService.call(
        appointment: other_appointment,
        actor: employee_user,
        confirmed: true,
        substitute_reason: "Empleado ausente"
      )

      expect(confirmed_result).to be_success
      other_appointment.reload
      expect(other_appointment.status).to eq("checked_in")
      expect(other_appointment.checkin_substitute).to be true
      expect(other_appointment.checkin_substitute_reason).to eq("Empleado ausente")
    end
  end
end
