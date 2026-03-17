# frozen_string_literal: true

# Adds columns expected by the frontend TypeScript types but missing from the DB.
class AddMissingColumnsForFrontendAlignment < ActiveRecord::Migration[8.0]
  def change
    # Appointment: cancellation_reason expected by frontend
    add_column :appointments, :cancellation_reason, :string

    # Employee: user_id, bio, commission_percentage expected by frontend
    add_column :employees, :user_id, :bigint
    add_column :employees, :bio, :text
    add_column :employees, :commission_percentage, :decimal, precision: 5, scale: 2

    add_index :employees, :user_id
    add_foreign_key :employees, :users

    # Customer: notes expected by frontend
    add_column :customers, :notes, :text

    # Payment: reference, submitted_at, approved_at, rejected_at, rejection_reason expected by frontend
    add_column :payments, :reference, :string
    add_column :payments, :submitted_at, :datetime
    add_column :payments, :approved_at, :datetime
    add_column :payments, :rejected_at, :datetime
    add_column :payments, :rejection_reason, :string

    # BlockedSlot: all_day expected by frontend
    add_column :blocked_slots, :all_day, :boolean, default: false, null: false

    # User: avatar_url expected by frontend
    add_column :users, :avatar_url, :string

    # Review: appointment_id, employee_id expected by frontend
    add_column :reviews, :appointment_id, :bigint
    add_column :reviews, :employee_id, :bigint

    add_index :reviews, :appointment_id
    add_index :reviews, :employee_id
    add_foreign_key :reviews, :appointments
    add_foreign_key :reviews, :employees
  end
end
