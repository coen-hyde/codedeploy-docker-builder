#!/bin/bash

set -eo

main() {
  if [[ ! $BUILDKITE_TAG ]]; then
    BUILDKITE_TAG=latest
  fi

  # Register revision with code deploy
  local revision=$(cat <<EOF
{
  "revisionType": "S3",
  "s3Location": {
    "bucket": "$RELEASES_BUCKET",
    "key": "release-${BUILDKITE_TAG}.tar",
    "bundleType": "tar"
  }
}
EOF
)

  aws deploy create-deployment \
    --application-name="$CD_APPLICATION_NAME" \
    --deployment-group-name="$CD_DEPLOYMENT_GROUP_NAME" \
    --deployment-config-name CodeDeployDefault.OneAtATime \
    --description="release: $BUILDKITE_TAG" \
    --revision="$revision"
}

main "$@"
