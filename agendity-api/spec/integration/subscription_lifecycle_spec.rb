require "rails_helper"

RSpec.describe "Subscription Lifecycle", type: :model do
  include ActiveJob::TestHelper

  let(:plan) { create(:plan, name: "Profesional", price_monthly: 49_900) }
  let!(:referral_code) { create(:referral_code, code: "EMBAJADOR", commission_percentage: 10.0) }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsappChannel).to receive(:deliver)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
    allow(SiteConfig).to receive(:get).and_return(nil)
  end

  it "completes the full subscription lifecycle: trial -> alerts -> suspension -> checkout -> approval -> renewal" do
    # ============================================================
    # Step 1: Register a new business with referral code
    # ============================================================
    register_result = Auth::RegisterService.call(
      name: "Carlos Barbero",
      email: "carlos@barberiaelite.com",
      password: "password123",
      password_confirmation: "password123",
      phone: "3001234567",
      business_name: "Barberia Elite",
      business_type: "barbershop",
      referral_code: "embajador",
      terms_accepted: true
    )

    expect(register_result).to be_success
    user = User.find_by(email: "carlos@barberiaelite.com")
    business = user.businesses.first

    # Verify trial is active
    expect(business.trial_ends_at).to be > Time.current
    expect(business.status).to eq("active")
    expect(business.trial_alert_stage).to eq(0)

    # Verify referral was created in pending
    referral = business.referral
    expect(referral).to be_present
    expect(referral.status).to eq("pending")
    expect(referral.referral_code).to eq(referral_code)

    # ============================================================
    # Step 2: Verify trial active — features accessible
    # ============================================================
    # No subscription yet, but trial is active — current_plan returns nil (trial = all features)
    expect(business.current_plan).to be_nil
    expect(business.has_feature?(:ai_features)).to be true # Trial grants all features

    # ============================================================
    # Step 3: Simulate trial expiring in 2 days
    # ============================================================
    business.update!(trial_ends_at: 5.days.from_now.beginning_of_day)

    # Step 4: Run TrialExpiryAlertJob -> Stage 1
    perform_enqueued_jobs { TrialExpiryAlertJob.perform_now }

    business.reload
    expect(business.trial_alert_stage).to eq(1)
    expect(Notification.where(business: business).count).to eq(1)

    # ============================================================
    # Step 5: Simulate trial ending today
    # ============================================================
    business.update!(trial_ends_at: Date.current.beginning_of_day)

    # Step 6: Run TrialExpiryAlertJob -> Stage 2 (thank you)
    perform_enqueued_jobs { TrialExpiryAlertJob.perform_now }

    business.reload
    expect(business.trial_alert_stage).to eq(2)

    # ============================================================
    # Step 7: Simulate 2 days after trial ended
    # ============================================================
    business.update!(trial_ends_at: 2.days.ago.beginning_of_day)

    # Step 8: Run TrialExpiryAlertJob -> Stage 3 (suspension)
    perform_enqueued_jobs { TrialExpiryAlertJob.perform_now }

    # Step 9: Verify business is suspended
    business.reload
    expect(business.trial_alert_stage).to eq(3)
    expect(business.status).to eq("suspended")

    # ============================================================
    # Step 10: Checkout — create order with plan + proof
    # ============================================================
    # Create a proof file for the order
    order = SubscriptionPaymentOrder.create!(
      business: business,
      plan: plan,
      amount: plan.price_monthly,
      due_date: Date.current,
      period_start: Date.current,
      period_end: Date.current + 1.month,
      status: "proof_submitted",
      proof_submitted_at: Time.current
    )

    expect(order.status).to eq("proof_submitted")

    # ============================================================
    # Step 11: Approve payment
    # ============================================================
    approve_result = Subscriptions::ApprovePaymentService.call(
      order: order,
      reviewed_by: "admin@agendity.com"
    )

    expect(approve_result).to be_success

    # ============================================================
    # Step 12: Verify subscription, reactivation, referral
    # ============================================================
    business.reload
    order.reload
    referral.reload

    # Business reactivated
    expect(business.status).to eq("active")

    # Subscription created
    subscription = order.subscription
    expect(subscription).to be_present
    expect(subscription.status).to eq("active")
    expect(subscription.plan).to eq(plan)
    expect(subscription.start_date).to eq(Date.current)
    expect(subscription.end_date).to eq(Date.current + 1.month)

    # Order marked as paid
    expect(order.status).to eq("paid")
    expect(order.reviewed_by).to eq("admin@agendity.com")
    expect(order.reviewed_at).to be_present

    # Referral activated
    expect(referral.status).to eq("activated")
    expect(referral.subscription).to eq(subscription)
    expect(referral.activated_at).to eq(Date.current)
    expected_commission = plan.price_monthly * (referral_code.commission_percentage / 100.0)
    expect(referral.commission_amount).to eq(expected_commission)

    # ============================================================
    # Step 13: Simulate subscription about to expire (5 days)
    # ============================================================
    subscription.update!(end_date: Date.current + 5, expiry_alert_stage: 0)

    # Step 14: Run SubscriptionExpiryAlertJob -> Stage 1 alert
    perform_enqueued_jobs { SubscriptionExpiryAlertJob.perform_now }

    subscription.reload
    expect(subscription.expiry_alert_stage).to eq(1)

    # Simulate subscription expiring today
    subscription.update!(end_date: Date.current, expiry_alert_stage: 1)
    perform_enqueued_jobs { SubscriptionExpiryAlertJob.perform_now }

    subscription.reload
    expect(subscription.expiry_alert_stage).to eq(2)

    # ============================================================
    # Step 15: Renew subscription via process_renewal!
    # ============================================================
    original_end_date = subscription.end_date
    subscription.process_renewal!

    # ============================================================
    # Step 16: Verify renewal
    # ============================================================
    subscription.reload
    expect(subscription.expiry_alert_stage).to eq(0)
    expect(subscription.end_date).to eq(original_end_date + 1.month)
    expect(subscription.status).to eq("active")

    # Business should still be active
    business.reload
    expect(business.status).to eq("active")
  end
end
