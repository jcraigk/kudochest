FROM ruby:3.2.2-slim

ARG APP_NAME=kudochest

ENV APP_NAME=${APP_NAME} \
    INSTALL_PATH=/${APP_NAME} \
    IN_DOCKER=true

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libmagickwand-dev \
      libpq-dev \
      libsodium-dev \
      memcached \
      postgresql-client \
      dh-python \
      curl \
      xz-utils \
      ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*;

# Response images
COPY lib/image_magick/policy.xml /etc/ImageMagick-6/policy.xml
RUN mkdir -p /storage/response_images/cache
RUN mkdir -p /storage/response_images/tmp

WORKDIR $INSTALL_PATH

COPY . .

## BEGIN ASSETS PRECOMPILE
ARG TARGETPLATFORM
# Node 16 is used to avoid OpenSSL issue
ARG NODE_VERSION=16.6.2
RUN case ${TARGETPLATFORM} in \
      "linux/amd64") \
        curl -fsSL "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
          | tar -xJf - -C /usr/local --strip-components=1 --no-same-owner ;; \
      "linux/arm64") \
        curl -fsSL "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-arm64.tar.xz" \
          | tar -xJf - -C /usr/local --strip-components=1 --no-same-owner ;; \
      *) echo "Unsupported platform: ${TARGETPLATFORM}" && exit 1 ;; \
    esac
RUN npm install yarn -g && npm cache clean --force;
RUN yarn install
RUN gem install bundler && bundle install
RUN bundle exec rake assets:precompile
## END ASSETS PRECOMPILE

EXPOSE 3000
CMD bundle exec puma -b tcp://0.0.0.0:3000
