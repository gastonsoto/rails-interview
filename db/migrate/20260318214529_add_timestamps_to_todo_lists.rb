class AddTimestampsToTodoLists < ActiveRecord::Migration[7.0]
  def change
    add_timestamps :todo_lists, null: true
    
    # Update existing records to have a timestamp if any
    long_ago = Time.at(0)
    TodoList.update_all(created_at: long_ago, updated_at: long_ago)
    
    # Change to null: false for future records
    change_column_null :todo_lists, :created_at, false
    change_column_null :todo_lists, :updated_at, false
  end
end
