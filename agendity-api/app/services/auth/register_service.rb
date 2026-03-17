# frozen_string_literal: true

module Auth
  # Registers a new business owner: creates the User, a default Business,
  # and returns JWT + refresh token so the client is immediately authenticated.
  class RegisterService < BaseService
    def initialize(name:, email:, password:, password_confirmation:, phone: nil, business_name: nil, business_type: nil)
      @name                  = name
      @email                 = email
      @password              = password
      @password_confirmation = password_confirmation
      @phone                 = phone
      @business_name         = business_name
      @business_type         = business_type || "barbershop"
    end

    def call
      ActiveRecord::Base.transaction do
        user = build_user
        return failure("Validation failed", details: user.errors.full_messages) unless user.save

        business = create_default_business(user)
        return failure("Business creation failed", details: business.errors.full_messages) unless business.persisted?

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
        trial_ends_at:  30.days.from_now,
        cancellation_policy_pct:     0,
        cancellation_deadline_hours: 0,
        rating_average:              0
      )
    end

    def create_refresh_token(user)
      user.refresh_tokens.create!(
        token:      SecureRandom.hex(32),
        expires_at: 30.days.from_now
      )
    end
  end
end
