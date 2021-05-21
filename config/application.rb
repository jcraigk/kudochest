# frozen_string_literal: true
require_relative 'boot'

require 'rails'
require 'action_cable/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'active_record/railtie'

Bundler.require(*Rails.groups)

module KarmaChest
  class Application < Rails::Application
    config.load_defaults '6.1'
    Rails.autoloaders.main.ignore(Rails.root.join('app/webpacker'))
    config.i18n.load_path += Dir[Rails.root.join('config/locales/**/*.yml')]
    config.exceptions_app = routes
    config.hosts.clear
    config.action_cable.allowed_request_origins = [%r{ http://* }, %r{https://*}]
    config.action_cable.worker_pool_size = 4
    config.active_job.queue_adapter = :sidekiq

    # Custom config
    config.app_name = 'KarmaChest'
    config.bot_name = 'KarmaChest'
    config.base_url = "https://#{ENV['WEB_DOMAIN']}"
    config.from_email = "KarmaChest <noreply@#{ENV['WEB_DOMAIN']}>"
    config.help_url = "#{config.base_url}/help"
    config.feedback_url = "#{config.base_url}/feedback"
    config.oauth_providers = %i[slack discord google facebook]

    # Slack
    config.slack_app_id = ENV['SLACK_APP_ID']
    config.base_command = 'karma'

    # Discord
    config.discord_cdn_base = 'https://cdn.discordapp.com'
    config.discord_token = "Bot #{ENV['DISCORD_BOT_TOKEN']}"
    config.discord_command = '!karma'
    config.discord_emoji = 'karma_plus_one'
    config.discord_permission = '1073743872' # Manage Emojis, Send Messages

    # SMTP
    config.action_mailer.default_url_options = { host: config.base_url }
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      authentication: :plain,
      address: ENV['SMTP_ADDRESS'],
      port: 587,
      domain: ENV['SMTP_DOMAIN'],
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD']
    }

    # Defaults
    config.max_response_mentions = 3
    config.undo_cutoff = 5.minutes
    config.max_karma_per_tip = 10
    config.default_max_level = 20
    config.default_max_level_karma = 1_000
    config.error_emoji = 'grimacing'
    config.default_karma_emoji = 'high_brightness'
    config.default_token_quantity = 50
    config.max_token_quantity = 1_000
    config.default_token_max = 50
    config.max_token_max = 1_000
    config.default_token_hour = 13
    config.default_time_zone = 'Pacific Time (US & Canada)'
    config.default_streak_duration = 5
    config.min_streak_duration = 3
    config.max_streak_duration = 100
    config.default_streak_reward = 1
    config.max_streak_reward = 5
    config.channel_cache_ttl = 5.minutes
    config.leaderboard_refresh_seconds = 10
    config.leaderboard_trend_days = 7
    config.leaderboard_size = 5
    config.modal_cache_ttl = 600 # seconds
    config.password_length = 5
    config.gentle_level_coefficient = 1.5
    config.steep_level_coefficient = 2.1
    config.default_tip_history_days = 14
    config.max_note_length = 150
    config.give_color = '#460878'
    config.receive_color = '#247808'
  end
end

App = Rails.configuration

STORAGE_PATH =
  if Rails.env.test?
    Rails.root.join('tmp/storage')
  elsif ENV['IN_DOCKER']
    '/storage'
  else
    ENV['STORAGE_PATH']
  end

COMMAND_KEYWORDS = {
  connect: %w[],
  claim: %w[buy get],
  help: %w[h support],
  leaderboard: %w[top leaders best],
  levels: %w[level leveling],
  mute: %w[stfu],
  settings: %w[config setup options],
  shop: %w[items loot rewards],
  stats: %w[me],
  topics: %w[],
  undo: %w[revoke],
  unmute: %w[]
}.freeze
PRIVATE_KEYWORDS = %w[connect help settings claim].freeze

CHAN_PREFIX = '#'
PROF_PREFIX = '@'
LEGACY_SLACK_SUFFIX_PATTERN = '\|[^>]+'

RID_CHARS = {
  slack: '[A-Z0-9]',
  discord: '\d'
}.with_indifferent_access.freeze

PROFILE_PREFIX = {
  slack: '@',
  discord: '@!'
}.with_indifferent_access.freeze
SUBTEAM_PREFIX = {
  slack: '!subteam^',
  discord: '@&'
}.with_indifferent_access.freeze

PROFILE_REGEX = {
  slack: /<@([A-Z0-9]+)(\|([^>]+))?>/,
  discord: /<@!(\d+)>/
}.with_indifferent_access.freeze
CHANNEL_REGEX = {
  slack: /<#([A-Z0-9]+)(\|([^>]+))?>/,
  discord: /<#(\d+)>/
}.with_indifferent_access.freeze
SUBTEAM_REGEX = {
  slack: /<!subteam\^([^>]+)>/,
  discord: /<@&(\d+)>/
}.with_indifferent_access.freeze
EVERYONE_PATTERN = {
  slack: '<!(everyone)>',
  discord: '@(everyone)'
}.with_indifferent_access.freeze

IMG_DELIM = '<COLOR>'

GIFS = {
  '32' => %w[trophy],
  '48' => %w[cake cherries comet confetti fern fire flower star tree]
}.freeze
