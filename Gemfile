source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
#gem 'rails', '4.1.1'
gem 'rails', github: 'rails/rails' #:git => 'git://github.com/rails/rails.git' 

# Use postgresql as the database for Active Record
gem 'pg'
# Use SCSS for stylesheets
#gem 'sass-rails' #, '~> 4.0.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'execjs'
gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0',          group: :doc

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring',        group: :development

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

gem 'rb-readline'
gem 'composite_primary_keys', {
    :git => 'git://github.com/composite-primary-keys/composite_primary_keys.git',
    :branch => 'ar_4.2.x'
}
gem 'awesome_print'



# For deploying
gem 'capistrano', group: :development
gem 'capistrano-rails', group: :development
gem 'capistrano-bundler', group: :development
gem 'capistrano-rvm', group: :development
gem 'capistrano-touch-linked-files', group: :development

# This is for env variables
gem 'dotenv-rails'
gem 'dotenv-deployment'

gem 'elasticsearch-model' 
gem 'elasticsearch-rails'
# To launch elastic search
# elasticsearch --config=/usr/local/opt/elasticsearch/config/elasticsearch.yml


gem 'batchelor' # This is for batching the Content::Translation

# Paging the results
# gem 'will_paginate'
gem 'kaminari'


gem 'yaml_db', github: 'sharabash/yaml_db'
gem 'sass-rails', github: 'rails/sass-rails' # '~> 4.0.3'

group :development, :test do
      gem 'jazz_hands', github: 'nixme/jazz_hands', branch: 'bring-your-own-debugger'
      gem 'pry-byebug'
      gem 'pry-rails'
end

gem 'elasticsearch'

