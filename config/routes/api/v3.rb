# frozen_string_literal: true

namespace :v3 do
  resources :foot_notes, only: :show

  resources :chapters, only: [:index, :show] do
    member do
      get :info, to: 'chapter_infos#show'
    end

    resources :verses, only: [:index, :show] do
      resources :audio_files, only: [:index]

      member do
        get '/tafsirs/:tafsir', to: 'tafsirs#show'
      end
    end
  end

  resources :juzs, only: [:show, :index]

  namespace :options do
    get :default
    get :translations
    get :recitations
    get :tafsirs
    get :languages
    get :chapter_info
  end

  get 'search', to: 'search#search'
  get 'suggest', to: 'search#suggest'
  get 'ping', to: 'ping#ping'
  get '/', to: 'ping#ping'
end
