"""
Unix system checks.
"""
# stdlib
import operator
import platform
import re
import sys
import time

# project
from checks import Check
from util import get_hostname
from utils.platform import Platform
from utils.subprocess_output import subprocess as sp

# locale-resilient float converter
to_float = lambda s: float(s.replace(",", "."))


class NetworkTraffic(Check):

    def __init__(self, logger):
        Check.__init__(self, logger)
        self.header_re = re.compile(r'([%\\/\-_a-zA-Z0-9]+)[\s+]?')
        self.item_re = re.compile(r'^([a-zA-Z0-9\/]+)')
        self.value_re = re.compile(r'\d+\.\d+')

    def check(self, agentConfig):
        """Capture io stats.

        @rtype dict
        @return {"device": {"metric": value, "metric": value}, ...}
        """
        return {'networkTraffic': {'eth0': {'trans_bytes': '54196', 'recv_bytes': '54196'}}}

if __name__ == '__main__':
    # 1s loop with results
    import logging

    logging.basicConfig(level=logging.DEBUG, format='%(asctime)-15s %(message)s')
    log = logging.getLogger()
    networkTraffic = NetworkTraffic(log)

    config = {"agent_key": "666"}

    while True:
        print("--- Network ---")
        print(networkTraffic.check(config))
        time.sleep(1)
