class AddFeaturesToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :features, :jsonb, default: []
  end
end
