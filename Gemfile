# frozen_string_literal: true
source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.0'

gem 'awesome_print'
gem 'aws-sdk-s3'
gem 'bulma-rails'
gem 'chartkick'
gem 'clipboard-rails'
gem 'discordrb'
gem 'dry-initializer'
gem 'enumerize'
gem 'gemoji'
gem 'groupdate'
gem 'http'
gem 'jquery-rails'
gem 'kaminari'
gem 'numbers_and_words'
gem 'pg'
gem 'puma', '6.0.1' # TODO: 6.0.2 failing to build on arm64
gem 'pundit'
gem 'rails'
gem 'rmagick'
gem 'sass-rails'
gem 'sidekiq'
gem 'sidekiq-scheduler', '5.0.0.beta2' # TODO: Unpin after release
gem 'sidekiq-unique-jobs'
gem 'slack-ruby-client'
gem 'slim'
gem 'sluggi'
gem 'sorcery'
gem 'webpacker'

group :production do
  gem 'honeybadger'
end

group :development do
  gem 'rubocop'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
end

group :development, :test do
  gem 'bullet'
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'webmock'
end

group :test do
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'super_diff'
  gem 'vcr'
end
