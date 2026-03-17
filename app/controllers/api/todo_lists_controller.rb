module Api
  class TodoListsController < BaseController

    # GET /api/todolists
    def index
      @todo_lists = TodoList.all
      render :index
    end

    # PATCH /api/todolists/:id
    def update
      todo_list = TodoList.find(params[:id])
      todo_list.update!(todo_list_params)
      render json: todo_list, status: :ok
    end

    private

    def todo_list_params
      params.require(:todo_list).permit(:name)
    end
  end
end
