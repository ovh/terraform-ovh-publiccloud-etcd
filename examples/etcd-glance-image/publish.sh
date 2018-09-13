#!/bin/bash

# PGP Signing ID
PGP_SIGN_ID=B3EA8AB9
PGP_VERI_ID=42D9B296B3EA8AB9

# Pgp key passphrase file
PGP_KEY_PASSPHRASE_FILE=$(dirname $0)/../../.gpg.passphrase

# The openstack region where to create the swift container
CONTAINER_REGION=${CONTAINER_REGION:-$OS_REGION_NAME}

# The name of the swift container
CONTAINER_NAME=${CONTAINER_NAME:-"ovhcommunity"}

# The name of the swift container
IMAGES_PREFIX=${IMAGES_PREFIX:-"images"}

# Image where the region has been built
IMAGE_REGION=${IMAGE_REGION:-$OS_REGION_NAME}

# Target is either coreos or centos7
TARGET="${1:-coreos}"

# Swift container segment size (1024*1024*128 = 128M)
SEGMENT_SIZE=134217728

# already_published_image checks if an image_name is already uploaded with the corresponding checksum
# checksum sig is checked
function already_published_image(){
    image_name=$1
    src_checksum=$2
    tmp_dir=$(mktemp -d)

    # download md5sum & sig
    if ! (swift --os-region-name "$CONTAINER_REGION" download -o "$tmp_dir/md5sum.txt.sig" "$CONTAINER_NAME" "$IMAGES_PREFIX/$image_name.md5sum.txt.sig" &&
            swift --os-region-name "$CONTAINER_REGION" download -o "$tmp_dir/md5sum.txt" "$CONTAINER_NAME" "$IMAGES_PREFIX/$image_name.md5sum.txt"); then
        echo "No md5sum files have been previously uploaded" >&2
        return 1
    fi

    # checking sig
    if ! (out=$(cd $tmp_dir && gpg --status-fd 1 --verify md5sum.txt.sig 2>/dev/null) &&
            echo "$out" | grep -qs "^\[GNUPG:\] VALIDSIG $PGP_VERI_ID " &&
            echo "$out" | grep -qs "^\[GNUPG:\] TRUST_ULTIMATE\$"); then
        echo "Bad md5sum signature " >&2
        return 1
    fi

    # checking md5 checksums
    if ! (md5=$(swift --os-region-name "$CONTAINER_REGION" stat "$CONTAINER_NAME" "$IMAGES_PREFIX/$image_name" | awk '/ETag/ {print $2}') &&
            [ "$src_checksum" == "$md5" ] &&
            [ "$src_checksum" == "$(awk '{print $1}' ${tmp_dir}/md5sum.txt)" ]); then
        return 1
    fi
}

image_commit=$(git rev-parse --verify --short HEAD 2>/dev/null)
tag=$((git describe --tags) 2>/dev/null)
image_tag=${tag:-latest}
image_name=""

if [ "$TARGET" == "coreos" ]; then
    image_name="CoreOS Stable Etcd"
elif [ "$TARGET" == "ubuntu1604" ]; then
    image_name="Ubuntu 16.04 Etcd"
elif [ "$TARGET" == "centos7" ]; then
    image_name="Centos 7 Etcd"
else
    echo "checking if image already built" >&2
    exit 1
fi

# computing image file name
image_file_name="$(echo "${image_name}_${image_commit}.raw" | tr ' ' '_' | tr '[:upper:]'  '[:lower:]')"
image_tag_file_name="$(echo "${image_name}.${image_tag}.txt" | tr ' ' '_' | tr '[:upper:]'  '[:lower:]')"

# Retrieving most recent image id
echo "getting id for image with name '$image_name' and commit '$image_commit' in region '$IMAGE_REGION'" >&2
image_id=$(openstack --os-region-name "$IMAGE_REGION" image list \
                     --name "$image_name" \
                     --property "commit=$image_commit" \
                     --sort "created_at:desc" \
                     --status active \
                     -f value \
                     -c ID | head -1)

if [ -z "${image_id}" ]; then
    echo "Unable to find image" >&2
    exit 1
fi

# Retrieving image checksum
echo "getting checksum for image with id '$image_id'" >&2
image_checksum=$(openstack --os-region-name "$IMAGE_REGION" image show \
                           -f value \
                           -c checksum \
                           "$image_id")

if already_published_image $image_file_name $image_checksum; then
    echo "image with id '$image_id' has already been published" >&2
    exit 0
fi

# creating tmp dir
tmp_dir=$(mktemp -d)
echo "downloading image in '$tmp_dir'" >&2

# download raw image
if ! openstack --os-region-name "$IMAGE_REGION" image save --file "${tmp_dir}/${image_file_name}" "${image_id}"; then
    echo "Unable to downlong image '${image_id}' in '${tmp_dir}'" >&2
    exit 1
fi

# compute downloaded file checksum
echo "computing downloaded image checksum" >&2
(cd ${tmp_dir} && md5sum ${image_file_name} > ${image_file_name}.md5sum.txt)

# check checksum
file_checksum="$(awk '{print $1}' ${tmp_dir}/${image_file_name}.md5sum.txt)"
if [ "${file_checksum}" != "${image_checksum}" ]; then
    echo "Image checksum '$image_checksum' is not equal to downloaded file checksum '${file_checksum}'" >&2
    exit 1
fi

# sign files
echo "signing image file in '$tmp_dir'" >&2
gpg --batch --passphrase-file "$PGP_KEY_PASSPHRASE_FILE" -u "$PGP_SIGN_ID" --detach-sig ${tmp_dir}/${image_file_name}
echo "signing image checksum fil in '$tmp_dir'" >&2
gpg --batch --passphrase-file "$PGP_KEY_PASSPHRASE_FILE" -u "$PGP_SIGN_ID" --detach-sig ${tmp_dir}/${image_file_name}.md5sum.txt

# creating tag file
echo $image_commit > "${tmp_dir}/${image_tag_file_name}"

# create swift container
echo "creating swift container '$CONTAINER_NAME' in region '${CONTAINER_REGION}'" >&2
openstack --os-region-name "$CONTAINER_REGION" container create "${CONTAINER_NAME}" >/dev/null
# make it publicly readable
swift --os-region-name "$CONTAINER_REGION" post --read-acl ".r:*" "${CONTAINER_NAME}" >/dev/null

# upload files on container
echo "uploading files from '$tmp_dir' in swift container '$CONTAINER_NAME'" >&2
swift --os-region-name "$CONTAINER_REGION" upload -S "$SEGMENT_SIZE" \
      --object-name "$IMAGES_PREFIX" "$CONTAINER_NAME" \
      "${tmp_dir}"
