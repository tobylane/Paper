#!/usr/bin/env bash
. "functions.sh"
setdir "$@"

(
echo "Rebuilding patch files from current fork state..."
nofilter="0"
if [ "$2" = "nofilter" ]; then
    nofilter="1"
fi
cleanupPatches() {
    cd "$1"
    for patch in *.patch; do
        echo "$patch"
        gitver=$(tail -n 2 "$patch" | grep -ve "^$" | tail -n 1)
        diffs=$($gitcmd diff --staged "$patch" | grep --color=none -E "^(\+|\-)" | grep --color=none -Ev "(From [a-f0-9]{32,}|\-\-\- a|\+\+\+ b|^.index)")
        if echo "$diffs" | tail -n 2 | grep --color=none -ve "^$" | tail -n 1 | grep --color=none "$gitver"; then
            diffs=$(echo "$diffs" | sed 'N;$!P;$!D;$d')
        else
            $gitcmd reset HEAD "$patch" >/dev/null
            $gitcmd checkout -- "$patch" >/dev/null
        fi
    done
}

savePatches() {
    what=$1
    what_name=$(basename "$what")
    target=$2
    echo "Formatting patches for $what..."

    cd "$basedir/${what_name}-Patches/"
    if [ -d "$basedir/$target/.git/rebase-apply" ]; then
        # in middle of a rebase, be smarter
        echo "REBASE DETECTED - PARTIAL SAVE"
        last=$(cat "$basedir/$target/.git/rebase-apply/last")
        next=$(cat "$basedir/$target/.git/rebase-apply/next")
        orderedfiles=$(find . -name "*.patch" | sort)
        for i in $(seq -f "%04g" 1 1 "$last")
        do
            if [ "$i" -lt "$next" ]; then
                rm "$(echo "$orderedfiles{@}" | sed -n "${i}p")"
            fi
        done
    else
        rm -rf ./*.patch
    fi

    cd "$basedir/$target"

    $gitcmd format-patch --no-stat -N -o "$basedir/${what_name}-Patches/" upstream/upstream >/dev/null
    cd "$basedir"
    $gitcmd add -A "$basedir/${what_name}-Patches"
    if [ "$nofilter" = "0" ]; then
        cleanupPatches "$basedir/${what_name}-Patches"
    fi
    echo "  Patches saved for $what to $what_name-Patches/"
}

savePatches "$workdir/Spigot/Spigot-API" "Paper-API"
if [ -f "$basedir/Paper-API/.git/patch-apply-failed" ]; then
    echo "$(color 1 31)[[[ WARNING ]]] $(color 1 33)- Not saving Paper-Server as it appears Paper-API did not apply clean.$(colorend)"
    echo "$(color 1 33)If this is a mistake, delete $(color 1 34)Paper-API/.git/patch-apply-failed$(color 1 33) and run rebuild again.$(colorend)"
    echo "$(color 1 33)Otherwise, rerun ./paper patch to have a clean Paper-API apply so the latest Paper-Server can build.$(colorend)"
else
    savePatches "$workdir/Spigot/Spigot-Server" "Paper-Server"
fi
) || exit 1
