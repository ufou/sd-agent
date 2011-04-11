#!/usr/bin/env python

"""
Classes for plugin download, installation, and registration.

"""


from optparse import OptionParser

class App(object):
    """
    Entry point to the plugin helper application.

    """
    def __init__(self):
        usage = 'usage: %prog [options] key'
        self.parser = OptionParser(usage=usage)
        self.parser.add_option('-v', '--verbose', action='store_true', dest='verbose',
                               default=True, help='run in verbose mode [default]')

    def run(self):
        (options, args) = self.parser.parse_args()
        print options, args
        downloader = PluginDownloader(args[0])
        downloader.start()

class PluginDownloader(object):
    """
    Class for downloading a plugin.

    """
    def __init__(self, key):
	    self.key = key

    def start(self):
        print 'downloading plugin...'
        pass

if __name__ == '__main__':
    app = App()
    app.run()
