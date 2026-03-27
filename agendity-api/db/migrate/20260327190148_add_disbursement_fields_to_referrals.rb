class AddDisbursementFieldsToReferrals < ActiveRecord::Migration[8.0]
  def change
    add_column :referrals, :disbursement_requested_at, :datetime
    add_column :referrals, :disbursement_paid_at, :datetime
    add_column :referrals, :disbursement_proof, :string
    add_column :referrals, :disbursement_notes, :text
  end
end
