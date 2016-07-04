#!/usr/bin/env bash

bundle install
bundle package
# Needed if no cache exists
mkdir -p $INTEGRATIONS_DIR
ls -al $INTEGRATIONS_DIR
rm -rf /home/travis/virtualenv/python$TRAVIS_PYTHON_VERSION.9/lib/python$TRAVIS_PYTHON_VERSION/site-packages/pip-6.0.7.dist-info
rm -rf /home/travis/virtualenv/python$TRAVIS_PYTHON_VERSION.9/lib/python$TRAVIS_PYTHON_VERSION/site-packages/setuptools-12.0.5.dist-info
'rake ci:run'
ls -al $INTEGRATIONS_DIR