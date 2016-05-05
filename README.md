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
include_recipe 'poise-monit'

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

## Recipes

* `poise-monit::default` – Install Monit.

## Attributes

* `node['poise-monit']['default_recipe']` – Recipe used by the `poise_service`
  provider to install Monit if not already available. *(default: poise-monit)*
* `node['poise-monit']['provider']` – Default provider for `monit` resource
  instances. *(default: auto)*
* `node['poise-monit']['recipe'][*]` – All subkeys of `'recipe'` will be passed
  as properties to the `monit` resource before installation.

For example, the `poise-monit` recipe can be customized by setting:

```ruby
override_attributes({
  'poise-monit' => {
    'recipe' => {
      'daemon_interval' => 60,
      'event_slots' => 0,
    }
  }
})
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
* `daemon_delay` – Number of intervals to wait on startup before running service
  checks. If unset or 0, no start delay is used. *(default: nil)*
* `daemon_verbose` – Run the daemon in verbose mode for debugging. *(default:
  log_level==debug)*
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

### `monit_check`

The `monit_check` resource writes out a Monit configuration file for a service
check. It is a subclass of `monit_config` and so inherits its actions and
properties. It defaults to being a process check.

```ruby
monit_check 'httpd' do
  check 'if failed port 80 protocol http request "/_status" then restart'
  extra [
    'every 5 cycles',
    'group www',
  ]
end
```

#### Actions

* `:create` – Create and manage the configuration file. *(default)*
* `:delete` – Delete the configuration file.

#### Properties

* `check_type` – Type of check. *(default: process)*
* `with` – WITH-ish string for this check. This is the part that goes after the
  check name. Set to false to disable. *(default: PIDFILE /var/run/check_name.pid)*
* `start_program` – Command to use to start the service for process checks. Set
  to false disable. *(default: automatic)*
* `stop_program` – Command to use to stop the service for process checks. Set
  to false disable. *(default: automatic)*
* `check` – Service health check or checks. `'IF '` will be prepended if not
  given.
* `extra` – Line or lines to be added to the service definition as is.

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

#### Provider Options

* `monit_binary` – Path to the `monit` executable. *(default: /usr/bin/monit)*

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

The service provider has two node attributes that can used for global tuning:

* `node['poise-monit']['monit_service_timeout']` – Seconds before timeout when
  registering a new service with Monit. *(default: 20)*
* `node['poise-monit']['monit_service_wait']` – Seconds to wait between attempts
  when registering a new service with Monit. *(default: 1)*

### Options

* `pid_file` – Path to PID file that the service command will create.
* `pid_file_external` – If true, assume the service will create the PID file
  itself. *(default: true if `pid_file` option is set)*
* `template` – Override the default script template. If you want to use a
  template in a different cookbook use `'cookbook:template'`.
* `monit_template` – Override the default monit template. If you want to use a
  template in a different cookbook use `'cookbook:template'`.
* `command` – Override the service command.
* `directory` – Override the service directory.
* `environment` – Override the service environment variables.
* `reload_signal` – Override the service reload signal.
* `stop_signal` – Override the service stop signal.
* `user` – Override the service user.
* `never_restart` – Never try to restart the service.
* `never_reload` – Never try to reload the service.
* `script_path` – Override the path to the generated service script.
* `parent` – Override the auto-detection of which `monit` resource to use.

## Upgrading From `monit`

Upgrading from the older [`monit` cookbook](https://github.com/poise/poise-monit-compat)
is relatively straightforward. The `node['monit']` attributes can either be
converted to `node['poise-monit']['recipe']` if you want to use the default
recipe, or you can invoke the `monit` resource in your own recipe code if needed.

When switching cookbooks in-place on a server, make sure you check for any
`conf.d/` config files created by the old cookbook. Notably `conf.d/compat.conf`
may interfere with the configuration generation. You can remove it:

```ruby
monit_config 'compat' do
  action :delete
end
```

## Sponsors

Development sponsored by [Bloomberg](http://www.bloomberg.com/company/technology/).

The Poise test server infrastructure is sponsored by [Rackspace](https://rackspace.com/).

## License

Copyright 2015-2016, Noah Kantrowitz

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
