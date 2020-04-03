#!/usr/bin/env bash
# shellcheck disable=SC2034
set -eo pipefail
if [ "$CI" ]; then set -x; fi
shopt -s nocasematch # Case insensitive comparisons

gitcmd="git -c commit.gpgsign=false -c core.safecrlf=false"

setdir() {
if [ "$1" ]; then mkdir -p "$1"; cd "$1"; fi
basedir="$(pwd -P)"
workdir="$basedir/work"
minecraftversion=$(grep "$workdir"/BuildData/info.json -e minecraftVersion | cut -d '"' -f 4)
}
setdir "$@"

# Windows detection to workaround ARG_MAX limitation
if [ "$OSTYPE" = "cygwin" ] || [ "$OSTYPE" = "msys" ]; then
  windows="true"
else
  windows="false"
fi

color() {
    if [ "$2" ]; then
      printf '%s\n' "\e[$1;$2m"
    else
      printf '%s\n' "\e[$1m"
    fi
}
colorend() {
    printf '%s\n' "\e[m"
}

paperstash() {
    STASHED=$($gitcmd stash 2>/dev/null || return 0) # errors are ok
}

paperunstash() {
    if [ "$STASHED" != "No local changes to save" ]; then
        $gitcmd stash pop 2>/dev/null || return 0 # errors are ok
    fi
}

containsElement() {
	local e
	for e in "${@:2}"; do
		[[ "$e" == "$1" ]] && return 0;
	done
	return 1
}
