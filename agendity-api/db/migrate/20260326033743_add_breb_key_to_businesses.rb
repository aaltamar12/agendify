class AddBrebKeyToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :breb_key, :string
  end
end
