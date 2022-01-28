[![Build Status](https://www.travis-ci.com/jcraigk/kudochest.svg?branch=master)](https://www.travis-ci.com/jcraigk/kudochest)
[![Maintainability](https://api.codeclimate.com/v1/badges/ca54364dc0911c26e35f/maintainability)](https://codeclimate.com/github/jcraigk/kudochest/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/ca54364dc0911c26e35f/test_coverage)](https://codeclimate.com/github/jcraigk/kudochest/test_coverage)
&nbsp;  
&nbsp;  

![KudoChest Logo](https://github.com/jcraigk/kudochest/blob/master/app/webpacker/images/logos/app-144.png)
&nbsp;  
&nbsp;  

# TODO
 * If multiple inline emoji types, give warning to user
 // streaks only be for giving kudos
 // ensure leveling down works
 // ensure negative profile/team totals work
 // Remove % share from leaderboard
 // Migration needs to create balances
 // Add kudonts to seeds
 // Tokens required to send
 // Add kudonts to profile (web/chat)
 // You can't give yourself kudonts, why you hate yourself?
 // /kudos admin
 // check digest output
 // Handle kudonts in image responses
 * Ensure discord emoji gets published
 * Specs
 * Smoke test discord
 * Update wiki

**KudoChest** is a team engagement tool for **Slack** and **Discord**. It allows users within a workspace to give each other points that accrue over time. A point represents a token of appreciation or recognition for a job well done. Users can view their profile, browse history, and access leaderboards on the web or within the chat client. App settings and moderation tools are provided via web UI.

This is a **Ruby on Rails** application backed by **Postgres** and **Redis**. It integrates tightly with chat platforms, keeping teams and users synced server-side. This enables web-based user profiles and other UX enhancements not possible in standard bots.

See the **[Wiki](https://github.com/jcraigk/kudochest/wiki)** or join the **[Discord](https://discord.gg/kbPnmz5q)**.
&nbsp;  
&nbsp;  


# Installation

To install KudoChest into your organization's Slack or Discord workspace, you must host the Rails components on a web server you control and configure the Slack or Discord App at the appropriate platform's site.

See the [Installation Instructions](https://github.com/jcraigk/kudochest/wiki/Installation) for more detail.
&nbsp;  
&nbsp;  


# Development

For local development, start by reading the [Installation Instructions](https://github.com/jcraigk/kudochest/wiki/Installation), paying special attention to the [Environment Variables](https://github.com/jcraigk/kudochest/wiki/Installation#environment-variables) section. Note that you will only need certain portions of what is described there, depending on your specific area of development.

## Setup

For Slack and OAuth callbacks, a tunneling service such as [ngrok](https://ngrok.com/) is recommended to expose your local server publicly.

You'll want to setup a dedicated workspace and App in Slack/Discord specifically for KudoChest development. Do not use your organization's production workspace or App to develop against.

If you're working on response images and running Sidekiq in Docker, you'll need to configure a local storage location in `docker-compose.yml` to map to `/storage` in the `sidekiq` container.
&nbsp;  
&nbsp;  


## Run the App Components

You may run all components in Docker with logging exposed using the command `make up` and then connect to the `kudochest_app` container and create the database.

Alternatively you can run services (PG and Redis) in Docker while running the Rails processes natively. This often eases debugging and development.

For running the Rails stack you'll need the following:
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
&nbsp;  

## Testing

To run specs in Docker:

```
make spec
```

To run specs natively:

```
make services
bundle exec rspec
```

To generate seed data for manual testing, first install your local instance of KudoChest into a development workspace and then run

```
bundle exec rails seeds:all
```
&nbsp;  


# Contributors

All contributions are welcome via Issues and Pull Requests. If you notice something wrong in the Wiki, please feel free to fix it!

* Code by [Justin Craig-Kuhn](https://github.com/jcraigk/)
* Logo and background mural by Evan Mahnke (Discord `8-bit adventurer#3751` / `gallanthomeslice at yahoo`)
* Animated GIFs and icons by Milton Monroe (Discord `carmelcamel#5829` / `milton dot p dot monroe at gmail`)
&nbsp;  
&nbsp;  


# Copyright

This software is released under an [MIT-LICENSE](https://github.com/jcraigk/kudochest/blob/master/MIT-LICENSE).
