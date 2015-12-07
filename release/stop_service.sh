#!/bin/bash

main() {
  local release_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
  local docker_compose_file="$release_dir/production.yml"

  docker-compose -f $docker_compose_file stop
  docker-compose -f $docker_compose_file rm
}

main "$@"
