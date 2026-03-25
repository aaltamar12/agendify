require "rails_helper"

RSpec.describe UserSerializer do
  let(:user) { create(:user) }

  subject(:result) { JSON.parse(described_class.render(user)) }

  it "renders expected keys" do
    expect(result).to include("id", "email", "name", "role")
  end

  it "does not expose password" do
    expect(result).not_to include("password", "encrypted_password")
  end
end
