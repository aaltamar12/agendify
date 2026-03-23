# frozen_string_literal: true

class CreateJobConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :job_configs do |t|
      t.string :job_class, null: false
      t.string :name, null: false
      t.string :description
      t.string :schedule              # informativo, copiado del YAML
      t.boolean :enabled, default: true
      t.datetime :last_run_at
      t.string :last_run_status       # success, error
      t.text :last_run_message
      t.timestamps
    end
    add_index :job_configs, :job_class, unique: true
  end
end
