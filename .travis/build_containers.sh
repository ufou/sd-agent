#!/bin/bash
set -ev

dockerfiles_dir=${1:-.travis/dockerfiles}
suffix=$2

if [ -n "${suffix}" ]; then
    suffix=_$suffix
fi

cd "$dockerfiles_dir"
if [ ! -d "$CACHE_DIR" ]; then
    sudo mkdir "$CACHE_DIR"
fi

for distro in *;
do
    container_name=${distro}${suffix}
    echo -en "travis_fold:start:build_${container_name}_container\\r"
    cache_file_var="CACHE_FILE_${container_name}"
    docker_cache=${!cache_file_var}
    if [ ! -f "$docker_cache"  ]; then
        cd "$distro"
        docker build -t serverdensity:"${container_name}" .
        cd ..
        docker save serverdensity:${container_name} | gzip > "$docker_cache"
    fi
    echo -en "travis_fold:end:build_${container_name}_container\\r"
done
