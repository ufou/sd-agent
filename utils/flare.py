# stdlib
import atexit
import cStringIO as StringIO
from functools import partial
import glob
try:
    import grp
except ImportError:
    # The module only exists on Unix platforms
    grp = None
import logging
import os
try:
    import pwd
except ImportError:
    # Same as above (exists on Unix platforms only)
    pwd = None
import re
import stat
import subprocess
import sys
import tarfile
import tempfile
from time import strftime
import traceback

# 3p
import requests

# DD imports
from checks.check_status import CollectorStatus, DogstatsdStatus, ForwarderStatus
from config import (
    check_yaml,
    get_confd_path,
    get_config,
    get_config_path,
    get_logging_config,
)
from util import get_hostname
from utils.jmx import jmx_command, JMXFiles
from utils.platform import Platform

# Globals
log = logging.getLogger(__name__)


def configcheck():
    all_valid = True
    for conf_path in glob.glob(os.path.join(get_confd_path(), "*.yaml")):
        basename = os.path.basename(conf_path)
        try:
            check_yaml(conf_path)
        except Exception, e:
            all_valid = False
            print "%s contains errors:\n    %s" % (basename, e)
        else:
            print "%s is valid" % basename
    if all_valid:
        print "All yaml files passed. You can now run the Server Density agent."
        return 0
    else:
        print("Fix the invalid yaml files above in order to start the Server Density agent. "
              "A useful external tool for yaml parsing can be found at "
              "http://yaml-online-parser.appspot.com/")
        return 1
