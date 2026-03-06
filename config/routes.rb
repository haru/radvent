# frozen_string_literal: true

Rails.application.routes.draw do
  resources :events, param: :name, except: %i[show index]
  get 'events/:name' => 'events#show', as: :show_event
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

  resources :boards, param: :board_id,
                     constraints: { board_id: /[a-z0-9_-]+/ } do
    resources :board_memberships, only: %i[index create]
  end
  resources :board_memberships, only: [:destroy]

  root 'welcome#index'
end
