#!/bin/bash
# Checks available DLC via Steam

cd $(dirname $0)/..

HIGHLIGHT='\033[1;32m'  # Light green
NORMAL='\033[0m'        # No Color

if [ $(uname) = Darwin ]; then
    steamgame=~/Library/Application\ Support/Steam/SteamApps/common/TalesMajEyal/game
elif [[ $(uname) == CYGWIN* ]]; then
    steamgame='/cygdrive/c/Program Files (x86)/Steam/steamapps/common/TalesMajEyal/game'
else
    echo "Don't know how to find Steam on $(uname)" 1>&2
    exit 1
fi
if [ ! -d "$steamgame" ]; then
    echo Failed to find Steam under $steamgame 1>&2
    exit 1
fi

function get_version() {
    addon=$1
    subdir=$2

    echo Checking $addon

    if [ ! -f "$steamgame/$addon" ]; then
        echo "'$steamgame/$addon' not found" 1>&2
        exit 1
    fi

    echo Found "'$steamgame/$addon'"

    ver=$((unzip -qc "$steamgame/$addon" ${subdir}init.lua; echo 'print(table.concat(addon_version or version or {}, "."))') | luajit)
    if [ -z "$ver" ]; then
        echo Version UNKNOWN
    else
        echo Version $ver
        filename=$(basename $addon)
        local_filename=dlc/${filename/.teaa/-$ver.teaa}
        if [ -f $local_filename ]; then
            echo Local filename: $local_filename
        else
            echo -e "${HIGHLIGHT}NEW suggested filename: $local_filename${NORMAL}"
        fi
    fi

    echo
}

get_version dlcs/ashes-urhrok.teaac tome-ashes-urhrok/
get_version dlcs/orcs.teaac tome-orcs/
