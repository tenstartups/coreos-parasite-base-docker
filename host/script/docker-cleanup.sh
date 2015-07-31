#!/bin/bash
set -e

# Set environment variables
DOCKER_IMAGE_ENV_REGEX="^\s*DOCKER_IMAGE_([_A-Z0-9]+)=(.+)\s*$"

# Change the umask so that lockfiles are created with proper permissions
old_umask=`umask`
umask 0000

# Cleanup stale containers (excluding containers labelled as volume containers)
(
  flock --exclusive --wait 300 200 || exit 1
  volume_container_ids=($(docker ps --no-trunc -a -q -f "label=${DOCKER_VOLUME_CONTAINER_LABEL}"))
  for container_id in $(docker ps --no-trunc -a -q -f 'status=exited'); do
    if [[ " ${volume_container_ids[*]} " = *" ${container_id} "* ]]; then continue; fi
    echo "Removing docker container ${container_id}"
    docker rm -v ${container_id} || true
  done
) 200>/tmp/.docker.lockfile

# Cleanup stale (untagged) images
(
  flock --exclusive --wait 300 200 || exit 1
  for image_id in $(docker images --no-trunc -q -f 'dangling=true'); do
    echo "Removing docker image ${image_id}"
    docker rmi ${image_id} || true
  done
) 200>/tmp/.docker.lockfile

# Cleanup tagged images that are not itemized in the environment list
(
  flock --exclusive --wait 300 200 || exit 1
  active_image_names=($(env | grep -E "${DOCKER_IMAGE_ENV_REGEX}" | sed -E "s/${DOCKER_IMAGE_ENV_REGEX}/\2/" | sort | uniq))
  while read -r image_name ; do
    if [[ " ${active_image_names[*]} " = *" ${image_name} "* ]]; then continue; fi
    echo "Removing docker image ${image_name}"
    docker rmi ${image_name} || true
  done < <(docker images | grep -v "REPOSITORY" | grep -v "<none>" | awk '{print $1 ":" $2}')
) 200>/tmp/.docker.lockfile

# Reset the umask to what is was previously
umask $old_umask