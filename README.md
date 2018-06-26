# What

It's a script to build a customized OpenWRT firmware image on a Linux x86_64 host
(basic familiarity with [OpenWRT](https://wiki.openwrt.org/doc/howto/user.beginner)
is assumed).

If the generated image is flashed on a device it will try to automatically
set up [extroot](http://wiki.openwrt.org/doc/howto/extroot) on **any
(!)** storage device plugged into the USB port (`/dev/sda`). Keep in
mind that **this will erase any inserted storage device while the
router is in the initial setup phase**! Unfortunately there's little
that can be done at that point to ask the user for confirmation.

# Why

So that e.g. customers can buy a router on their own, flash our custom
firmware, plug in a pendrive, and manage their SIP (telephony) node
from our webapp.

I've extracted the generic parts from the above mentioned auto-provision
project because I thought it's useful enough for making it public.

# How
### Building

To build it, issue the following command: `./build.sh architecture variant device-profile`, e.g.:
* `./build.sh ar71xx generic tl-wr1043nd-v2`

Results will be under `build/openwrt-imagebuilder-${release}-${architecture}-${variant}.Linux-x86_64/bin/`.

To see a list of available targets, run `make info` in the ImageBuilder dir.

If you want to change which OpenWRT version is used, then edit the relevant variable(s) in `build.sh`.

### Setup stages

Blinking leds show which phase the extroot setup scripts are in. Consult the
sources for details: [autoprovision-functions.sh](image-extras/common/root/autoprovision-functions.sh#L49).

#### Stage 1: setup extroot

When the custom firmware first boots, the autoprovision script will
wait for anything (!) in `/dev/sda` to show up (that is >= 512M), then erase
it and set up a `swap`, an `extroot`, and a `data`filesystem (for the remaining
space), and then reboot.

#### Stage 2: download and install some packages from the internet

Once it booted into the new extroot, it will continuously attempt to install
some OpenWRT packages until an internet connection is set up on the router
(either by using ssh or the web UI (LuCI)).

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

At the time of writing it only supports a few `ar71xx` routers out of the box,
but it's easy to extend it.

## Tested with

[OpenWRT 17.01.4](https://downloads.openwrt.org/releases/)
on a TP-Link WR-1043nd-v2.

# Troubleshooting

## Which file should I flash?

You should consult the [OpenWRT documentation](https://wiki.openwrt.org/doc/howto/user.beginner).
The produced firmware files should be somewhere around ```build/openwrt-imagebuilder-17.01.4-ar71xx-generic.Linux-x86_64/bin/ar71xx```.

In short:

* You need a file with the name ```-factory.bin``` or ```-sysupgrade.bin```. The former is to
  be used when you first install OpenWRT, the latter is when you upgrade an already installed
  OpenWRT.

* You must carefully pick the proper firmware file for your **hardware version**! I advise you
  to look up the wiki page for your hardware on the [OpenWRT wiki](https://wiki.openwrt.org),
  because most of them have a table of the released hardware versions with comments on their
  status (sometimes new hardware revisions are only supported by the latest OpenWRT, which is
  not released yet).

## Help! The build has finished but there's no firmware file!

If the build doesn't yield a firmware file (```*-factory.bin``` and/or ```*-sysupgrade.bin```):
when there's not enough space in the flash memory of the target device to install everything
then the OpenWRT ImageBuilder prints a hardly visible error into its flow of output and
silently continues. Look into [build.sh](build.sh#L31) and try to remove some packages
that you can live without.
