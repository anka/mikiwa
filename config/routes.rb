Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :magic_links, only: %i[new create], param: :token do
    collection do
      get ":token", action: :show, as: :show
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "offline" => "pages#offline", as: :offline

  resources :children, only: %i[index new create edit update show] do
    member do
      patch :deactivate
    end
    resources :emergency_contacts, only: %i[new create edit update destroy]
    resources :medical_notes, only: %i[new create edit update destroy]
  end

  resources :parents, only: %i[index new create] do
    member do
      patch :lock
      patch :unlock
      post  :reinvite
    end
  end

  resource :profile, only: %i[show update], controller: "profile" do
    member do
      patch :rotate_ical_token
    end
  end

  resources :calendar_events
  resources :events, only: %i[index show new create edit update destroy] do
    member do
      patch :cancel
    end
  end

  resources :groups
  resources :kindergarten_years do
    member do
      patch :activate
      get   :rollover
      post  :execute_rollover
    end
  end

  namespace :webhooks do
    post "bounce" => "bounces#create"
  end

  namespace :admin do
    resources :users, only: %i[index new create destroy] do
      member do
        patch :lock
        patch :unlock
      end
    end
    get "impressum"  => "pages#impressum",  as: :impressum
    get "datenschutz" => "pages#datenschutz", as: :datenschutz
  end

  get "impressum"   => "admin/pages#impressum",   as: :impressum
  get "datenschutz" => "admin/pages#datenschutz",  as: :datenschutz

  root "pages#home"
end
