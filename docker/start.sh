#!/bin/sh

POSTGRES_USER="$1"
POSTGRES_PASSWORD="$2"
HOST_STORAGE="$3"

HOME=/home/app

# Create user
echo "====> Create user"
useradd --shell /bin/bash -u $UID -d $HOME -o -c "" -m user

# Set .env
echo "====> Set .env"
echo "export OCCPATH=${OCCPATH}" > $HOME/.env
echo "export GMSHPATH=${GMSHPATH}" >> $HOME/.env
echo "export FREEFEMPATH=${FREEFEMPATH}" >> $HOME/.env
echo "export CONVERTERSPATH=${CONVERTERSPATH}" >> $HOME/.env
echo "export DB_ADMIN=${DB_ADMIN}" >> $HOME/.env
echo "export DB_ADMIN_PASSWORD=${DB_ADMIN_PASSWORD}" >> $HOME/.env
echo "export DB_HOST=${DB_HOST}" >> $HOME/.env
echo "export DB_ADMIN=${DB_ADMIN}" >> $HOME/.env
echo "export DOMAIN=${DOMAIN}" >> $HOME/.env
echo "export ADDITIONAL_PATH=${ADDITIONAL_PATH}" >> $HOME/.env
echo "export HOST_STORAGE=${STORAGE_PATH}" >> $HOME/.env
echo "export HTTP_PROXY=${HTTP_PROXY}" >> $HOME/.env
echo "export HTTPS_PROXY=${HTTPS_PROXY}" >> $HOME/.env
echo "export SHARETASK_JVM=${SHARETASK_JVM}" >> $HOME/.env

# Grant access
echo "====> Grant access"
chown -R user:user $HOME

# Switch user
sudo -i -u user bash << EOF
echo "====> User is now 'user'"

# Get .env
echo "====> Get .env"
source ${HOME}/.env
export PATH=$GMSHPATH/bin:$FREEFEMPATH/bin:$CONVERTERSPATH/bin:$PATH
export LD_LIBRARY_PATH=$OCCPATH/lib:$GMSHPATH/lib:$FREEFEMPATH/lib:$VTKPATH/lib:$CONVERTERSPATH/lib:$LD_LIBRARY_PATH
export FF_INCLUDEPATH=$FREEFEMPATH/lib/ff++/4.9/idp
export FF_LOADPATH=$FREEFEMPATH/lib/ff++/4.9/lib

# Wait for postgresql
echo "====> Wait for Postgres"
until PGPASSWORD=$POSTGRES_PASSWORD psql -h database -U "$POSTGRES_USER" -c '\q'; do
  >&2 echo "Postgres is unavailable - waiting..."
  sleep 1
done

>&2 echo "Postgres is up - starting Tanatloc..."

# dB & data install
echo "====> Install"
node dist-install/install

# Corepack
echo "====> Hydrate corepack..."
corepack hydrate yarn-3.2.0.tgz

# Start app
echo "====> Start..."
HOST_STORAGE="${HOST_STORAGE}" HTTP_PROXY="${HTTP_PROXY}" HTTPS_PROXY="${HTTPS_PROXY}" yarn run start

EOF