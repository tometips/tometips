#!/bin/bash
# Fetches DLC from Steam

set -ex

cd $(dirname $0)/..

rm -rf [0-9]*/dlc [0-9]*/data-

function link_dlc() {
    dlc=$1
    dlc_ver=$2
    shift 2
    for tome_ver in $*; do
        mkdir -p $tome_ver/dlc
        ln -sfv ../../dlc/tome-$dlc-$dlc_ver $tome_ver/dlc/tome-$dlc
        ln -sfv ../dlc/tome-$dlc-$dlc_ver/data $tome_ver/data-$dlc
    done
}

all_versions="1.3.0 1.3.1 1.3.3 1.4.0 1.4.1 1.4.2 1.4.3 1.4.4 1.4.5 1.4.6 1.4.7 1.4.8"

link_dlc stone-wardens 1.2.3 $all_versions
link_dlc ashes-urhrok 1.0.5 $all_versions

link_dlc orcs 1.0.1 1.4.4
link_dlc orcs 1.0.2 1.4.5
link_dlc orcs 1.0.3 1.4.6
