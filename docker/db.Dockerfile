FROM postgres:14.5-alpine

ENV POSTGRES_USER data
ENV POSTGRES_PASSWORD oBa5UiDLZM
ENV POSTGRES_DB biosmart

COPY ./docker/biosmart-staging.sql /docker-entrypoint-initdb.d/
