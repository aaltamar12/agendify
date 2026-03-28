class AddLiveChatToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :live_chat, :boolean, default: false, null: false
  end
end
