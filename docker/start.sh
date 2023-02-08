#!/bin/sh

HOME=/home/app

# Create user
echo "====> Create user"
useradd --shell /bin/bash -u "$UID" -d "$HOME" -o -c "" -m "$USER"

# Set .env
echo "====> Set .env"
{
  echo "export OCCPATH=${OCCPATH}"
  echo "export GMSHPATH=${GMSHPATH}"
  echo "export FREEFEMPATH=${FREEFEMPATH}"
  echo "export CONVERTERSPATH=${CONVERTERSPATH}"
  echo "export DB_ADMIN=${DB_ADMIN}"
  echo "export DB_ADMIN_PASSWORD=${DB_ADMIN_PASSWORD}"
  echo "export DB_HOST=${DB_HOST}"
  echo "export DB_ADMIN=${DB_ADMIN}"
  echo "export DOMAIN=${DOMAIN}"
  echo "export ADDITIONAL_PATH=${ADDITIONAL_PATH}"
  echo "export HOST_STORAGE=${HOST_STORAGE}"
  echo "export HTTP_PROXY=${HTTP_PROXY}"
  echo "export HTTPS_PROXY=${HTTPS_PROXY}"
  echo "export SHARETASK_JVM=${SHARETASK_JVM}"
} >$HOME/.env

# Grant access
echo "====> Grant access"
chown -R $USER:$USER $HOME

# Yarn version
echo "====> Yarn version"
YARN_VERSION=$(cat package.json | grep packageManager | head -1 | awk -F: '{ print $2 }' | sed 's/["\ ]//g' | sed 's/yarn@//g')
echo "      $YARN_VERSION"

# Switch user
sudo -i -u "$USER" bash <<EOF
echo "====> User is now '$USER'"

# Get .env
echo "====> Get .env"
source ${HOME}/.env
export PATH=$GMSHPATH/bin:$FREEFEMPATH/bin:$CONVERTERSPATH/bin:$PATH
export LD_LIBRARY_PATH=$OCCPATH/lib:$GMSHPATH/lib:$FREEFEMPATH/lib:$VTKPATH/lib:$CONVERTERSPATH/lib:$LD_LIBRARY_PATH
export FF_INCLUDEPATH=$FREEFEMPATH/lib/ff++/4.9/idp
export FF_LOADPATH=$FREEFEMPATH/lib/ff++/4.9/lib

# Wait for postgresql
echo "====> Wait for Postgres"
until PGPASSWORD=${DB_ADMIN_PASSWORD} psql -h database -U "${DB_ADMIN}" -c '\q'; do
  >&2 echo "Postgres is unavailable - waiting..."
  sleep 1
done

>&2 echo "Postgres is up - starting Tanatloc..."

# dB & data install
echo "====> Install"
ls node_modules/mathjax
ls node_modules/three
node --experimental-specifier-resolution=node dist-install/install

# Corepack
echo "====> Hydrate corepack..."
corepack hydrate yarn-${YARN_VERSION}.tgz

# Start app
echo "====> Start..."
HOST_STORAGE="${HOST_STORAGE}" HTTP_PROXY="${HTTP_PROXY}" HTTPS_PROXY="${HTTPS_PROXY}" .yarn/releases/yarn-${YARN_VERSION}.cjs start

EOF
