#!/bin/sh
set +o pipefail

# If the following variables are not set then set them
if [[ -z $PROJECT ]];then
  PROJECT="${NAME:-$CIRCLE_PROJECT_REPONAME}"
fi
if [[ -z $VCS_URL ]];then
  VCS_URL="https://github.com/${MAINTAINER:?}/${PROJECT:?}"
fi
if [[ -z $DATE ]];then
  DATE=$(date +%Y-%m-%dT%T%z)
fi
if [[ -z $COMMIT ]];then
  COMMIT=$(git rev-parse --short HEAD)
fi
if [[ -z $FILE ]];then
  FILE="Dockerfile"
fi
#You also need to set
#PROJECT
#MAINTAINER
#DESCRIPTION

build() {
  # Only load and save cache in CI environment
  if [[ -e /caches/app.tar ]];then
    docker load -i /caches/app.tar
  fi

  docker build --cache-from="${MAINTAINER:?}"/"${PROJECT:?}" \
               --build-arg PROJECT="${PROJECT:?}" \
               --build-arg MAINTAINER="${MAINTAINER:?}" \
               --build-arg URL="${VCS_URL:?}" \
               --build-arg DATE="${DATE:?}" \
               --build-arg COMMIT="${COMMIT:?}" \
               --build-arg DESCRIPTION="${DESCRIPTION:?}" \
               --file "${FILE:?}" \
               --tag "${MAINTAINER:?}"/"${PROJECT:?}" .

   if [[ -z $CI ]];then
     mkdir -p /caches
     docker save -o /caches/app.tar ${MAINTAINER:?}/"${PROJECT:?}"
   fi
}

push() {
  TAG=${CIRCLE_BUILD_NUM:-beta}

  if [ "${CIRCLE_BRANCH}" = "master" ]; then
    docker login -u "${DOCKER_LOGIN:?}" -p "${DOCKER_PASSWORD:?}"

    printf "\n\n--- Images ---\n\n"
    docker images "${MAINTAINER:?}/${PROJECT:?}"

    printf "\n\n--- Tagging ---\n\n"
    docker tag "${MAINTAINER:?}/${PROJECT:?}:latest" "${MAINTAINER:?}/${PROJECT:?}:${TAG:?}"

    printf "\n\n--- Pushing Images to Docker Hub---\n\n"
    docker push "${MAINTAINER:?}/${PROJECT:?}:${TAG:?}"
  else
    echo "Not on master so not tagging"
    docker images
  fi
}

push_beta() {
  true
}

test() {
  docker run -it "${MAINTAINER:?}"/"${PROJECT:?}" "${1:?}"
}
