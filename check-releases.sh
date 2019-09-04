#!/usr/bin/env bash

VERSIONS_FILE="released_versions.txt"
PUBLIC_DOCKER_IMAGE_NAME="onedata/rest-cli"
PRIVATE_DOCKER_IMAGE_NAME="docker.onedata.org/rest-cli"

echo "This script will read all versions from $VERSIONS_FILE"
echo "check if the coresponding docker images docker.onedata.org/rest-cli:<RELEASE>"
echo "are present in docker.onedata.org repository and mirrored in https://hub.docker.com."
echo

tr -s '[:blank:]' '[\n*]' < "$VERSIONS_FILE" |
  while IFS= read -r version; do
    if ! private_manifest=$(docker manifest inspect "$PRIVATE_DOCKER_IMAGE_NAME:$version" 2>/dev/null); then
      echo "[ERROR] Manifest for image $PRIVATE_DOCKER_IMAGE_NAME:$version does not exist in docker.onedata.org!"
    else
      if ! public_manifest=$(docker manifest inspect "$PUBLIC_DOCKER_IMAGE_NAME:$version" 2>/dev/null); then
        echo "[ERROR] Manifest for image $PRIVATE_DOCKER_IMAGE_NAME:$version exitst, but $PUBLIC_DOCKER_IMAGE_NAME:$version does not!"
      else
        if cmp <(echo "$private_manifest") <(echo "$public_manifest") > /dev/null; then
          echo "Both $PRIVATE_DOCKER_IMAGE_NAME:$version and $PUBLIC_DOCKER_IMAGE_NAME:$version exist."
        else
          echo "[ERROR] Both $PRIVATE_DOCKER_IMAGE_NAME:$version and $PUBLIC_DOCKER_IMAGE_NAME:$version exist but their manifests are different! Inspect with: cmp <(docker manifest inspect $PRIVATE_DOCKER_IMAGE_NAME:$version) <(docker manifest inspect $PUBLIC_DOCKER_IMAGE_NAME:$version)"
        fi
      fi
    fi
  done

