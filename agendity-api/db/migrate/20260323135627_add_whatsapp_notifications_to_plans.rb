class AddWhatsappNotificationsToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :whatsapp_notifications, :boolean, default: false, null: false
  end
end
