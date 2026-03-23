# frozen_string_literal: true

class CreateSiteConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :site_configs do |t|
      t.string :key, null: false
      t.text :value, null: false
      t.string :description
      t.timestamps
    end
    add_index :site_configs, :key, unique: true
  end
end
