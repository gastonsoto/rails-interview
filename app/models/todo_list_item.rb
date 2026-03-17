class TodoListItem < ApplicationRecord
  belongs_to :todo_list

  enum status: { draft: 0, active: 1, closed: 2 }

  after_commit :broadcast_lists

  private

  def broadcast_lists
    Turbo::StreamsChannel.broadcast_replace_to(
      "todo_lists",
      target: "todo_lists",
      partial: "todo_lists/todo_lists",
      locals: { todo_lists: TodoList.includes(:todo_list_items).order(:id) }
    )
  end
end

