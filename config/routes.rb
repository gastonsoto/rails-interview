Rails.application.routes.draw do
  devise_for :users
  unless Rails.env.test?
    begin
      require "sidekiq/web"
      mount Sidekiq::Web => "/sidekiq"
    rescue LoadError
      # Sidekiq Web is optional in some environments
    end
  end

  namespace :api do
    resources :todo_lists, only: %i[index update], path: :todolists do
      resources :todo_list_items, only: %i[create update destroy]
      resource :bulk_actions, only: %i[create], controller: "bulk_actions"
    end
  end

  resources :todo_lists, only: %i[index new create], path: :todolists
end
