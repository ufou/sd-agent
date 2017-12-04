Testing & dd-agent
==================

[![Build Status](https://travis-ci.org/serverdensity/sd-agent.svg?branch=master)](https://travis-ci.org/serverdensity/sd-agent)

# Lint

Your code should always be clean when doing `rake lint`. It runs `flake8`, ignoring these [rules](../tox.ini).

# Organisation of the tests directory

```bash
tests
├── checks # tests of checks.d/*
│   ├── integration # contains all real integration tests (run on Travis)
│   ├── mock # contains mocked tests (run on Travis)
│   └── fixtures # files needed by tests (conf files, mocks, ...)
└── core # core agent tests (unit and integration tests, run on Travis)
    └── fixtures # files needed by tests
```

We use [rake](http://docs.seattlerb.org/rake/) & [nosetests](https://nose.readthedocs.org/en/latest/) to manage the tests.

To run individual tests:
```
# Whole file
nosetests tests/checks/mock/test_system_swap.py
# Whole class
nosetests tests/checks/mock/test_system_swap.py:SystemSwapTestCase
# Single test case
nosetests tests/checks/mock/test_system_swap.py:SystemSwapTestCase.test_system_swap
```

To run a specific ci flavor (our way of splitting tests, for more details see [integration tests](#integration-tests)):
```
# Run the flavor my_flavor
rake ci:run[my_flavor]
```

# Unit tests

They are split in different flavors:
```
# Run the mock/unit core tests
rake ci:run

# Run mock/unit checks tests
rake ci:run[checks_mock]

# Agent core integration tests (can take more than 5min)
rake ci:run[core_integration]
```


# Plugin tests

All plugins, except for the kubernates and docker ones, have been moved to the [Plugins SDK](https://github.com/serverdensity/sd-agent-core-plugins). Please look there to see
 the Plugins Tests.

# Travis

Its configuration is stored in [.travis.yml](../.travis.yml).

It's running the exact same command described above (`rake ci:run[flavor]`), with the restriction of one flavor + version per build. (we use the [build matrix](http://docs.travis-ci.com/user/customizing-the-build/#Build-Matrix) to split flavors)

We use the newly released [docker-based infrastructure](http://blog.travis-ci.com/2014-12-17-faster-builds-with-container-based-infrastructure/).
