[![Build Status](https://travis-ci.org/serverdensity/sd-agent.svg?branch=master)](https://travis-ci.org/serverdensity/sd-agent)

You're looking at the source code right now. We provide a number of
[pre-packaged binaries](https://support.serverdensity.com/hc/en-us/sections/202790618-Agent-Installation-Configuration) for your convenience.

# How to configure the Agent

If you are using packages on linux, the main configuration file lives
in `/etc/sd-agent/config.cfg`. Per-check configuration files are in
`/etc/sd-agent/conf.d`. We provide an example in the same directory
that you can use as a template.

# Contributors

```bash
git log --all | gawk '/Author/ {print}' | sort | uniq
```

# Installing Server Density Old Style Plugins

We have maintained compatibility with the original agent's plugins. All
"old style" plugins are full usable with this new agent.

You can see more info about how to use them at
https://support.serverdensity.com/hc/en-us/articles/213074438
