#!/bin/sh
source /lib/gentoo/functions.sh

# XXX Fix broken build image
# fixes compilation errors like this one:
#     In file included from utils.c:36:0:
#     ../include/namespace.h:35:19: error: static declaration of 'setns' follows non-static declaration
#      static inline int setns(int fd, int nstype)
#                        ^
#     In file included from /usr/include/sched.h:43:0,
#                      from ../include/namespace.h:4,
#                      from utils.c:36:
#     /usr/include/bits/sched.h:91:12: note: previous declaration of 'setns' was here
#      extern int setns (int __fd, int __nstype) __THROW;
#                 ^
USE="multitarget graphite go" emerge --getbinpkgonly --backtrack=50 glibc binutils binutils-libs gcc
eselect binutils set x86_64-pc-linux-gnu-2.28.1
gcc-config x86_64-pc-linux-gnu-5.4.0

# Set portage root and install stuff
export ROOT=/tmp/portage-root

#export USE="-suid -pam -fdformat -ncurses -nls"
#export USE="-suid"
mkdir -p $ROOT/etc

#ebegin "Setting locales to generate"
#cat <<EOF> $ROOT/etc/locale.gen
#en_DK.UTF-8 UTF-8
#EOF
#eend $? "Failed" || exit $?
#ebegin "Setting locales to preserve"
#cat <<EOF> $ROOT/etc/locale.nopurge
#MANDELETE
#SHOWFREEDSPACE
#en_DK.UTF-8 UTF-8
#EOF
#eend $? "Failed" || exit $?


#emerge --quiet-build=n --verbose --verbose-conflicts --tree openssl iproute2 grep gawk \
#    coreutils attr net-misc/curl sed
emerge glibc coreutils sed grep gawk attr net-misc/curl openssl iproute2 bash


#rm -rf $ROOT/var/cache/edb/*
