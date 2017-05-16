#!/bin/bash
chmod +x /root/pbuilder-bootstrap.sh

sh /root/pbuilder-bootstrap.sh
dpkg-source -b /sd-agent
for arch in amd64 i386; do
    if [ ! -d /packages/precise ]; then
        mkdir /packages/precise
    fi
    if [ ! -d /packages/precise/$arch ]; then
        mkdir /packages/precise/$arch
    fi
    pbuilder-dist precise $arch build \
    --buildresult /packages/precise/$arch *.dsc
done
