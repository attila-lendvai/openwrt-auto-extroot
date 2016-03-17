#!/bin/sh

# autoprovision stage 1: this script will be executed upon boot without a valid extroot (i.e. when rc.local is found and run from the internal overlay)

. /root/autoprovision-functions.sh

getPendriveSize()
{
    # this is needed for the mmc card in some (all?) Huawei 3G dongle.
    # details: https://dev.openwrt.org/ticket/10716#comment:4
    if [ -e /dev/sda ]; then
        # force re-read of the partition table
        head -c 1024 /dev/sda >/dev/null
    fi

    if (grep -q sda /proc/partitions) then
        cat /sys/block/sda/size
    else
        echo 0
    fi
}

hasBigEnoughPendrive()
{
    local size=$(getPendriveSize)
    if [ $size -ge 600000 ]; then
        log "Found a pendrive of size: $(($size / 2 / 1024)) MB"
        return 0
    else
        return 1
    fi
}

setupPendrivePartitions()
{
    # erase partition table
    dd if=/dev/zero of=/dev/sda bs=1M count=1

    # sda1 is 'swap'
    # sda2 is 'root'
    # sda3 is 'data'
    fdisk /dev/sda <<EOF
o
n
p
1

+64M
n
p
2

+512M
n
p
3


t
1
82
w
q
EOF
    log "Finished partitioning /dev/sda using fdisk"

    sleep 2

    until [ -e /dev/sda1 ]
    do
        echo "Waiting for partitions to show up in /dev"
        sleep 1
    done

    mkswap -L swap -U $swapUUID /dev/sda1
    mkfs.ext4 -L root -U $rootUUID /dev/sda2
    mkfs.ext4 -L data -U $dataUUID /dev/sda3

    log "Finished setting up filesystems"
}

setupExtroot()
{
    mkdir -p /mnt/extroot/
    mount -U $rootUUID /mnt/extroot

    overlay_root=/mnt/extroot/upper

    # at this point we could copy the entire root (a previous version of this script did that), or just the overlay from the flash,
    # but it seems to work fine if we just create an empty overlay that is only replacing the rc.local from the firmware.

    # let's write a new rc.local on the extroot that will shadow the one which is in the rom (to run stage2 instead of stage1)
    mkdir -p ${overlay_root}/etc/
    cat >${overlay_root}/etc/rc.local <<EOF
/root/autoprovision-stage2.sh
exit 0
EOF

    # TODO FIXME when this below is enabled then Chaos Calmer doesn't turn on the network and the device remains unreachable

    # make sure that we shadow the /var -> /tmp symlink in the new extroot, so that /var becomes persistent across reboots.
#    mkdir -p ${overlay_root}/var
    # KLUDGE: /var/state is assumed to be transient, so link it to tmp, see https://dev.openwrt.org/ticket/12228
#    cd ${overlay_root}/var
#    ln -s /tmp state
#    cd -

    log "Finished setting up extroot"
}

autoprovisionStage1()
{
    signalAutoprovisionWorking

    signalAutoprovisionWaitingForUser
    signalWaitingForPendrive

    until hasBigEnoughPendrive
    do
        echo "Waiting for a pendrive to be inserted"
        sleep 3
    done

    signalAutoprovisionWorking # to make it flash in sync with the USB led
    signalFormatting

    sleep 1

    setupPendrivePartitions
    sleep 1
    setupExtroot

    sync
    stopSignallingAnything
    reboot
}

autoprovisionStage1
