# What

It's a script to build a customized
[OpenWrt](https://openwrt.org/docs/guide-user/start)
firmware image using
[ImageBuilder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder).

If the generated image is flashed on a router, then during its boot
process it will try to automatically set up
[extroot](https://openwrt.org/docs/guide-user/additional-software/extroot_configuration)
on **any (!)** storage device plugged into the USB port (`/dev/sda`),
including your already working extroot pendrive if you plug it in too
late in the boot process.

# Why

So that e.g. customers can buy a router on their own, download and flash our custom
firmware, plug in a pendrive, and manage their SIP (telephony) node
from our webapp.

I've extracted the generic parts from the above mentioned auto-provision
project because I thought it's useful enough for making it public.

It also serves me well on my own routers ever since then.

# How

You can read more about the underlying technology on the OpenWrt wiki: see e.g. the
[ImageBuilder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder)
page, or the page that lists some other
[ImageBuilder frontends](https://openwrt.org/docs/guide-developer/imagebuilder_frontends).

As for the actual mechanism: custom scripts are baked into the boot
process of the flashed firmware. If the extroot overlay is properly
set up, then these scripts get hidden by it; i.e. they will only be run
when the extroot has failed to mount early in the boot process.

Keep in mind that **this will automatically erase/format any inserted
storage device while the router is in the initial setup phase**!
Unfortunately there's little that can be done at that point to ask the
user for confirmation.

### Building

OpenWrt's ImageBuilder only works on Linux x86_64. To build a firmware, issue the following command:
`./build.sh architecture variant device-profile`, e.g.:

* `./build.sh ath79 generic tplink_tl-wr1043nd-v1`
* `./build.sh ath79 generic tplink_archer-c6-v2`
* `./build.sh ath79 generic tplink_tl-wdr4300-v1`
* `./build.sh bcm53xx generic dlink_dir-885l`

Results will be under `build/openwrt-imagebuilder-${release}-${architecture}-${variant}.Linux-x86_64/bin/`.

To see a list of available targets, run `make info` in the ImageBuilder dir.

If you want to change which OpenWrt version is used, then try editing
the relevant variable(s) in `build.sh`. It's not guaranteed to work
across OpenWrt releases, therefore we keep git branches for the past
releases.

### Setup stages

Blinking leds show which phase the extroot setup scripts are in. Consult the
sources for details: [autoprovision-functions.sh](image-extras/common/root/autoprovision-functions.sh#L49).

#### Stage 1: setup extroot

When the custom firmware first boots, the autoprovision script will
wait for anything (!) in `/dev/sda` to show up (that is >= 512M), then erase
it and set up a `swap`, an `extroot`, and a `data`filesystem (for the remaining
space), and then reboot.

#### Stage 2: download and install some packages from the internet

Once it rebooted into the new extroot, it will continuously keep trying to install
some OpenWrt packages until an internet connection is set up on the router. You
need to do that manually either by using ssh or the web UI (LuCI).

#### Stage 3, optional

We also have a 3rd stage, written in Python, but it's commented out here.
Search for `autoprovision-stage3.py` to see how it's done.

### Login

After flashing the firmware the router will have the standard
`192.168.1.1` IP address.

By default the root passwd is not set, so the router will start telnet with
no password. If you want to set up a password, then edit the stage 2 script:
[autoprovision-stage2.sh](image-extras/common/root/autoprovision-stage2.sh#L53).

If a password is set, then telnet is disabled by OpenWrt and SSH will listen
using the keys specified in [authorized_keys](image-extras/common/etc/dropbear/authorized_keys).

Once connected, you can read the log with `logread -f`.

# Status

This is more of a template than something standalone, but I use it for
my home routers as is. For more specific applications you most
probably want to customize this script here and there; search for
`CUSTOMIZE` for places of interest.

Most importantly, **set up a password and maybe add your ssh key** by
adding it to `image-extras/common/etc/dropbear/authorized_keys`.

None of this script is hardware specific except `setLedAttribute`,
which is used to provide feedback about the progress of the initial
setup phase. At the time of writing it only works on a few routers
(mostly `ath79` ones), but without this everything should work fine,
if only a bit less convenient.

# Troubleshooting

## Which file should I flash?

You should consult the [OpenWrt documentation](https://openwrt.org/docs/guide-user/start).
The produced firmware files should be somewhere around
```./build/openwrt-imagebuilder-21.02.0-ath79-generic.Linux-x86_64/bin/targets/ath79/generic/```.

In short:

* You need a file with the name ```-factory.bin``` or ```-sysupgrade.bin```. The former is to
  be used when you first install OpenWrt, the latter is when you upgrade an already installed
  OpenWrt.

* You must carefully pick the proper firmware file for your **hardware version**! I advise you
  to look up the wiki page for your hardware on the [OpenWrt wiki](https://openwrt.org),
  because most of them have a table of the released hardware versions with comments on their
  status (sometimes new hardware revisions are only supported by the latest OpenWrt, which is
  not released yet).

## Help! The build has finished but there's no firmware file!

If the build doesn't yield a firmware file (```*-factory.bin``` and/or ```*-sysupgrade.bin```):
when there's not enough space in the flash memory of the target device to install everything
then the OpenWrt ImageBuilder prints a hardly visible error into its flow of output and
silently continues. Look into [build.sh](build.sh#L31) and try to remove some packages
that you can live without.

## Extroot is not mounted after a `sysupgrade`

In short, this is an OpenWrt issue, and the solution is to mount the extroot
somewhere, and delete `/etc/.extroot-uuid`. More details are available in
[this issue](https://github.com/attila-lendvai/openwrt-auto-extroot/issues/12),
and a way to deal with it can be found in
[this blog post](https://blog.mbirth.de/archives/2014/05/26/openwrt-sysupgrade-with-extroot.html).
You may also want to check out the
[official OpenWrt wiki](https://openwrt.org/docs/guide-user/additional-software/extroot_configuration#system_upgrade)
on this topic.
