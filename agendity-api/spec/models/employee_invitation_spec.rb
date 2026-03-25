require "rails_helper"

RSpec.describe EmployeeInvitation, type: :model do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }

  describe "associations" do
    it { is_expected.to belong_to(:employee) }
    it { is_expected.to belong_to(:business) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }

    it "auto-generates token before validation" do
      invitation = build(:employee_invitation, employee: employee, business: business, token: nil)
      invitation.valid?
      expect(invitation.token).to be_present
    end

    it "validates uniqueness of token" do
      inv1 = create(:employee_invitation, employee: employee, business: business)
      inv2 = build(:employee_invitation, employee: employee, business: business, token: inv1.token)
      expect(inv2).not_to be_valid
    end
  end

  describe "callbacks" do
    it "sets expiration on create" do
      invitation = create(:employee_invitation, employee: employee, business: business)
      expect(invitation.expires_at).to be_present
      expect(invitation.expires_at).to be > Time.current
    end
  end

  describe "#expired?" do
    it "returns true when past expiration" do
      invitation = create(:employee_invitation, employee: employee, business: business)
      invitation.update_column(:expires_at, 1.day.ago)
      expect(invitation.expired?).to be true
    end

    it "returns false when not expired" do
      invitation = create(:employee_invitation, employee: employee, business: business)
      expect(invitation.expired?).to be false
    end
  end

  describe "#accepted?" do
    it "returns true when accepted_at is set" do
      invitation = create(:employee_invitation, employee: employee, business: business)
      invitation.update_column(:accepted_at, Time.current)
      expect(invitation.accepted?).to be true
    end

    it "returns false when not accepted" do
      invitation = create(:employee_invitation, employee: employee, business: business)
      expect(invitation.accepted?).to be false
    end
  end

  describe "scopes" do
    describe ".pending" do
      let!(:pending) { create(:employee_invitation, employee: employee, business: business) }
      let!(:accepted) do
        inv = create(:employee_invitation, employee: employee, business: business)
        inv.update_column(:accepted_at, Time.current)
        inv
      end
      let!(:expired) do
        inv = create(:employee_invitation, employee: employee, business: business)
        inv.update_column(:expires_at, 1.day.ago)
        inv
      end

      it "returns only pending, non-expired invitations" do
        expect(described_class.pending).to include(pending)
        expect(described_class.pending).not_to include(accepted)
        expect(described_class.pending).not_to include(expired)
      end
    end
  end
end
