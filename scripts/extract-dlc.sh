#!/bin/bash

set -ex
shopt -s extglob

cd $(dirname $0)/../dlc

rm -rf tome-stone-wardens-+([0-9.]) tome-ashes-urhrok-+([0-9.]) tome-orcs-+([0-9.])

function version() {
    ver=$1
    ver=${ver%.teaa*}
    ver=${ver##*-}
    echo $ver
}

for f in tome-stone-wardens*.teaa; do
    unzip $f -d $(basename $f .teaa)
done

for f in ashes-urhrok*.teaac; do
    ver=$(version $f)
    unzip $f "tome-ashes-urhrok/*"
    mv tome-ashes-urhrok{,-$ver}
done

for f in orcs-*.teaac; do
    ver=$(version $f)
    unzip $f "tome-orcs/*"
    mv tome-orcs{,-$ver}
done

