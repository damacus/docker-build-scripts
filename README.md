# Docker Build Scripts

Build functions for Docker.

The following environment variables are used

VARIABLE    |                             Description                              |                    Default
:---------- | :------------------------------------------------------------------: | :--------------------------------------------:
DESCRIPTION |                    Description of the repository                     |                     empty
DATE        |                              Build date                              |   Current date in the format YYYY-MM-DD-TIME
COMMIT      |                             Commit Hash                              |     Output from git rev-parse --short HEAD
BRANCH      |                            Current branch                            |   Output from git symbolic-ref --short HEAD
FILE        |                     The source Dockerfile to use                     |                   Dockerfile
VCS_URL     |                      Git URL for the container                       | Output from git config --get remote.origin.url
NPM_TOKEN   | Optional argument that to allow npm install to work in the container |                     empty
PROJECT     |                      The project name and owner                      |     Organisation and user from the Git URL
MAINTAINER  |                      Maintainer of the project                       |     Organisation or user from the Git URL

## Usage

Download an source the script:

```shell
if ! [[ -e .docker/functions.sh ]];then
  wget "https://raw.githubusercontent.com/damacus/docker-build-scripts/master/functions.sh" > ".docker/functions.sh"
fi

source `.docker/functions.sh`
```

## Overwriting a DEFAULT_VALUE

Overwrite a default by exporting it before you source the script.

`export DATE=$(date +%Y-%m-%d)` << This will omit the current time.
