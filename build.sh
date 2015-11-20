#!/bin/bash

set -eo

main() {
  local image_dir=/usr/src/image-2-build
  local build_dir=/usr/src/docker-builder

  cd $image_dir

  if [[ ! $BUILDKITE_TAG ]]; then
    BUILDKITE_TAG=latest
  fi

  # Build image
  docker build -t $DOCKER_IMAGE:$BUILDKITE_TAG .

  # Push to registry
  docker login --email="${DOCKER_LOGIN_EMAIL}" --username="${DOCKER_LOGIN_USERNAME}" --password="${DOCKER_LOGIN_PASSWORD}" $DOCKER_REGISTRY
  docker push $DOCKER_IMAGE:$BUILDKITE_TAG

  if [[ $BUILDKITE_TAG != "latest" ]]; then
    docker push $DOCKER_IMAGE:latest
  fi
}

main "$@"
