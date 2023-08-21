#!/bin/bash

set -e

echo "Update hotfix"

## Submodules
submodules() {
    cd tanatloc && git pull && .github/submodules.sh && cd-
}

## Update
update() {
    git add .
    git commit -m"update"
    git push
}

submodules
update
