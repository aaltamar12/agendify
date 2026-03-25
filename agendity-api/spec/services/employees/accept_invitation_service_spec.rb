require "rails_helper"

RSpec.describe Employees::AcceptInvitationService do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business, user_id: nil, name: "Juan Barbero") }
  let!(:invitation) do
    create(:employee_invitation,
      employee: employee,
      business: business,
      email: "juan@test.com")
  end

  let(:password) { "securepass123" }

  subject do
    described_class.call(
      token: invitation.token,
      password: password,
      password_confirmation: password
    )
  end

  context "with valid invitation" do
    it "returns success" do
      expect(subject).to be_success
    end

    it "creates a user with role employee" do
      expect { subject }.to change(User, :count).by(1)
      user = User.last
      expect(user.role).to eq("employee")
      expect(user.name).to eq("Juan Barbero")
      expect(user.email).to eq("juan@test.com")
    end

    it "links the user to the employee" do
      subject
      expect(employee.reload.user_id).to be_present
      expect(employee.user.email).to eq("juan@test.com")
    end

    it "marks invitation as accepted" do
      subject
      expect(invitation.reload.accepted_at).to be_present
    end

    it "returns JWT token and refresh token" do
      result = subject
      expect(result.data[:token]).to be_present
      expect(result.data[:refresh_token]).to be_present
      expect(result.data[:user]).to be_present
    end
  end

  context "with expired invitation" do
    before do
      invitation.update_column(:expires_at, 1.hour.ago)
    end

    it "returns failure" do
      result = subject
      expect(result).to be_failure
      expect(result.error).to eq("La invitacion ha expirado")
    end

    it "does not create a user" do
      expect { subject }.not_to change(User, :count)
    end
  end

  context "with already accepted invitation" do
    before do
      invitation.update_column(:accepted_at, 1.hour.ago)
    end

    it "returns failure" do
      result = subject
      expect(result).to be_failure
      expect(result.error).to eq("La invitacion ya fue aceptada")
    end
  end

  context "with invalid token" do
    subject do
      described_class.call(
        token: "nonexistent-token",
        password: password,
        password_confirmation: password
      )
    end

    it "returns failure" do
      result = subject
      expect(result).to be_failure
      expect(result.error).to eq("Invitacion no encontrada")
    end
  end

  context "when employee already has an account" do
    before do
      existing_user = create(:user)
      employee.update!(user_id: existing_user.id)
    end

    it "returns failure" do
      result = subject
      expect(result).to be_failure
      expect(result.error).to eq("El empleado ya tiene una cuenta")
    end
  end

  context "with mismatching passwords" do
    subject do
      described_class.call(
        token: invitation.token,
        password: "password1",
        password_confirmation: "password2"
      )
    end

    it "returns failure with validation errors" do
      result = subject
      expect(result).to be_failure
    end
  end
end
