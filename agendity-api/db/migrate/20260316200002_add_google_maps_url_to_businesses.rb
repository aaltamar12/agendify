class AddGoogleMapsUrlToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :google_maps_url, :string
  end
end
