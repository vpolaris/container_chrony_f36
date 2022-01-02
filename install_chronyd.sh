#!/bin/bash
#source https://github.com/moby/moby/blob/master/contrib/mkimage-yum.sh#L144
proc="$(uname -m)"
printf "architecture is ${proc}\n"
if ! [ -f ./layer.tar ]; then 
    page="https://fr2.rpmfind.net/linux/fedora/linux/releases/33/Container/${proc}/images/" 
    image="$(curl -s ${page} | grep -e "Fedora-Container-Base-.*.tar.xz"|sed -e 's!^.*\(Fedora-Container-Base.*.tar.xz\).*$!\1!m')" 
    curl -sSl ${page}${image} -o/tmp/${image} 
    tar -Jxv -f /tmp/${image} --wildcards --strip-components=1 */layer.tar
fi
sysroot=/mnt/sysroot
if  [ -d ${sysroot} ];then rm -rf ${sysroot};fi
mkdir -m766 -p ${sysroot}
podman build --cap-add MKNOD --squash-all --build-arg arch=${proc} -v${sysroot}:${sysroot}:Z -t f33:builder -f ./Dockerfile.f33
# podman run -dt --name f33.builder -t f33:builder
if  [ -f ./layer.tar.xz ]; then rm -rf layer.tar.xz; fi
tar -cJ -C ${sysroot} . -f layer.tar.xz 
CHRONYVERSION=$(cat ${sysroot}/chrony.version)
# podman stop f33.builder
# podman rm f33.builder
# podman rmi f33:builder
podman build --squash-all -t chrony:${CHRONYVERSION} -f ./Dockerfile.chrony
podman run -ti --rm -v /etc/chrony.conf:/etc/chrony.conf:ro -p 123:123/udp -t chrony:${CHRONYVERSION}

rm -rf ${sysroot}