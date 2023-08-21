#!/bin/bash

set -e

echo "Update hotfix"

## Submodules
submodules() {
    cd tanatloc && git pull && .github/submodules.sh && cd-
}

submodules
