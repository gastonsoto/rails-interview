module Api
  class TodoListsController < BaseController

    # GET /api/todolists
    def index
      @todo_lists = TodoList.all

      respond_to :json
    end
  end
end
