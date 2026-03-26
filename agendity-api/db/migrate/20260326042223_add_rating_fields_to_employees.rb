class AddRatingFieldsToEmployees < ActiveRecord::Migration[8.0]
  def change
    add_column :employees, :rating_average, :decimal, precision: 3, scale: 2, default: 0, null: false
    add_column :employees, :total_reviews, :integer, default: 0, null: false
  end
end
