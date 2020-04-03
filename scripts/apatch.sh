#!/usr/bin/env bash
source "functions.sh"

noapply=1
isreject=0
if [ "$1" = "--noapplied" ]; then
	noapply=1
	shift
fi

if [ -n "$1" ]; then
	file="$1"
elif [ -z "$1" ] && [ -f .git/rebase-apply/patch ]; then
	file=".git/rebase-apply/patch"
	noapply=1
	isreject=1
else
	echo "Please specify a file"
	exit 1
fi
applied=$(echo $file | sed 's/.patch$/-applied\.patch/g')
if [ "$1" = "--reset" ]; then
	$gitcmd am --abort
	$gitcmd reset --hard
	$gitcmd clean -f
	exit 0
fi

if [ "$isreject" = "1" ] || ! $gitcmd am -3 $file; then
	echo "Failures - Wiggling"
	$gitcmd reset --hard
	$gitcmd clean -f
	errors=$($gitcmd apply --rej $file 2>&1)
	echo "$errors" >> ~/patch.log
	export missingfiles=""
	export summaryfail=""
	export summarygood=""
	find mydir -name '*.rej' -exec sh -c '
        base=$(echo "$i" | sed "s/.rej//g")
		if [ -f "$i" ]; then
        		sed -e "s/^diff a\/\(.*\) b\/\(.*\)[[:space:]].*rejected.*$/--- \1\n+++ \2/" -i "$i" && wiggle -v -l --replace "$base" "$i"
        		rm "$base.porig" "$i"
		else
			echo "No such file: $base"
			missingfiles="$missingfiles\n$base"
		fi
	' sh {} \;
	for i in $($gitcmd status --porcelain | awk '{print $2}'); do
		if [ -f "$file" ] && grep "$i" -e "<<<<<"; then
			export summaryfail="$summaryfail\nFAILED TO APPLY: $i"
		else
			$gitcmd add "$i"
			export summarygood="$summarygood\nAPPLIED CLEAN: $i"
		fi
	done
	echo -e "$summarygood"
	echo -e "$summaryfail"
	if [[ "$errors" == *"No such file"* ]]; then
		echo "===========================";
		echo " "
		echo " MISSING FILES"
		grep "$errors" -e "No such file"
		echo -e "$missingfiles"
		echo " "
		echo "===========================";
	fi
	$gitcmd status
	$gitcmd diff
fi

if [[ "$noapply" != "1" ]] && [[ "$file" != *-applied.patch ]]; then
	mv "$file" "$applied"
fi
