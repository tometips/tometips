#!/bin/bash
# Prepares an engine + module tree corresponding to a Git tag by setting up
# directories and copying files.

set -eu
set -o pipefail

. $(dirname $0)/src-dirs.bash
cd $(dirname $0)/..

tag=$1

gittag=$tag

trap "rm -rf $tag" ERR

trap "(cd t-engine4 && git checkout master)" EXIT SIGINT SIGTERM
(cd t-engine4 && git checkout tome-$gittag)

rm -rf $tag
mkdir $tag
while read src dst; do
    # Canonicalize destination directory
    destdir=$(readlink -f $tag/$dst)

    mkdir -p $destdir
	(cd t-engine4/$src && cp -v --parents $(find . -name '*.lua') $destdir)
done < <(list_dirs)

