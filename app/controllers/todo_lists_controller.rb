class TodoListsController < ApplicationController
  # GET /todolists
  def index
    @todo_lists = TodoList.includes(:todo_list_items).order(:id)

    respond_to :html
  end

  # GET /todolists/new
  def new
    @todo_list = TodoList.new

    respond_to :html
  end

  # POST /todolists
  def create
    todo_list = TodoList.create!(todo_list_params)
    redirect_to todo_lists_path, notice: "Created “#{todo_list.name}”."
  end

  private

  def todo_list_params
    params.require(:todo_list).permit(:name)
  end
end
