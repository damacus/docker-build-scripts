# Docker Build Scripts

Common build scripts & functions

## Usage

Export the following variables e.g. in something like variables.sh.

### Mandatory Arguments

```shell
PROJECT
MAINTAINER
DESCRIPTION
```

### Optional Arguments

```shell
export VCS_URL="https://github.com/${MAINTAINER:?}/${PROJECT:?}"
export DATE=$(date +%Y-%m-%dT%T%z)
export COMMIT=$(git rev-parse --short HEAD)
export FILE="Dockerfile"
````

Download an source the script:

```shell
if ! [[ -e .docker/functions.sh ]];then
  wget "https://raw.githubusercontent.com/damacus/docker-build-scripts/master/functions.sh" > ".docker/functions.sh"
fi

source `.docker/functions.sh`
```
