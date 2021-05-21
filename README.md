![KarmaChest Logo](https://github.com/jcraigk/karmachest/blob/master/app/webpacker/images/logos/karmachest-144.png)

# KarmaChest

KarmaChest is a team engagement tool for Slack and Discord. It allows users within a workspace to give each other karma points that accrue over time. A karma point represents a token of appreciation or recognition for a job well done. Users can view their profile, browse their history, and access leaderboards on the web or within the chat client. Numerous options are provided via web-based admin.

This is a Ruby on Rails application that uses Postgres and Redis for storage. It integrates tightly with chat platforms (currently Slack and Discord), keeping teams and users synced server-side. This enables web-based user profiles/history, improved admin management, and gamification features.

Download the [Onboarding Deck](https://github.com/jcraigk/karmachest/files/6523729/KarmaChest-Onboarding.pdf) for a quick intro or take a deeper dive in the [Wiki](https://github.com/jcraigk/karmachest/wiki).


# App Installation

If you want to install KarmaChest into your organization's Slack or Discord team, you must setup a Slack App (or Discord App) at the third party and host this Rails app internally or on a public server you control. See the [Wiki](https://github.com/jcraigk/karmachest/wiki/App-Installation) for detailed instructions.


# Development Setup

You may run Postgres and Redis using the included `Dockerfile` or natively.

For Slack and OAuth callbacks, a tunneling service such as [ngrok](https://ngrok.com/) is recommended to expose your local server publicly.


## Environment variables

Environment variables may be provided locally in a `.env` file.

You may provide `DATABASE_URL` or `config/database.yml`.

You may provide `RAILS_MASTER_KEY` or `config/master.key`.

You may provide `REDIS_URL` or leave it blank for default localhost.

Provide the following to enable the web UI where app administration takes place.

```
ASSET_HOST
WEB_DOMAIN
```

STMP config must be provided to enable email-based signup and password reset.

```
SMTP_ADDRESS
SMTP_DOMAIN
SMTP_PASSWORD
SMTP_USERNAME
```

For Sidekiq web admin (at `/sidekiq`), setup desired username and password used for HTTP Basic Auth:

```
SIDEKIQ_USERNAME
SIDEKIQ_PASSWORD
```

If you are working on Slack integration, create a Slack App specifically for development and provide its details in the following variables. Make sure you set `config.bot_name` in `config/application.rb` appropriately. For a detailed guide, see [Slack App Setup](https://github.com/jcraigk/karmachest/wiki/Slack-App-Setup).

```
SLACK_APP_ID
SLACK_CLIENT_ID
SLACK_CLIENT_SECRET
SLACK_SIGNING_SECRET
```

If you are working on Discord integration, create a Discord App specifically for development and provide its details in the following variables.  Make sure you set `config.bot_name` in `config/application.rb` appropriately. You'll also want to fire up the Discord Gateway Listener from a fresh terminal using `bin/discord_listener`. For a detailed guide, see [Discord App Setup](https://github.com/jcraigk/karmachest/wiki/Discord-App-Setup).

```
DISCORD_APP_USERNAME
DISCORD_BOT_TOKEN
DISCORD_CLIENT_ID
DISCORD_CLIENT_SECRET
DISCORD_LISTENER_STARTUP_DELAY
DISCORDRB_NONACL=true
```

If you are working on OAuth integration, create the appropriate apps in the third party services and provide their values. You'll want to set `config.oauth_providers` in `config/application.rb` according to the integrations you have setup.

```
OAUTH_FACEBOOK_KEY
OAUTH_FACEBOOK_SECRET
OAUTH_GOOGLE_KEY
OAUTH_GOOGLE_SECRET
```

For working on graphical image responses, setup an AWS bucket to cache the composed images and provide the credentials.

```
RESPONSE_IMAGE_AWS_ACCESS_KEY_ID
RESPONSE_IMAGE_AWS_BUCKET
RESPONSE_IMAGE_AWS_REGION
RESPONSE_IMAGE_AWS_SECRET_ACCESS_KEY
RESPONSE_IMAGE_HOST
```

## Fine Tuning

Most of the app's basic settings are configured in `config/application.rb`.


## Periodic Jobs

You'll want to configure when `WeeklyReport::RecurrentWorker` runs in `config/sidekiq.yml` or disable it.


## Fire Up Rails

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

## Install in Chat Client

You'll want to setup a workspace in Slack or Discord specifically for KarmaChest development. Do not use your organization's production workspace to develop against.

Visit `http://localhost:3000` (or your public [ngrok](https://ngrok.com/) URL) and sign in. Follow the installation instructions on the landing page to install the app into the chat client. You now have admin control over the workspace. You may also connect your web profile by following the instructions on the landing page
