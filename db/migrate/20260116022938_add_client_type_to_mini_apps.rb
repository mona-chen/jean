class AddClientTypeToMiniApps < ActiveRecord::Migration[8.1]
  def change
    add_column :mini_apps, :client_type, :string, default: "public", null: false
    add_index :mini_apps, :client_type
  end
end
