#!/bin/bash

REGIONS=${1:-$OS_REGION_NAME}
DIRS=(public-cluster public-cluster-cl private-cluster private-cluster-cl)

if [ ! -f "$SSH_AUTH_SOCK" ]; then
    eval $(ssh-agent) && ssh-add ${TEST_SSH_PRIVATE_KEY:-$HOME/.ssh/id_rsa}
fi

EXIT=0
for d in ${DIRS[@]}; do
    for r in $REGIONS; do
        $(dirname $0)/runtest.sh "$(dirname $0)/../examples/$d" "$r"
        EXIT=$((EXIT+$?))
    done
done

exit $EXIT
