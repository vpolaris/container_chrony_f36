# Podman (or Docker) - Minimal Chrony service
Build from scratch a minimal Fedora 33 image with only chrony service implemented. The goal is to reduce surface attack with only few binary tools onboarded and a reduced size cost

![image](https://user-images.githubusercontent.com/73080749/147420710-87af57fb-e789-40d9-8868-7c2773f9fa45.png)

## Prerequisites
You need to build the image on a Fedora server with podman 3.3.1 installed

## Installation
The process will pull up all packages, install it in a temporary directory, create chrony user do the cleanup. Create layer for Dockerfile and build the image container, and finally run a test container

``` sh
git clone https://github.com/vpolaris/contenair-tiny-chrony.f33.git
cd contenair-tiny-chrony.f33 && chmod u+x install_chronyd.sh 
sudo ./install_chronyd.sh
```
To schedule the default service use the following command

``` sh
sudo podman run --cap-add SYS_TIME -dt --name chrony-svc -v /etc/chrony.conf:/etc/chrony.conf:ro -p 123:123/udp -t chrony:4.1-1.fc33 
```

## Check
``` sh
sudo podman exec chronysvc chronyc sources
```
![image](https://user-images.githubusercontent.com/73080749/147421822-f0409336-027a-4531-ab9c-859e91d03c39.png)
