#!/bin/bash
#source https://github.com/moby/moby/blob/master/contrib/mkimage-yum.sh#L144

sysroot=/mnt/sysroot
if ! [ -d ${sysroot} ];then mkdir -m766 -p ${sysroot};fi

#install system
yum -y  --installroot=${sysroot} --setopt=tsflags=nodocs --releasever 33  install glibc.x86_64 setup shadow-utils

yes |rm -f ${sysroot}/dev/null
mknod -m 600 ${sysroot}/dev/initctl p
mknod -m 666 ${sysroot}/dev/full c 1 7
mknod -m 666 ${sysroot}/dev/null c 1 3
mknod -m 666 ${sysroot}/dev/ptmx c 5 2
mknod -m 666 ${sysroot}/dev/random c 1 8
mknod -m 666 ${sysroot}/dev/tty c 5 0
mknod -m 666 ${sysroot}/dev/tty0 c 4 0
mknod -m 666 ${sysroot}/dev/urandom c 1 9


#chronyd prerequisites
yum -y --installroot=${sysroot} --setopt=tsflags=nodocs --releasever 33  install libedit libcap nettle bash libseccomp p11-kit libidn2 libtasn1 
yum -y --installroot=${sysroot}  --releasever 33  download gnutls chrony
TLSRPM="$(ls gnutls*x86_64.rpm)"
rpm -ivh --root=${sysroot}  --nodeps --excludedocs ${TLSRPM}

#install chronyd
CHRONYRPM="$(ls chrony*x86_64.rpm)"
CHRONYVERSION=$(sed -e 's/chrony-\(.*\)\.x86_64.rpm/\1/' <<< $CHRONYRPM)
rpm -ivh --root=${sysroot}  --nodeps --excludedocs --noscripts ${CHRONYRPM}
rm -rf ${sysroot}/var/lib/chrony
chroot ${sysroot} groupadd -g 500 chrony
chroot ${sysroot} useradd -d /var/lib/chrony -c 'chrony daemon' -s /bin/false -g 500 -u 500 chrony

cat > ${sysroot}/etc/sysconfig/network << EOF
NETWORKING=yes
HOSTNAME=localhost.localdomain
EOF

#clean up
yum -y --installroot=${sysroot} --setopt=tsflags=nodocs --releasever 33 remove shadow-utils
yum -y --installroot=${sysroot} --setopt=tsflags=nodocs --releasever 33  clean all 

rm -rf ${sysroot}/usr/{{lib,share}/locale,{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive}
#  docs and man pages
rm -rf ${sysroot}/usr/share/{man,doc,info,gnome/help}
#  cracklib
rm -rf ${sysroot}/usr/share/cracklib
#  i18n
rm -rf ${sysroot}/usr/share/i18n
#  yum cache
rm -rf ${sysroot}/var/cache/yum
mkdir -p --mode=0755 ${sysroot}/var/cache/yum
#  sln
rm -rf ${sysroot}/sbin/sln
#  ldconfig
rm -rf ${sysroot}/etc/ld.so.cache ${sysroot}/var/cache/ldconfig
mkdir -p --mode=0755 ${sysroot}/var/cache/ldconfig


tar -cJ -C ${sysroot} . -f layer.tar.xz
podman build --squash-all --security-opt=seccomp=unconfined --cap-add SYS_TIME  -t chrony:${CHRONYVERSION} -f ./Dockerfile
podman run --cap-add SYS_TIME -ti --rm -v /etc/chrony.conf:/etc/chrony.conf:ro -p 123:123/udp -t chrony:${CHRONYVERSION}