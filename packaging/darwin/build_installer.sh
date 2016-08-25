#!/bin/bash
set -ev

# Build requisites
PATH=~/Library/Python/2.7/bin:$PATH

BUILD_DIR=build/darwin
DEST_VENV=/usr/local/sd-agent/
DARWIN_SCRIPTS=packaging/darwin

source ${DARWIN_SCRIPTS}/darwin_version.sh
PKG_NAME="Server Density Agent Installer ${AGENT_VERSION}.pkg"

VENV_PYTHON_CMD="${BUILD_DIR}/bin/python"
VENV_PIP_CMD="${BUILD_DIR}/bin/pip"

# Prepare virtual environment
mkdir -p ${BUILD_DIR}
curl -LO https://pypi.python.org/packages/source/v/virtualenv/virtualenv-13.1.2.tar.gz
tar xzf virtualenv-13.1.2.tar.gz
python virtualenv-13.1.2/virtualenv.py ${BUILD_DIR}

$VENV_PIP_CMD install -r requirements.txt
PIP_COMMAND=${VENV_PIP_CMD} ./utils/pip-allow-failures.sh requirements-opt.txt
${VENV_PYTHON_CMD} setup.py build
${VENV_PYTHON_CMD} setup.py install

# Fix venv activate paths.
sed -i ".bak" "s|^VIRTUAL_ENV=.*|VIRTUAL_ENV=${DEST_VENV}|" ${BUILD_DIR}/bin/activate
sed -i "'.bak'" "s|^setenv VIRTUAL_ENV.*|setenv VIRTUAL_ENV ${DEST_VENV}|" ${BUILD_DIR}/bin/activate.csh
sed -i "'.bak'" "s|^set -gx VIRTUAL_ENV.*|set -gx VIRTUAL_ENV ${DEST_VENV}|" ${BUILD_DIR}/bin/activate.fish

# Fix venv shebangs
grep -l -r -e '^#!.*bin/\(env \)\?\(python\|pypy\|ipy\|jython\)' ${BUILD_DIR}/bin | xargs sed -i ".bak" 's|^#!.*bin/\(env \)\?.*|#!$(DEST_VENV)/bin/python|'

# Remove backup files
rm -f ${BUILD_DIR}/bin/*.bak

mkdir -p ${BUILD_DIR}/etc/
cp config.cfg.example ${BUILD_DIR}/etc/config.cfg
cp plugins.cfg.example ${BUILD_DIR}/etc/plugins.cfg

mkdir -p ${BUILD_DIR}/checks.d
mkdir -p ${BUILD_DIR}/conf.d

# Copy agent code

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
util.py ${BUILD_DIR}

cp checks.d/disk.py \
checks.d/sd.py \
checks.d/sd_cpu_stats.py \
checks.d/network.py ${BUILD_DIR}/checks.d

cp conf.d/disk.yaml.default \
conf.d/sd.yaml.default \
conf.d/sd_cpu_stats.yaml.default \
conf.d/network.yaml.default ${BUILD_DIR}/conf.d

# Copy startup item
mkdir ${BUILD_DIR}/darwin
cp ${DARWIN_SCRIPTS}/com.serverdensity.agent.plist ${BUILD_DIR}/darwin

# Package it up
pkgbuild --identifier com.serverdensity.agent-service \
--version ${AGENT_VERSION} \
--install-location "/usr/local/sd-agent/" \
--scripts ${DARWIN_SCRIPTS}/scripts \
--ownership recommended \
--root ${BUILD_DIR} \
--component-plist ${DARWIN_SCRIPTS}/AgentComponents.plist \
"Server Density Agent Service.pkg"

# TODO: Package a preference pane as a separate component
mkdir -p diskimage

if [ ! -z "${DARWIN_INSTALLER_CN}" ]; then

    # Retrieve signing key from Travis environment and add it to a new default keychain
    echo ${DARWIN_INSTALLER_KEY} | base64 -D -o ServerDensity.p12
    KEYCHAIN_NAME=agent.keychain
    security create-keychain -p travis ${KEYCHAIN_NAME}
    security default-keychain -s ${KEYCHAIN_NAME}
    security unlock-keychain -p travis
    security set-keychain-settings -t 3600 -u
    security import ServerDensity.p12 -f pkcs12 -P "" -k ${KEYCHAIN_NAME} -T /usr/bin/productbuild
    # this may help when debugging, lists the known identities:
    # security find-identity

    productbuild --distribution ${DARWIN_SCRIPTS}/distribution.xml \
        --identifier com.serverdensity.agent \
        --resources ${DARWIN_SCRIPTS}/Resources \
        --sign "${DARWIN_INSTALLER_CN}" \
        diskimage/"${PKG_NAME}"

    # Trust, but verify
    spctl --assess --type install diskimage/"${PKG_NAME}"
else
    echo "Signing disabled..."
    productbuild --distribution ${DARWIN_SCRIPTS}/distribution.xml \
        --identifier com.serverdensity.agent \
        --resources ${DARWIN_SCRIPTS}/Resources \
        diskimage/"${PKG_NAME}"
fi

# Add the icon
${DARWIN_SCRIPTS}/scripts/setIcon.py ${DARWIN_SCRIPTS}/Resources/sd-agent-installer.icns diskimage/"${PKG_NAME}"

# Package the disk image
# This may fail sometimes due to a "Resource busy" error, in that case re-running the job usually fixes it
hdiutil create -srcfolder diskimage -volname "Agent Installer" "sd-agent-${AGENT_VERSION}.dmg"
