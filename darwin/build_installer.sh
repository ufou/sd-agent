#!/bin/bash

# Build requisites
pip install --user virtualenv
PATH=~/Library/Python/2.7/bin:$PATH

pushd `dirname $0` > /dev/null
SOURCE_PATH=`pwd`/..
popd > /dev/null


SD_HOME=/tmp/sd_agent_work

mkdir -p $SD_HOME

cp ../requirements.txt $SD_HOME
cp ../requirements-opt.txt $SD_HOME

# Prepare virtual environment

cd $SD_HOME
virtualenv venv --distribute
source venv/bin/activate

VENV_PYTHON_CMD="$SD_HOME/venv/bin/python"
VENV_PIP_CMD="$SD_HOME/venv/bin/pip"
curl -k -L -o $SD_HOME/ez_setup.py https://bootstrap.pypa.io/ez_setup.py
curl -k -L -o $SD_HOME/get-pip.py https://bootstrap.pypa.io/get-pip.py 

$VENV_PYTHON_CMD ez_setup.py --version="20.9.0"
$VENV_PYTHON_CMD $SD_HOME/get-pip.py
$VENV_PIP_CMD install "pip==6.1.1"

rm $SD_HOME/ez_setup.py
rm -f "$SD_HOME/get-pip.py"

$VENV_PIP_CMD install -r requirements.txt
$SOURCE_PATH/utils/pip-allow-failures.sh $SD_HOME/requirements-opt.txt

mkdir -p $SD_HOME/agent

# Copy agent code

cp -R $SOURCE_PATH $SD_HOME/agent

rm $SD_HOME/*txt
rm $SD_HOME/*zip

virtualenv --relocatable $SD_HOME/venv

# Package it up
cd $SOURCE_PATH/darwin
source darwin_version.sh
pkgbuild --identifier com.serverdensity.agent-service \
--version $AGENT_VERSION \
--install-location "/usr/local/sd-agent/" \
--scripts scripts \
--ownership recommended \
--root $SD_HOME \
--component-plist AgentComponents.plist \
"Server Density Agent Service.pkg"

# TODO: Package a preference pane as a separate component

productbuild --distribution distribution.xml \
--identifier com.serverdensity.agent \
--resources . \
"Server Density Agent Installer $AGENT_VERSION.pkg"    




