##
#  Generic dockerfile for dbt image building.
#  See README for operational details
##

# Top level build args
ARG build_for=linux/amd64
ARG dbt_core_ref=dbt-core@v1.4.0a1

##
# base image (abstract)
##
FROM --platform=$build_for nikolaik/python-nodejs:python3.10-nodejs18-slim as base
USER root

# N.B. The refs updated automagically every release via bumpversion
# N.B. dbt-postgres is currently found in the core codebase so a value of dbt-core@<some_version> is correct
ARG dbt_third_party

# System setup
RUN apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install -y --no-install-recommends \
    git \
    ssh-client \
    software-properties-common \
    make \
    build-essential \
    ca-certificates \
    libpq-dev \
  && apt-get clean \
  && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Env vars
ENV PYTHONIOENCODING=utf-8
ENV LANG=C.UTF-8
ENV DBT_PROJECT_PATH=/usr/app/dbt

# Update python
RUN python -m pip install --upgrade pip setuptools wheel --no-cache-dir

##
# dbt-core
##
FROM base as dbt-core
RUN python -m pip install --no-cache-dir "git+https://github.com/dbt-labs/dbt-core@v1.2.2#egg=dbt-core&subdirectory=core"

##
# dbt-third-party
##
FROM dbt-core as dbt-third-party
RUN python -m pip install --no-cache-dir \
  dbt-sqlite

# Set docker basics
USER pn
WORKDIR /usr/app/dbt/
VOLUME /usr/app

# Run dbt
COPY --chown=pn atlas_demo_dbt /usr/app/dbt/
COPY --chown=pn profiles.yml /home/pn/.dbt/
RUN mkdir -p /home/pn/sqlite/dbt/
RUN dbt deps
RUN dbt seed
RUN dbt run

# Clone the Atlas repo
WORKDIR /usr/app/
RUN git clone https://github.com/mjirv/atlas.git
WORKDIR /usr/app/atlas
RUN yarn install \
  && yarn build

# run with `docker run -p 3000:3000 atlas-demo start
EXPOSE 3000
ENTRYPOINT ["yarn"]
