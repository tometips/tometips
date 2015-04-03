#!/bin/bash
# Fetches DLC from Steam

mkdir -p $(dirname $0)/../dlc
cd $(dirname $0)/../dlc
ver=$1

if [ -z "$1" ]; then
    echo Usage: $0 tome-ver 1>&2
    exit 2
fi

if [ $(uname) = Darwin ]; then
    steamgame=~/Library/Application\ Support/Steam/SteamApps/common/TalesMajEyal/game
else
    # Assume Cygwin
    steamgame='/cygdrive/c/Program Files (x86)/Steam/steamapps/common/TalesMajEyal/game'
fi

rm -rf tome-stone-wardens tome-ashes-urhrok
unzip "$steamgame/addons/tome-stone-wardens.teaa" -d tome-stone-wardens
unzip "$steamgame/dlcs/ashes-urhrok.teaac" "tome-ashes-urhrok/*"

cd ..
for dlc in stone-wardens ashes-urhrok; do
    ln -s ../dlc/tome-$dlc/data $ver/data-$dlc
done
