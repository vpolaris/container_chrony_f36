FROM fedora:36 as builder
ARG DISTVERSION=36
ARG sysroot=/mnt/sysroot
ARG DNFOPTION="--setopt=install_weak_deps=False --nodocs"

#update builder
RUN dnf makecache && dnf -y update
#install system
RUN dnf -y --installroot=${sysroot} ${DNFOPTION} --releasever ${DISTVERSION} install glibc setup shadow-utils

RUN yes | rm -f ${sysroot}/dev/null \
    &&mknod -m 600 ${sysroot}/dev/initctl p \
    && mknod -m 666 ${sysroot}/dev/full c 1 7 \
    && mknod -m 666 ${sysroot}/dev/null c 1 3 \
    && mknod -m 666 ${sysroot}/dev/ptmx c 5 2 \
    && mknod -m 666 ${sysroot}/dev/random c 1 8 \
    && mknod -m 666 ${sysroot}/dev/tty c 5 0 \
    && mknod -m 666 ${sysroot}/dev/tty0 c 4 0 \
    && mknod -m 666 ${sysroot}/dev/urandom c 1 9

#chronyd prerequisites
RUN dnf -y --installroot=${sysroot} ${DNFOPTION} --releasever ${DISTVERSION} install libedit libcap nettle bash libseccomp p11-kit libidn2 libtasn1 zlib
RUN dnf -y --installroot=${sysroot} ${DNFOPTION} --releasever ${DISTVERSION} install --downloadonly --downloaddir=./ gnutls chrony

RUN ARCH="$(uname -m)" \
    && TLSRPM="$(ls gnutls*${ARCH}.rpm)" \
    && rpm -ivh --root=${sysroot}  --nodeps --excludedocs ${TLSRPM}

#install chronyd
RUN ARCH="$(uname -m)" \
    && CHRONYRPM="$(ls chrony*${ARCH}.rpm)" \
    && CHRONYVERSION=$(sed -e "s/chrony-\(.*\)\.${ARCH}.rpm/\1/" <<< $CHRONYRPM) \
    && chroot ${sysroot} groupadd -g 500 chrony \
    && chroot ${sysroot} useradd -d /var/lib/chrony -c 'chrony daemon' -s /bin/false -g 500 -u 500 chrony \
    && rpm -ivh --root=${sysroot}  --nodeps --excludedocs --noscripts ${CHRONYRPM} \
    && printf ${CHRONYVERSION} > ${sysroot}/chrony.version

RUN cat << EOF | tee ${sysroot}/etc/sysconfig/network \
    NETWORKING=yes \
    HOSTNAME=localhost.localdomain\
    EOF
    
#clean up
RUN dnf -y --installroot=${sysroot} ${DNFOPTION} --releasever ${DISTVERSION} remove shadow-utils \
    && dnf -y --installroot=${sysroot} ${DNFOPTION} --releasever ${DISTVERSION} remove util-linux-core --skip-broken
    
#clean up    
RUN dnf -y --installroot=${sysroot} ${DNFOPTION} --releasever ${DISTVERSION}  autoremove \    
    && dnf -y --installroot=${sysroot} ${DNFOPTION} --releasever ${DISTVERSION}  clean all \
    && rm -rf ${sysroot}/usr/{{lib,share}/locale,{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive} \
#  docs and man pages       
    && rm -rf ${sysroot}/usr/share/{man,doc,info,gnome/help} \
#  purge log files
    && rm -f ${sysroot}/var/log/* || exit 0 \
#  cracklib
    && rm -rf ${sysroot}/usr/share/cracklib \
#  i18n
    && rm -rf ${sysroot}/usr/share/i18n \
#  dnf cache
    && rm -rf ${sysroot}/var/cache/dnf/ \
    && mkdir -p --mode=0755 ${sysroot}/var/cache/dnf/ \
    && rm -f ${sysroot}//var/lib/dnf/history.* \
#  sln
    && rm -rf ${sysroot}/sbin/sln \
#  ldconfig
    && rm -rf ${sysroot}/etc/ld.so.cache ${sysroot}/var/cache/ldconfig \
    && mkdir -p --mode=0755 ${sysroot}/var/cache/ldconfig

FROM scratch 
ARG sysroot=/mnt/sysroot
COPY --from=builder ${sysroot} /
ENV DISTTAG=f36container FGC=f36 FBR=f36 container=podman
ENV DISTRIB_ID fedora
ENV DISTRIB_RELEASE 36
ENV PLATFORM_ID "platform:f36"
ENV DISTRIB_DESCRIPTION "Fedora 36 Container"
ENV TZ UTC
ENV LANG C.UTF-8
ENV TERM xterm
EXPOSE 123/udp
HEALTHCHECK CMD chronyc tracking || exit 1
CMD /sbin/chronyd -dUx -u chrony