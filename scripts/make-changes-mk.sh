#!/bin/bash

make_entry() {
    local prev=$1
    local ver=$2
    local prefix=$3
cat <<EOF
html/data/$ver/${prefix}changes.talents.json: html/data/$prev/tome.json html/data/$ver/tome.json
	\$(LUA) make_change_list.lua html/data/ $prev $ver $prefix
EOF
}

# Makes a dummy entry, indicating nothing needs to be done.
make_dummy_entry() {
    local ver=$1
    local prefix=$2
cat <<EOF
html/data/$ver/${prefix}changes.talents.json:
EOF
}

for ver in $*; do
    # Special case: master
    if [[ "$ver" == master ]]; then
        make_entry $prev $ver
        make_dummy_entry $ver recent-
        continue
    fi

    if [[ "$ver" == *.0 && -n "$prev" ]]; then
        prev_major=$prev
    fi
    if [ -n "$prev_major" ]; then
        make_entry $prev_major $ver
    else
        make_dummy_entry $ver
    fi
    if [ -n "$prev" -a "$prev" != "$prev_major" ]; then
        make_entry $prev $ver recent-
    else
        make_dummy_entry $ver recent-
    fi
    prev=$ver
done
