source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 7.1.0'

# Use MongoDB as the database for Active Record
gem 'mongoid', '~> 8.1'
gem 'mongo', '~> 2.19'

# Use Puma as the app server
gem 'puma', '~> 6.0'

# Build JSON APIs with ease
gem 'jbuilder', '~> 2.11'

# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 5.0'

# Use Active Model has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Authentication
gem 'devise', '~> 4.9'
gem 'devise-jwt', '~> 0.11'

# Authorization
gem 'pundit', '~> 2.3'

# CORS
gem 'rack-cors'

# Serialization
gem 'active_model_serializers', '~> 0.10.13'

# Pagination
gem 'kaminari-mongoid'
gem 'kaminari-actionview'

# Background Jobs
gem 'sidekiq', '~> 7.0'

# Environment variables
gem 'dotenv-rails', groups: [:development, :test]

# Reduce boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Rate limiting
gem 'rack-attack', '~> 6.7'

# Performance monitoring
gem 'newrelic_rpm'

group :development, :test do
  # Debugging
  gem 'debug', platforms: %i[ mri mingw x64_mingw ]
  gem 'pry-rails'
  gem 'pry-byebug'

  # Testing
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'faker', '~> 3.2'
  gem 'database_cleaner-mongoid', '~> 2.0'
end

group :development do
  gem 'listen', '~> 3.8'
  # Spring speeds up development by keeping your application running in the background
  gem 'spring'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end

group :test do
  gem 'shoulda-matchers', '~> 5.3'
  gem 'simplecov', require: false
  gem 'webmock', '~> 3.18'
  gem 'vcr', '~> 6.1'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[ mingw mswin x64_mingw jruby ]
