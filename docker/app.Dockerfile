FROM ruby:3.0.2

SHELL ["/bin/bash", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/*

RUN addgroup app && adduser --ingroup app app

ENV INSTALL_PATH /usr/src/app
RUN mkdir -p $INSTALL_PATH
RUN chown -R app:app $INSTALL_PATH

WORKDIR /usr/src/app
USER app
COPY --chown=app:app Gemfile Gemfile.lock ./
RUN bundle install

COPY --chown=app:app . ./
RUN mkdir -p $INSTALL_PATH/tmp/sockets
RUN chown -R app:app $INSTALL_PATH/tmp/sockets

EXPOSE 8080

# CMD ["puma", "config.ru", "-C", "config/puma.rb"]
ENTRYPOINT ["tail", "-f", "/dev/null"]
