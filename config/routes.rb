Rails.application.routes.draw do

  #API
  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do

      resources :itineraries do
        collection do
          post 'plan'
        end
      end

      resources :places do
        collection do
          get 'search'
          get 'boundary'
          get 'synonyms'
          get 'blacklist'
        end
      end

      resources :defaults, path: '/:type/defaults', constraints: { type: /internal|external/ }

    end
  end

  #Not API
  resources :settings, :only => [:index] do
    collection do
      patch 'set_callnride_boundary'
    end
  end

end
