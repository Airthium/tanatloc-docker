## BUILDER ##
FROM tanatloc/worker as builder

USER root

ENV DEBIAN_FRONTEND noninteractive

ENV INSTALL_PATH /home/app
ENV APP_PATH /home/app

# Install packages
RUN apt update \
    && apt upgrade -yq \
    && apt install -yq \
        apt-utils curl \
        git gnupg g++ libpq-dev \
        make python3 \
        nodejs node-gyp

# Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt update \
    && apt install -yq \
        yarn

# NVM
ENV NODE_VERSION=16.13.0
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
ENV NVM_DIR /root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"

RUN apt autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Build
ARG DB_ADMIN
ENV DB_ADMIN $DB_ADMIN

ARG DB_ADMIN_PASSWORD
ENV DB_ADMIN_PASSWORD $DB_ADMIN_PASSWORD

ARG DB_HOST
ENV DB_HOST $DB_HOST

ARG DB_PORT
ENV DB_PORT $DB_PORT

COPY tanatloc/.git ${INSTALL_PATH}/.git
COPY tanatloc/config ${INSTALL_PATH}/config
COPY tanatloc/install ${INSTALL_PATH}/install
COPY tanatloc/models ${INSTALL_PATH}/models
COPY tanatloc/modules ${INSTALL_PATH}/modules
COPY tanatloc/plugins ${INSTALL_PATH}/plugins
COPY tanatloc/public ${INSTALL_PATH}/public
COPY tanatloc/src ${INSTALL_PATH}/src
COPY tanatloc/templates ${INSTALL_PATH}/templates
COPY tanatloc/.eslintrc ${INSTALL_PATH}/.eslintrc
COPY tanatloc/.swcrc ${INSTALL_PATH}/.swcrc
COPY tanatloc/next-env.d.ts ${INSTALL_PATH}/next-env.d.ts
COPY tanatloc/next.config.js ${INSTALL_PATH}/next.config.js
COPY tanatloc/package.json ${INSTALL_PATH}/package.json
COPY tanatloc/process.d.ts ${INSTALL_PATH}/process.d.ts
COPY tanatloc/tsconfig.json ${INSTALL_PATH}/tsconfig.json
COPY tanatloc/yarn.lock ${INSTALL_PATH}/yarn.lock

WORKDIR ${INSTALL_PATH}

RUN yarn
RUN yarn prestartwithoutrun
RUN yarn next telemetry disable

RUN yarn build

## RELEASE ##
FROM tanatloc/worker

USER root

ENV DEBIAN_FRONTEND noninteractive

ENV INSTALL_PATH /home/app
ENV APP_PATH /home/app

ARG DB_ADMIN
ENV DB_ADMIN $DB_ADMIN

ARG DB_ADMIN_PASSWORD
ENV DB_ADMIN_PASSWORD $DB_ADMIN_PASSWORD

ARG DB_HOST
ENV DB_HOST $DB_HOST

ARG DB_PORT
ENV DB_PORT $DB_PORT

# Install packages
RUN apt update \
    && apt upgrade -yq \
    && apt install -yq \
        curl git gnupg g++ libpq-dev \
        make postgresql python3 \
        nodejs node-gyp

# Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt update \
    && apt install -yq \
        yarn

# NVM
ENV NODE_VERSION=16.13.0
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
ENV NVM_DIR /root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"

RUN apt autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy
WORKDIR ${APP_PATH}

COPY docker/package.json package.json

COPY --from=builder ${INSTALL_PATH}/dist-install dist-install
COPY --from=builder ${INSTALL_PATH}/modules modules
COPY --from=builder ${INSTALL_PATH}/public public
COPY --from=builder ${INSTALL_PATH}/templates templates
COPY --from=builder ${INSTALL_PATH}/plugins plugins
COPY --from=builder ${INSTALL_PATH}/.next .next
COPY --from=builder ${INSTALL_PATH}/yarn.lock yarn.lock

RUN yarn
RUN yarn next telemetry disable

COPY docker/start.sh start.sh
RUN chmod +x start.sh

## START
CMD ${APP_PATH}/start.sh $DB_ADMIN $DB_ADMIN_PASSWORD
