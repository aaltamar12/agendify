# frozen_string_literal: true

module Auth
  # Registers a new business owner: creates the User, a default Business,
  # and returns JWT + refresh token so the client is immediately authenticated.
  class RegisterService < BaseService
    def initialize(name:, email:, password:, password_confirmation:, phone: nil, business_name: nil, business_type: nil, referral_code: nil, terms_accepted: nil)
      @name                  = name
      @email                 = email
      @password              = password
      @password_confirmation = password_confirmation
      @phone                 = phone
      @business_name         = business_name
      @business_type         = business_type || "barbershop"
      @referral_code         = referral_code
      @terms_accepted        = terms_accepted
    end

    def call
      return failure("Debes aceptar los términos y condiciones", code: "TERMS_NOT_ACCEPTED") unless @terms_accepted.present?

      ActiveRecord::Base.transaction do
        user = build_user
        return failure("Validation failed", code: "USER_VALIDATION_FAILED", details: user.errors.full_messages) unless user.save

        business = create_default_business(user)
        return failure("Business creation failed", code: "BUSINESS_CREATION_FAILED", details: business.errors.full_messages) unless business.persisted?

        associate_referral!(business)

        BusinessMailer.welcome(business).deliver_later

        trial_days = ((business.trial_ends_at - Time.current) / 1.day).round
        AdminNotification.notify!(
          title: "Nuevo negocio registrado",
          body: "#{business.name} (#{user.email}) — Trial #{trial_days} dias",
          notification_type: "new_business",
          link: "/admin/businesses/#{business.id}",
          icon: "🆕"
        )

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
        role:                  :owner,
        terms_accepted_at:     Time.current
      )
    end

    def create_default_business(user)
      user.businesses.create!(
        name:           @business_name.presence || "#{@name}'s Business",
        business_type:  @business_type,
        status:         :active,
        trial_ends_at:  trial_duration.from_now,
        cancellation_policy_pct:     0,
        cancellation_deadline_hours: 0,
        rating_average:              0
      )
    end

    def trial_duration
      if @referral_code.present? &&
         ReferralCode.active.where("LOWER(code) = ?", @referral_code.downcase).exists?
        (SiteConfig.get("referral_trial_days") || "25").to_i.days
      else
        (SiteConfig.get("default_trial_days") || "7").to_i.days
      end
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
