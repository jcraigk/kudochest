FROM ruby:3.1.2-slim

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
      nodejs \
      npm \
      postgresql-client \
      python2 \
    && apt-get clean

COPY lib/image_magick/policy.xml /etc/ImageMagick-6/policy.xml
RUN mkdir -p /storage/response_images/cache
RUN mkdir -p /storage/response_images/tmp

WORKDIR $INSTALL_PATH

COPY . .

RUN npm install yarn -g
RUN yarn install
RUN gem install bundler && bundle install
RUN bundle exec rake assets:precompile

EXPOSE 3000
CMD bundle exec puma -b tcp://0.0.0.0:3000
