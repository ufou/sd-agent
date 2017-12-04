"""
Unix system checks.
"""
# stdlib
import platform
import re

# project
from checks import Check

# locale-resilient float converter
to_float = lambda s: float(s.replace(",", "."))

pythonVersion = platform.python_version_tuple()
python24 = platform.python_version().startswith('2.4')

class Identifier(Check):

    def __init__(self, logger):
        Check.__init__(self, logger)
        self.header_re = re.compile(r'([%\\/\-_a-zA-Z0-9]+)[\s+]?')
        self.item_re = re.compile(r'^([a-zA-Z0-9\/]+)')
        self.value_re = re.compile(r'\d+\.\d+')

    def check(self, agentConfig):
        return {"sdAgentVersion": 2.0}
