#!/usr/bin/env bash
. "functions.sh"
setdir "$@"

(
updated="0"
getRef() {
    git ls-tree "$1" "$2"  | cut -d' ' -f3 | cut -f1
}
update() {
    cd "$workdir/$1"
    $gitcmd fetch && $gitcmd clean -fd && $gitcmd reset --hard origin/master
    refRemote=$(git rev-parse HEAD)
    cd ../
    $gitcmd add "$1" -f
    refHEAD=$(getRef HEAD "$workdir/$1")
    echo "$1 $refHEAD - $refRemote"
    if [ "$refHEAD" != "$refRemote" ]; then
        export updated="1"
    fi
}

update Bukkit
update CraftBukkit
update Spigot

if [ "$2" = "all" ] || [ "$2" = "a" ] ; then
	update BuildData
	update Paperclip
fi
if [ "$updated" = "1" ]; then
    echo "Rebuilding patches without filtering to improve apply ability"
    cd "$basedir"
    scripts/rebuildPatches.sh "$basedir" nofilter 1>/dev/null || exit 1
fi
)
