#!/usr/bin/env bash
source "functions.sh"

(
minecraftserverurl=$(grep "$workdir"/BuildData/info.json -e serverUrl | cut -d '"' -f 4)
minecrafthash=$(grep "$workdir"/BuildData/info.json -e minecraftHash | cut -d '"' -f 4)
accesstransforms="$workdir/BuildData/mappings/"$(grep "$workdir"/BuildData/info.json -e accessTransforms | cut -d '"' -f 4)
classmappings="$workdir/BuildData/mappings/"$(grep "$workdir"/BuildData/info.json -e classMappings | cut -d '"' -f 4)
membermappings="$workdir/BuildData/mappings/"$(grep "$workdir"/BuildData/info.json -e memberMappings | cut -d '"' -f 4)
packagemappings="$workdir/BuildData/mappings/"$(grep "$workdir"/BuildData/info.json -e packageMappings | cut -d '"' -f 4)
decompiledir="$workdir/Minecraft/$minecraftversion"
jarpath="$decompiledir/$minecraftversion"
mkdir -p "$decompiledir"

echo "Downloading unmapped vanilla jar..."
if [ ! -f  "$jarpath.jar" ]; then
    if curl -s -o "$jarpath.jar" "$minecraftserverurl"; then
        echo "Failed to download the vanilla server jar. Check connectivity or try again later."
        exit 1
    fi
fi

# OS X & FreeBSD don't have md5sum, just md5 -r
if md5sum --version >/dev/null 2>&1; then
  checksum=$(md5sum "$jarpath.jar" | cut -d ' ' -f 1)
elif md5 -x >/dev/null 2>&1; then
  checksum=$(md5 -r "$jarpath.jar" | cut -d ' ' -f 1)
else
  echo >&2 "No md5sum or md5 command found"
  exit 1
fi

if [ "$checksum" != "$minecrafthash" ]; then
    echo "The MD5 checksum of the downloaded server jar does not match the BuildData hash."
    exit 1
fi

echo "Applying class mappings..."
if [ ! -f "$jarpath-cl.jar" ]; then
    if java -jar "$workdir/BuildData/bin/SpecialSource-2.jar" map --only . --only net/minecraft --auto-lvt BASIC --auto-member SYNTHETIC -i "$jarpath.jar" -m "$classmappings" -o "$jarpath-cl.jar" 1>/dev/null; then
        echo "Failed to apply class mappings."
        exit 1
    fi
fi

echo "Applying member mappings..."
if [ ! -f "$jarpath-m.jar" ]; then
    if java -jar "$workdir/BuildData/bin/SpecialSource-2.jar" map --only . --only net/minecraft --auto-member LOGGER --auto-member TOKENS -i "$jarpath-cl.jar" -m "$membermappings" -o "$jarpath-m.jar" 1>/dev/null; then
        echo "Failed to apply member mappings."
        exit 1
    fi
fi

echo "Creating remapped jar..."
if [ ! -f "$jarpath-mapped.jar" ]; then
    if java -jar "$workdir/BuildData/bin/SpecialSource.jar" --only . --only net/minecraft -i "$jarpath-m.jar" --access-transformer "$accesstransforms" -m "$packagemappings" -o "$jarpath-mapped.jar" 1>/dev/null; then
        echo "Failed to create remapped jar."
        exit 1
    fi
fi

echo "Installing remapped jar..."
cd "$workdir/CraftBukkit" # Need to be in a directory with a valid POM at the time of install.
if mvn install:install-file -q -Dfile="$jarpath-mapped.jar" -Dpackaging=jar -DgroupId=org.spigotmc -DartifactId=minecraft-server -Dversion="$minecraftversion-SNAPSHOT"; then
    echo "Failed to install remapped jar."
    exit 1
fi
)
