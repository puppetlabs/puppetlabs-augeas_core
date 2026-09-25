
# augeas_core

[![Modules Status](https://github.com/puppetlabs/puppetlabs-augeas_core/workflows/%5BDaily%5D%20Unit%20Tests%20with%20nightly%20Puppet%20gem/badge.svg?branch=main)](https://github.com/puppetlabs/puppetlabs-augeas_core/actions)
[![Modules Status](https://github.com/puppetlabs/puppetlabs-augeas_core/workflows/Static%20Code%20Analysis/badge.svg?branch=main)](https://github.com/puppetlabs/puppetlabs-augeas_core/actions) 
[![Modules Status](https://github.com/puppetlabs/puppetlabs-augeas_core/workflows/Unit%20Tests%20with%20nightly%20Puppet%20gem/badge.svg?branch=main)](https://github.com/puppetlabs/puppetlabs-augeas_core/actions) 
[![Modules Status](https://github.com/puppetlabs/puppetlabs-augeas_core/workflows/Unit%20Tests%20with%20released%20Puppet%20gem/badge.svg?branch=main)](https://github.com/puppetlabs/puppetlabs-augeas_core/actions)


#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with augeas_core](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with augeas_core](#beginning-with-augeas)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

<a id="description"></a>
## Description

The `augeas_core` module is used to manage configuration files using Augeas. This module is suitable for any host for which there are Augeas libraries and ruby bindings.

<a id="setup"></a>
## Setup

<a id="setup-requirements"></a>
### Setup Requirements

The augeas libraries and ruby bindings must be installed in order to use this module. If you are using `puppet-agent` packages, then those prerequisites are already satisfied for most platforms.

<a id="beginning-with-augeas"></a>
### Beginning with augeas_core

To manage a configuration file using `augeas`, use the following code:

```
augeas { 'add_services_entry':
  context => '/files/etc/services',
  incl    => '/etc/services',
  lens    => 'Services.lns',
  changes => [
    'ins service-name after service-name[last()]',
    'set service-name[last()] "Doom"',
    'set service-name[. = "Doom"]/port "666"',
    'set service-name[. = "Doom"]/protocol "udp"'
  ]
}
```

<a id="usage"></a>
## Usage

Please see REFERENCE.md for the reference documentation and [examples](https://puppet.com/docs/puppet/latest/resources_augeas.html) for details on usage.

### Apply changes only on refresh

Set `refreshonly => true` to apply changes only when a resource sends a refresh event using `~>`, `notify`, or `subscribe`.
Ordering with `->` or `require` does not send an event.
The default is `false`; `onlyif` still applies on refresh, and `force` does not override `refreshonly` or `onlyif`.

This example uses a dedicated temporary directory and a sample services file, leaving `/etc/services` untouched.
Create the directory with `mktemp -d /tmp/augeas-refreshonly.XXXXXX` and replace the path below with its output.

```puppet
$demo_dir = '/tmp/augeas-refreshonly.REPLACE_ME'

# Seed the sample once; do not reset its content on subsequent runs.
file { "${demo_dir}/services":
  ensure  => file,
  content => "ssh 22/tcp\n",
  replace => false,
}

file { "${demo_dir}/trigger":
  content => 'bar',
} ~>
augeas { 'add_services_entry_on_refresh':
  incl        => "${demo_dir}/services",
  lens        => 'Services.lns',
  changes     => [
    'ins service-name after service-name[last()]',
    'set service-name[last()] "Doom"',
    'set service-name[last()]/port "666"',
    'set service-name[last()]/protocol "udp"',
  ],
  refreshonly => true,
  require     => File["${demo_dir}/services"],
}
```

The first run creates the trigger file and inserts one entry.
The second run leaves the trigger unchanged, sends no event, and makes no Augeas changes.
Changing the trigger's desired content sends a new event and inserts another entry.
This example deliberately uses a non-idempotent insertion to demonstrate that `refreshonly` controls execution.

<a id="reference"></a>
## Reference

Please see REFERENCE.md for the reference documentation.

This module is documented using Puppet Strings.

For a quick primer on how Strings works, please see [this blog post](https://puppet.com/blog/using-puppet-strings-generate-great-documentation-puppet-modules) or the [README.md](https://github.com/puppetlabs/puppet-strings/blob/master/README.md) for Puppet Strings.

To generate documentation locally, run the following command:
```
bundle install
bundle exec puppet strings generate ./lib/**/*.rb
```
This command will create a browsable `_index.html` file in the `doc` directory. The references available here are all generated from YARD-style comments embedded in the code base. When any development happens on this module, the impacted documentation should also be updated.

<a id="limitations"></a>
## Limitations

This module is only available on platforms that have augeas libraries and ruby bindings installed.

<a id="development"></a>
## Development

Puppet Labs modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. We can't access the huge number of platforms and myriad of hardware, software, and deployment configurations that Puppet is intended to serve.

We want to keep it as easy as possible to contribute changes so that our modules work in your environment. There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

For more information, see our [module contribution guide.](https://puppet.com/docs/puppet/latest/contributing.html)
