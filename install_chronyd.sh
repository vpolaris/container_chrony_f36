#!/bin/bash

podman build --cap-add MKNOD --squash-all -t f36:chrony -f ./Dockerfile

if [[ $(podman volume exists run_chrony;echo $?) -eq 1 ]]; then  
    podman volume create --opt device=tmpfs --opt type=tmpfs --opt o=nodev,noexec,uid=500,gid=500,mode=1750,size=4K run_chrony;
fi

if [[ $(podman volume exists var_chrony;echo $?) -eq 1 ]]; then  
    podman volume create --opt device=tmpfs --opt type=tmpfs --opt o=nodev,noexec,uid=500,gid=500,mode=1750,size=1M var_chrony;
fi

podman run -d  --read-only  \
    --name chrony \
    --read-only \
    --publish 123:123/udp \
    --health-cmd 'CMD-SHELL chronyc tracking || exit 1' \
    --health-interval 15m \
    --health-start-period 2m \
    --restart on-failure \
    --volume /etc/chrony.conf:/etc/chrony.conf:ro \
    --volume run_chrony:/run/chrony:Z \
    --volume var_chrony:/var/lib/chrony:rw \
    -t f36:chrony
