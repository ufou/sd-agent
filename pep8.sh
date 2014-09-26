#!/usr/bin/env bash

set -e
set -u

pep8 --ignore=E501 --exclude=minjson.py .
