# Podman (or Docker) - Minimal Chrony service
Build from scratch a minimal Fedora 33 image with only chrony service implemented. The goal is to reduce surface attack with only few binary tools onboarded and a reduced size cost

![image](https://user-images.githubusercontent.com/73080749/147420710-87af57fb-e789-40d9-8868-7c2773f9fa45.png)

## Prerequisites
You need to build the image on a Fedora server with podman 3.3.1 installed

The process will pull up all packages, install it in a temporary directory, create chrony user do the cleanupn create layer for Dockerfile and build the image container, and finally run a test container

To schedule the default service use the following command

```podman run --cap-add SYS_TIME -dt --name chrony-svc --rm -v /etc/chrony.conf:/etc/chrony.conf:ro -p 123:123/udp -t chrony:4.1-1.fc33 ```
