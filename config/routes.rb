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

  get "calendar/:token(.:format)", to: "ical_feeds#show", as: :ical_feed

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "offline" => "pages#offline", as: :offline

  resources :children, only: %i[index new create edit update show] do
    collection do
      get :inactive
    end
    member do
      patch  :deactivate
      patch  :reactivate
      patch  :update_consent
      post   :attach_parent
      delete :detach_parent
      get    :attendance
    end
    resources :emergency_contacts, only: %i[new create edit update destroy]
    resources :medical_notes, only: %i[new create edit update destroy]
  end

  resources :parents, only: %i[index show new create edit update] do
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

  resources :messages, only: %i[index new create show destroy]
  get  "inbox",       to: "inbox#index", as: :inbox
  get  "inbox/:id",   to: "inbox#show",  as: :inbox_message

  resources :galleries, only: %i[index show new create edit update destroy] do
    member do
      post   :add_photo
      delete :remove_photo
      get    :download
      patch  :release
      patch  :withdraw
      delete :audio, action: :purge_audio, as: :purge_audio
    end
    resources :photos, only: %i[update destroy] do
      collection { patch :reorder }
    end
  end

  resources :polls, only: %i[index show new create edit update destroy] do
    member do
      post  :vote
      patch :close
      get   :export
    end
  end

  resources :meal_entries, only: %i[index new create edit update destroy] do
    collection do
      get :print
      get :export
    end
  end

  resources :attendances, only: %i[index create update] do
    collection do
      get :export
    end
  end
  get "birthdays", to: "birthdays#index", as: :birthdays

  resources :calendar_events
  # F80: Foto-Import für neue Einkaufsliste (POST /shopping_lists/photo_imports)
  namespace :shopping_lists do
    resource :photo_imports, only: %i[create], controller: "photo_imports"
  end

  resources :shopping_lists do
    resources :shopping_items, only: %i[create update destroy] do
      member do
        patch :complete
        patch :uncomplete
        delete :photo, action: :purge_photo, as: :purge_photo
      end
    end
    # F80: Foto-Import zum Ergänzen einer bestehenden Liste
    resource :photo_imports, only: %i[create], module: "shopping_lists",
                              controller: "photo_imports"
  end
  resources :attendance_lists do
    member do
      get   :export
      get   :edit_dates
      patch :update_dates
    end
    resources :attendance_entries, only: %i[create destroy]
  end
  resources :events, only: %i[index show new create edit update destroy] do
    member do
      patch :cancel
    end
  end

  resources :groups
  resources :kindergarten_years do
    member do
      patch :activate
      patch :archive
      get   :rollover
      post  :execute_rollover
    end
  end

  get  "/rollover",         to: "rollovers#new",     as: :rollover
  post "/rollover/confirm", to: "rollovers#confirm", as: :rollover_confirm
  post "/rollover/execute", to: "rollovers#execute", as: :rollover_execute

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

  get "dashboard/parent", to: "dashboards#parent", as: :parent_dashboard
  get "dashboard/staff",  to: "dashboards#staff",  as: :staff_dashboard

  root "pages#home"
end
