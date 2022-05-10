## BUILDER ##
FROM tanatloc/worker as builder

ENV DEBIAN_FRONTEND noninteractive

ENV INSTALL_PATH /home/app

# Install packages
RUN apt update \
    && apt upgrade -yq \
    && apt install -yq \
    apt-utils curl \
    git gnupg g++ libpq-dev \
    make python3 \
    && apt autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Node
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -yq nodejs \
    && apt autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Yarn
RUN corepack enable

# Build (one shot in order to do not keep ssh key in a layer)
ARG SSH_PRIVATE_KEY
ARG SSH_PUBLIC_KEY
ARG GIT_PARAM

ARG DB_ADMIN
ENV DB_ADMIN $DB_ADMIN

ARG DB_ADMIN_PASSWORD
ENV DB_ADMIN_PASSWORD $DB_ADMIN_PASSWORD

ARG DB_HOST
ENV DB_HOST $DB_HOST

ARG DB_PORT
ENV DB_PORT $DB_PORT

WORKDIR ${INSTALL_PATH}

# SSH key
RUN mkdir -p /root/.ssh \
    && chmod 0700 /root/.ssh \
    && ssh-keyscan github.com > /root/.ssh/known_hosts \
    && echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa \
    && echo "$SSH_PUBLIC_KEY" > /root/.ssh/id_rsa.pub \
    && chmod 600 /root/.ssh/id_rsa \
    && chmod 600 /root/.ssh/id_rsa.pub \
    # Clone
    && git clone "$GIT_PARAM" git@github.com:Airthium/tanatloc.git ${INSTALL_PATH} -b dev \
    # Build
    && YARN_CHECKSUM_BEHAVIOR="update" yarn install \
    && yarn run prestart:norun \
    && yarn run next telemetry disable \
    && yarn run build \
    # Remove SSH key
    && rm /root/.ssh/id_rsa /root/.ssh/id_rsa.pub

## RELEASE ##
FROM tanatloc/worker

ENV DEBIAN_FRONTEND noninteractive

ENV INSTALL_PATH /home/app
ENV APP_PATH /home/app

# Install packages
RUN apt update \
    && apt upgrade -yq \
    && apt install -yq \
    curl git gnupg g++ libpq-dev \
    make postgresql python3 \
    sudo \
    && apt autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Node
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs \
    && apt autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Yarn
RUN corepack enable

# Copy
WORKDIR ${APP_PATH}

COPY docker/package.json package.json

COPY --from=builder ${INSTALL_PATH}/.git .git
COPY --from=builder ${INSTALL_PATH}/.yarn .yarn
COPY --from=builder ${INSTALL_PATH}/.yarnrc.yml .yarnrc.yml
COPY --from=builder ${INSTALL_PATH}/dist dist
COPY --from=builder ${INSTALL_PATH}/dist-install dist-install
COPY --from=builder ${INSTALL_PATH}/public public
COPY --from=builder ${INSTALL_PATH}/templates templates
COPY --from=builder ${INSTALL_PATH}/plugins plugins
COPY --from=builder ${INSTALL_PATH}/.next .next
COPY --from=builder ${INSTALL_PATH}/yarn.lock yarn.lock

# Corepack prepare
RUN corepack prepare yarn@3.2.0 -o=yarn-3.2.0.tgz
RUN cp -r /root/.node ${APP_PATH}/.node

# Build (one shot in order to do not keep ssh key in a layer)
ARG SSH_PRIVATE_KEY
ARG SSH_PUBLIC_KEY

ARG DB_ADMIN
ENV DB_ADMIN $DB_ADMIN

ARG DB_ADMIN_PASSWORD
ENV DB_ADMIN_PASSWORD $DB_ADMIN_PASSWORD

ARG DB_HOST
ENV DB_HOST $DB_HOST

ARG DB_PORT
ENV DB_PORT $DB_PORT

# SSH key
RUN mkdir -p /root/.ssh \
    && chmod 0700 /root/.ssh \
    && ssh-keyscan github.com > /root/.ssh/known_hosts \
    && echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa \
    && echo "$SSH_PUBLIC_KEY" > /root/.ssh/id_rsa.pub \
    && chmod 600 /root/.ssh/id_rsa \
    && chmod 600 /root/.ssh/id_rsa.pub \
    # Build
    && YARN_CHECKSUM_BEHAVIOR="update" yarn install \
    && yarn run next telemetry disable \
    # Remove SSH key
    && rm /root/.ssh/id_rsa /root/.ssh/id_rsa.pub

# Path
ENV ADDITIONAL_PATH $ADDITIONAL_PATH

# Storage
ENV HOST_STORAGE=${HOST_STORAGE}

# ShareTask
ENV SHARETASK_JVM $SHARETASK_JVM
RUN mkdir -p /usr/local/sharetask/bin
RUN mkdir -p /usr/local/jre/bin

# Start script
COPY docker/start.sh start.sh
RUN chmod a+x start.sh

## START
CMD export PATH=$PATH:$ADDITIONAL_PATH; ${APP_PATH}/start.sh $DB_ADMIN $DB_ADMIN_PASSWORD $HOST_STORAGE
