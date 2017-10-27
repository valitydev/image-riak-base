#!/bin/sh
source /lib/gentoo/functions.sh

# XXX Fix broken build image
USE="multitarget graphite go"
emerge --getbinpkgonly --backtrack=50 glibc binutils binutils-libs gcc
eselect binutils set x86_64-pc-linux-gnu-2.28.1
gcc-config x86_64-pc-linux-gnu-5.4.0

# Set portage root and install stuff
export ROOT=/tmp/portage-root
export USE="-suid -pam -fdformat -ncurses -nls"
mkdir -p $ROOT/etc

ebegin "Setting locales to generate"
cat <<EOF> $ROOT/etc/locale.gen
en_DK.UTF-8 UTF-8
EOF
eend $? "Failed" || exit $?
ebegin "Setting locales to preserve"
cat <<EOF> $ROOT/etc/locale.nopurge
MANDELETE
SHOWFREEDSPACE
en_DK.UTF-8 UTF-8
EOF
eend $? "Failed" || exit $?


emerge --quiet-build=n --verbose --verbose-conflicts --tree openssl iproute2 grep gawk \
    coreutils attr util-linux net-misc/curl sed

rm -rf $ROOT/var/cache/edb/*
