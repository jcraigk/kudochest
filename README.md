![KarmaChest Logo](https://github.com/jcraigk/karmachest/blob/master/app/webpacker/images/logos/karmachest-144.png)

# KarmaChest

KarmaChest is a team engagement tool for Slack and Discord. It allows users within a workspace to give each other karma points that accrue over time. A karma point represents a token of appreciation or recognition for a job well done. Users can view their profile, browse their history, and access leaderboards on the web or within the chat client. Numerous options are provided via web-based admin.

This is a Ruby on Rails application that uses Postgres and Redis for storage. It integrates tightly with chat platforms (currently Slack and Discord), keeping teams and users synced server-side. This enables web-based user profiles/history, improved admin management, and gamification features.

Download the [Onboarding Deck](https://github.com/jcraigk/karmachest/files/6523729/KarmaChest-Onboarding.pdf) for a quick intro or take a deeper dive in the [Wiki](https://github.com/jcraigk/karmachest/wiki).


# Installation

If you want to install KarmaChest into your organization's Slack or Discord team, you must setup a Slack App (or Discord App) at the third party and host this Rails app and its dependencies on a web server you control. Follow the [Installation Instructions](https://github.com/jcraigk/karmachest/wiki/Installation) to proceed.


# Development Setup

For Slack and OAuth callbacks, a tunneling service such as [ngrok](https://ngrok.com/) is recommended to expose your local server publicly.

For local development, start by reading the [Installation Instructions](https://github.com/jcraigk/karmachest/wiki/Installation). Note that you will only need certain portions of what is described there, depending on your specific area of development.

You'll want to setup a dedicated workspace and App in Slack/Discord specifically for KarmaChest development. Do not use your organization's production workspace to develop against.


## Run the App Components

You may run all components in Docker with logging exposed using the command

```
make up
```

or you can run services (PG and Redis) in Docker and the Rails processes natively. This may be better for debugging and development.

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
