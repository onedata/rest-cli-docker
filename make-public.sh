#!/usr/bin/env bash

echo "This script will check for the tag of HEAD commit"
echo "check if the corresponding docker images docker.onedata.org/rest-cli:<RELEASE>"
echo "double check if it is uploaded in https://hub.docker.com as onedata/rest-cli:<RELEASE>"
echo "and upload the image to https://hub.docker.com"
echo

get_digest() {
  local docker_image=$1
  local tag=$2
  local digest

  docker pull ${docker_image}:${tag} >/dev/null 2>/dev/null
  if ! digest=$(docker inspect ${docker_image}:${tag} --format '{{.RepoDigests}}' 2>/dev/null); then
    return 1
  else
    echo ${digest} | tr ' ' '\n' | tr -d '[]' | grep ${docker_image} | sed -e "s|${docker_image}@||"
  fi
}

RELEASE=$1
if [[ "${RELEASE}" == "" ]]; then
  if ! RELEASE=$(git describe --tags --exact-match HEAD) ; then
    echo "[ERROR] The head commit is not tagged, please tag it or supply a RELEASE tag as a first argument to the script. Example: ${0##*/} 19.02.0-beta1"
    exit 1
  fi
fi

PUBLIC_IMAGE="onedata/rest-cli"
PRIVATE_IMAGE="docker.onedata.org/rest-cli"

if ! PRIVATE_DIGEST=$(get_digest "${PRIVATE_IMAGE}" "${RELEASE}" 2>/dev/null); then
  echo "[ERROR] Image ${PRIVATE_IMAGE}:${RELEASE} does not exist in docker.onedata.org!"
  exit 1
else
  if ! PUBLIC_DIGEST=$(get_digest "${PUBLIC_IMAGE}" "${RELEASE}" 2>/dev/null); then
    echo "Image ${PRIVATE_IMAGE}:${RELEASE} exist, but is not uploaded to ${PUBLIC_IMAGE}:${RELEASE}. Uploading..."
    docker tag "${PRIVATE_IMAGE}:${RELEASE}" "${PUBLIC_IMAGE}:${RELEASE}"
    docker push "${PUBLIC_IMAGE}:${RELEASE}"
  else
    if cmp <(echo "${PRIVATE_DIGEST}") <(echo "${PUBLIC_DIGEST}") > /dev/null; then
      echo "Both ${PRIVATE_IMAGE}:${RELEASE} and ${PUBLIC_IMAGE}:${RELEASE} exist and are the same - no action needed."
      echo "${PRIVATE_IMAGE}:${RELEASE}  -  ${PRIVATE_DIGEST}"
      echo "${PUBLIC_IMAGE}:${RELEASE}  -  ${PUBLIC_DIGEST}"
    else
      echo "[ERROR] Both ${PRIVATE_IMAGE}:${RELEASE} and ${PUBLIC_IMAGE}:${RELEASE} exist but their digests are different! Fix manually..."
      echo "${PRIVATE_IMAGE}:${RELEASE}  -  ${PRIVATE_DIGEST}"
      echo "${PUBLIC_IMAGE}:${RELEASE}  -  ${PUBLIC_DIGEST}"
      exit 1
    fi
  fi
fi
