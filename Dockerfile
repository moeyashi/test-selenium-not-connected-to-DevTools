FROM python:3.9-slim as python-base

ENV PYTHONUNBUFFERED=1 \
  \
  PIP_NO_CACHE_DIR=off \
  PIP_DISABLE_PIP_VERSION_CHECK=on \
  PIP_DEFAULT_TIMEOUT=100 \
  \
  POETRY_VERSION=1.4.2 \
  POETRY_HOME="/opt/poetry" \
  POETRY_VIRTUALENVS_CREATE=false \
  \
  PYSETUP_PATH="/opt/pysetup" \
  \
  LANGUAGE=ja_JP.UTF-8 \
  LANG=ja_JP.UTF-8

ENV PATH="$POETRY_HOME/bin:$PATH"
# 本番環境でも必要なpackage
RUN apt-get update \
  && apt-get install --no-install-recommends -y \
  libpq-dev \
  chromium \
  locales \
  && locale-gen ja_JP.UTF-8 \
  && apt-get install -y --no-install-recommends fonts-ipafont

FROM python-base as initial
# 開発環境で必要なpackage、設定
RUN apt-get install --no-install-recommends -y \
  curl \
  build-essential \
  git \
  openssh-server \
  && curl -sSL https://install.python-poetry.org | python3

WORKDIR $PYSETUP_PATH

FROM initial as development-base
ENV POETRY_NO_INTERACTION=1
COPY pyproject.toml ./

FROM development-base as development
RUN poetry install

WORKDIR /app

FROM development-base as builder-base
RUN poetry install --no-dev

FROM python-base as production
COPY --from=builder-base /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
WORKDIR /app

CMD python main.py
