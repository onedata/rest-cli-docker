#!/usr/bin/env bash

RELEASE=$1
VERSIONS_FILE="released_versions.txt"


if [[ "$RELEASE" == "" ]] ; then
  "[ERROR] Please supply release name. Example: 19.02.0"
fi

echo "Prepending $RELEASE to list of versions in $VERSIONS_FILE"
echo -en "$RELEASE $(cat $VERSIONS_FILE)" >$VERSIONS_FILE
echo "New released_versions.txt: $(cat $VERSIONS_FILE)"

echo "Creating a commit for a release $RELEASE..."
git add "$VERSIONS_FILE"
git commit -m "added version $RELEASE to list of supported versions"

echo "Creating a release tag..."
git tag  -m "Releasing version $RELEASE" "$RELEASE"

echo "The current HEAD is:"
git --no-pager log -1

read -p "Do you want to push changes and tags to the origin (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] ;then
  git push
  git push --tags
else
  echo "Aborting a push."
  exit 1
fi
