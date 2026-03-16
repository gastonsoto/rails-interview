class TodoListItem < ApplicationRecord
  belongs_to :todo_list

  enum status: { draft: 0, active: 1, closed: 2 }
end

