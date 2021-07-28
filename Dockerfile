FROM ruby:2.7.3-slim

ARG APP_NAME=kudochest

ENV APP_NAME=${APP_NAME} \
    INSTALL_PATH=/${APP_NAME} \
    IN_DOCKER=true

RUN apt-get update -qq && \
    apt-get install -y \
      build-essential \
      git \
      libmagickwand-dev \
      libpq-dev \
      libsodium-dev \
      memcached \
      postgresql-client \
    && apt-get clean

COPY lib/image_magick/policy.xml /etc/ImageMagick-6/policy.xml

WORKDIR $INSTALL_PATH

COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install

COPY . .

EXPOSE 3000
CMD bundle exec puma -b tcp://0.0.0.0:3000
