# Removes deprecated fields from businesses table.
#
# bank_account_info — replaced by specific fields: nequi_phone, daviplata_phone, bancolombia_account
# payment_instructions — now auto-generated from the specific payment method fields above
#
# See docs/tech/decisiones/002-eliminar-campos-pago-genericos.md for full rationale.
class RemoveDeprecatedFieldsFromBusinesses < ActiveRecord::Migration[8.0]
  def change
    remove_column :businesses, :bank_account_info, :text
    remove_column :businesses, :payment_instructions, :text
  end
end
