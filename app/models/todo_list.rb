class TodoList < ApplicationRecord
  has_many :todo_list_items, dependent: :destroy

  after_commit :broadcast_lists

  def self.broadcast_lists!
    Turbo::StreamsChannel.broadcast_replace_to(
      "todo_lists",
      target: "todo_lists",
      partial: "todo_lists/todo_lists",
      locals: { todo_lists: TodoList.includes(:todo_list_items).order(:id) }
    )
  end

  private

  def broadcast_lists
    self.class.broadcast_lists!
  end
end