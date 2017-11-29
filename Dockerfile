FROM ruby:2.4.2
LABEL maintainer="Haruyuki Iida"

RUN mkdir -p /usr/local

RUN git clone https://github.com/haru/radvent.git -b 2.0b2 /usr/local/radvent
WORKDIR /usr/local/radvent

RUN bundle install --without test development

RUN apt-get update \
    && apt-get install -y nodejs --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

RUN bundle exec rake radvent:generate_default_settings
RUN bundle exec rake assets:clean && bundle exec rake assets:precompile
COPY docker/run.sh /usr/local/bin/run.sh
COPY docker/database.yml /usr/local/radvent/config/
RUN mkdir -p /var/radvent_data/uploads
RUN rm -f /usr/local/radvent/public/uploads
RUN ln -s /var/radvent_data/uploads /usr/local/radvent/public/uploads

EXPOSE 3000

CMD sh -x /usr/local/bin/run.sh
