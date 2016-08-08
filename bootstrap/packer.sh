#!/bin/sh
# usage: stage-arch arch-name suffix

VerifyHashOfStage3() {
    # First param is package tarball, 2nd is the *.DIGEST file
    test_sum=$(awk -v myvar="$1" '$2==myvar {for(i=1; i<=1; i++) { print $1; exit}}' "${2}")
    calculated_sum=$(sha512sum "${1}" | awk '{print $1}' -)
    if [[ "$test_sum" == "$calculated_sum" ]]; then
	return 0
    else
	return 1
    fi
}

suffix="-hardened+nomultilib" # e.g. -hardened
arch="amd64"
dist="http://gentoo.bakka.su/releases/${arch}/autobuilds/"

echo "-I- dist: ${dist}"
echo "-I- arch: ${arch} suffix: ${suffix}"

echo '-=- Preparing the working directory'
mkdir newWorldOrder; cd newWorldOrder || exit 1
cp /bin/busybox . || exit 1
echo '-ok'

echo "-=- Downloading ${dist}/latest-stage3-${arch}${suffix}.txt"
wget -q "${dist}/latest-stage3-${arch}${suffix}.txt" || exit 1
echo '-ok'
stage3path="$(cat latest-stage3-${arch}${suffix}.txt | tail -n 1 | cut -f 1 -d ' ')"
stage3="$(basename ${stage3path})"
echo "-I- latest stage3: ${stage3path}"

echo "-=- Downloading ${dist}/${stage3path} and its DIGESTS"
wget -q -c "${dist}/${stage3path}" "${dist}/${stage3path}.DIGESTS" || exit 1
echo "-ok"
if VerifyHashOfStage3 "${stage3}" "${stage3}.DIGESTS"; then
    echo "-ok DIGEST verification passed, sha512 hashes match."
else
    echo "-!! DIGEST verification failed!"
    exit 1
fi
echo "-=- Unpacking ${stage3}"
bunzip2 -c "${stage3}" | tar --exclude "./etc/hosts" --exclude "./sys/*" -xf - || exit 1
echo "-ok"
echo "-=- Removing ${stage3}"
/newWorldOrder/busybox rm -f "${stage3}" || exit 1
echo "-ok"

echo "-=- Installing unpacked contents"
/newWorldOrder/busybox rm -rf /lib* /usr/sbin /var /bin /sbin /opt /mnt /media /root /home /run || exit 1
/newWorldOrder/busybox cp -fRap lib* bin boot home media mnt opt root run sbin tmp usr var / || exit 1
/newWorldOrder/busybox cp -fRap etc/* /etc/ || exit 1
echo "-ok"

echo "-=- Cleaning up"
cd /
/newWorldOrder/busybox rm -rf /newWorldOrder /build.sh /linuxrc || exit 1
echo "-ok"

echo "-I- Bootstrapped ${stage3path} into /"
echo "-I- Here begins the New World Order"

/bin/bash <<EOL
source /lib/gentoo/functions.sh

export EMERGE="emerge -q"

ebegin "Setting locales to generate"
cat <<EOF> /etc/locale.gen
en_DK.UTF-8 UTF-8
EOF
eend \$? "Failed" || exit \$?
locale-gen || exit \$?

eselect locale set en_DK.utf8 || exit \$?

ebegin "Downloading CA for the package repository"
mkdir -p /usr/local/share/ca-certificates \
    && wget -q http://bakka.su/ca/baka_bakka.crt -O /usr/local/share/ca-certificates/baka_bakka.crt
eend \$? "Failed" || exit \$?
ebegin "Updating CA cerificates"
update-ca-certificates --fresh > /dev/null
eend \$? "Failed" || exit \$?

ebegin "Copying portage/make.conf"
cp /tmp/data/portage.make.conf /etc/portage/make.conf
eend \$? "Failed" || exit \$?

ebegin "Adding repos.conf/gentoo"
mkdir -p /etc/portage/repos.conf \
    && cat <<EOF> /etc/portage/repos.conf/gentoo.conf
[DEFAULT]
main-repo = gentoo

[gentoo]
location = /usr/portage
sync-type = git
sync-uri = git://git.bakka.su/gentoo-mirror
EOF
eend \$? "Failed" || exit \$?

ebegin "Selecting profile"
eselect profile set hardened/linux/amd64/no-multilib
eend \$? "Failed" || exit \$?

ebegin "Setting bootstrap flags"
mkdir -p /etc/portage/package.{accept_keywords,keywords,use,env} \
    && cat <<'EOF'>> /etc/portage/package.keywords/bootstrap
=app-admin/salt-2015.8.8 ~amd64
net-libs/zeromq:0/5 ~amd64
<dev-python/pyzmq-16 ~amd64
dev-python/cffi ~amd64
EOF
eend \$? "Failed" || exit \$?

ebegin "Rebuilding openssl and openssh -bindist"
FEATURES="-getbinpkg" \${EMERGE} --verbose=n openssl openssh
eend \$? "Failed" || exit \$?

ebegin "Uncommenting GENTOO_MIRRORS and other vars in make.conf"
sed -i "s|\# sed-remove||g" /etc/portage/make.conf
eend \$? "Failed" || exit \$?

ebegin "Emerging git, salt qemacs nvi"
\${EMERGE} --verbose=n ">=zeromq-4.1" salt dev-vcs/git qemacs nvi
eend \$? "Failed" || exit \$?

ebegin "Selecting python2.7 as default python interpreter"
eselect python set python2.7
eend \$? "Failed" || exit \$?

ebegin "Selecting pager"
eselect pager set /usr/bin/less
eend \$? "Failed" || exit \$?

ebegin "Updating world"
\${EMERGE} -uDN @world
eend \$? "Failed" || exit \$?

ebegin "Cleaning deps"
\${EMERGE} --verbose=n --depclean
eend \$? "Failed" || exit \$?

ebegin "Removing temporary directories and logs"
rm -rf /var/tmp/{portage,packages,distfiles} /var/log/*.log
eend \$? "Failed" || exit \$?

if [ ! -d /var/salt ]; then
    ebegin "Creating /var/salt"
    mkdir -p /var/salt
    eend \$? || exit \$?
fi
EOL
