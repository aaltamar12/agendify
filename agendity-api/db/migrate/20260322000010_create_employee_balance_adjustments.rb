# frozen_string_literal: true

class CreateEmployeeBalanceAdjustments < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_balance_adjustments do |t|
      t.references :business, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.references :performed_by_user, null: false, foreign_key: { to_table: :users }
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.decimal :balance_before, precision: 12, scale: 2
      t.decimal :balance_after, precision: 12, scale: 2
      t.string :reason, null: false
      t.text :notes
      t.timestamps
    end

    add_index :employee_balance_adjustments, %i[business_id employee_id]
  end
end
