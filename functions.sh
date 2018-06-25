#!/bin/bash -e
set +o pipefail

# Usage:
# DESCRIPTION:    Description/usage of the image
#                 e.g. This image is super awesome
# MAINTAINER:     Image maintainer e.g. damacus
# PROJECT:        Project name e.g. docker-builder

# AUTOMATICALLY SET
# DATE:           Date time the project was built
# COMMIT:         Commit hash that was used to build the Dockerfile
# BRANCH:         Branch to determine if we're on master or not.
#                 This script only allows pushing to Dockerhub on master
# VCS_URL:        The git URL Used to compute other attributes
#                 and for image metadata
# DOCKERHUB_REPO: hub.docker.com reference to the repo.
#                 e.g. damacus/docker-builder

# Computed Defaults
VCS_URL_DEFAULT=$(git config --get remote.origin.url)
DATE_DEFAULT=$(date +%Y-%m-%dT%T%z)
BRANCH_DEFAULT="$(git symbolic-ref --short HEAD)"
COMMIT_DEFAULT=$(git rev-parse --short HEAD)

# This strips the matching .git, makes everything lowercase and leaves us with just the repo name
# e.g.
# git@github.com:damacus/docker-builder.git
# docker-builder
PROJECT_DEFAULT=$(echo "${VCS_URL_DEFAULT%.git}" | cut -d: -f2 | tr '[:upper:]' '[:lower:]' | cut -d/ -f2)
PROJECT=${PROJECT:-PROJECT_DEFAULT}

DESCRIPTION_DEFAULT="Dockerfile for $PROJECT"
MAINTAINER_DEFAULT=$(echo "$PROJECT" | cut -d/ -f1)

PROJECT=${PROJECT:-PROJECT_DEFAULT}
DESCRIPTION="${DESCRIPTION:-$DESCRIPTION_DEFAULT}"
DATE=${DATE:-$DATE_DEFAULT}
COMMIT=${COMMIT:-$COMMIT_DEFAULT}
BRANCH="${CIRCLE_BRANCH:-$BRANCH_DEFAULT}"

echo "Project is set to: $PROJECT"
echo "Branch is set to: $BRANCH"
echo "Description is set to: $DESCRIPTION"

if [[ -z $FILE ]];then
  if [[ -e "./.docker/Dockerfile" ]];then
    FILE="./.docker/Dockerfile"
  elif [[ -e "./Dockerfile" ]];then
    FILE="./Dockerfile"
  else
    echo "Error: Did not find either ./Dockerfile or ./.docker/Dockerfile"
  fi
fi

MAINTAINER=${MAINTAINER:-$MAINTAINER_DEFAULT}
VCS_URL=${VCS_URL:-$VCS_URL_DEFAULT}

if [[ -z ${DOCKERHUB_REPO} ]];then
  DOCKERHUB_REPO=${PROJECT_DEFAULT}
else
  DOCKERHUB_REPO="${MAINTAINER}/${PROJECT}"
fi

build_argument() {
  local value
	value=$(eval echo -n '$'"$1")

	if [[ -n "${value/[ ]*\\n/}" ]];then
		echo "--build-arg $1=\"$value\" "
	else
    return 0
  fi
}

build() {
  local DOCKER_BUILD_ARGS=()
  DOCKER_BUILD_ARGS+=( "PROJECT" "DATE" "COMMIT" "DESCRIPTION" )
  if [[ ${#EXTRA_BUILD_ARGS[@]} -gt 0 ]];then
    DOCKER_BUILD_ARGS+=( "${EXTRA_BUILD_ARGS[@]}" )
  fi

  # Only load and save cache in CI environment
  if [[ -e /caches/app.tar ]];then
    docker load -i /caches/app.tar
  fi

  args=()
  for arg in "${DOCKER_BUILD_ARGS[@]}";do
  	args+=( "$(build_argument "$arg" )" )
  done

  local BUILD_ARGS="${args[*]}"
  local CACHE="--cache-from=${DOCKERHUB_REPO:?}"
  local FILE_FROM="--file ${FILE:?}"
  local TAG_ARG="--tag ${DOCKERHUB_REPO:?}"

  eval "docker build ${CACHE} ${BUILD_ARGS} ${FILE_FROM} ${TAG_ARG} ."

 if [[ ${CI} == 'true' ]];then
   mkdir -p /caches
   docker save -o /caches/app.tar "${DOCKERHUB_REPO:?}"
 fi
}

push() {
  TAG=${CIRCLE_BUILD_NUM:-beta}

  if [ "${BRANCH}" = "master" ]; then
    docker login -u "${DOCKER_LOGIN:?}" -p "${DOCKER_PASSWORD:?}"

    printf "\\n\\n--- Images ---\\n"
    docker images "${DOCKERHUB_REPO:?}"

    printf "\\n\\n--- Tagging ---\\n"
    docker tag "${DOCKERHUB_REPO:?}:latest" "${DOCKERHUB_REPO:?}:${TAG:?}"

    printf "\\n\\n--- Pushing Images to Docker Hub ---\\n"
    docker push "${DOCKERHUB_REPO:?}:${TAG:?}"
    docker push "${DOCKERHUB_REPO:?}:latest"
  else
    printf "\\n\\n---Not on master so not tagging ---\\n"
    printf "\\nBuilt Images"
    docker images
  fi
}

push_beta() {
  true
}

test() {
  docker run -it "${DOCKERHUB_REPO:?}" "${1:?}"
}
