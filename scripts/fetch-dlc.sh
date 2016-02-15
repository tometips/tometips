#!/bin/bash
# Fetches DLC from Steam

cd $(dirname $0)/..

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

mkdir -p dlc
cd dlc

rm -rf tome-stone-wardens tome-ashes-urhrok
unzip "$steamgame/addons/tome-stone-wardens.teaa" -d tome-stone-wardens
unzip "$steamgame/dlcs/ashes-urhrok.teaac" "tome-ashes-urhrok/*"

cd ..

rm -f [0-9]*/dlc [0-9]*/data-

for ver in $*; do
    ln -sfv ../dlc $ver
    for dlc in stone-wardens ashes-urhrok; do
        ln -sfv ../dlc/tome-$dlc/data $ver/data-$dlc
    done
done
