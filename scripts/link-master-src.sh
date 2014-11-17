#!/bin/bash
# Prepares an engine + module tree corresponding to the Git master by setting up
# directories and symlinks.

set -eu

. $(dirname $0)/src-dirs.bash
cd $(dirname $0)/..

trap "rm -rf master" ERR

rm -rf master
mkdir -p master
while read src dst; do
    ln -sv ../t-engine4/$src master/$dst
done < <(list_dirs)

