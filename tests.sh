#!/bin/bash
set -euo pipefail

kimg="$1"

for i in $(go list ./...); do
    echo "$i:" 

    dir=$(mktemp -d)
    trap "{ rm -r $dir; }" EXIT

    go test -c "$i" -o "$dir/run"
    # No binary built if there are no test files
    if [[ ! -e "$dir/run" ]]; then
        continue
    fi

    # Steal /mnt as a mount point as virtme does not create mount points that don't exist
    # https://github.com/amluto/virtme/pull/28
    virtme-run --kimg "$kimg" --memory "256M" --busybox "$(which busybox)" --rwdir "/mnt=$dir" --script-sh "/mnt/run && touch /mnt/ok" &
    #pid=$!

    #spin='-\|/'

    #i=0
    #while kill -0 $pid 2>/dev/null; do
    #    i=$(( (i+1) %4 ))
    #    printf "\r${spin:$i:1}"
    #    sleep .1
    #done

    if [[ ! -e "$dir/ok" ]]; then
        exit 1
    fi
done
