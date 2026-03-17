# frozen_string_literal: true

class BlockedSlotSerializer < Blueprinter::Base
  identifier :id

  fields :business_id, :employee_id, :date, :reason, :all_day,
         :created_at, :updated_at

  field :start_time do |blocked_slot, _options|
    blocked_slot.start_time&.strftime("%H:%M")
  end

  field :end_time do |blocked_slot, _options|
    blocked_slot.end_time&.strftime("%H:%M")
  end
end
