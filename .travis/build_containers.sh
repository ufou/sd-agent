#!/bin/bash
set -ev
cd ${1:-.travis/dockerfiles}
if [ ! -d "$CACHE_DIR" ]; then
    sudo mkdir "$CACHE_DIR"
fi

for distro in *;
do
    echo -en "travis_fold:start:build_${distro}_container\\r"
    TEMP="\${CACHE_FILE_${distro}}"
    DOCKER_CACHE=$(eval echo "$TEMP")
    if [ ! -f "$DOCKER_CACHE"  ]; then
        cd "$distro"
        docker build -t serverdensity:"${distro}" .
        cd ..
        docker save serverdensity:${distro} | gzip > "$DOCKER_CACHE";
    fi
    echo -en "travis_fold:end:build_${distro}_container\\r"
done
