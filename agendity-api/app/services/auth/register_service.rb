# frozen_string_literal: true

module Auth
  # Registers a new business owner: creates the User, a default Business,
  # and returns JWT + refresh token so the client is immediately authenticated.
  class RegisterService < BaseService
    def initialize(name:, email:, password:, password_confirmation:, phone: nil, business_name: nil, business_type: nil, referral_code: nil)
      @name                  = name
      @email                 = email
      @password              = password
      @password_confirmation = password_confirmation
      @phone                 = phone
      @business_name         = business_name
      @business_type         = business_type || "barbershop"
      @referral_code         = referral_code
    end

    def call
      ActiveRecord::Base.transaction do
        user = build_user
        return failure("Validation failed", code: "USER_VALIDATION_FAILED", details: user.errors.full_messages) unless user.save

        business = create_default_business(user)
        return failure("Business creation failed", code: "BUSINESS_CREATION_FAILED", details: business.errors.full_messages) unless business.persisted?

        associate_referral!(business)

        token         = TokenGenerator.encode(user)
        refresh_token = create_refresh_token(user)

        success({ token: token, refresh_token: refresh_token.token, user: UserSerializer.render_as_hash(user) })
      end
    end

    private

    def build_user
      User.new(
        name:                  @name,
        email:                 @email,
        password:              @password,
        password_confirmation: @password_confirmation,
        phone:                 @phone,
        role:                  :owner
      )
    end

    def create_default_business(user)
      user.businesses.create!(
        name:           @business_name.presence || "#{@name}'s Business",
        business_type:  @business_type,
        status:         :active,
        trial_ends_at:  7.days.from_now,
        cancellation_policy_pct:     0,
        cancellation_deadline_hours: 0,
        rating_average:              0
      )
    end

    def associate_referral!(business)
      return if @referral_code.blank?

      code = ReferralCode.active.find_by("LOWER(code) = ?", @referral_code.downcase)
      return unless code

      business.update!(referral_code: code)
      Referral.create!(referral_code: code, business: business, status: :pending)
    end

    def create_refresh_token(user)
      user.refresh_tokens.create!(
        token:      SecureRandom.hex(32),
        expires_at: 30.days.from_now
      )
    end
  end
end
