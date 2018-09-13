#!/bin/bash
PACKERBIN=$(which packer-io || which packer)
TARGET="${1:-coreos}"
TAG=$((git describe --tags) 2>/dev/null)
VERSION=${TAG:-latest}
COMMIT=$(git rev-parse --verify --short HEAD 2>/dev/null)

image_name=""
if [ "$TARGET" == "coreos" ]; then
    image_name="CoreOS Stable Etcd"
elif [ "$TARGET" == "centos7" ]; then
    image_name="Centos 7 Etcd"
elif [ "$TARGET" == "ubuntu1604" ]; then
    image_name="Ubuntu 16.04 Etcd"
else
    echo "checking if image already built" >&2
    exit 1
fi

echo "checking if image already built for commit $COMMIT and target $TARGET" >&2
image_id=$(openstack image list \
                     --name "$image_name" \
                     --property "tag=$VERSION" \
                     --property "commit=$COMMIT" \
                     --status active \
                     -f value \
                     -c ID)

if [ ! -z "$image_id" ]; then
    echo "image already built under id $image_id" >&2
    exit 0
fi

$PACKERBIN build \
           -var image_name="$image_name" \
           -var region="$OS_REGION_NAME" \
           -var ext_net_id=$(openstack network show -c id -f value "Ext-Net") \
           -var tag="$VERSION" \
           -var commit="$COMMIT" \
           -only "$TARGET" \
           packer.json

