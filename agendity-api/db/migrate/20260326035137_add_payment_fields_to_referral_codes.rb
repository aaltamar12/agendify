class AddPaymentFieldsToReferralCodes < ActiveRecord::Migration[8.0]
  def change
    add_column :referral_codes, :bank_account, :string
    add_column :referral_codes, :bank_name, :string
    add_column :referral_codes, :breb_key, :string
  end
end
