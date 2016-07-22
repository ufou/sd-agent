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
virtualenv $SD_HOME --distribute
source bin/activate

VENV_PYTHON_CMD="$SD_HOME/bin/python"
VENV_PIP_CMD="$SD_HOME//bin/pip"
curl -k -L -o $SD_HOME/ez_setup.py https://bootstrap.pypa.io/ez_setup.py
curl -k -L -o $SD_HOME/get-pip.py https://bootstrap.pypa.io/get-pip.py 

$VENV_PYTHON_CMD ez_setup.py --version="20.9.0"
$VENV_PYTHON_CMD $SD_HOME/get-pip.py
$VENV_PIP_CMD install "pip==6.1.1"

rm $SD_HOME/ez_setup.py
rm -f "$SD_HOME/get-pip.py"

$VENV_PIP_CMD install -r requirements.txt
$SOURCE_PATH/utils/pip-allow-failures.sh $SD_HOME/requirements-opt.txt

mkdir -p $SD_HOME/checks.d
mkdir -p $SD_HOME/conf.d

# Copy agent code
cd $SOURCE_PATH

cp agent.py \
aggregator.py \
config.py \
daemon.py \
sdagent.py \
emitter.py \
graphite.py \
modules.py \
sd-cert.pem \
transaction.py \
util.py $SD_HOME

cp checks.d/disk.py \
checks.d/sd.py \
checks.d/sd_cpu_stats.py \
checks.d/network.py $SD_HOME/checks.d

cp conf.d/disk.yaml.default \
conf.d/sd.yaml.default \
conf.d/sd_cpu_stats.yaml.default \
conf.d/network.yaml.default $SD_HOME/conf.d

cp config.cfg.example plugins.cfg.example $SD_HOME

# Copy startup item
mkdir $SD_HOME/darwin
cp darwin/com.serverdensity.agent.plist $SD_HOME/darwin

# Install plugins
$VENV_PYTHON_CMD setup.py build
$VENV_PYTHON_CMD setup.py install




# FIXME: Fix paths
virtualenv --relocatable $SD_HOME

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

# Retrieve signing key from Travis environment and add it to a new default keychain
echo $DARWIN_INSTALLER_KEY | base64 -D -o ServerDensity.p12
KEYCHAIN_NAME=agent.keychain
security create-keychain -p travis $KEYCHAIN_NAME
security default-keychain -s $KEYCHAIN_NAME
security unlock-keychain -p travis
security set-keychain-settings -t 3600 -u
security import ServerDensity.p12 -f pkcs12 -P "" -k $KEYCHAIN_NAME -T /usr/bin/productbuild

CERT_COMMON_NAME='Developer ID Installer: victor jalencas (8T3Z42HHGB)'

# TODO: Package a preference pane as a separate component
mkdir -p diskimage
productbuild --distribution distribution.xml \
--identifier com.serverdensity.agent \
--resources Resources \
--sign "$CERT_COMMON_NAME" \
diskimage/"Server Density Agent Installer $AGENT_VERSION.pkg"    

# Add the icon
scripts/setIcon.py Resources/sd-agent-installer.icns diskimage/"Server Density Agent Installer $AGENT_VERSION.pkg" 

# Package the disk image
hdiutil create -srcfolder diskimage -volname "Agent Installer" "sd-agent-$AGENT_VERSION.dmg"

