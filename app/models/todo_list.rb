class TodoList < ApplicationRecord
  belongs_to :user
  has_many :todo_list_items, dependent: :destroy
  has_many :bulk_operations, dependent: :destroy

  after_commit :broadcast_lists
  before_create :set_timestamps_if_missing
  before_update :set_timestamps_if_missing

  def self.broadcast_lists!(user)
    Turbo::StreamsChannel.broadcast_replace_to(
      user,
      "todo_lists",
      target: "todo_lists",
      partial: "todo_lists/todo_lists",
      locals: { todo_lists: user.todo_lists.includes(:todo_list_items).order(:id) }
    )
  end

  private

  def broadcast_lists
    self.class.broadcast_lists!(user)
  end

  def set_timestamps_if_missing
    now = Time.current
    self.created_at ||= now if respond_to?(:created_at)
    self.updated_at ||= now if respond_to?(:updated_at)
  end
end
