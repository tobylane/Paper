#!/usr/bin/env bash
# shellcheck disable=SC2034
set -e

gitcmd="git -c commit.gpgsign=false -c core.safecrlf=false"
basedir="$(cd "$1" && pwd -P)"
workdir="$basedir/work"
minecraftversion=$(grep "$workdir"/BuildData/info.json -e minecraftVersion | cut -d '"' -f 4)

# Windows detection to workaround ARG_MAX limitation
if [ "$OSTYPE" = "cygwin" ] || [ "$OSTYPE" = "msys" ]; then
  windows="true"
else
  windows="false"
fi

color() {
    if [ "$2" ]; then
            echo -e "\e[$1;$2m"
    else
            echo -e "\e[$1m"
    fi
}
colorend() {
    echo -e "\e[m"
}

paperstash() {
    STASHED=$($gitcmd stash  2>/dev/null|| return 0) # errors are ok
}

paperunstash() {
    if [[ "$STASHED" != "No local changes to save" ]] ; then
        $gitcmd stash pop 2>/dev/null|| return 0 # errors are ok
    fi
}
