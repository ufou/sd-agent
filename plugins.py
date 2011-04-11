#!/usr/bin/env python

"""
Classes for plugin download, installation, and registration.

"""


import os
import platform
from optparse import OptionParser

python_version = platform.python_version_tuple()

if int(python_version[1]) >= 6:
    import json
else:
    import minjson

class App(object):
    """
    Class for collecting arguments and options for the plugin
    download and installation process.

    """

    def __init__(self):
        usage = 'usage: %prog [options] key'
        self.parser = OptionParser(usage=usage)
        self.parser.add_option('-v', '--verbose', action='store_true', dest='verbose',
                               default=False, help='run in verbose mode [default]')

    def run(self):
        """
        Entry point to the plugin helper application.

        """
        (options, args) = self.parser.parse_args()
        if len(args) != 1:
            self.parser.error('incorrect number of arguments')
        downloader = PluginDownloader(args[0], options.verbose)
        downloader.start()

class PluginMetadata(object):
    def __init__(self, downloader):
        assert downloader, 'cannot get metadata without a downloader.'
        self.downloader = downloader

    def get(self):
        raise Exception, 'sub-classes to provide implementation.'

    def json(self):
        metadata = self.get()
        if self.downloader.verbose:
            print metadata
        if json:
            return json.loads(metadata)
        else:
            return minjson.safeRead(metadata)

class FilePluginMetadata(PluginMetadata):
    """
    File-based metadata provider, for testing purposes.

    """
    def get(self):
        path = os.path.join(os.path.dirname(__file__), 'tests/plugin.json')
        if self.downloader.verbose:
            print 'reading plugin data from %s' % path
        f = open(path, 'r')
        data = f.read()
        f.close()
        return data

class PluginDownloader(object):
    """
    Class for downloading a plugin.

    """
    def __init__(self, key, verbose=True):
        self.key = key
        self.verbose = verbose

    def start(self):
        metadata = FilePluginMetadata(self).json()
        if self.verbose:
            print 'retrieved metadata.'

if __name__ == '__main__':
    app = App()
    app.run()
