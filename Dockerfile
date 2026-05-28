# Use a modern Judge0 compilers image (Debian Bullseye/Bookworm based)
FROM judge0/compilers:1.13.0 AS production

# Metadata
ENV JUDGE0_HOMEPAGE="https://judge0.com"
LABEL homepage=$JUDGE0_HOMEPAGE

ENV JUDGE0_SOURCE_CODE="https://github.com/judge0/judge0"
LABEL source_code=$JUDGE0_SOURCE_CODE

ENV JUDGE0_MAINTAINER="Herman Zvonimir Došilović <hermanz.dosilovic@gmail.com>"
LABEL maintainer=$JUDGE0_MAINTAINER

# Ruby/Gem paths
ENV PATH="/usr/local/ruby-2.7.0/bin:/opt/.gem/bin:$PATH"
ENV GEM_HOME="/opt/.gem/"

# Install dependencies (using updated repos)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      cron \
      libpq-dev \
      sudo && \
    rm -rf /var/lib/apt/lists/* && \
    echo "gem: --no-document" > /root/.gemrc && \
    gem install bundler:2.1.4 && \
    npm install -g --unsafe-perm aglio@2.3.0

# Expose Judge0 API port
EXPOSE 2358

WORKDIR /api

# Install Ruby gems
COPY Gemfile* ./
RUN RAILS_ENV=production bundle install

# Setup cron jobs
COPY cron /etc/cron.d
RUN cat /etc/cron.d/* | crontab -

# Copy app source
COPY . .

# Entrypoint
ENTRYPOINT ["/api/docker-entrypoint.sh"]
CMD ["/api/scripts/server"]

# Create judge0 user
RUN useradd -u 1000 -m -r judge0 && \
    echo "judge0 ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers && \
    chown judge0: /api/tmp/

USER judge0

ENV JUDGE0_VERSION="1.13.1"
LABEL version=$JUDGE0_VERSION

# Development stage
FROM production AS development
CMD ["sleep", "infinity"]
