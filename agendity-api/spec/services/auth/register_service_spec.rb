require "rails_helper"

RSpec.describe Auth::RegisterService do
  let(:base_params) do
    {
      name: "Carlos Barbero",
      email: "carlos@barberia.com",
      password: "password123",
      password_confirmation: "password123",
      phone: "3001234567",
      business_name: "Barberia Elite",
      business_type: "barbershop",
      terms_accepted: true
    }
  end

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsappChannel).to receive(:deliver)
  end

  describe "#call" do
    subject { described_class.call(**base_params) }

    context "with valid params" do
      it "creates a User with owner role" do
        expect { subject }.to change(User, :count).by(1)

        user = User.last
        expect(user.name).to eq("Carlos Barbero")
        expect(user.email).to eq("carlos@barberia.com")
        expect(user.role).to eq("owner")
      end

      it "creates a Business with trial_ends_at = 25 days from now" do
        freeze_time do
          result = subject
          business = Business.last

          expect(business.name).to eq("Barberia Elite")
          expect(business.business_type).to eq("barbershop")
          expect(business.status).to eq("active")
          expect(business.trial_ends_at).to be_within(1.second).of(25.days.from_now)
        end
      end

      it "returns JWT token and refresh token" do
        result = subject

        expect(result).to be_success
        expect(result.data[:token]).to be_present
        expect(result.data[:refresh_token]).to be_present
        expect(result.data[:user]).to be_present
      end

      it "creates a refresh token for the user" do
        expect { subject }.to change(RefreshToken, :count).by(1)
      end

      it "sends welcome email" do
        expect { subject }.to have_enqueued_mail(BusinessMailer, :welcome)
      end

      it "creates an AdminNotification for the new business" do
        expect { subject }.to change(AdminNotification, :count).by(1)

        notification = AdminNotification.last
        expect(notification.title).to eq("Nuevo negocio registrado")
        expect(notification.notification_type).to eq("new_business")
      end

      it "uses the user name for business if business_name is blank" do
        params = base_params.merge(business_name: nil)
        described_class.call(**params)

        business = Business.last
        expect(business.name).to eq("Carlos Barbero's Business")
      end
    end

    context "with a valid referral code" do
      let!(:referral_code) { create(:referral_code, code: "AMIGO2024") }

      subject { described_class.call(**base_params.merge(referral_code: "amigo2024")) }

      it "creates a Referral in pending status" do
        expect { subject }.to change(Referral, :count).by(1)

        referral = Referral.last
        expect(referral.status).to eq("pending")
        expect(referral.referral_code).to eq(referral_code)
      end

      it "associates the referral_code with the business" do
        subject
        business = Business.last

        expect(business.referral_code).to eq(referral_code)
      end

      it "matches referral code case-insensitively" do
        result = described_class.call(**base_params.merge(
          referral_code: "AMIGO2024",
          email: "otro@test.com"
        ))

        expect(result).to be_success
        expect(Referral.count).to eq(1)
      end
    end

    context "with an invalid referral code" do
      subject { described_class.call(**base_params.merge(referral_code: "NOEXISTE")) }

      it "still registers the user and business successfully" do
        result = subject

        expect(result).to be_success
        expect(User.count).to eq(1)
        expect(Business.count).to eq(1)
      end

      it "does not create a Referral" do
        expect { subject }.not_to change(Referral, :count)
      end

      it "does not associate any referral_code with the business" do
        subject
        business = Business.last

        expect(business.referral_code).to be_nil
      end
    end

    context "with an inactive referral code" do
      let!(:referral_code) { create(:referral_code, code: "INACTIVE1", status: :inactive) }

      subject { described_class.call(**base_params.merge(referral_code: "INACTIVE1")) }

      it "does not create a Referral (inactive codes are filtered)" do
        expect { subject }.not_to change(Referral, :count)
      end
    end

    context "with blank referral code" do
      subject { described_class.call(**base_params.merge(referral_code: "")) }

      it "registers successfully without referral" do
        result = subject

        expect(result).to be_success
        expect(Referral.count).to eq(0)
      end
    end

    context "without terms_accepted" do
      subject { described_class.call(**base_params.merge(terms_accepted: nil)) }

      it "returns failure with TERMS_NOT_ACCEPTED code" do
        result = subject

        expect(result).to be_failure
        expect(result.error_code).to eq("TERMS_NOT_ACCEPTED")
        expect(result.error).to eq("Debes aceptar los términos y condiciones")
      end

      it "does not create a User" do
        expect { subject }.not_to change(User, :count)
      end

      it "does not create a Business" do
        expect { subject }.not_to change(Business, :count)
      end
    end

    context "with terms_accepted" do
      subject { described_class.call(**base_params.merge(terms_accepted: true)) }

      it "sets terms_accepted_at on the user" do
        freeze_time do
          subject
          user = User.last

          expect(user.terms_accepted_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    context "with invalid user data" do
      subject { described_class.call(**base_params.merge(password_confirmation: "wrong")) }

      it "returns failure" do
        result = subject

        expect(result).to be_failure
        expect(result.error_code).to eq("USER_VALIDATION_FAILED")
      end

      it "does not create a User" do
        expect { subject }.not_to change(User, :count)
      end

      it "does not create a Business" do
        expect { subject }.not_to change(Business, :count)
      end
    end

    context "with duplicate email" do
      before { create(:user, email: "carlos@barberia.com") }

      it "returns failure" do
        result = subject

        expect(result).to be_failure
      end
    end
  end
end
