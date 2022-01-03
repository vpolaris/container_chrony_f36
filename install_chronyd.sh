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
podman rmi f33:builder
podman build --squash-all -t chrony:${CHRONYVERSION}-${proc} -f ./Dockerfile.chrony
if [[ $(podman volume exists run_chrony;echo $?) -eq 1 ]]; then  
podman volume create --opt device=tmpfs --opt type=tmpfs --opt o=nodev,noexec,uid=500,gid=500,mode=1750,size=4K run_chrony
;fi

if [[ $(podman volume exists var_chrony;echo $?) -eq 1 ]]; then  
podman volume create --opt device=tmpfs --opt type=tmpfs --opt o=nodev,noexec,uid=500,gid=500,mode=1750,size=1M var_chrony
;fi

podman run -ti --rm  --read-only  \
    --name chrony \
    --publish 123:123/udp \
    --health-cmd 'CMD-SHELL chronyc tracking || exit 1' \
    --health-interval 15m \
    --health-start-period 2m \
    --restart on-failure \
    --volume /etc/chrony.conf:/etc/chrony.conf:ro \
    --volume run_chrony:/run/chrony:Z \
    --volume var_chrony:/var/lib/chrony:rw \
    -t chrony:${CHRONYVERSION}-${proc}

rm -rf ${sysroot}