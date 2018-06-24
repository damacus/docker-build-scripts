# Docker Build Scripts

Build functions for Docker.

The following environment variables are used:

VARIABLE    |          Description          |                    Default
:---------- | :---------------------------: | :--------------------------------------------:
DESCRIPTION | Description of the repository |            Dockerfile for $PROJECT
DATE        |          Build date           |   Current date in the format YYYY-MM-DD-TIME
COMMIT      |          Commit Hash          |     Output from git rev-parse --short HEAD
BRANCH      |        Current branch         |   Output from git symbolic-ref --short HEAD
FILE        | The source Dockerfile to use  |                   Dockerfile
VCS_URL     |   Git URL for the container   | Output from git config --get remote.origin.url
PROJECT     |  The project name and owner   |     Organisation and user from the Git URL
MAINTAINER  |   Maintainer of the project   |     Organisation or user from the Git URL

You may set extra variables to be passed in e.g.

```bash
EXTRA_BUILD_ARGS+=( "NPM_TOKEN" )

NPM_TOKEN='12345'
```

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

This will omit the current time.

```bash
export DATE=$(date +%Y-%m-%d)
```

If your Github repository does not match the docker hub repository, you may wish to set the PROJECT variable

e.g. Dockerhub repo is set to `foo` Github repo is set to `bar`

To push to the `foo` repo on Dockerhub

```bash
export PROJECT=foo`
```
