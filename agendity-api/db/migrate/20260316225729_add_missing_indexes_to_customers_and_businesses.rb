class AddMissingIndexesToCustomersAndBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_index :customers, :email
    add_index :businesses, :city
  end
end
