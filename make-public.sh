#!/usr/bin/env bash

echo "This script will check for the tag of HEAD commit"
echo "check if the coresponding docker images docker.onedata.org/rest-cli:<RELEASE>"
echo "double check if it is uploaded in https://hub.docker.com as onedata/rest-cli:<RELEASE>"
echo "and upload the image to https://hub.docker.com"
echo

RELEASE=$1
PUBLIC_DOCKER_IMAGE_NAME="onedata/rest-cli"
PRIVATE_DOCKER_IMAGE_NAME="docker.onedata.org/rest-cli"

if [[ "$RELEASE" == "" ]]; then
  if ! RELEASE=$(git describe --exact-match HEAD) ; then
    "[ERROR] The head commit is not tagged, please tag it or supply a RELASE tag as a first argument to the script. Example: ${0##*/} 19.02.0-beta1"
  fi
fi

version=$RELEASE
if ! private_manifest=$(docker manifest inspect "$PRIVATE_DOCKER_IMAGE_NAME:$version" 2>/dev/null); then
  echo "[ERROR] Manifest for image $PRIVATE_DOCKER_IMAGE_NAME:$version does not exist in docker.onedata.org!"
else
  if ! public_manifest=$(docker manifest inspect "$PUBLIC_DOCKER_IMAGE_NAME:$version" 2>/dev/null); then
    echo "Manifest for image $PRIVATE_DOCKER_IMAGE_NAME:$version exitst, but is not uploaded to $PUBLIC_DOCKER_IMAGE_NAME:$version. Uploading..."
    docker pull "$PRIVATE_DOCKER_IMAGE_NAME:$version"
    docker tag "$PRIVATE_DOCKER_IMAGE_NAME:$version" "$PUBLIC_DOCKER_IMAGE_NAME:$version"
    docker push "$PUBLIC_DOCKER_IMAGE_NAME:$version"
  else
    if cmp <(echo "$private_manifest") <(echo "$public_manifest") > /dev/null; then
      echo "[ERROR] Both $PRIVATE_DOCKER_IMAGE_NAME:$version and $PUBLIC_DOCKER_IMAGE_NAME:$version exist."
    else
      echo "[ERROR] Both $PRIVATE_DOCKER_IMAGE_NAME:$version and $PUBLIC_DOCKER_IMAGE_NAME:$version exist but their manifests are different! Inspect with: cmp <(docker manifest inspect $PRIVATE_DOCKER_IMAGE_NAME:$version) <(docker manifest inspect $PUBLIC_DOCKER_IMAGE_NAME:$version)"
    fi
  fi
fi
