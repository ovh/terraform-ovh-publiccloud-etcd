#!/bin/bash
set -e

if [ -n "$(command -v yum)" ]; then
    sudo yum upgrade -y >/dev/null
elif [ -n "$(command -v apt-get)" ]; then
    echo "Debian based. upgrading system." >&2
    export DEBIAN_FRONTEND=noninteractive
    sudo -E apt update -y -q
    # run it twice in case upgrade generates other upgrades
    sudo -E apt upgrade -y -q
    sudo -E apt upgrade -y -q
elif [ -n "$(command -v coreos-install)" ]; then
    echo "Nothing to do for coreos" >&2
else
    echo "Unsupported OS." >&2
    exit 1
fi
