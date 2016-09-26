#!/bin/bash

set -eo pipefail

main() {
  local release_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
  local config="$(cat ${release_dir}/config.json)"
  local port="$(echo $config | jq -r '.port')"

  # wait for service to become available
  echo "Waiting for service to become available"

  local attempts=0
  until $(curl --output /dev/null --silent --head --fail http://127.0.0.1:${port}/healthcheck); do
    printf '.'

    attempts=$(( attempts + 1))
    if [[ attempts -eq 300 ]]; then
      echo "Tried 300 times to access new version of application. Failing deployment"
      exit 1
    fi

    sleep 1
  done
}

main "$@"
