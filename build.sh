#!/usr/bin/env bash

# Note: this runs as-is, pretty much without external
# dependencies. The OpenWrt ImageBuilder contains the toolchain and
# everything that is needed to build the firmware images.

set -e

TARGET_ARCHITECTURE=$1
TARGET_VARIANT=$2
TARGET_DEVICE=$3

BUILD="$(dirname "${0}")/build/"
BUILD="$(readlink -f "${BUILD}")"

###
### chose a release
###
RELEASE="23.05.2"

IMGBUILDER_NAME="openwrt-imagebuilder-${RELEASE}-${TARGET_ARCHITECTURE}-${TARGET_VARIANT}.Linux-x86_64"
IMGBUILDER_DIR="${BUILD}/${IMGBUILDER_NAME}"
IMGBUILDER_ARCHIVE="${IMGBUILDER_NAME}.tar.xz"

IMGTEMPDIR="${BUILD}/image-extras"
# see this feature request:
# FS#1670 - consistent naming convention for the imagebuilder.tar.xz URL
# https://bugs.openwrt.org/index.php?do=details&task_id=1670
IMGBUILDERURL="https://downloads.openwrt.org/releases/${RELEASE}/targets/${TARGET_ARCHITECTURE}/${TARGET_VARIANT}/${IMGBUILDER_ARCHIVE}"

if [ -z ${TARGET_DEVICE} ]; then
    echo "Usage: $0 architecture variant device-profile"
    echo " e.g.: $0 ath79 generic tplink_tl-wr1043nd-v1"
    echo "       $0 ath79 generic tplink_archer-c6-v2"
    echo "       $0 ath79 generic tplink_tl-wdr4300-v1"
    echo "       $0 bcm53xx generic dlink_dir-885l"
    echo " to get a list of supported devices issue a 'make info' in the OpenWRT image builder directory:"
    echo "   '${IMGBUILDER_DIR}'"
    echo " the build results will be under '${IMGBUILDER_DIR}/bin/targets/'"
    kill -INT $$
fi

# the absolute minimum for extroot to work at all (i.e. when the disk is already set up, for example by hand).
# this list may be smaller and/or different for your router, but it works with my ath79.
# blockdev is needed to re-read the partition table using `blockdev --rereadpt /dev/sdX`
PREINSTALLED_PACKAGES="block-mount kmod-fs-ext4 kmod-usb-storage blockdev"

# some kernel modules may also be needed for your hardware
#PREINSTALLED_PACKAGES+=" kmod-usb-uhci kmod-usb-ohci"

# these are needed for the proper functioning of the auto extroot scripts
PREINSTALLED_PACKAGES+=" blkid mount-utils swap-utils e2fsprogs fdisk"

# the following packages are optional, feel free to (un)comment them
PREINSTALLED_PACKAGES+=" wireless-tools firewall4"
PREINSTALLED_PACKAGES+=" kmod-usb-storage-extras kmod-mmc"
PREINSTALLED_PACKAGES+=" ppp ppp-mod-pppoe ppp-mod-pppol2tp ppp-mod-pptp kmod-ppp kmod-pppoe"
PREINSTALLED_PACKAGES+=" luci"

# you exclude packages with this to shrink the image for
# routers with smaller flash storage.
# SAVE_SPACE_PACKAGES=" -ppp -ppp-mod-pppoe -ip6tables -odhcp6c -kmod-ipv6 -kmod-ip6tables -ath10k"
SAVE_SPACE_PACKAGES=""

PREINSTALLED_PACKAGES+=${SAVE_SPACE_PACKAGES}

mkdir -pv "${BUILD}"

rm -rf "${IMGTEMPDIR}"
cp -r image-extras/common/ "${IMGTEMPDIR}"
PER_PLATFORM_IMAGE_EXTRAS="image-extras/${TARGET_DEVICE}/"
if [ -e "${PER_PLATFORM_IMAGE_EXTRAS}" ]; then
    rsync -pr "${PER_PLATFORM_IMAGE_EXTRAS}" "${IMGTEMPDIR}/"
fi

if [ ! -e "${IMGBUILDER_DIR}" ]; then
    pushd "${BUILD}"
    # --no-check-certificate if needed
    wget --continue "${IMGBUILDERURL}"
    xz -d <"${IMGBUILDER_ARCHIVE}" | tar vx
    popd
fi

pushd "${IMGBUILDER_DIR}"

make image PROFILE=${TARGET_DEVICE} PACKAGES="${PREINSTALLED_PACKAGES}" FILES=${IMGTEMPDIR}

pushd "bin/targets/${TARGET_ARCHITECTURE}/"
ln -sf ../../../packages .
popd

popd
