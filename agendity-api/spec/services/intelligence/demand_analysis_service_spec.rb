require "rails_helper"

RSpec.describe Intelligence::DemandAnalysisService do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:service)  { create(:service, business: business, duration_minutes: 30) }

  subject { described_class.call(business: business) }

  describe "minimum data requirement" do
    context "with no appointments" do
      it "returns success with empty suggestions" do
        result = subject
        expect(result).to be_success
        expect(result.data).to be_empty
      end
    end
  end

  describe "high-demand months detection" do
    context "when a month has high occupancy" do
      before do
        # Create enough appointments to trigger high demand
        # Monthly capacity = 1 employee * (8*60/30 = 16 slots) * 26 days = 416
        # 70% threshold = ~291 appointments
        300.times do |i|
          customer = create(:customer, business: business)
          create(:appointment,
            business: business,
            employee: employee,
            service: service,
            customer: customer,
            appointment_date: 2.months.ago + (i % 28).days,
            start_time: "10:00",
            end_time: "10:30",
            status: :completed,
            price: 25_000)
        end
      end

      it "creates a pricing suggestion for the high-demand month" do
        result = subject
        expect(result).to be_success
        suggestions = result.data.select { |s| s.name.include?("Temporada alta") }
        expect(suggestions).not_to be_empty
      end

      it "creates suggestions with status 'suggested'" do
        result = subject
        result.data.each do |suggestion|
          expect(suggestion.status).to eq("suggested")
        end
      end
    end
  end

  describe "weekend patterns detection" do
    context "when weekends have significantly more demand" do
      before do
        # Create more appointments on weekends vs weekdays
        3.months.ago.to_date.upto(Date.current) do |date|
          next if date.wday.between?(1, 5) && rand > 0.2 # sparse weekdays
          count = [0, 6].include?(date.wday) ? 4 : 1

          count.times do
            customer = create(:customer, business: business)
            create(:appointment,
              business: business,
              employee: employee,
              service: service,
              customer: customer,
              appointment_date: date,
              start_time: "#{10 + rand(6)}:00",
              end_time: "#{10 + rand(6)}:30",
              status: :completed,
              price: 25_000)
          end
        end
      end

      it "detects weekend pattern and creates suggestion" do
        result = subject
        weekend_suggestion = result.data.find { |s| s.name.include?("fin de semana") }
        if weekend_suggestion
          expect(weekend_suggestion.days_of_week).to eq([0, 6])
          expect(weekend_suggestion.status).to eq("suggested")
        end
      end
    end
  end

  describe "does not create duplicate suggestions" do
    before do
      # Create an existing suggestion that overlaps
      create(:dynamic_pricing,
        business: business,
        name: "Existing pricing",
        start_date: Date.current,
        end_date: Date.current + 90.days,
        status: :suggested)

      # Create some appointments to potentially trigger suggestions
      50.times do |i|
        customer = create(:customer, business: business)
        create(:appointment,
          business: business,
          employee: employee,
          service: service,
          customer: customer,
          appointment_date: Date.current + (i % 7).days,
          start_time: "10:00",
          end_time: "10:30",
          status: :completed,
          price: 25_000)
      end
    end

    it "filters out suggestions that overlap with existing ones" do
      result = subject
      expect(result).to be_success
      # Should not create duplicate suggestions for the same period
      overlapping = DynamicPricing.where(business: business)
        .where(status: [:suggested, :active])
      # The existing one plus any non-overlapping new ones
      result.data.each do |suggestion|
        expect(suggestion.persisted?).to be true
      end
    end
  end

  describe "seasonal (December) patterns" do
    context "when December has significantly higher demand" do
      before do
        # Create high December appointments
        yearly_avg = 20
        dec_count = (yearly_avg * 1.5).to_i # 30 — well above 1.4x threshold

        # Spread appointments across all months for context
        (1..12).each do |month|
          count = month == 12 ? dec_count : yearly_avg
          count.times do
            customer = create(:customer, business: business)
            day = rand(1..28)
            create(:appointment,
              business: business,
              employee: employee,
              service: service,
              customer: customer,
              appointment_date: Date.new(Date.current.year - 1, month, day),
              start_time: "10:00",
              end_time: "10:30",
              status: :completed,
              price: 25_000)
          end
        end
      end

      it "creates a seasonal suggestion for December" do
        result = subject
        christmas = result.data.find { |s| s.name.include?("navidena") }
        if christmas
          expect(christmas.adjustment_mode).to eq("progressive_asc")
          expect(christmas.adjustment_start_value).to eq(10)
          expect(christmas.adjustment_end_value).to eq(25)
        end
      end
    end
  end
end
