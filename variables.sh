#/bin/sh -e

export PROJECT="${NAME:-$CIRCLE_PROJECT_REPONAME}"
export DESCRIPTION=""
export MAINTAINER="damacus"
export VCS_URL="https://github.com/${MAINTAINER:?}/${PROJECT:?}"
export DATE=$(date +%Y-%m-%dT%T%z)
export COMMIT=$(git rev-parse --short HEAD)
export FILE="Dockerfile"
