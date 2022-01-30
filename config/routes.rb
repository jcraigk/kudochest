# frozen_string_literal: true
require 'sidekiq/web'
require 'sidekiq-scheduler/web'
require 'sidekiq_unique_jobs/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq', constraints: AdminConstraint.new

  get 'healthz', to: 'ops#healthz'

  root to: 'public#landing'

  get :dashboard, to: 'dashboard#show', as: :dashboard
  get :wallboard, to: 'wallboard#show', as: :wallboard

  namespace :hooks do
    namespace :slack do
      post :action, to: 'actions#receiver'
      post :command, to: 'commands#receiver'
      post :event, to: 'events#receiver'
      post :options, to: 'options#receiver'
    end
  end

  namespace :oauth do
    get :slack_integration, to: 'slack#integration'
    get :discord_integration, to: 'discord#integration'

    get 'callback/:provider', to: 'sorcery#callback'
    get ':provider', to: 'sorcery#oauth', as: :at_provider
  end
  get 'connect/:reg_token', to: 'profiles#connect', as: :profile_connection

  resources :users, only: %i[new create] do
    collection do
      get :resend_verification
    end
    member do
      get :verify
      get :edit_preferences
      patch :update_preferences
      patch :update_email
      patch :update_password
    end
  end
  get 'user-settings', to: 'users#edit_preferences', as: :user_settings
  resources :user_sessions, only: %i[new create destroy]
  resources :password_resets, only: %i[new create edit update]
  get 'login', to: 'user_sessions#new', as: :login
  delete 'logout', to: 'user_sessions#destroy', as: :logout

  resources :teams, only: %i[edit update new] do
    collection do
      get 'leaderboard_page'
    end
    member do
      patch 'reset_stats'
      patch 'join_channels'
      patch 'export_data'
    end
  end
  get 'app-settings', to: 'teams#edit', as: :app_settings

  resources :profiles, only: %i[show edit update new] do
    collection do
      get 'random_showcase'
    end
  end
  get 'profile-settings', to: 'profiles#edit', as: :profile_settings

  resources :tips, only: %i[index destroy]
  resources :rewards, except: %i[show]
  resources :topics, except: %i[show]
  resources :bonuses, only: %i[index create]
  resources :claims, except: %i[new create]

  get  'shop',         to: 'rewards#shop',       as: :shop
  get  'topic-list',   to: 'topics#list',        as: :topic_list
  post 'claim',        to: 'rewards#claim',      as: :claim_reward
  get  'my-claims',    to: 'claims#my_claims',   as: :my_claims
  get  'unsubscribe',  to: 'emails#unsubscribe', as: :unsubscribe

  match '/404', to: 'errors#not_found', via: :all
  match '/403', to: 'errors#forbidden', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
end
