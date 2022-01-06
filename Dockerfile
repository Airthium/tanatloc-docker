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

# NVM
ENV NODE_VERSION=16.13.1
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR /root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"

# Yarn
RUN corepack enable

RUN apt autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# SSH key
ARG SSH_PRIVATE_KEY
ARG SSH_PUBLIC_KEY

RUN mkdir -p /root/.ssh && \
    chmod 0700 /root/.ssh && \
    ssh-keyscan github.com > /root/.ssh/known_hosts

RUN echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa && \
    echo "$SSH_PUBLIC_KEY" > /root/.ssh/id_rsa.pub && \
    chmod 600 /root/.ssh/id_rsa && \
    chmod 600 /root/.ssh/id_rsa.pub

# Clone
RUN git clone git@github.com:Airthium/tanatloc.git ${INSTALL_PATH} -b dev

# Build
ARG DB_ADMIN
ENV DB_ADMIN $DB_ADMIN

ARG DB_ADMIN_PASSWORD
ENV DB_ADMIN_PASSWORD $DB_ADMIN_PASSWORD

ARG DB_HOST
ENV DB_HOST $DB_HOST

ARG DB_PORT
ENV DB_PORT $DB_PORT

WORKDIR ${INSTALL_PATH}

RUN yarn install
RUN yarn run prestartwithoutrun
RUN yarn run next telemetry disable

RUN yarn run build

# Remove SSH key
RUN rm /root/.ssh/id_rsa /root/.ssh/id_rsa.pub

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

# NVM
ENV NODE_VERSION=16.13.1
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR /root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"

# Yarn
RUN corepack enable

RUN apt autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# SSH key
ARG SSH_PRIVATE_KEY
ARG SSH_PUBLIC_KEY

RUN mkdir -p /root/.ssh && \
    chmod 0700 /root/.ssh && \
    ssh-keyscan github.com > /root/.ssh/known_hosts

RUN echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa && \
    echo "$SSH_PUBLIC_KEY" > /root/.ssh/id_rsa.pub && \
    chmod 600 /root/.ssh/id_rsa && \
    chmod 600 /root/.ssh/id_rsa.pub

# Copy
WORKDIR ${APP_PATH}

COPY docker/package.json package.json

COPY --from=builder ${INSTALL_PATH}/.git .git
COPY --from=builder ${INSTALL_PATH}/.yarn .yarn
COPY --from=builder ${INSTALL_PATH}/.yarnrc.yml .yarnrc.yml
COPY --from=builder ${INSTALL_PATH}/dist-install dist-install
COPY --from=builder ${INSTALL_PATH}/public public
COPY --from=builder ${INSTALL_PATH}/templates templates
COPY --from=builder ${INSTALL_PATH}/plugins plugins
COPY --from=builder ${INSTALL_PATH}/.next .next
COPY --from=builder ${INSTALL_PATH}/yarn.lock yarn.lock

RUN yarn install
RUN yarn run next telemetry disable

COPY docker/start.sh start.sh
RUN chmod +x start.sh

# Remove SSH key
RUN rm /root/.ssh/id_rsa /root/.ssh/id_rsa.pub

## START
CMD ${APP_PATH}/start.sh $DB_ADMIN $DB_ADMIN_PASSWORD
