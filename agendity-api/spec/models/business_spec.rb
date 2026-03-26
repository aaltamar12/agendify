require "rails_helper"

RSpec.describe Business, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:business_type) }
    it { should validate_presence_of(:status) }

    it do
      create(:business)
      should validate_uniqueness_of(:slug)
    end
  end

  describe "enums" do
    it { should define_enum_for(:business_type).with_values(barbershop: 0, salon: 1, spa: 2, nails: 3, other: 4, estetica: 5, consultorio: 6) }
    it { should define_enum_for(:status).with_values(active: 0, suspended: 1, inactive: 2) }
  end

  describe "associations" do
    it { should belong_to(:owner).class_name("User") }
    it { should have_many(:employees).dependent(:destroy) }
    it { should have_many(:services).dependent(:destroy) }
    it { should have_many(:customers).dependent(:destroy) }
    it { should have_many(:appointments).dependent(:destroy) }
    it { should have_many(:reviews).dependent(:destroy) }
    it { should have_many(:business_hours).dependent(:destroy) }
    it { should have_many(:blocked_slots).dependent(:destroy) }
    it { should have_many(:subscriptions).dependent(:destroy) }
  end

  describe "encrypted attributes" do
    let(:business) { create(:business, breb_key: "ABC123DEF456") }

    it "encrypts breb_key" do
      # Reading back should return the original value (transparent decryption)
      expect(business.reload.breb_key).to eq("ABC123DEF456")
    end

    it "stores breb_key encrypted in the database" do
      business.reload
      raw = Business.connection.select_value(
        "SELECT breb_key FROM businesses WHERE id = #{business.id}"
      )
      expect(raw).not_to eq("ABC123DEF456")
    end
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_biz) { create(:business, status: :active) }
      let!(:suspended_biz) { create(:business, status: :suspended) }

      it "returns only active businesses" do
        expect(Business.active).to include(active_biz)
        expect(Business.active).not_to include(suspended_biz)
      end
    end

    describe ".independent" do
      let!(:independent_biz) { create(:business, independent: true) }
      let!(:establishment_biz) { create(:business, independent: false) }

      it "returns only independent businesses" do
        expect(Business.independent).to include(independent_biz)
        expect(Business.independent).not_to include(establishment_biz)
      end
    end

    describe ".establishments" do
      let!(:independent_biz) { create(:business, independent: true) }
      let!(:establishment_biz) { create(:business, independent: false) }

      it "returns only non-independent businesses" do
        expect(Business.establishments).to include(establishment_biz)
        expect(Business.establishments).not_to include(independent_biz)
      end
    end

    describe ".in_trial" do
      let!(:in_trial) { create(:business, trial_ends_at: 5.days.from_now) }
      let!(:trial_over) { create(:business, trial_ends_at: 1.day.ago) }

      it "returns businesses with active trial" do
        expect(Business.in_trial).to include(in_trial)
        expect(Business.in_trial).not_to include(trial_over)
      end
    end

    describe ".trial_expiring_in" do
      let!(:expiring_in_5) { create(:business, trial_ends_at: (Date.current + 5).beginning_of_day) }
      let!(:expiring_in_10) { create(:business, trial_ends_at: (Date.current + 10).beginning_of_day) }

      it "returns businesses whose trial expires in N days" do
        expect(Business.trial_expiring_in(5)).to include(expiring_in_5)
        expect(Business.trial_expiring_in(5)).not_to include(expiring_in_10)
      end
    end

    describe ".trial_expired_since" do
      let!(:expired_2_days) { create(:business, trial_ends_at: (Date.current - 2).beginning_of_day) }
      let!(:expired_5_days) { create(:business, trial_ends_at: (Date.current - 5).beginning_of_day) }

      it "returns businesses whose trial expired N days ago" do
        expect(Business.trial_expired_since(2)).to include(expired_2_days)
        expect(Business.trial_expired_since(2)).not_to include(expired_5_days)
      end
    end
  end

  describe "callbacks" do
    describe "#extract_coords_from_google_maps_url" do
      it "extracts coordinates from /@lat,lng pattern" do
        business = create(:business, google_maps_url: "https://www.google.com/maps/place/Test/@10.9878,-74.7889,17z/data=blah")
        expect(business.latitude).to eq(10.9878)
        expect(business.longitude).to eq(-74.7889)
      end

      it "extracts coordinates from ?q=lat,lng pattern" do
        business = create(:business, google_maps_url: "https://maps.google.com/?q=10.9878,-74.7889")
        expect(business.latitude).to eq(10.9878)
        expect(business.longitude).to eq(-74.7889)
      end

      it "extracts coordinates from /search/lat,lng pattern" do
        business = create(:business, google_maps_url: "https://www.google.com/maps/search/10.9878,-74.7889")
        expect(business.latitude).to eq(10.9878)
        expect(business.longitude).to eq(-74.7889)
      end

      it "extracts coordinates from !3d!4d pattern" do
        business = create(:business, google_maps_url: "https://www.google.com/maps/!3d10.9878!4d-74.7889")
        expect(business.latitude).to eq(10.9878)
        expect(business.longitude).to eq(-74.7889)
      end

      it "extracts coordinates from /place/lat,lng pattern" do
        business = create(:business, google_maps_url: "https://www.google.com/maps/place/10.9878,-74.7889")
        expect(business.latitude).to eq(10.9878)
        expect(business.longitude).to eq(-74.7889)
      end

      it "does not crash on blank google_maps_url" do
        business = create(:business, google_maps_url: "")
        expect(business).to be_valid
      end

      it "handles short URLs by attempting to resolve them" do
        redirect_response = double("redirect_response")
        allow(redirect_response).to receive(:is_a?).and_return(false)
        allow(redirect_response).to receive(:is_a?).with(Net::HTTPRedirection).and_return(true)
        allow(redirect_response).to receive(:[]).with("location").and_return("https://www.google.com/maps/place/Test/@10.9878,-74.7889,17z")
        allow(Net::HTTP).to receive(:start).and_return(redirect_response)

        business = create(:business, google_maps_url: "https://goo.gl/maps/abc123")
        expect(business.latitude).to eq(10.9878)
        expect(business.longitude).to eq(-74.7889)
      end

      it "gracefully handles resolution errors for short URLs" do
        allow(Net::HTTP).to receive(:start).and_raise(StandardError.new("DNS failure"))

        expect { create(:business, google_maps_url: "https://goo.gl/maps/badurl") }.not_to raise_error
      end

      it "follows chained short URL redirects (maps.app redirect)" do
        # First redirect to another maps.app URL, then to the final URL
        first_response = double("first_response")
        allow(first_response).to receive(:is_a?).with(anything).and_return(false)
        allow(first_response).to receive(:is_a?).with(Net::HTTPRedirection).and_return(true)
        allow(first_response).to receive(:[]).with("location").and_return("https://maps.app.goo.gl/chain123")

        second_response = double("second_response")
        allow(second_response).to receive(:is_a?).with(anything).and_return(false)
        allow(second_response).to receive(:is_a?).with(Net::HTTPRedirection).and_return(true)
        allow(second_response).to receive(:[]).with("location").and_return("https://www.google.com/maps/place/Test/@10.1234,-74.5678,17z")

        call_count = 0
        allow(Net::HTTP).to receive(:start) do
          call_count += 1
          call_count == 1 ? first_response : second_response
        end

        business = create(:business, google_maps_url: "https://goo.gl/maps/test123")
        expect(business.latitude).to eq(10.1234)
        expect(business.longitude).to eq(-74.5678)
      end

      it "returns original URL when response is not a redirect" do
        non_redirect = double("non_redirect")
        allow(non_redirect).to receive(:is_a?).with(anything).and_return(false)
        allow(non_redirect).to receive(:is_a?).with(Net::HTTPRedirection).and_return(false)
        allow(Net::HTTP).to receive(:start).and_return(non_redirect)

        # URL without coords won't set lat/lng but should not error
        expect { create(:business, google_maps_url: "https://goo.gl/maps/nocoords") }.not_to raise_error
      end
    end
  end

  describe ".ransackable_attributes" do
    it "returns expected attributes" do
      expect(Business.ransackable_attributes).to include("name", "slug", "business_type", "status")
    end
  end

  describe ".ransackable_associations" do
    it "returns expected associations" do
      expect(Business.ransackable_associations).to include("owner", "employees")
    end
  end

  describe "#full_address (private)" do
    it "concatenates address, city, country" do
      business = build(:business, address: "Calle 50", city: "Barranquilla", country: "CO")
      expect(business.send(:full_address)).to eq("Calle 50, Barranquilla, CO")
    end
  end

  describe "PlanEnforcement" do
    let(:business) { create(:business) }

    let(:plan_basico) do
      create(:plan, name: "Básico", price_monthly: 30_000,
             max_employees: 3, max_services: 5,
             ticket_digital: false, advanced_reports: false,
             brand_customization: false, ai_features: false)
    end

    let(:plan_profesional) do
      create(:plan, name: "Profesional", price_monthly: 59_900,
             max_employees: 10, max_services: nil,
             ticket_digital: true, advanced_reports: true,
             brand_customization: true, ai_features: false)
    end

    describe "#current_plan" do
      it "returns nil when no active subscription" do
        expect(business.current_plan).to be_nil
      end

      it "returns the plan of the current active subscription" do
        create(:subscription, business: business, plan: plan_basico,
               status: :active, start_date: Date.current, end_date: 30.days.from_now)
        expect(business.current_plan).to eq(plan_basico)
      end

      it "ignores expired subscriptions" do
        create(:subscription, business: business, plan: plan_basico,
               status: :active, start_date: 60.days.ago, end_date: 1.day.ago)
        expect(business.current_plan).to be_nil
      end
    end

    describe "#can_create_employee?" do
      context "with no plan (trial)" do
        it "returns true" do
          expect(business.can_create_employee?).to be true
        end
      end

      context "with basic plan (max 3 employees)" do
        before do
          create(:subscription, business: business, plan: plan_basico,
                 status: :active, start_date: Date.current, end_date: 30.days.from_now)
        end

        it "returns true when under the limit" do
          create_list(:employee, 2, business: business, active: true)
          expect(business.can_create_employee?).to be true
        end

        it "returns false when at the limit" do
          create_list(:employee, 3, business: business, active: true)
          expect(business.can_create_employee?).to be false
        end

        it "does not count inactive employees" do
          create_list(:employee, 3, business: business, active: true)
          create(:employee, business: business, active: false)
          business.employees.active.first.update!(active: false)
          expect(business.can_create_employee?).to be true
        end
      end

      context "with professional plan (max 10 employees)" do
        before do
          create(:subscription, business: business, plan: plan_profesional,
                 status: :active, start_date: Date.current, end_date: 30.days.from_now)
        end

        it "returns true when under the limit" do
          create_list(:employee, 5, business: business, active: true)
          expect(business.can_create_employee?).to be true
        end
      end
    end

    describe "#can_create_service?" do
      context "with no plan (trial)" do
        it "returns true" do
          expect(business.can_create_service?).to be true
        end
      end

      context "with basic plan (max 5 services)" do
        before do
          create(:subscription, business: business, plan: plan_basico,
                 status: :active, start_date: Date.current, end_date: 30.days.from_now)
        end

        it "returns true when under the limit" do
          create_list(:service, 4, business: business, active: true)
          expect(business.can_create_service?).to be true
        end

        it "returns false when at the limit" do
          create_list(:service, 5, business: business, active: true)
          expect(business.can_create_service?).to be false
        end
      end

      context "with professional plan (unlimited services)" do
        before do
          create(:subscription, business: business, plan: plan_profesional,
                 status: :active, start_date: Date.current, end_date: 30.days.from_now)
        end

        it "returns true regardless of count" do
          create_list(:service, 20, business: business, active: true)
          expect(business.can_create_service?).to be true
        end
      end
    end

    describe "#has_feature?" do
      context "with no plan (trial)" do
        it "returns true for any feature" do
          expect(business.has_feature?(:ticket_digital)).to be true
          expect(business.has_feature?(:brand_customization)).to be true
          expect(business.has_feature?(:ai_features)).to be true
        end
      end

      context "with basic plan" do
        before do
          create(:subscription, business: business, plan: plan_basico,
                 status: :active, start_date: Date.current, end_date: 30.days.from_now)
        end

        it "returns false for premium features" do
          expect(business.has_feature?(:ticket_digital)).to be false
          expect(business.has_feature?(:brand_customization)).to be false
          expect(business.has_feature?(:advanced_reports)).to be false
          expect(business.has_feature?(:ai_features)).to be false
        end
      end

      context "with professional plan" do
        before do
          create(:subscription, business: business, plan: plan_profesional,
                 status: :active, start_date: Date.current, end_date: 30.days.from_now)
        end

        it "returns true for professional features" do
          expect(business.has_feature?(:ticket_digital)).to be true
          expect(business.has_feature?(:brand_customization)).to be true
          expect(business.has_feature?(:advanced_reports)).to be true
        end

        it "returns false for AI features" do
          expect(business.has_feature?(:ai_features)).to be false
        end
      end
    end
  end

  describe "AttachmentValidations" do
    let(:business) { create(:business) }

    it "rejects logo with invalid content type" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("fake content"),
        filename: "test.txt",
        content_type: "text/plain"
      )
      business.logo.attach(blob)
      business.validate
      expect(business.errors[:logo]).to be_present
    end

    it "rejects logo that exceeds max size" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("x" * 6.megabytes),
        filename: "huge.png",
        content_type: "image/png"
      )
      business.logo.attach(blob)
      business.validate
      expect(business.errors[:logo]).to be_present
    end
  end
end
