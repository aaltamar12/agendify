# frozen_string_literal: true

class AddIndependentAndLegalFields < ActiveRecord::Migration[8.0]
  def change
    # Legal fields for businesses
    add_column :businesses, :nit, :string
    add_column :businesses, :legal_representative_name, :string
    add_column :businesses, :legal_representative_document, :string
    add_column :businesses, :legal_representative_document_type, :string
    add_column :businesses, :independent, :boolean, default: false, null: false

    # Legal/identity fields for employees (used by independent professionals)
    add_column :employees, :document_number, :string
    add_column :employees, :document_type, :string
    add_column :employees, :fiscal_address, :string

    add_index :businesses, :independent
  end
end
