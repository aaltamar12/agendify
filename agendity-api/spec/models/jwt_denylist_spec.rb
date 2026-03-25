require "rails_helper"

RSpec.describe JwtDenylist, type: :model do
  it "can be created with jti and exp" do
    denylist = described_class.create!(jti: SecureRandom.uuid, exp: 1.day.from_now)
    expect(denylist).to be_persisted
  end

  it "enforces unique jti" do
    jti = SecureRandom.uuid
    described_class.create!(jti: jti, exp: 1.day.from_now)
    expect {
      described_class.create!(jti: jti, exp: 1.day.from_now)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
