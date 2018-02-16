FROM ubuntu:precise
WORKDIR /root
RUN apt-get update && apt-get install -y pbuilder debootstrap devscripts ubuntu-dev-tools qemu qemu-user-static binfmt-support
RUN echo 'for arch in amd64 i386; do pbuilder-dist precise $arch create; done' > /root/pbuilder-bootstrap.sh
RUN apt-get install --reinstall qemu-user-static
COPY ./entrypoint.sh /
CMD ["/entrypoint.sh"]
