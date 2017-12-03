FROM ruby:2.4.2
LABEL maintainer="Haruyuki Iida"

RUN apt-get update \
  && apt-get install -y nodejs libmysqlclient-dev --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /usr/local

COPY lib/radvent/version.rb /tmp/
RUN ruby -I /tmp -r version.rb -e "puts Radvent::VERSION.version" > /tmp/version
RUN git clone https://github.com/haru/radvent.git -b `cat /tmp/version` /usr/local/radvent
RUN rm /tmp/version.rb /tmp/version
WORKDIR /usr/local/radvent

RUN bundle install --without test development

COPY docker/database.yml /usr/local/radvent/config/
RUN bundle exec rake radvent:generate_default_settings
RUN bundle exec rake assets:clean && bundle exec rake assets:precompile
COPY docker/run.sh /usr/local/bin/run.sh

RUN mkdir -p /var/radvent_data/uploads
RUN rm -f /usr/local/radvent/public/uploads
RUN ln -s /var/radvent_data/uploads /usr/local/radvent/public/uploads

EXPOSE 3000

CMD sh -x /usr/local/bin/run.sh
