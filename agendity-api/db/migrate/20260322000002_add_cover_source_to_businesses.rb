# frozen_string_literal: true

class AddCoverSourceToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :cover_source, :string, default: "upload"
  end
end
