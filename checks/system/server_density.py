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
        #return {'networkTraffic': {'eth0': {'trans_bytes': '54196', 'recv_bytes': '54196'}}}

        network_traffic = {}

	if sys.platform == 'linux2':
            self.logger.debug('getNetworkTraffic: linux2')

            try:
                self.logger.debug('getNetworkTraffic: attempting open')
                proc = open('/proc/net/dev', 'r')
                lines = proc.readlines()
                proc.close()

            except IOError, e:
                self.logger.error('getNetworkTraffic: exception = %s', e)
                return False

            self.logger.debug('getNetworkTraffic: open success, parsing')

            columnLine = lines[1]
            _, receiveCols, transmitCols = columnLine.split('|')
            receiveCols = map(lambda a: 'recv_' + a, receiveCols.split())
            transmitCols = map(lambda a: 'trans_' + a, transmitCols.split())

            cols = receiveCols + transmitCols
            self.logger.debug('getNetworkTraffic: parsing, looping')

            faces = {}
            for line in lines[2:]:
                if line.find(':') < 0:
                    continue
                face, data = line.split(':')
                faceData = dict(zip(cols, data.split()))
                faces[face] = faceData

            self.logger.debug('getNetworkTraffic: parsed, looping')

            interfaces = {}

            # Now loop through each interface
            for face in faces:
                key = face.strip()

                # We need to work out the traffic since the last check so first time we store the current value
                # then the next time we can calculate the difference
                try:
                    if key in network_traffic:
                        interfaces[key] = {}
                        interfaces[key]['recv_bytes'] = long(faces[face]['recv_bytes']) - long(network_traffic[key]['recv_bytes'])
                        interfaces[key]['trans_bytes'] = long(faces[face]['trans_bytes']) - long(network_traffic[key]['trans_bytes'])

                        if interfaces[key]['recv_bytes'] < 0:
                            interfaces[key]['recv_bytes'] = long(faces[face]['recv_bytes'])

                        if interfaces[key]['trans_bytes'] < 0:
                            interfaces[key]['trans_bytes'] = long(faces[face]['trans_bytes'])

                        interfaces[key]['recv_bytes'] = str(interfaces[key]['recv_bytes'])
                        interfaces[key]['trans_bytes'] = str(interfaces[key]['trans_bytes'])

                        # And update the stored value to subtract next time round
                        network_traffic[key]['recv_bytes'] = faces[face]['recv_bytes']
                        network_traffic[key]['trans_bytes'] = faces[face]['trans_bytes']

                    else:
                        network_traffic[key] = {}
                        network_traffic[key]['recv_bytes'] = faces[face]['recv_bytes']
                        network_traffic[key]['trans_bytes'] = faces[face]['trans_bytes']

                    # Logging
                    self.logger.debug('getNetworkTraffic: %s = %s', key, network_traffic[key]['recv_bytes'])
                    self.logger.debug('getNetworkTraffic: %s = %s', key, network_traffic[key]['trans_bytes'])

                except KeyError:
                    self.logger.error('getNetworkTraffic: no data for %s', key)

                except ValueError:
                    self.logger.error('getNetworkTraffic: invalid data for %s', key)

            self.logger.debug('getNetworkTraffic: completed, returning')
            self.logger.debug('getNetworkTraffic: completed, returning %s' % (str(network_traffic)))

            return {'networkTraffic': network_traffic}



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
