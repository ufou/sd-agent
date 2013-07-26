#!/usr/bin/env bash

##
###
### Based on the original script by the friendly guys at Boundary
###
### Copyright 2011-2013, Boundary
### Copyright 2013, Server Density
###
### Licensed under the Apache License, Version 2.0 (the "License");
### you may not use this file except in compliance with the License.
### You may obtain a copy of the License at
###
###     http://www.apache.org/licenses/LICENSE-2.0
###
### Unless required by applicable law or agreed to in writing, software
### distributed under the License is distributed on an "AS IS" BASIS,
### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
### See the License for the specific language governing permissions and
### limitations under the License.
###

PLATFORMS=("Ubuntu" "Debian" "CentOS" "Amazon" "RHEL")

# Put additional version numbers here.
# These variables take the form ${platform}_VERSIONS, where $platform matches
# the tags in $PLATFORMS
Ubuntu_VERSIONS=("10.04" "10.10" "11.04" "11.10" "12.04" "12.10" "13.04")
Debian_VERSIONS=("5" "6")
CentOS_VERSIONS=("5" "6")
Amazon_VERSIONS=("2012.09" "2013.03")
RHEL_VERSIONS=("5" "6")

# For version number updates you hopefully don't need to modify below this line
# -----------------------------------------------------------------------------

SUPPORTED_ARCH=0
SUPPORTED_PLATFORM=0

APT_CMD="apt-get -q -y --force-yes"
YUM_CMD="yum -d0 -e0 -y"

trap "exit" INT TERM EXIT

function print_supported_platforms() {
    echo "Supported platforms are:"
    for d in ${PLATFORMS[*]}
    do
        echo -n " * $d:"
        foo="\${${d}_VERSIONS[*]}"
        versions=`eval echo $foo`
        for v in $versions
        do
            echo -n " $v"
        done
        echo ""
    done
}

function check_distro_version() {
    PLATFORM=$1
    DISTRO=$2
    VERSION=$3

    TEMP="\${${DISTRO}_versions[*]}"
    VERSIONS=`eval echo $TEMP`

    if [ $DISTRO = "Ubuntu" ]; then
        MAJOR_VERSION=`echo $VERSION | awk -F. '{print $1}'`
        MINOR_VERSION=`echo $VERSION | awk -F. '{print $2}'`
        PATCH_VERSION=`echo $VERSION | awk -F. '{print $3}'`

        TEMP="\${${DISTRO}_VERSIONS[*]}"
        VERSIONS=`eval echo $TEMP`
        for v in $VERSIONS ; do
            if [ "$MAJOR_VERSION.$MINOR_VERSION" = "$v" ]; then
                return 0
            fi
        done

    elif [ $DISTRO = "CentOS" ] || [ $DISTRO = "RHEL" ]; then
        MAJOR_VERSION=`echo $VERSION | awk -F. '{print $1}'`
        MINOR_VERSION=`echo $VERSION | awk -F. '{print $2}'`

        TEMP="\${${DISTRO}_VERSIONS[*]}"
        VERSIONS=`eval echo $TEMP`
        for v in $VERSIONS ; do
            if [ "$MAJOR_VERSION" = "$v" ]; then
                return 0
            fi
        done

    elif [ $DISTRO = "Amazon" ]; then
        VERSION=`echo $PLATFORM | awk '{print $5}'`
        # Some of these include minor numbers. Trim.
        VERSION=${VERSION:0:7}

        TEMP="\${${DISTRO}_VERSIONS[*]}"
        VERSIONS=`eval echo $TEMP`
        for v in $VERSIONS ; do
            if [ "$VERSION" = "$v" ]; then
                return 0
            fi
        done

    elif [ $DISTRO = "Debian" ]; then
        MAJOR_VERSION=`echo $VERSION | awk -F. '{print $1}'`
        MINOR_VERSION=`echo $VERSION | awk -F. '{print $2}'`

        TEMP="\${${DISTRO}_VERSIONS[*]}"
        VERSIONS=`eval echo $TEMP`
        for v in $VERSIONS ; do
            if [ "$MAJOR_VERSION" = "$v" ]; then
                return 0
            fi
        done
    fi

    echo "Detected $DISTRO but with an unsupported version ($VERSION)"
    return 1
}

function print_help() {
    echo "   $0 -a https://example.serverdensity.io -k agentKey"
    echo "      -a: Required. Account URL in form https://example.serverdensity.io"
    echo "      -k: Required. Agent key."
    exit 0
}

function do_install() {
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        sudo $APT_CMD update > /dev/null

        APT_STRING="deb http://www.serverdensity.com/downloads/linux/deb all main"
        echo "Adding repository"
        sudo sh -c "echo \"deb http://www.serverdensity.com/downloads/linux/deb all main\" > /etc/apt/sources.list.d/sd-agent.list"

        $CURL -s https://www.serverdensity.com/downloads/boxedice-public.key | sudo apt-key add -
        if [ $? -gt 0 ]; then
            echo "Error downloading key"
            exit 1
        fi

        echo "Installing agent"

        sudo $APT_CMD update > /dev/null
        sudo $APT_CMD install sd-agent
        return $?
    
    elif [ "$DISTRO" = "CentOS" ] || [ $DISTRO = "Amazon" ] || [ $DISTRO = "RHEL" ]; then        
        echo "Adding repository"

        sudo sh -c "cat - > /etc/yum.repos.d/serverdensity.repo <<EOF
[serverdensity]
name=Server Density
baseurl=http://www.serverdensity.com/downloads/linux/redhat/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-serverdensity
EOF"

        $CURL -s https://www.serverdensity.com/downloads/boxedice-public.key | sudo tee /etc/pki/rpm-gpg/RPM-GPG-KEY-serverdensity > /dev/null
        if [ $? -gt 0 ]; then
            echo "Error downloading key"
            exit 1
        fi

        echo "Installing agent"

        sudo $YUM_CMD install sd-agent
        return $?
    fi
}

function configure_agent() {
    echo "Configuring agent"

    sudo sh -c "cat - > /etc/sd-agent/config.cfg <<EOF
#
# Server Density Agent Config
# Docs: http://support.serverdensity.com/knowledgebase/articles/69360-agent-config-variables-linux-mac-freebsd
#

[Main]
sd_url: $ACCOUNT
agent_key: $AGENTKEY

#
# Plugins
#
# Leave blank to ignore. See http://support.serverdensity.com/knowledgebase/articles/76018-writing-a-plugin-linux-mac-and-freebsd
#

plugin_directory:

#
# Optional status monitoring
#
# See http://support.serverdensity.com/knowledgebase/topics/10921-configuration
# Ignore these if you do not wish to monitor them
#

# Apache
# See http://support.serverdensity.com/knowledgebase/articles/71145-apache-monitoring-linux-mac-and-freebsd

apache_status_url: http://www.example.com/server-status/?auto
apache_status_user:
apache_status_pass:

# MongoDB
# See http://support.serverdensity.com/knowledgebase/articles/71151-mongodb-monitoring-linux-mac-and-freebsd

mongodb_server:
mongodb_dbstats: no
mongodb_replset: no

# MySQL
# See http://support.serverdensity.com/knowledgebase/articles/71166-mysql-monitoring-linux-mac-and-freebsd

mysql_server:
mysql_user:
mysql_pass:

# nginx
# See http://support.serverdensity.com/knowledgebase/articles/75885-nginx-monitoring-linux-mac-and-freebsd

nginx_status_url: http://www.example.com/nginx_status

# RabbitMQ
# See http://support.serverdensity.com/knowledgebase/articles/75888-rabbitmq-monitoring-linux-mac-and-freebsd

# for rabbit > 2.x use this url:
# rabbitmq_status_url: http://www.example.com:55672/api/overview
# for earlier, use this:
rabbitmq_status_url: http://www.example.com:55672/json
rabbitmq_user: guest
rabbitmq_pass: guest

# Temporary file location
# See http://support.serverdensity.com/knowledgebase/articles/69360-agent-config-variables-linux-mac-freebsd

# tmp_directory: /var/log/custom_location

# Pid file location
# See http://support.serverdensity.com/knowledgebase/articles/69360-agent-config-variables-linux-mac-freebsd

# pidfile_directory: /var/custom_location

# Set log level
# See http://support.serverdensity.com/knowledgebase/articles/69360-agent-config-variables-linux-mac-freebsd

# logging_level: debug
EOF"

    sudo /etc/init.d/sd-agent restart
}

function pre_install_sanity() {
    SUDO=`which sudo`
    if [ $? -ne 0 ]; then
        echo "This script requires that sudo be installed and configured for your user."
        echo "Please install sudo. For assistance, hello@serverdensity.com"
        exit 1
    fi

    which curl > /dev/null
    if [ $? -gt 0 ]; then
        echo "The 'curl' command is either not installed or not on the PATH ..."

        echo "Installing curl ..."

        if [ $DISTRO = "Ubuntu" ] || [ $DISTRO = "Debian" ]; then
            sudo $APT_CMD update > /dev/null
            sudo $APT_CMD install curl

        elif [ $DISTRO = "CentOS" ] || [ $DISTRO = "Amazon" ] || [ $DISTRO = "RHEL" ]; then
            sudo $YUM_CMD install curl
        fi
    fi

    CURL="`which curl`"
}

# Grab some system information
if [ -f /etc/redhat-release ] ; then
    PLATFORM=`cat /etc/redhat-release`
    DISTRO=`echo $PLATFORM | awk '{print $1}'`
    if [ "$DISTRO" != "CentOS" ]; then
        if [ "$DISTRO" = "Red" ]; then
                DISTRO="RHEL"
                VERSION=`echo $PLATFORM | awk '{print $7}'`
        else
                DISTRO="unknown"
                PLATFORM="unknown"
                VERSION="unknown"
        fi
    elif [ "$DISTRO" = "CentOS" ]; then
        VERSION=`echo $PLATFORM | awk '{print $3}'`
    fi
    MACHINE=`uname -m`
elif [ -f /etc/system-release ]; then
    PLATFORM=`cat /etc/system-release | head -n 1`
    DISTRO=`echo $PLATFORM | awk '{print $1}'`
    VERSION=`echo $PLATFORM | awk '{print $5}'`
    MACHINE=`uname -m`
elif [ -f /etc/lsb-release ] ; then
    #Ubuntu version lsb-release - https://help.ubuntu.com/community/CheckingYourUbuntuVersion
    . /etc/lsb-release
    PLATFORM=$DISTRIB_DESCRIPTION
    DISTRO=$DISTRIB_ID
    VERSION=$DISTRIB_RELEASE
    MACHINE=`uname -m`
elif [ -f /etc/debian_version ] ; then
    #Debian Version /etc/debian_version - Source: http://www.debian.org/doc/manuals/debian-faq/ch-software.en.html#s-isitdebian
    DISTRO="Debian"
    VERSION=`cat /etc/debian_version`
    INFO="$DISTRO $VERSION"
    PLATFORM=$INFO
    MACHINE=`uname -m`
else
    PLATFORM=`uname -sv | grep 'SunOS joyent'` > /dev/null
    if [ "$?" = "0" ]; then
      PLATFORM="SmartOS"
      DISTRO="SmartOS"
      VERSION=`cat /etc/product | grep 'Image' | awk '{ print $3}' | awk -F. '{print $1}'`
      MACHINE="i686"
      JOYENT=`cat /etc/product | grep 'Name' | awk '{ print $2}'`

    elif [ "$?" != "0" ]; then
        PLATFORM="unknown"
        DISTRO="unknown"
        MACHINE=`uname -m`
    fi
fi

IGNORE_RELEASE=0

while getopts "a:k:" opt; do
  case $opt in
    a)
      ACCOUNT="$OPTARG" >&2
      ;;
    k)
      AGENTKEY="$OPTARG" >&2
      ;;
    \?)
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [ -z $ACCOUNT ]; then
    print_help
fi

if [ -z $AGENTKEY ]; then
    print_help
fi

echo ""
echo "Server Density Agent Installer"
echo ""
echo "Account: $ACCOUNT"
echo "Agent Key: $AGENTKEY"
echo "OS: $DISTRO $VERSION..."
echo ""

if [ $MACHINE = "i686" ]; then
    ARCH="32"
    SUPPORTED_ARCH=1
fi

if [ $MACHINE = "x86_64" ] || [ $MACHINE = "amd64" ]; then
    ARCH="64"
    SUPPORTED_ARCH=1
fi

if [ $SUPPORTED_ARCH -eq 0 ]; then
    echo "Unsupported architecture ($MACHINE) ..."
    echo "This is an unsupported platform for the sd-agent."
    echo "Please contact hello@serverdensity.com to request support for this architecture."
    exit 1
fi

# Check the distribution
for d in ${PLATFORMS[*]} ; do
    if [ $DISTRO = $d ]; then
        SUPPORTED_PLATFORM=1
        break
    fi
done
if [ $SUPPORTED_PLATFORM -eq 0 ]; then
    echo "Your platform is not supported by this script, but you may be able to do a manual install. Select Manual Install from the dropdown in the web UI."
    echo ""
    print_supported_platforms
    exit 0
fi

if [ $IGNORE_RELEASE -ne 1 ]; then
    # Check the version number
    check_distro_version "$PLATFORM" $DISTRO $VERSION
    if [ $? -ne 0 ]; then
        IGNORE_RELEASE=1
        echo "Detected $PLATFORM $DISTRO $VERSION"
    fi
fi

# The version number hasn't been found; let's just try and masquerade
# (and tell users what we're doing)
if [ $IGNORE_RELEASE ] ; then
    TEMP="\${${DISTRO}_VERSIONS[*]}"
    VERSIONS=`eval echo $TEMP`
    # Assume ordered list; grab latest version
    VERSION=`echo $VERSIONS | awk '{print $NF}'`
    MAJOR_VERSION=`echo $VERSION | awk -F. '{print $1}'`
    MINOR_VERSION=`echo $VERSION | awk -F. '{print $2}'`

    echo ""
    echo "Continuing; for reference, script is masquerading as: $DISTRO $VERSION"
    echo ""
fi

# At this point, we think we have a supported OS.
pre_install_sanity $d $v

do_install

configure_agent

if [ $? -ne 0 ]; then
    echo "I added the correct repositories, but the agent installation failed."
    echo "Please contact hello@serverdensity.com about this problem."
    exit 1
fi

echo ""
echo "The agent has been installed successfully!"
echo "Head back to $ACCOUNT to see your stats and set up some alerts."
