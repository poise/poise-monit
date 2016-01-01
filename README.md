# Poise-Monit Cookbook

[![Build Status](https://img.shields.io/travis/poise/poise-monit.svg)](https://travis-ci.org/poise/poise-monit)
[![Gem Version](https://img.shields.io/gem/v/poise-monit.svg)](https://rubygems.org/gems/poise-monit)
[![Cookbook Version](https://img.shields.io/cookbook/v/poise-monit.svg)](https://supermarket.chef.io/cookbooks/poise-monit)
[![Coverage](https://img.shields.io/codecov/c/github/poise/poise-monit.svg)](https://codecov.io/github/poise/poise-monit)
[![Gemnasium](https://img.shields.io/gemnasium/poise/poise-monit.svg)](https://gemnasium.com/poise/poise-monit)
[![License](https://img.shields.io/badge/license-Apache_2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

A [Chef](https://www.chef.io/) cookbook to manage [Monit](https://mmonit.com/monit/).

## Quick Start

To install Monit and configure a mail server:

```ruby
include_recipe 'monit'

monit_config 'mailconfig' do
  content <<-EOH
SET MAILSERVER mail.example.com
SET ALERT devoops@example.com
EOH
end
```

To create a service managed by Monit with a health check:

```ruby
poise_service 'apache2' do
  command '/usr/sbin/apache2 -f /etc/apache2/apache2.conf -DFOREGROUND'
  stop_signal 'WINCH'
  reload_signal 'USR1'
  provider :monit
  options :monit, checks: 'if failed host localhost port 80 protocol HTTP request "/" then restart'
end
```

## Resources

### `monit`

The `monit` resource installs and configures Monit.

```ruby
monit 'monit' do
  daemon_interval 60
  event_slots 1000
end
```

#### Actions

* `:enable` – Install, enable and start Monit. *(default)*
* `:disable` – Stop, disable, and uninstall Monit.
* `:start` – Start Monit.
* `:stop` – Stop Monit.
* `:restart` – Stop and then start Monit.
* `:reload` – Send SIGHUP signal to Monit.

#### Properties

* `service_name` – Name of the Monit instance. *(name attribute)*
* `daemon_interval` – Number of seconds between service checks. *(default: 120)*
* `event_slots` – Number of slots in the Monit event buffer. Set to 0 to disable
  event buffering, or -1 for an unlimited queue. *(default: 100)*
* `httpd_port` – Port to listen on for Monit's HTTPD. If a path is specified, it
  is used as a Unix socket path. If set to nil or false, no HTTPD configuration
  is generated. This may break some other poise-monit resources. *(default:
  /var/run/monit.sock if the version of Monit supports it, otherwise 2812)*
* `httpd_password` – Cleartext password for authentication between the Monit
  daemon and CLI. Set to nil or false to disable authentication. *(default: nil
  for Unix socket connections, otherwise auto-generated)*
* `httpd_username` – Username for authentication between the Monit daemon and
  CLI. *(default: cli)*
* `group` – System group to deploy Monit as.
* `logfile` – Path to the Monit log file. *(default: /var/log/monit.log)*
* `owner` – System user to deploy Monit as.
* `path` – Path to the Monit configuration directory. *(default: /etc/monit)*
* `pidfile` – Path to the Monit PID file. *(default: /var/run/monit.pid)*
* `var_path` – Path the Monit state directory. *(default: /var/lib/monit)*
* `version` – Version of Monit to install.

#### Provider Options

The `monit` resource uses provide options for per-provider configuration. See
[the poise-service documentation](https://github.com/poise/poise-service#service-options)
for more information on using provider options.

### `monit_config`

The `monit_config` resource writes out a Monit configuration file to the
`conf.d/` directory.

```ruby
monit_config 'ssh' do
  source 'monit_ssh.conf.erb'
  variables threshold: 5
end
```

#### Actions

* `:create` – Create and manage the configuration file. *(default)*
* `:delete` – Delete the configuration file.

#### Properties

* `config_name` – Name of the configuration file. *(name attribute)*
* `content` – File content to write.
* `cookbook` – Cookbook to search for `source` in.
* `parent` – Name or reference for the parent `monit` resource. *(required, default: automatic)*
* `path` – Path to the configuration file. *(default: automatic)*
* `source` – Template path to render.
* `variables` – Template variables.

One of `source` or `content` is required.

## Monit Providers

### `binaries`

The `binaries_bitbucket` provider supports installing Monit from static binaries
mirrored to BitBucket. This is the default provider if you are installing on an
OS that has binaries available.

```ruby
monit 'monit' do
  provider :binaries
end
```

*NOTE:* If BitBucket is unavailable you can set the `url` provider option to
`https://mmonit.com/monit/dist/binary/%{version}/monit-%{version}-%{machine_label}.tar.gz`
to use downloads directly from `mmonit.com`, however this server has a relatively
strict download quota system so this is not recommended.

#### Provider Options

* `path` – Path to install Monit to. *(default: /opt/monit-<version>)*
* `retries` – Number of times to retry failed downloads. *(default: 5)*
* `static_version` – Full version number for use in interpolation. *(default: automatic)*
* `strip_components` – Value to pass to tar --strip-components. *(default: 1)*
* `url` – URL template to download from. *(default: `https://bitbucket.org/tildeslash/monit/downloads/monit-%{version}-%{machine_label}.tar.gz`)*

### `system`

The `system` provider supports installing Monit from system packages. This
requires EPEL for RHEL/CentOS as they do not ship Monit in the base OS
repositories. Because this is not a default provider, EPEL is *not* a dependency
of this cookbook, you will have to add it to your run list or as a dependency of
a wrapper cookbook.

```ruby
monit 'monit' do
  provider :system
end
```

#### Provider Options

* `no_epel` – Do not try to enable EPEL on EL nodes. *(default: false)*
* `package` – Package name to install. *(default: monit)*

### `dummy`

The `dummy` provider supports using the `monit` resource with ChefSpec or other
testing frameworks to not actually install Monit. It is used by default under
ChefSpec.

```ruby
monit 'monit' do
  provider :dummy
end
```

## Service Provider

The `monit` service provider is included to allow [`poise_service` resources](https://github.com/poise/poise-service)
to use Monit as the service manager. This uses the normal `sysvinit` provider
from `poise-service` to generate the init scripts, but manages service state
through Monit.

```ruby
poise_service 'apache2' do
  command '/usr/sbin/apache2 -f /etc/apache2/apache2.conf -DFOREGROUND'
  stop_signal 'WINCH'
  reload_signal 'USR1'
  provider :monit
  options :monit, checks: 'if failed host localhost port 80 protocol HTTP request "/" then restart'
end
```

To set the `monit` provider as the global default, use [`poise-sevice-monit`](https://github.com/poise/poise-service-monit).

## Sponsors

Development sponsored by [Bloomberg](http://www.bloomberg.com/company/technology/).

The Poise test server infrastructure is sponsored by [Rackspace](https://rackspace.com/).

## License

Copyright 2015, Noah Kantrowitz

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
