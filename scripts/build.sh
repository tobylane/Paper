#!/usr/bin/env bash

if [ -d "$1" ]; then
  mkdir -p "$1"
  cd "$1" || exit
fi
basedir="$(pwd -P)"

(
 (git submodule update --init && ./scripts/remap.sh "$basedir" &&
   ./scripts/decompile.sh "$basedir" &&
   ./scripts/init.sh "$basedir" &&
   ./scripts/applyPatches.sh "$basedir"
 ) || (
    echo "Failed to build Paper"
    exit 1
      ) || exit 1
if [ "$2" = "--jar" ]; then
    mvn clean install && ./scripts/paperclip.sh "$basedir"
fi
) || exit 1
