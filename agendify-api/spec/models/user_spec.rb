require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:role) }

    it do
      create(:user)
      should validate_uniqueness_of(:email).case_insensitive
    end
  end

  describe "enums" do
    it { should define_enum_for(:role).with_values(owner: 0, admin: 1, employee: 2) }
  end

  describe "associations" do
    it { should have_many(:businesses).with_foreign_key(:owner_id).dependent(:destroy) }
    it { should have_many(:refresh_tokens).dependent(:destroy) }
  end
end
