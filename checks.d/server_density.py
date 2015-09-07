from checks import AgentCheck

class ServerDensityCheck(AgentCheck):
    """ Collects metrics about the machine's disks. """

    def check(self, instance):
        self.log.debug('hello')
        self.gauge('hello.world1', 1)
        self.gauge('hello.world2', 1)
        self.gauge('hello.world3', 1)
        self.gauge('hello.world4', 1)
        self.log.debug('hello2')
