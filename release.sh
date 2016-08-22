#!/bin/bash

set -eo

main() {
  local image_dir=/usr/src/image-2-build
  local build_dir=/usr/src/docker-builder

  cd $image_dir

  cp docker-compose/production.yml $build_dir/release/production.yml

  cd $build_dir

  cat <<EOF >./release/config.json
{
  "docker": {
    "registry": "$DOCKER_REGISTRY",
    "image": "$DOCKER_IMAGE:$BUILDKITE_BUILD_ID",
    "login_email": "$DOCKER_LOGIN_EMAIL",
    "login_username": "$DOCKER_LOGIN_USERNAME",
    "login_password": "$DOCKER_LOGIN_PASSWORD"
  }
}
EOF

  # Package release
  $(cd release && tar -cf ../release.tar ./)

  # Put release on S3
  echo "Pushing release to s3://$RELEASES_BUCKET/release-${BUILDKITE_BUILD_ID}.tar"
  echo "aws s3api put-object --bucket=\"$RELEASES_BUCKET\" --key=\"release-${BUILDKITE_BUILD_ID}.tar\" --body release.tar"
  aws s3api put-object --bucket="$RELEASES_BUCKET" --key="release-${BUILDKITE_BUILD_ID}.tar" --body=release.tar

  # Register revision with code deploy
  local revision=$(cat <<EOF
{
  "revisionType": "S3",
  "s3Location": {
    "bucket": "$RELEASES_BUCKET",
    "key": "release-${BUILDKITE_BUILD_ID}.tar",
    "bundleType": "tar"
  }
}
EOF
)

  aws deploy create-deployment \
    --application-name="$CD_APPLICATION_NAME" \
    --deployment-group-name="$CD_DEPLOYMENT_GROUP_NAME" \
    --deployment-config-name CodeDeployDefault.OneAtATime \
    --description="release: $BUILDKITE_BUILD_ID" \
    --revision="$revision"
}

main "$@"
