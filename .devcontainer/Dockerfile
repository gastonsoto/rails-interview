FROM ruby:3.1.6

# Install system deps
RUN apt-get update && apt-get install -y \
  build-essential \
  libsqlite3-dev \
  sqlite3 \
  nodejs \
  git \
  curl

WORKDIR /workspaces/app

# Install bundler
RUN gem install bundler

# Optional: speed up bundler
ENV BUNDLE_PATH=/usr/local/bundle
