class CreateEmailLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :email_logs do |t|
      t.string :recipient
      t.string :subject
      t.string :mailer_class
      t.string :mailer_action
      t.text :body_html
      t.string :status
      t.text :error_message
      t.datetime :sent_at

      t.timestamps
    end
    add_index :email_logs, :recipient
    add_index :email_logs, :created_at
  end
end
