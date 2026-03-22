require "rails_helper"

RSpec.describe Employees::InviteService do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business, user_id: nil) }
  let(:email)    { "barbero@test.com" }

  before do
    # Stub mailer
    allow(EmployeeMailer).to receive_message_chain(:invitation, :deliver_later)
  end

  subject { described_class.call(employee: employee, email: email) }

  context "when employee has no linked account" do
    it "returns success" do
      expect(subject).to be_success
    end

    it "creates an invitation with a token" do
      expect { subject }.to change(EmployeeInvitation, :count).by(1)
      invitation = EmployeeInvitation.last
      expect(invitation.employee).to eq(employee)
      expect(invitation.business).to eq(business)
      expect(invitation.email).to eq(email)
      expect(invitation.token).to be_present
      expect(invitation.expires_at).to be > Time.current
    end

    it "sends invitation email" do
      mailer_double = double(deliver_later: true)
      expect(EmployeeMailer).to receive(:invitation).and_return(mailer_double)
      subject
    end

    it "does not send email when send_email is false" do
      expect(EmployeeMailer).not_to receive(:invitation)
      described_class.call(employee: employee, email: email, send_email: false)
    end
  end

  context "when employee already has an account" do
    let(:user) { create(:user) }
    let(:employee) { create(:employee, business: business, user_id: user.id) }

    it "returns failure" do
      result = subject
      expect(result).to be_failure
      expect(result.error).to eq("El empleado ya tiene una cuenta vinculada")
    end

    it "does not create an invitation" do
      expect { subject }.not_to change(EmployeeInvitation, :count)
    end
  end
end
