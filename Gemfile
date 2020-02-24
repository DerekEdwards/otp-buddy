source 'http://rubygems.org'

ruby '2.3.7'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.6'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Bootstrap Stuff
gem 'bootstrap-sass', '~> 3.4.1'
gem 'autoprefixer-rails'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'awesome_print'
gem 'rb-readline'
gem 'rails_12factor'

gem 'responders', '~> 2.0'

#Needed for Within_Area call, Boundary, and CallnRide
gem 'rgeo'
gem 'rgeo-geojson'
gem 'rgeo-shapefile'
gem "rgeo-proj4"

#Needed for Geocoder
gem 'Indirizzo'
gem 'geocoder'
gem 'faraday_middleware'

#Needed for application.yml
gem 'figaro'

#Needed to show map of CallNRide Boundary
gem 'leaflet-rails'

gem 'haml-rails'
gem 'simple_form'
gem 'rubyzip'
gem 'polylines'

group :pg do 
  # Use postgresql as the database for Active Record
  gem 'pg', '~> 0.15'
end

group :oracle do
  # Needed to Connect to Oracle DB
  gem 'activerecord-oracle_enhanced-adapter', '~> 1.6.0'
  gem 'ruby-oci8'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'letter_opener'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  # Allows in-browser inspection of errors
  gem 'better_errors'
end

