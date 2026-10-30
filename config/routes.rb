# frozen_string_literal: true

Rails.application.routes.draw do
  resources :events, param: :name, except: %i[show index]
  get 'events/:name' => 'events#show', as: :show_event
  delete 'users/delete/:id' => 'users#destroy', as: :delete_user
  get 'user/:id/edit' => 'users#edit_info', as: :edit_user
  put 'user/:id/update' => 'users#update_info', as: :update_user
  resources :users, only: [:index]

  # The unlock routes are skipped: locks are lifted by time or by a password
  # reset, and no unlock mail is ever sent (docs/adr/0012-*).
  devise_for :users, controllers: { sessions: 'users/sessions', registrations: 'users/registrations',
                                    passwords: 'users/passwords' },
                     skip: [:unlocks]
  patch 'theme' => 'themes#update'
  resources :items do
    collection do
      post 'preview', action: :preview_new, as: :preview
    end
    member do
      match 'preview', via: %i[get post patch]
    end
    resources :likes, only: %i[create destroy]
  end

  resources :advent_calendar_items
  resources :attachments, only: [:create]
  get 'attachments/:id/:filename', to: 'attachments#show', as: :attachment_image,
                                   constraints: { id: /\d+/, filename: %r{[^/]+} }, format: false
  resources :comments

  resources :boards, param: :board_id,
                     constraints: { board_id: /[a-z0-9_-]+/ } do
    resources :board_memberships, only: %i[index create] do
      get :search, on: :collection
    end
    resources :events, param: :name, only: %i[show edit update destroy]
  end
  get 'boards/:board_ref_id/other_boards' => 'board_other_boards#index', as: :board_other_boards
  resources :board_memberships, only: [:destroy]

  root 'welcome#index'
end
