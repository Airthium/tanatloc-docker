#!/bin/sh

POSTGRES_USER="$1"
POSTGRES_PASSWORD="$2"
HOST_STORAGE="$3"

HOME=/home/app

# Wait for postgresql
until PGPASSWORD=$POSTGRES_PASSWORD psql -h database -U "$POSTGRES_USER" -c '\q'; do
  >&2 echo "Postgres is unavailable - waiting..."
  sleep 1
done

>&2 echo "Postgres is up - starting Tanatloc..."

# dB install
echo "====> Install"
node dist-install/install

# Corepack
echo "====> Hydrate corepack..."
corepack hydrate yarn-3.1.1.tgz

# Start app
echo "====> Start..."
HOST_STORAGE=${HOST_STORAGE} HTTP_PROXY=${HTTP_PROXY} HTTPS_PROXY=${HTTPS_PROXY} yarn run start
