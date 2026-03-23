# frozen_string_literal: true

class CreateAdBanners < ActiveRecord::Migration[8.0]
  def change
    create_table :ad_banners do |t|
      t.string :name, null: false
      t.string :placement, null: false
      t.string :image_url
      t.string :link_url
      t.string :alt_text
      t.boolean :active, default: true
      t.integer :priority, default: 0
      t.date :start_date
      t.date :end_date
      t.integer :impressions_count, default: 0
      t.integer :clicks_count, default: 0
      t.timestamps
    end

    add_index :ad_banners, [:placement, :active]
  end
end
