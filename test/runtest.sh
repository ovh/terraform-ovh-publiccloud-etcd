#!/bin/bash

DIR=${1:-$(dirname $0)/../examples/public-cluster}
REGION=${2:-$OS_REGION_NAME}
DESTROY=${3:-1}
CLEAN=${4:-1}
PROJECT=${OS_TENANT_ID}
VRACK=${OVH_VRACK_ID}

test_tf(){
    # timeout is not 60 seconds but 60 loops, each taking at least 1 sec
    local timeout=60
    local inc=0
    local res=1

    while [ "$res" -ne 0 ] && [ "$inc" -lt "$timeout" ]; do
        (cd "${DIR}" && terraform output tf_test | sh)
        res=$?
        sleep 1
        ((inc++))
    done

    return $res
}

if [ ! -f "$SSH_AUTH_SOCK" ]; then
    eval $(ssh-agent) && ssh-add ${TEST_SSH_PRIVATE_KEY:-$HOME/.ssh/id_rsa}
fi

# if destroy mode, clean previous terraform setup
if [ "${CLEAN}" == "1" ]; then
    (cd "${DIR}" && rm -Rf .terraform *.tfstate*)
fi

# run the full terraform setup
(cd "${DIR}" && terraform init \
	   && terraform apply -auto-approve -var os_region_name="${REGION}")
EXIT_APPLY=$?
echo "apply exited with $EXIT_APPLY" >&2

# if terraform went well run test
if [ "${EXIT_APPLY}" == 0 ]; then
    test_tf
    EXIT_APPLY=$?
    echo "test after apply exited with $EXIT_APPLY" >&2
fi

# if destroy mode, clean terraform setup
if [ "${DESTROY}" == "1" ]; then
    (cd "${DIR}" && terraform destroy -force -var os_region_name="${REGION}" \
         && rm -Rf .terraform *.tfstate*)
    EXIT_DESTROY=$?
else
    EXIT_DESTROY=0
fi
echo "destroy exited with $EXIT_DESTROY" >&2

exit $((EXIT_APPLY+EXIT_DESTROY))
