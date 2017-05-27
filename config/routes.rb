Rails.application.routes.draw do
  devise_for :users
  root 'games#index'
  resources :games do
    post 'forfeit', on: :member
    resources :pieces, only: [:index, :update]
  end
end
