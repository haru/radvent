FROM ruby:4.0
LABEL maintainer="Haruyuki Iida"

RUN apt-get update \
  && apt-get install -y curl --no-install-recommends \
  && curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
  && apt-get install -y nodejs --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*
RUN npm install -g yarn
RUN mkdir -p /usr/local

COPY . /usr/local/radvent/
WORKDIR /usr/local/radvent

RUN bundle config set --local without 'test development'
RUN bundle install

COPY docker/database.yml /usr/local/radvent/config/
RUN bundle exec rake radvent:generate_default_settings
RUN yarn install
RUN mkdir -p app/assets/builds
RUN SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rake assets:clean assets:precompile
COPY docker/run.sh /usr/local/bin/run.sh

RUN mkdir -p /var/radvent_data/uploads
RUN rm -f /usr/local/radvent/public/uploads
RUN ln -s /var/radvent_data/uploads /usr/local/radvent/public/uploads

ENV RAILS_ENV=production

EXPOSE 3000

CMD sh -x /usr/local/bin/run.sh
