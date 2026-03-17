class AddWebsiteUrlToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :website_url, :string
  end
end
