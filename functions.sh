#!/bin/sh -e
set +o pipefail

MAINTAINER="${MAINTAINER:?}"
DESCRIPTION="${DESCRIPTION:?}"
PROJECT="${PROJECT:-$CIRCLE_PROJECT_REPONAME}"
NPM_TOKEN=${NPM_TOKEN:-nil}

DEFAULT_DATE=$(date +%Y-%m-%dT%T%z)
DATE=${DATE:-$DEFAULT_DATE}

DEFAULT_COMMIT=$(git rev-parse --short HEAD)
COMMIT=${COMMIT:-$DEFAULT_COMMIT}

BRANCH_DEFAULT="$(git symbolic-ref --short HEAD)"
BRANCH="${CIRCLE_BRANCH:-BRANCH_DEFAULT}"

FILE=${FILE:-Dockerfile}
VCS_URL="https://github.com/${MAINTAINER:?}/${PROJECT:?}"

build() {
  # Only load and save cache in CI environment
  if [[ -e /caches/app.tar ]];then
    docker load -i /caches/app.tar
  fi

  docker build --cache-from="${MAINTAINER:?}"/"${PROJECT:?}" \
               --build-arg PROJECT="${PROJECT:?}"            \
               --build-arg MAINTAINER="${MAINTAINER:?}"      \
               --build-arg URL="${VCS_URL:?}"                \
               --build-arg DATE="${DATE:?}"                  \
               --build-arg COMMIT="${COMMIT:?}"              \
               --build-arg DESCRIPTION="${DESCRIPTION:?}"    \
               --build-arg NPM_TOKEN="${NPM_TOKEN:?}"        \
               --file "${FILE:?}"                            \
               --tag "${MAINTAINER:?}"/"${PROJECT:?}" .
   if [[ ${CI} == 'true' ]];then
     mkdir -p /caches
     docker save -o /caches/app.tar ${MAINTAINER:?}/"${PROJECT:?}"
   fi
}

push() {
  TAG=${CIRCLE_BUILD_NUM:-beta}

  if [ "${BRANCH}" = "master" ]; then
    docker login -u "${DOCKER_LOGIN:?}" -p "${DOCKER_PASSWORD:?}"

    printf "\n\n--- Images ---\n"
    docker images "${MAINTAINER:?}/${PROJECT:?}"

    printf "\n\n--- Tagging ---\n"
    docker tag "${MAINTAINER:?}/${PROJECT:?}:latest" "${MAINTAINER:?}/${PROJECT:?}:${TAG:?}"

    printf "\n\n--- Pushing Images to Docker Hub ---\n"
    docker push "${MAINTAINER:?}/${PROJECT:?}:${TAG:?}"
    docker push "${MAINTAINER:?}/${PROJECT:?}:latest"
  else
    printf "\n\n---Not on master so not tagging ---\n"
    printf "\nBuilt Images"
    docker images
  fi
}

push_beta() {
  true
}

test() {
  docker run -it "${MAINTAINER:?}"/"${PROJECT:?}" "${1:?}"
}
