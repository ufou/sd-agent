#!/bin/bash

PACKAGES_DIR="/packages"
REPOSITORY_DIR="/archive"
EL5_ARCHTYPES=("x86_64" "i386")
EL5_PLUGINS=("apache" "btrfs" "consul" "couchbase" "couchdb" "directory" "docker" "elastic" "haproxy" "hdfs" "kafka-consumer" "memcache" "mongo" "mysql" "nginx" "ntp" "phpfpm" "postfix" "postgresql" "rabbitmq" "redis" "riak" "supervisord" "varnish" "zookeeper")
EL5_REPOFILES=("17d94a8defa9605ca412dbdbf74851de1db570db-filelists.xml.gz" "2197450b28e2ff77d7a0eb72372e85cd83d4e917-primary.sqlite.bz2" "609fcb039fac036236b24f412acf1f916d805b73-primary.xml.gz" "8fb13b674c6eb2dbefbfdadbf1b922e2e15208e3-filelists.sqlite.bz2" "b0d70975130c75e61c511b880f2549a269df9493-other.xml.gz" "ecb0c3fcf1d8d86a19367730085c7a67bdd79e6a-other.sqlite.bz2" "repomd.xml")

set -ev

if [ ! -d "$CACHE_DIR" ]; then
    sudo mkdir "$CACHE_DIR"
fi

if [ ! -d "$REPOSITORY_DIR" ]; then
    sudo mkdir "$REPOSITORY_DIR"
fi

if [ -f "$CACHE_FILE_PACKAGES_LINUX"  ]; then
   sudo tar -zxvf "$CACHE_FILE_PACKAGES_LINUX" -C "$REPOSITORY_DIR"
fi

if [ -f "$CACHE_FILE_PACKAGES_MAC"  ]; then
    sudo mkdir "$REPOSITORY_DIR"/macOS
    sudo cp "$CACHE_FILE_PACKAGES_MAC" "$REPOSITORY_DIR"/macOS/sd-agent-latest.dmg
fi


echo -en "travis_fold:start:get_el5_repo\\r"
#Get el5 repo as we are no longer building packages for it.
for arch in ${EL5_ARCHTYPES[*]};
do
    sudo wget http://archive.serverdensity.com/el/5/"$arch"/sd-agent-2.1.5-1."$arch".rpm -O "$REPOSITORY_DIR"/el/5/"$arch"/sd-agent-2.1.5-1."$arch".rpm
    for plugin in ${EL5_PLUGINS[*]};
    do
        sudo wget http://archive.serverdensity.com/el/5/"$arch"/sd-agent-"$plugin"-2.1.5-1."$arch".rpm -O "$REPOSITORY_DIR"/el/5/"$arch"/sd-agent-"$plugin"-2.1.5-1."$arch".rpm
    done
done
for file in ${EL5_REPOFILES[*]};
do
    sudo wget http://archive.serverdensity.com/el/5/repodata/"$file" -O "$REPOSITORY_DIR"/el/5/repodata/"$file"
done
echo -en "travis_fold:end:get_el5_repo\\r"
find "$REPOSITORY_DIR"
curl -H "Authorization: token ${GITHUB_TOKEN}" -H 'Accept: application/vnd.github.v3.raw' -L https://api.github.com/repos/serverdensity/travis-softlayer-object-storage/contents/bootstrap-generic.sh | sed 's|export SLOS_INPUT=${TRAVIS_BUILD_DIR}|export SLOS_INPUT=${REPOSITORY_DIR}|g' | sed 's:export SLOS_NAME=`echo "${TRAVIS_REPO_SLUG}" | cut -f 2 -d /`:export SLOS_NAME=agent-repo:g' | /bin/sh
find /tmp
