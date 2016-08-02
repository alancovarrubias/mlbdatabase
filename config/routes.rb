Rails.application.routes.draw do

  get 'admin', :to => 'index#home'

  root 'index#home'

  match ':controller(/:action(/:id))', :via => [:get, :post]

  resources :products do
    resources :reviews
  end
  
end
