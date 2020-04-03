#!/usr/bin/env bash
source "functions.sh"

(
paperjar="$basedir/Paper-Server/target/paper-$minecraftversion.jar"
vanillajar="$workdir/Minecraft/$minecraftversion/$minecraftversion.jar"

(
    cd "$workdir/Paperclip"
    mvn clean package "-Dmcver=$minecraftversion" "-Dpaperjar=$paperjar" "-Dvanillajar=$vanillajar"
)
cp "$workdir/Paperclip/assembly/target/paperclip-${minecraftversion}.jar" "$basedir/paperclip.jar"

echo ""
echo ""
echo ""
echo "Build success!"
echo "Copied final jar to $(cd "$basedir" && pwd -P)/paperclip.jar"
) || exit 1
