class CreateDiscountCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :discount_codes do |t|
      t.references :business, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name
      t.string :discount_type, default: "percentage" # percentage | fixed
      t.decimal :discount_value, precision: 10, scale: 2, null: false
      t.integer :max_uses
      t.integer :current_uses, default: 0, null: false
      t.date :valid_from
      t.date :valid_until
      t.boolean :active, default: true, null: false
      t.string :source # manual | birthday | referral | promo
      t.references :customer, foreign_key: true # if specific to a customer
      t.timestamps
    end

    add_index :discount_codes, [:business_id, :code], unique: true
  end
end
