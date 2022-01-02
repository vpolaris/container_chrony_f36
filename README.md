# Podman - Minimal Chrony service
Build from scratch a minimal Fedora 33 image with only chrony service implemented as time server. The goal is to reduce surface attack with only few binary tools onboarded, use chrony user to lauch the service and cost size reduced as much as possible.

![image](https://user-images.githubusercontent.com/73080749/147420710-87af57fb-e789-40d9-8868-7c2773f9fa45.png)

## Prerequisites
You need to build the image on a machine with podman 3.3.1 installed

## What the script does ?
 - Pull a fedora 33 container as helper
 - Mount a directory to build the chrony image
 - use fedora container to build the chony service inside the mounted directory
 - archive the mounted directory in a layer.tar.xz
 - use the new layer as sysroot directory to build the final image
 - create 2 tmpfs volume to secure the chrony service
 - Launch a test container with the local chrony.conf as time source in the most secure way
 - remove sysroot content

## Installation

You can clone the repository or download files 

``` sh
git clone https://github.com/vpolaris/contenair-tiny-chrony.f33.git
cd contenair-tiny-chrony.f33 && chmod u+x install_chronyd.sh 
sudo ./install_chronyd.sh
```
To schedule the default service use the following command

``` sh
podman run -d --read-only  \
    --name chrony \
    --publish 123:123/udp \
    --health-cmd 'CMD-SHELL chronyc tracking || exit 1' \
    --health-interval 15m \
    --health-start-period 2m \
    --restart on-failure \
    --volume /etc/chrony.conf:/etc/chrony.conf:ro \
    --volume run_chrony:/run/chrony:Z \
    --volume var_chrony:/var/lib/chrony:rw \
    -t chrony:4.1-1.fc33
```

## Check
Launch the health check
``` sh
podman healthcheck run chrony
```
![image](https://user-images.githubusercontent.com/73080749/147881721-cd2772a1-7704-48a5-8d73-f3965fca958e.png)

## sources
This is the site whare i found the materials

https://github.com/cturra/docker-ntp
https://github.com/moby/moby/blob/master/contrib/mkimage-yum.sh



