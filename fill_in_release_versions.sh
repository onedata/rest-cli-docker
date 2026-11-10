#!/usr/bin/env bash

inject_versions() {
  echo "Injecting release versions list: $1 to file $2 "
  sed "s/LIST_OF_RELEASES__SUPPLIED_AT_BUILD_TIME/$1/g" -i "$2"
}

inject_versions "$1" "onedata-select-version.sh"
inject_versions "$1" "_onedata-select-version"