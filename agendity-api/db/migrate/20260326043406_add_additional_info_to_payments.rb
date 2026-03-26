class AddAdditionalInfoToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :additional_info, :text
  end
end
