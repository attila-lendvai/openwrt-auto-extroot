#!/bin/bash

set -e

RELEASE=$1
TARGET_ARCHITECTURE=$2
TARGET_VARIANT=$3
TARGET_DEVICE=$4

BUILD=`dirname "$0"`"/build/"
BUILD=`readlink -f $BUILD`

###
### chose a release
###

if [[ ! -n ${RELEASE} ]]; then
	RELEASE="21.02.0"
fi

echo "Build release: ${RELEASE}"

IMGBUILDER_NAME="openwrt-imagebuilder-${RELEASE}-${TARGET_ARCHITECTURE}-${TARGET_VARIANT}.Linux-x86_64"
IMGBUILDER_DIR="${BUILD}/${IMGBUILDER_NAME}"
IMGBUILDER_ARCHIVE="${IMGBUILDER_NAME}.tar.xz"

IMGTEMPDIR="${BUILD}/image-extras"
# see this feature request:
# FS#1670 - consistent naming convention for the imagebuilder.tar.xz URL
# https://bugs.openwrt.org/index.php?do=details&task_id=1670
IMGBUILDERURL="https://downloads.openwrt.org/releases/${RELEASE}/targets/${TARGET_ARCHITECTURE}/${TARGET_VARIANT}/${IMGBUILDER_ARCHIVE}"

#if [ -z ${TARGET_DEVICE} ]; then
#    echo "Usage: $0 architecture variant device-profile"
#    echo " e.g.: $0 ath79 generic tplink_tl-wr1043nd-v1"
#    echo "       $0 ath79 generic tplink_archer-c6-v2"
#    echo "       $0 ath79 generic tplink_tl-wdr4300-v1"
#    echo "       $0 bcm53xx generic dlink_dir-885l"
#    echo "       (this last one will not work without editing build.sh, details: https://github.com/attila-lendvai/openwrt-auto-extroot/pull/15#issuecomment-405847440)"
#    echo " to get a list of supported devices issue a 'make info' in the OpenWRT image builder directory:"
#    echo "   '${IMGBUILDER_DIR}'"
#    kill -INT $$
#fi

# the absolute minimum for extroot to work at all (i.e. when the disk is already set up, for example by hand).
# this list may be smaller and/or different for your router, but it works with my ath79.
PREINSTALLED_PACKAGES="block-mount kmod-fs-ext4 kmod-usb-storage"

# some kernel modules may also be needed for your hardware
PREINSTALLED_PACKAGES+=" kmod-usb-uhci kmod-usb-ohci"

# these are needed for the proper functioning of the auto extroot scripts
PREINSTALLED_PACKAGES+=" blkid mount-utils swap-utils e2fsprogs fdisk"

# Extra pkgs, current, useless

# # SAMBA

EXTRA_PACKAGES="samba4-libs samba4-server luci-app-samba4 luci-i18n-samba4-pt-br"

# # HDIDLE
EXTRA_PACKAGES+=" hd-idle luci-app-hd-idle luci-i18n-hd-idle-pt-br"

printf "%s\n" "${EXTRA_PACKAGES}" >> "image-extras/common/root/pkgs.txt"

# the following packages are optional, feel free to (un)comment them
#PREINSTALLED_PACKAGES+=" wireless-tools firewall iptables"
#PREINSTALLED_PACKAGES+=" kmod-usb-storage-extras kmod-mmc"
#PREINSTALLED_PACKAGES+=" ppp ppp-mod-pppoe ppp-mod-pppol2tp ppp-mod-pptp kmod-ppp kmod-pppoe"
PREINSTALLED_PACKAGES+=" luci"

SAVE_SPACE_PACKAGES=" -ppp -ppp-mod-pppoe -ip6tables -odhcp6c -kmod-ipv6 -kmod-ip6tables -ath10k"

echo "Remove pkgs? ${SAVE_SPACE_PACKAGES}"
echo
read -p "Remove packages: (y/n): " wont_install_pkgs

if [[ -n ${wont_install_pkgs} ]]; then
	PREINSTALLED_PACKAGES+=${SAVE_SPACE_PACKAGES}
fi

mkdir -pv ${BUILD}

rm -rf $IMGTEMPDIR
cp -r image-extras/common/ $IMGTEMPDIR
PER_PLATFORM_IMAGE_EXTRAS=image-extras/${TARGET_DEVICE}/
if [[ -e $PER_PLATFORM_IMAGE_EXTRAS ]]; then
    rsync -pr $PER_PLATFORM_IMAGE_EXTRAS $IMGTEMPDIR/
fi

if [[ ! -e ${IMGBUILDER_DIR} ]]; then
    pushd ${BUILD}
    # --no-check-certificate if needed
    wget --continue ${IMGBUILDERURL}
    xz -d <${IMGBUILDER_ARCHIVE} | tar vx
    popd
fi

pushd ${IMGBUILDER_DIR}

make image PROFILE=${TARGET_DEVICE} PACKAGES="${PREINSTALLED_PACKAGES}" FILES=${IMGTEMPDIR}

pushd bin/targets/${TARGET_ARCHITECTURE}/
ln -s ../../../packages .
popd

popd
