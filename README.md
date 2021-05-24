[![Maintainability](https://api.codeclimate.com/v1/badges/ac612f0aec880d523ab4/maintainability)](https://codeclimate.com/github/jcraigk/karmachest/maintainability)
[![Build Status](https://www.travis-ci.com/jcraigk/karmachest.svg?branch=master)](https://www.travis-ci.com/jcraigk/karmachest)
[![Test Coverage](https://api.codeclimate.com/v1/badges/ac612f0aec880d523ab4/test_coverage)](https://codeclimate.com/github/jcraigk/karmachest/test_coverage)

![KarmaChest Logo](https://github.com/jcraigk/karmachest/blob/master/app/webpacker/images/logos/karmachest-full.png)

KarmaChest is a team engagement tool for Slack and Discord. It allows users within a workspace to give each other karma points that accrue over time. A karma point represents a token of appreciation or recognition for a job well done. Users can view their profile, browse their history, and access leaderboards on the web or within the chat client. Numerous options are provided via web-based admin.

This is a Ruby on Rails application that uses Postgres and Redis for storage. It integrates tightly with chat platforms (currently Slack and Discord), keeping teams and users synced server-side. This enables web-based user profiles/history, improved admin management, and gamification features.

Download the [Onboarding Deck](https://github.com/jcraigk/karmachest/files/6523729/KarmaChest-Onboarding.pdf) for a quick intro or take a deeper dive in the [Wiki](https://github.com/jcraigk/karmachest/wiki).


# Installation

To install KarmaChest into your organization's Slack or Discord workspace, you must host this Rails repo on a web server you control and configure the Slack or Discord App at the third party website.

See the [Installation Instructions](https://github.com/jcraigk/karmachest/wiki/Installation) for more detail.


# Development Setup

For local development, start by reading the [Installation Instructions](https://github.com/jcraigk/karmachest/wiki/Installation). Note that you will only need certain portions of what is described there, depending on your specific area of development.

For Slack and OAuth callbacks, a tunneling service such as [ngrok](https://ngrok.com/) is recommended to expose your local server publicly via SSL.

You'll want to setup a dedicated workspace and App in Slack/Discord specifically for KarmaChest development. Do not use your organization's production workspace or App to develop against.

If you're working on response images and running Sidekiq in Docker, you'll need to configure a local storage location in `docker-compose.yml` to map to `/storage` in the `sidekiq` container.


## Run the App Components

You may run all components in Docker with logging exposed using the command

```
make up
```

or you can run services (PG and Redis) in Docker and the Rails processes natively. This may ease debugging and development.

For running the Rails stack locally you'll need the following:
* Ruby (use [rvm](https://rvm.io/) or [asdf](https://asdf-vm.com/))
* [NodeJS](https://nodejs.org/en/)
* [Yarn](https://www.npmjs.com/package/yarn)

```bash
# Install Ruby dependencies
bundle install

# Initialize database
make services
bundle exec rails db:create
bundle exec rails db:reset

# Install javascript dependencies
yarn install

# Start web server (terminal 1)
bundle exec rails s

# Start Sidekiq (terminal 2)
bundle exec sidekiq

# Start Discord listener (terminal 3) - Discord only
bin/discord_listener
```

## Contributions

All contributions are welcome via Issues and Pull Requests. If you notice something wrong in the Wiki, please feel free to fix it!
