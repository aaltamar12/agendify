# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Credits Toggle (credits_enabled)", type: :model do
  include ActiveJob::TestHelper

  let(:plan) do
    create(:plan,
      name: "Profesional",
      price_monthly: 99_900,
      cashback_enabled: true,
      cashback_percentage: 5)
  end
  let(:business) do
    create(:business, :with_hours,
      timezone: "America/Bogota",
      credits_enabled: true)
  end
  let!(:subscription) { create(:subscription, business: business, plan: plan, status: :active) }
  let(:service)  { create(:service, business: business, price: 40_000, duration_minutes: 30) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:tomorrow) { Date.tomorrow }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsAppChannel).to receive(:deliver)
    allow(Notifications::MultiChannelService).to receive(:call).and_return(
      ServiceResult.new(success: true, data: nil)
    )
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
    allow(SiteConfig).to receive(:get).and_return(nil)

    employee.services << service
    employee.employee_schedules.create!(
      day_of_week: tomorrow.wday,
      start_time: "08:00",
      end_time: "18:00"
    )
  end

  describe "booking with credits" do
    let!(:credit_account) do
      CreditAccount.create!(customer: customer, business: business, balance: 10_000)
    end

    context "when credits_enabled is true" do
      it "allows applying credits to a booking" do
        result = Appointments::CreateAppointmentService.call(
          business: business,
          params: {
            service_id: service.id,
            employee_id: employee.id,
            appointment_date: tomorrow,
            start_time: "10:00",
            customer_email: customer.email,
            customer_name: customer.name,
            customer_phone: customer.phone,
            apply_credits: 5_000
          }
        )

        expect(result).to be_success
        appointment = result.data[:appointment]
        expect(appointment.credits_applied).to eq(5_000)
        expect(credit_account.reload.balance).to eq(5_000)
      end
    end

    context "when credits_enabled is false" do
      before { business.update!(credits_enabled: false) }

      it "ignores apply_credits and does not deduct balance" do
        result = Appointments::CreateAppointmentService.call(
          business: business,
          params: {
            service_id: service.id,
            employee_id: employee.id,
            appointment_date: tomorrow,
            start_time: "10:00",
            customer_email: customer.email,
            customer_name: customer.name,
            customer_phone: customer.phone,
            apply_credits: 5_000
          }
        )

        expect(result).to be_success
        appointment = result.data[:appointment]
        expect(appointment.credits_applied).to eq(0)
        expect(credit_account.reload.balance).to eq(10_000)
      end
    end
  end

  describe "cashback on completion" do
    context "when credits_enabled is true" do
      it "awards cashback credits" do
        appointment = create(:appointment,
          business: business,
          customer: customer,
          employee: employee,
          service: service,
          price: 40_000,
          status: :completed)

        result = Credits::CashbackService.call(appointment: appointment)
        expect(result).to be_success
        expect(result.data).to eq(2_000) # 5% of 40,000
      end
    end

    context "when credits_enabled is false" do
      before { business.update!(credits_enabled: false) }

      it "does not award cashback credits" do
        appointment = create(:appointment,
          business: business,
          customer: customer,
          employee: employee,
          service: service,
          price: 40_000,
          status: :completed)

        result = Credits::CashbackService.call(appointment: appointment)
        expect(result).to be_success
        expect(result.data).to be_nil
      end
    end
  end
end
