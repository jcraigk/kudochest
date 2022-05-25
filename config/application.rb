# frozen_string_literal: true
require_relative 'boot'

require 'rails'
require 'action_cable/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'active_record/railtie'

Bundler.require(*Rails.groups)

module KudoChest
  class Application < Rails::Application
    config.load_defaults '7.0'
    Rails.autoloaders.main.ignore(Rails.root.join('app/webpacker'))
    config.i18n.load_path += Dir[Rails.root.join('config/locales/**/*.yml')]
    config.exceptions_app = routes
    config.hosts.clear
    config.action_cable.allowed_request_origins = [%r{ http://* }, %r{https://*}]
    config.action_cable.worker_pool_size = 4
    config.active_job.queue_adapter = :sidekiq

    ## Basic Info
    config.app_name = ENV.fetch('APP_NAME', 'KudoChest')
    config.bot_name = ENV.fetch('BOT_NAME', 'KudoChest')
    config.base_url = ENV.fetch('BASE_URL', "https://#{ENV.fetch('WEB_DOMAIN', 'localhost')}")
    config.from_email = ENV.fetch \
      'FROM_EMAIL',
      "#{config.app_name} <noreply@#{ENV.fetch('WEB_DOMAIN', 'localhost')}>"
    config.point_term = ENV.fetch('POINT_TERM', 'kudo')
    config.points_term = ENV.fetch('POINTS_TERM', 'kudos')
    config.jab_term = ENV.fetch('POINT_TERM', 'kudont')
    config.jabs_term = ENV.fetch('POINTS_TERM', 'kudonts')
    config.point_singular_prefix = ENV.fetch('POINT_SINGULAR_PREFIX', 'a')
    config.jab_singular_prefix = ENV.fetch('JAB_SINGULAR_PREFIX', 'a')
    config.help_url = 'https://github.com/jcraigk/kudochest/wiki'
    config.issues_url = 'https://github.com/jcraigk/kudochest/issues'
    config.asset_host = ENV.fetch('ASSET_HOST', nil)

    ## Access Control
    # Default to single team install
    config.max_teams = ENV.fetch('MAX_TEAMS', 1)
    # ['example.org'] to restrict to `bob@example.org` etc
    domains = ENV.fetch('USER_EMAIL_DOMAINS', nil).presence&.split(',')
    config.user_email_domains = domains || []
    # Possible values: [slack discord google facebook]
    providers = ENV.fetch('OAUTH_PROVIDERS', nil).presence&.split(',')&.map(&:to_sym)
    config.oauth_providers = providers || []
    config.shared_admin = ENV.fetch('SHARED_ADMIN', 'false').casecmp('true').zero?

    ## Slack
    config.slack_app_id = ENV.fetch('SLACK_APP_ID', nil)
    config.base_command = ENV.fetch('BASE_COMMAND', 'kudos')
    config.default_point_emoji = 'star'
    config.default_jab_emoji = 'arrow_down'
    config.default_ditto_emoji = 'heavy_plus_sign'

    ## Discord
    config.discord_cdn_base = 'https://cdn.discordapp.com'
    config.discord_token = "Bot #{ENV.fetch('DISCORD_BOT_TOKEN', nil)}"
    config.discord_command = "!#{config.base_command}"
    config.discord_point_emoji = 'plus_plus'
    config.discord_jab_emoji = 'minus_minus'
    config.discord_ditto_emoji = 'plus_one'
    config.discord_permission = '1073743872' # Manage Emojis, Send Messages

    ## Email
    config.action_mailer.default_url_options = { host: config.base_url }
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      authentication: :plain,
      address: ENV.fetch('SMTP_ADDRESS', nil),
      port: 587,
      domain: ENV.fetch('SMTP_DOMAIN', nil),
      user_name: ENV.fetch('SMTP_USERNAME', nil),
      password: ENV.fetch('SMTP_PASSWORD', nil)
    }

    ## Feature defaults/limits
    config.max_response_mentions = 3
    config.undo_cutoff = 1.minute
    config.max_points_per_tip = 100
    config.default_max_level = 20
    config.default_max_level_points = 1_000
    config.error_emoji = 'grimacing'
    config.default_token_quantity = 100
    config.max_token_quantity = 1_000
    config.default_token_max = 100
    config.max_token_max = 1_000
    config.default_action_hour = 13
    config.default_time_zone = 'Pacific Time (US & Canada)'
    config.default_streak_duration = 5
    config.min_streak_duration = 3
    config.max_streak_duration = 100
    config.default_streak_reward = 1
    config.max_streak_reward = 5
    config.channel_cache_ttl = 5.minutes
    # config.leaderboard_trend_days = 7 # TODO: Re-enable leaderboard trends
    config.default_leaderboard_size = 5
    config.modal_cache_ttl = 600 # seconds
    config.password_length = 5
    config.gentle_level_coefficient = 1.5
    config.steep_level_coefficient = 2.1
    config.default_tip_history_days = 14
    config.max_note_length = 255
    config.give_color = '#460878'
    config.receive_color = '#247808'
  end
end

App = Rails.configuration

# Errors
class ChatFeedback < StandardError; end

# Structs
ChannelData = Struct.new(:rid, :name)
ChatResponse = Struct.new(:mode, :text, :image, :response, :tips, keyword_init: true)
EntityMention = Struct.new(:entity, :profiles, :topic_id, :quantity, :note, keyword_init: true)
Mention = Struct.new(:rid, :topic_id, :quantity, :note, keyword_init: true)
LeaderboardProfile = Struct.new \
  :id, :rank, :previous_rank, :slug, :link, :display_name, :real_name,
  :points, :last_timestamp, :avatar_url, keyword_init: true
LeaderboardPage = Struct.new(:updated_at, :profiles)

# App constants, will rarely change
STORAGE_PATH =
  if Rails.env.test?
    Rails.root.join('tmp/storage')
  elsif ENV.fetch('IN_DOCKER', false)
    '/storage'
  else
    ENV.fetch('STORAGE_PATH', '/')
  end

COMMAND_KEYWORDS = {
  admin: %w[],
  connect: %w[],
  claim: %w[buy get],
  help: %w[h support],
  leaderboard: %w[top leaders best],
  levels: %w[level leveling],
  preferences: %w[config setup options settings prefs],
  report: %w[digest activity weekly summary],
  shop: %w[items loot rewards],
  stats: %w[me],
  topics: %w[],
  undo: %w[revoke]
}.freeze
PRIVATE_KEYWORDS = %w[admin connect help claim].freeze

CHAN_PREFIX = '#'
PROF_PREFIX = '@'
LEGACY_SLACK_SUFFIX_PATTERN = '\|[^>]*'

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
}.freeze
SUBTEAM_REGEX = {
  slack: /<!subteam\^([^>]+)>/,
  discord: /<@&(\d+)>/
}.freeze

SLACK_DM_NAME = 'direct-message'
SLACK_DM_PREFIX = 'mpdm-'
SLACK_DM_PHRASE = 'a group chat'
POINT_INLINES = %w[++ +=].freeze
JAB_INLINES = %w[-- -=].freeze

IMG_DELIM = '<COLOR>'

GIFS = {
  '32' => %w[trophy],
  '48' => %w[cake cherries comet confetti fern fire flower star tree]
}.freeze
