# What

It's a script to build a customized OpenWRT firmware image
(basic familiarity with OpenWRT is assumed).

If this image is flashed on a device it will try to automatically
set up [extroot](http://wiki.openwrt.org/doc/howto/extroot) on **any
(!)** storage device plugged into the USB port (`/dev/sda`). Keep in
mind that **this will erase any inserted storage device while the
router is in the initial setup phase**! Unfortunately there's little
that can be done at that point to ask the user for confirmation.

# Why

So that e.g. customers can buy a router on their own, flash our custom
firmware, plug in a pendrive, and manage their SIP (telephony) node
from our webapp.

# How
### Building

e.g. `./build.sh TLWDR4300`

Results will be under `build/OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64`.

To see a list of available targets, run this in the ImageBuilder dir: ```make info```.

### Setup stages

Blinking leds show which phase the extroot setup scripts are in. Consult the
sources for details: [autoprovision-functions.sh](image-extras/common/root/autoprovision-functions.sh#L49).

#### Stage 1: setup extroot

At the first boot after flashing the firmware the autoprovision script will
wait for anything (!) in `/dev/sda` to show up (that is >= 512M), then erase
it and set up a `swap`, an `extroot`, and a `data`filesystem (for the remaining
space), and then reboot.

#### Stage 2: download and install some packages from the internet

Once it booted into the new extroot, it will continuously attempt to install
some OpenWRT packages until an internet connection is set up on the router
(either by using ssh or LuCI if you could fit it into the firmware).

### Login

After flashing the firmware the router will have the standard
`192.168.1.1` IP address.

By default the root passwd is not set, so the router will start telnet with
no password. If you want to set up a password, then edit the stage 2 script:
[autoprovision-stage2.sh](image-extras/common/root/autoprovision-stage2.sh#L53).

If a password is set, then telnet is disabled by OpenWRT and SSH will listen
using the keys specified in [authorized_keys](image-extras/common/etc/dropbear/authorized_keys).

Once connected, you can read the log with `logread -f`.

# Status

This is more of a template than something standalone. You most
probably want to customize this script here and there; search for
`CUSTOMIZE` for places of interest.

Most importantly, **set up a password and maybe an ssh key**.

I've extracted this from a project of mine where OpenWRT nodes auto-provision
themselves in 3 stages (stage 3 was a Python script for an app-level sync feature),
but I thought it's useful enough for making it public.

At the time of writing it only supports a few `ar71xx` routers out of the box,
but it's easy to extend it.

## Tested with

[OpenWRT Chaos Calmer 15.05 RC1](https://downloads.openwrt.org/chaos_calmer/15.05-rc1/)
on a TP-Link WDR4300.

# Troubleshooting

* If the build doesn't yield a firmware file: if there's not enough
space in the flash of the target device to install all the requested
packages then the OpenWRT ImageBuilder silently skips that target. Remove
some packages from the build and try again.
