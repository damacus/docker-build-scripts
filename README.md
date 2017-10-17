# Docker Build Scripts

Common build scripts & functions

## Usage

Export the following variables (e.g. in variables.sh)

```shell
export PROJECT="${NAME:-$CIRCLE_PROJECT_REPONAME}"
export DESCRIPTION="Docker container composer on PHP 5.5"
export MAINTAINER="damacus"
export VCS_URL="https://github.com/${MAINTAINER:?}/${PROJECT:?}"
export DATE=$(date +%Y-%m-%dT%T%z)
export COMMIT=$(git rev-parse --short HEAD)
export FILE="Dockerfile"
```

`wget "<https://raw.githubusercontent.com/damacus/docker-build-scripts/master/functions.sh>" > ".docker/functions.sh"`
