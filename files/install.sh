#!/bin/bash
set -e eu
DEST="/tmp/portage-root"

source /lib/gentoo/functions.sh
source /etc/portage/make.conf

GCC_LDPATH="$(gcc-config -L)"

mkdir -p "${DEST}"/{etc,run,var}/
echo 'Europe/Moscow' > "${DEST}"/etc/timezone

export ROOT="${DEST}"
emerge --getbinpkgonly sys-libs/glibc sys-libs/timezone-data
emerge -t sys-libs/zlib dev-libs/openssl net-libs/libmnl dev-libs/elfutils \
       sys-apps/busybox app-shells/bash net-misc/curl

equery s \*
# Link logger to busybox to avoid installing util-linux
ln -s /bin/busybox "${DEST}/usr/bin/logger"
ln -s /run /var/run

mkdir -p "$(dirname "${DEST}${GCC_LDPATH}")"
cp -r "${GCC_LDPATH}" "${DEST}${GCC_LDPATH}"
cp /etc/ld.so.conf.d/05gcc-x86_64-pc-linux-gnu.conf \
   "${DEST}/etc/ld.so.conf.d/05gcc-x86_64-pc-linux-gnu.conf"
ldconfig -r "${DEST}"

rm -rf "${DEST}/var/cache/edb"/*
