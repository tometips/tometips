#!/bin/bash
# Prepares an engine + module tree corresponding to a Git tag by setting up
# directories and copying files.

set -eu
set -o pipefail

. $(dirname $0)/src-dirs.bash
cd $(dirname $0)/..

tag=$1

os=$(uname -s)

# Fix up alternate schemes for tag names.
if [ "$tag" = "1.3.0" ]; then
    gittag=1.3.0-release
else
    gittag=$tag
fi

trap "rm -rf $tag" ERR

trap "(cd t-engine4 && git checkout master)" EXIT SIGINT SIGTERM
(cd t-engine4 && git checkout tome-$gittag)

rm -rf $tag
mkdir $tag
while read src dst; do
    # Canonicalize destination directory
		if [ $os = "Darwin" ]; then
				destdir=$(greadlink -f $tag/$dst)
		else
				destdir=$(readlink -f $tag/$dst)
		fi

    mkdir -p $destdir

	if [ $os = "Darwin" ]; then
		(cd t-engine4/$src && gcp -v --parents $(find . -name '*.lua') $destdir)
	else
		(cd t-engine4/$src && cp -v --parents $(find . -name '*.lua') $destdir)
	fi
done < <(list_dirs)

