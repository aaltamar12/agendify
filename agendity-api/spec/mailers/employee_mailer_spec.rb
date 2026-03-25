require "rails_helper"

RSpec.describe EmployeeMailer, type: :mailer do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:invitation) { create(:employee_invitation, employee: employee, business: business) }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
  end

  describe "#invitation" do
    let(:mail) { described_class.invitation(invitation) }

    it "sends to the invitation email" do
      expect(mail.to).to eq([invitation.email])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("invitaron")
      expect(mail.subject).to include(business.name)
    end
  end
end
