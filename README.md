![KarmaChest Logo](https://github.com/jcraigk/karmachest/blob/master/app/webpacker/images/logos/karmachest-144.png)

# KarmaChest

KarmaChest is a team engagement tool for Slack and Discord. It allows users within a workspace to give each other karma points that accrue over time. A karma point represents a token of appreciation or recognition for a job well done. Users can view their profile, browse their history, and access leaderboards on the web or within the chat client. Numerous options are provided via web-based admin.

This is a Ruby on Rails application that uses Postgres and Redis for storage. It integrates tightly with chat platforms (currently Slack and Discord), keeping teams and users synced server-side. This enables web-based user profiles/history, improved admin management, and gamification features.

For a full list of features, see the wiki.


# App Installation

If you want to install KarmaChest into your organization's Slack or Discord team, you must setup a Slack App (or Discord App) and host this Rails app internally or on a public server. See the wiki for detailed instructions.


# Development Setup

You may run Postgres and Redis in Docker or natively.

For Slack callbacks, a tunneling service such as [ngrok](https://ngrok.com/) is recommended to expose your local server.


## Environment variables

Environment variables may be provided locally in a `.env` file.

You may provide `DATABASE_URL` or `config/database.yml`.

You may provide `RAILS_MASTER_KEY` or `config/master.key`.

You mavey provide `REDIS_URL` or leave it blank for default localhost.

The following must be provided to enable web-based features.

```
ASSET_HOST
SMTP_ADDRESS
SMTP_DOMAIN
SMTP_PASSWORD
SMTP_USERNAME
WEB_DOMAIN
```

If you are working on Slack integration, create a Slack App specifically for development (you could name it "KarmaChestDev") and provide its details in the following variables. For more information on how to setup the Slack App, see the wiki.

```
SLACK_APP_ID
SLACK_CLIENT_ID
SLACK_CLIENT_SECRET
SLACK_SIGNING_SECRET
```

Similarly, if you are working on Discord integration, create a Discord App specifically for development and provide its details. You'll also want to fire up the Discord listener using `bin/discord_listener`.

```
DISCORD_APP_USERNAME
DISCORD_BOT_TOKEN
DISCORD_CLIENT_ID
DISCORD_CLIENT_SECRET
DISCORD_LISTENER_STARTUP_DELAY
DISCORDRB_NONACL=true
```

If you are working on OAuth integration, create the appropriate apps in the third party services and provide their values. You'll want to set the `config.oauth_providers` value in `config/application.rb` according to the integrations you have setup.

```
OAUTH_FACEBOOK_KEY
OAUTH_FACEBOOK_SECRET
OAUTH_GOOGLE_KEY
OAUTH_GOOGLE_SECRET
```

If you are working on graphical image responses, setup an AWS bucket to hold the composed images and provide the details.

```
RESPONSE_IMAGE_AWS_ACCESS_KEY_ID
RESPONSE_IMAGE_AWS_BUCKET
RESPONSE_IMAGE_AWS_REGION
RESPONSE_IMAGE_AWS_SECRET_ACCESS_KEY
RESPONSE_IMAGE_HOST
```

## Fine Tuning

Most of the app's basic settings are configured in `config/application.rb` using `Rails.config`.


## Periodic Jobs

You'll want to configure when `WeeklyReport::RecurrentWorker` runs in `config/sidekiq.yml` or disable it.


## Fire It Up

```bash
make services
bundle install
bundle exec rails db:create
bundle exec rails db:reset

# Start web server (terminal 1)
bundle exec rails s

# Start Sidekiq (terminal 2)
bundle exec sidekiq

# Start Discord listener (terminal 3) - Discord only
bin/discord_listener
```
