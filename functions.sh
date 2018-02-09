#!/bin/bash -e
set +o pipefail

if [[ -n "${DESCRIPTION}" ]];then
  DESCRIPTION="${DESCRIPTION:?}"
fi

DEFAULT_DATE=$(date +%Y-%m-%dT%T%z)
DATE=${DATE:-$DEFAULT_DATE}

DEFAULT_COMMIT=$(git rev-parse --short HEAD)
COMMIT=${COMMIT:-$DEFAULT_COMMIT}

BRANCH_DEFAULT="$(git symbolic-ref --short HEAD)"
BRANCH="${CIRCLE_BRANCH:-$BRANCH_DEFAULT}"

if [[ -z $FILE ]];then
  if [[ -e "./.docker/Dockerfile" ]];then
    FILE="./.docker/Dockerfile"
  elif [[ -e "./Dockerfile" ]];then
    FILE="./Dockerfile"
  else
    echo "Didn't file either ./Dockerfile or ./.docker/Dockerfile"
  fi
fi

DEFAULT_VCS_URL=$(git config --get remote.origin.url)
# This strips the matching .git, then splits on :
PROJECT=$(echo "${DEFAULT_VCS_URL%.git}" | cut -d: -f2 | tr '[:upper:]' '[:lower:]')

DEFAULT_MAINTAINER=$(echo "$PROJECT" | cut -d/ -f1)
MAINTAINER=${MAINTAINER:-$DEFAULT_MAINTAINER}
VCS_URL=${VCS_URL:-$DEFAULT_VCS_URL}

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
  local CACHE="--cache-from=${PROJECT:?}"
  local FILE_FROM="--file ${FILE:?}"
  local TAG_ARG="--tag ${PROJECT:?}"

  echo "passing build arguments ${BUILD_ARGS}"
  eval "docker build ${CACHE} ${BUILD_ARGS} ${FILE_FROM} ${TAG_ARG} ."

 if [[ ${CI} == 'true' ]];then
   mkdir -p /caches
   docker save -o /caches/app.tar "${PROJECT:?}"
 fi
}

push() {
  TAG=${CIRCLE_BUILD_NUM:-beta}

  if [ "${BRANCH}" = "master" ]; then
    docker login -u "${DOCKER_LOGIN:?}" -p "${DOCKER_PASSWORD:?}"

    printf "\\n\\n--- Images ---\\n"
    docker images "${PROJECT:?}"

    printf "\\n\\n--- Tagging ---\\n"
    docker tag "${PROJECT:?}:latest" "${PROJECT:?}:${TAG:?}"

    printf "\\n\\n--- Pushing Images to Docker Hub ---\\n"
    docker push "${PROJECT:?}:${TAG:?}"
    docker push "${PROJECT:?}:latest"
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
  docker run -it "${PROJECT:?}" "${1:?}"
}
