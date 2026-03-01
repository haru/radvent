# frozen_string_literal: true

Rails.application.routes.draw do
  resources :events, except: [:show]
  get 'events/:name' => 'events#show', as: :show_event
  get 'admin/events' => 'events#list', as: :events_list
  delete 'users/delete/:id' => 'users#destroy', as: :delete_user
  get 'user/:id/edit' => 'users#edit_info', as: :edit_user
  put 'user/:id/update' => 'users#update_info', as: :update_user
  resources :users, only: [:index]

  devise_for :users
  resources :items do
    collection do
      post 'preview'
    end
    member do
      match 'preview', via: %i[get post patch]
    end
    resources :likes, only: %i[create destroy]
  end

  resources :advent_calendar_items
  resources :attachments
  resources :comments

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
