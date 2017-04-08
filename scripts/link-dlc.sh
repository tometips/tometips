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

all_versions="1.4.9 1.5.0 1.5.1 1.5.2 master"

link_dlc ashes-urhrok 1.0.5 1.4.9
link_dlc ashes-urhrok 1.0.6 1.5.0 1.5.1 1.5.2 master

link_dlc orcs 1.0.3 1.4.9
link_dlc orcs 1.0.4 1.5.0 1.5.1 1.5.2 master

link_dlc possessors 1.5 1.5.0 1.5.1 1.5.2 master

