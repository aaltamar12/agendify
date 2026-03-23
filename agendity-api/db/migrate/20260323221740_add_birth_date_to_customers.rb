class AddBirthDateToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :birth_date, :date
  end
end
