FROM scratch
ADD layer.tar.xz /
ENV DISTRIB_ID fedora
ENV DISTRIB_RELEASE 33
ENV container podman
ENV PLATFORM_ID "platform:f33"
ENV DISTRIB_DESCRIPTION "Fedora 33 Container"
ENV TZ UTC
ENV LANG C.UTF-8
EXPOSE 123/upd
CMD /sbin/chronyd -d