class AddVirtualBusinessToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :virtual_business, :boolean, default: false, null: false
  end
end
