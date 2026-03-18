class AddExternalSyncFieldsToTodoListsAndItems < ActiveRecord::Migration[7.0]
  def change
    # For TodoLists
    add_column :todo_lists, :external_id, :string
    add_index :todo_lists, :external_id
    add_column :todo_lists, :provider, :string
    add_index :todo_lists, :provider
    add_column :todo_lists, :last_synced_at, :datetime

    # For TodoListItems
    add_column :todo_list_items, :external_id, :string
    add_index :todo_list_items, :external_id
  end
end
