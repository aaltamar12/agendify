# frozen_string_literal: true

# Join table linking appointments to additional services.
# Stores the price and duration at the time of booking for historical accuracy.
class AppointmentService < ApplicationRecord
  belongs_to :appointment
  belongs_to :service

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
  validates :service_id, uniqueness: { scope: :appointment_id }
end
