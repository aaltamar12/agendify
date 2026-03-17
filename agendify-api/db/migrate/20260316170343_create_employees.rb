# frozen_string_literal: true

class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees do |t|
      t.references :business, null: false, foreign_key: true
      t.string  :name, null: false
      t.string  :photo_url
      t.string  :phone
      t.string  :email
      t.boolean :active, default: true, null: false

      t.timestamps
    end
  end
end
