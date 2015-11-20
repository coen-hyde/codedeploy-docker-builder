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

  cp $image_dir/deployment/production.yml $build_dir/release/production.yml

  cd $build_dir

  cat <<EOF >./release/config.json
{
  "docker": {
    "registry": "$DOCKER_REGISTRY",
    "image": "$DOCKER_IMAGE:$BUILDKITE_TAG",
    "login_email": "$DOCKER_LOGIN_EMAIL",
    "login_username": "$DOCKER_LOGIN_USERNAME",
    "login_password": "$DOCKER_LOGIN_PASSWORD"
  }
}
EOF

  # Package release
  $(cd release && tar -cf ../release.tar ./)

  # Put release on S3
  echo "Pushing release to s3://$RELEASES_BUCKET/release-${BUILDKITE_TAG}.tar"
  echo "aws s3api put-object --bucket=\"$RELEASES_BUCKET\" --key=\"release-${BUILDKITE_TAG}.tar\" --body release.tar"
  aws s3api put-object --bucket="$RELEASES_BUCKET" --key="release-${BUILDKITE_TAG}.tar" --body=release.tar
}

main "$@"
