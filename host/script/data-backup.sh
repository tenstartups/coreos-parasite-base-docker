#!/bin/bash +x
set -e

# Source systemd environment variables
. <%= getenv!(:parasite_config_directory) %>/env/docker-images.env

/usr/bin/docker run --rm \
  -v <%= getenv!(:parasite_data_docker_volume) %>:<%= getenv!(:parasite_data_directory) %> \
  -v $(pwd):/tmp \
  -w "<%= getenv!(:parasite_data_directory) %>" \
  ${PARASITE_DOCKER_IMAGE_SHELL} \
  tar cvzf "/tmp/<%= getenv!(:parasite_data_backup_archive) %>" --exclude=./.* .
