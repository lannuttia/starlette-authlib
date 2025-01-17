ARG PYTHON_VERSION=3.10
FROM aogier/python-poetry:py${PYTHON_VERSION}-git as poetry

WORKDIR /srv
COPY . .

RUN set -x \
    && poetry config virtualenvs.create false \
    && poetry install

FROM poetry as test

ARG PYTHON_VERSION=3.10

RUN if [ $PYTHON_VERSION != 3.7 ] \
    ;then \
        poetry run \
            pre-commit run \
                -a --show-diff-on-failure \
    ;fi \
    && poetry run \
        pytest \
            --ignore venv \
            -W ignore::DeprecationWarning \
            --cov-report=xml \
            --cov=starlette_authlib \
            --cov=tests \
            --cov-fail-under=100 \
            --cov-report=term-missing

FROM poetry as release

ARG PYPI_TOKEN
ARG CODECOV_TOKEN
ARG GIT_SHA

COPY --from=test /srv/coverage.xml .

RUN set -x \
    && poetry publish --build \
        --username __token__ \
        --password $PYPI_TOKEN \
    && codecov \
        --token $CODECOV_TOKEN \
        --commit $GIT_SHA
