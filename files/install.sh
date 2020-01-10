#!/bin/bash
set -e eu
DEST="/tmp/portage-root"

source /lib/gentoo/functions.sh
source /etc/portage/make.conf

GCC_LDPATH="$(gcc-config -L)"

mkdir -p "${DEST}"/{etc,run,var,lib64,usr/lib64}/
ln -s /run "${DEST}/var/run"
ln -s /lib64 "${DEST}/lib"
ln -s /usr/lib64 "${DEST}/usr/lib64"

echo 'Europe/Moscow' > "${DEST}"/etc/timezone

export USE=unconfined
export ROOT="${DEST}"
emerge --getbinpkgonly sys-libs/glibc sys-libs/timezone-data gcc binutils make autoconf
emerge -t sys-libs/zlib "<dev-libs/openssl-1.1" net-libs/libmnl dev-libs/elfutils \
       sys-libs/ncurses sys-apps/busybox app-shells/bash net-misc/curl \
       dev-vcs/git =dev-lang/erlang-17.5

equery s \*
# Link logger to busybox to avoid installing util-linux
ln -s -f /bin/busybox "${DEST}/usr/bin/logger"

mkdir -p "$(dirname "${DEST}${GCC_LDPATH}")"
cp -r "${GCC_LDPATH}" "${DEST}${GCC_LDPATH}"
cp /etc/ld.so.conf.d/05gcc-x86_64-pc-linux-gnu.conf \
   "${DEST}/etc/ld.so.conf.d/05gcc-x86_64-pc-linux-gnu.conf"
ldconfig -r "${DEST}"

rm -rf "${DEST}/var/cache/edb"/*
