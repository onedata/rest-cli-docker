#!/usr/bin/env bash

declare -a onedata_components
onedata_components=(onezone oneprovider onepanel luma)


declare -a onedata_releases
onedata_releases=LIST_OF_RELEASES__SUPPLIED_AT_BUILD_TIME

#
# If no version specified, list available versions
#
if [[ $# -eq 0 ]]; then
  echo "Please select Onedata release - currently selected is $ONEDATA_VERSION"
  echo "Available releases:"
  for rel in "${onedata_releases[@]}"; do
    echo "- ${rel}"
  done
  exit 0
fi


#
# Check if version is valid
#
valid_version=0
for rel in "${onedata_releases[@]}"; do
  if [[ $rel == $1 ]]; then
    valid_version=1;
  fi
done

if [[ $valid_version == 0 ]]; then
  cowsay "Invalid version $1"
  exit 1
fi

#
# Remove old version symlinks
#
for oc in "${onedata_components[@]}"; do
  rm -f /usr/local/bin/$oc-rest-cli
  rm -f /root/.oh-my-zsh/plugins/onedata/_$oc-rest-cli
done

#
# Create symbolic links to current version
#
for oc in "${onedata_components[@]}"; do
  cp /var/opt/onedata/$oc/bash/$1/$oc-rest-cli /usr/local/bin/$oc-rest-cli || (echo "Missing $oc source files for version $1" ; exit 1)
  cp /var/opt/onedata/$oc/bash/$1/_$oc-rest-cli /usr/local/share/zsh/site-functions/_$oc-rest-cli || (echo "Missing $oc source files for version $1" ; exit 1)
  chmod 755 /usr/local/bin/$oc-rest-cli
  chmod 755 /usr/local/share/zsh/site-functions/_$oc-rest-cli
#  unfunction _$oc-rest-cli
#  autoload -U _$oc-rest-cli
done


#
# Setup prompt
#
echo -n "$1" > /etc/onedata.release
