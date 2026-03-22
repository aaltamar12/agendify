# frozen_string_literal: true

class CreateEmployeeInvitationsAndCheckinFields < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_invitations do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :business, null: false, foreign_key: true
      t.string :email, null: false
      t.string :token, null: false
      t.datetime :accepted_at
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :employee_invitations, :token, unique: true

    # Check-in tracking fields
    add_column :appointments, :checked_in_by_type, :string
    add_column :appointments, :checked_in_by_id, :integer
    add_column :appointments, :checkin_substitute, :boolean, default: false
    add_column :appointments, :checkin_substitute_reason, :string
  end
end
