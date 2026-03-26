# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  let(:user) { create(:user, email: "test@example.com") }

  describe "#reset_password" do
    let(:token) { "abc123resettoken" }
    let(:mail) { described_class.reset_password(user, token) }

    it "renders the headers" do
      expect(mail.to).to eq(["test@example.com"])
      expect(mail.subject).to include("Restablecer tu contraseña")
    end

    it "includes the reset URL in the body" do
      expect(mail.body.parts.map(&:body).join).to include("reset-password?token=#{token}")
    end
  end
end
