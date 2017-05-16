#!/bin/bash

DOCKERFILE_DIR=".travis/dockerfiles/"
PACKAGES_DIR="/packages"
REPOSITORY_DIR="/archive"
set -ev
cd "$DOCKERFILE_DIR"

#Create required folders if they do not already exist
if [ ! -d "$PACKAGES_DIR" ]; then
    sudo mkdir "$PACKAGES_DIR"
fi
if [ ! -d "$CACHE_DIR" ]; then
    sudo mkdir "$CACHE_DIR"
fi

#If the containers are in cache, load them, else create containers (They should be in cache already)
for d in * ;
do
    echo -en "travis_fold:start:build_${d}_container\\r"
    TEMP="\${CACHE_FILE_${d}}"
    DOCKER_CACHE=$(eval echo "$TEMP")
    if [ -f "$DOCKER_CACHE"  ]; then
        gunzip -c "$DOCKER_CACHE" | docker load;
    else
        (cd "$d" && docker build -t serverdensity:"${d}" .)
        if [ ! -f "$DOCKER_CACHE"  ]; then
            docker save serverdensity:"${d}" | gzip > "$DOCKER_CACHE";
        fi
    fi

    echo -en "travis_fold:end:build_${d}_container\\r"
done

#Run the containers, if container name is precise run with --privileged

for d in * ;
do
    echo "$d"
    if [[ "$d" == "precise" ]]; then
        echo -en "travis_fold:start:run_${d}_container\\r"
        sudo docker run --volume="${TRAVIS_BUILD_DIR}":/sd-agent:rw --volume=/packages:/packages:rw --privileged serverdensity:"${d}"
        echo -en "travis_fold:end:run_${d}_container\\r"
    else
        echo -en "travis_fold:start:run_${d}_container\\r"
        sudo docker run --volume="${TRAVIS_BUILD_DIR}":/sd-agent:rw --volume=/packages:/packages:rw serverdensity:"${d}"
        echo -en "travis_fold:end:run_${d}_container\\r"
    fi
done

# Prepare folder to be come the repository
if [ ! -d "$REPOSITORY_DIR" ]; then
    sudo mkdir "$REPOSITORY_DIR"
fi

if [ ! -d "$REPOSITORY_DIR"/el ]; then
    sudo mkdir "$REPOSITORY_DIR"/el
fi

if [ ! -d "$REPOSITORY_DIR"/el/5 ]; then
    sudo mkdir "$REPOSITORY_DIR"/el/5
    sudo mkdir "$REPOSITORY_DIR"/el/5/x86_64
    sudo mkdir "$REPOSITORY_DIR"/el/5/i386
    sudo mkdir "$REPOSITORY_DIR"/el/5/repodata
fi

if [ ! -d "$REPOSITORY_DIR"/ubuntu ]; then
    sudo mkdir "$REPOSITORY_DIR"/ubuntu
fi

sudo cp -a "$TRAVIS_BUILD_DIR"/packaging/ubuntu/conf/. "$REPOSITORY_DIR"/ubuntu/conf

# Prepare el packages as repo
find "$PACKAGES_DIR"
sudo cp -a "$PACKAGES_DIR"/el/. "$REPOSITORY_DIR"/el
cd "$REPOSITORY_DIR"/el

sudo createrepo 6
sudo createrepo 7
#cat << EOF > ~/.rpmmacros
#%_topdir /tmp/el
#%_tmppath %{_topdir}/tmp
#%_signature gpg
#%_gpg_name hello@serverdensity.com
#%_gpg_path ~/.gnupg
#EOF
#LC_ALL=C rpm --addsign 6/*/*.rpm 7/*/*.rpm

# Prepare deb packages as repo
cd "$REPOSITORY_DIR"/ubuntu
#FOR TESTING
sed -i '/SignWith: 131EFC09/d' "$REPOSITORY_DIR"/ubuntu/conf/distributions
sed -i '/ask-passphrase/d' "$REPOSITORY_DIR"/ubuntu/conf/options

sudo reprepro includedeb all "$PACKAGES_DIR"/precise/amd64/sd-agent*.deb "$PACKAGES_DIR"/precise/i386/sd-agent*i386*.deb

find "$REPOSITORY_DIR"

find /tmp

tar -zcvf "$CACHE_FILE_PACKAGES_LINUX" -C "$REPOSITORY_DIR" .
