#!/bin/bash
source /lib/gentoo/functions.sh

export EMERGE="emerge -q"
SALT_VERSION="2015.8.13"

# Get utf-8 support with default locale
ebegin "Setting locales to generate"
# DK uses 24h time
cat <<EOF> /etc/locale.gen
en_DK.UTF-8 UTF-8
EOF
eend $? "Failed" || exit $?
ebegin "Setting locales to preserve"
cat <<EOF> /etc/locale.nopurge
MANDELETE
SHOWFREEDSPACE
en_DK.UTF-8 UTF-8
EOF
eend $? "Failed" || exit $?

locale-gen || exit $?

eselect locale set en_DK.utf8 || exit $?

# Get cert for loading packages from bakka repo via HTTPS
ebegin "Downloading CA for the package repository"
mkdir -p /usr/local/share/ca-certificates \
    && wget -q http://bakka.su/ca/baka_bakka.crt -O /usr/local/share/ca-certificates/baka_bakka.crt
eend $? "Failed" || exit $?
ebegin "Updating CA cerificates"
update-ca-certificates --fresh > /dev/null
eend $? "Failed" || exit $?

# /tmp/data mount set in packer.json
ebegin "Copying portage/make.conf"
cp /tmp/data/portage.make.conf /etc/portage/make.conf
eend $? "Failed" || exit $?

ebegin "Adding repos.conf/gentoo"
mkdir -p /etc/portage/repos.conf \
    && cat <<EOF> /etc/portage/repos.conf/gentoo.conf
[DEFAULT]
main-repo = gentoo

[gentoo]
location = /usr/portage
sync-type = rsync
auto-sync = false
EOF
eend $? "Failed" || exit $?

# https://wiki.gentoo.org/wiki/Profile_(Portage)
ebegin "Selecting profile"
eselect profile set hardened/linux/amd64/no-multilib
eend $? "Failed" || exit $?

ebegin "Setting bootstrap flags"
mkdir -p /etc/portage/package.{accept_keywords,keywords,use,env} \
    && touch /etc/portage/package.keywords/bootstrap
eend $? "Failed" || exit $?

# XXX we may need to remove openssh
ebegin "Removing openssh (to skip it's rebuilding with -bindist)"
${EMERGE} -C openssh
eend $? "Failed" || exit $?

# bakka.su cert is ECDSA and to get this supported we rebuild openssl without
# bindist
ebegin "Rebuilding openssl -bindist"
FEATURES="-getbinpkg" ${EMERGE} --verbose=n openssl
eend $? "Failed" || exit $?

# Enable bakka.su mirrors
ebegin "Uncommenting GENTOO_MIRRORS and other vars in make.conf"
sed -i "s|\# sed-remove||g" /etc/portage/make.conf
eend $? "Failed" || exit $?

ebegin "Emerging localepurge qemacs nvi openssh"
${EMERGE} --verbose=n qemacs nvi app-admin/localepurge
eend $? "Failed" || exit $?

# XXX python2.7 is needed by salt
#ebegin "Selecting python2.7 as default python interpreter"
#eselect python set python2.7
#eend $? "Failed" || exit $?

ebegin "Selecting pager"
eselect pager set /usr/bin/less
eend $? "Failed" || exit $?

# XXX perl is needed by at least localepurge
einfo "Updating perl"
perl-cleaner --reallyall || exit $?

ebegin "Updating world"
${EMERGE} -uDN @world
eend $? "Failed" || exit $?

# remove orphaned deps
ebegin "Cleaning deps"
${EMERGE} --verbose=n --depclean
eend $? "Failed" || exit $?

einfo "Purging extra locales"
localepurge || exit $?

find /usr/share/gtk-doc -delete
find /usr/share/man -delete
find /usr/share/doc -delete
find /usr/share/sgml -print -delete
find /usr/share/i18n -print
find /usr/share/misc -print
find / -name '*.pyc' -delete

ebegin "Removing temporary directories and logs"
rm -rf /var/tmp/{portage,packages,distfiles}
find /var/log -type f ! -name '.keep*' -print -delete
eend $? "Failed" || exit $?

einfo "And here are some resulting space consumption details"
find / -mindepth 2 -maxdepth 4 -exec 'du' '-hsx' '{}' ';' | sort -h | tail -n 50
find / -maxdepth 1 -exec 'du' '-hsx' '{}' ';' | sort -h | tail -n 50
