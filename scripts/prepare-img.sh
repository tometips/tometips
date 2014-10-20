#!/bin/bash
# Prepares web site images by copying and resizing from the Git repo.

set -e

cd $(dirname $0)/..

mkdir -p html/img/talents/{64,48,32}
cp -v --update t-engine4/game/modules/tome/data/gfx/talents/*.png html/img/talents/64/
for size in 32 48; do
    for img in html/img/talents/64/*.png; do
        newimg=${img/64/$size}
        if [ ! -f $newimg -o $img -nt $newimg ]; then
            echo Converting $newimg...
            convert -resize ${size}x${size} $img $newimg
        fi
    done
done

