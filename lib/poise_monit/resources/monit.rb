#
# Copyright 2015-2016, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'securerandom'

require 'chef/provider'
require 'chef/resource'
require 'poise'
require 'poise_service/service_mixin'


module PoiseMonit
  module Resources
    # (see Monit::Resource)
    # @since 1.0.0
    module Monit
      UNIXSOCKET_VERSION = Gem::Requirement.create('>= 5.12')

      # A `monit` resource to install and configure Monit.
      #
      # @provides monit
      # @action enable
      # @action disable
      # @action start
      # @action stop
      # @action restart
      # @action reload
      # @example
      #   monit 'monit'
      class Resource < Chef::Resource
        include Poise(container: true, inversion: true)
        provides(:monit)
        include PoiseService::ServiceMixin

        # @!attribute config
        #   Template content resource for the Monit configuration file.
        attribute(:config, template: true, default_source: 'monit.conf.erb')
        # @!attribute daemon_interval
        #   Number of seconds between service checks. Defaults to 120 seconds.
        #   @return [Integer]
        attribute(:daemon_interval, kind_of: Integer, default: 120)
        # @!attribute daemon_delay
        #   Number of intervals to wait on startup before running service checks.
        #   If unset or 0, no start delay is used. Defaults to nil for backwards
        #   compat.
        #   @return [Integer, nil, false]
        attribute(:daemon_delay, kind_of: [Integer, NilClass, FalseClass], default: nil)
        # @!attribute daemon_verbose
        #   Run the daemon in verbose mode for debugging. Defaults to true if
        #   Chef is run with debug logging.
        #   @return [Boolean]
        attribute(:daemon_verbose, equal_to: [true, false], default: lazy { Chef::Log.level == :debug })
        # @!attribute event_slots
        #   Number of slots in the Monit event buffer. Set to 0 to disable
        #   event buffering, or -1 for an unlimited queue. Defaults to 100.
        #   @return [Integer]
        attribute(:event_slots, kind_of: Integer, default: 100)
        # @!attribute httpd_port
        #   Port to listen on for Monit's HTTPD. If a path is specified, it is
        #   used as a Unix socket path. If set to nil or false, no HTTPD
        #   configuration is generated. This may break some other poise-monit
        #   resources. Default is a Unix socket if the version of Monit supports
        #   it, otherwise 2812.
        #   @return [String, Integer, nil, false]
        attribute(:httpd_port, kind_of: [String, Integer, NilClass, FalseClass], default: lazy { default_httpd_port })
        # @!attribute httpd_password
        #   Cleartext password for authentication between the Monit daemon and
        #   CLI. Set to nil or false to disable authentication. Default is nil
        #   for Unix socket connections and auto-generated otherwise.
        #   @return [String, nil, false]
        attribute(:httpd_password, kind_of: [String, NilClass, FalseClass], default: lazy { default_httpd_password })
        # @!attribute httpd_username
        #   Username for authentication between the Monit daemon and CLI.
        #   Default is cli.
        #   @return [String]
        attribute(:httpd_username, kind_of: String, default: 'cli')
        # @!attribute group
        #   System group to deploy Monit as.
        #   @return [String, nil, false]
        attribute(:group, kind_of: [String, NilClass, FalseClass], default: nil)
        # @!attribute logfile
        #   Path to the Monit log file. Default is /var/log/monit.log.
        #   @return [String, nil, false]
        attribute(:logfile, kind_of: [String, NilClass, FalseClass], default: lazy { default_logfile })
        # @!attribute owner
        #   System user to deploy Monit as.
        #   @return [String, nil, false]
        attribute(:owner, kind_of: [String, NilClass, FalseClass], default: nil)
        # @!attribute path
        #   Path to the Monit configuration directory. Default is /etc/monit.
        #   @return [String]
        attribute(:path, kind_of: String, default: lazy { default_path })
        # @!attribute pidfile
        #   Path to the Monit PID file. Default is /var/run/monit.pid.
        #   @return [String]
        attribute(:pidfile, kind_of: String, default: lazy { default_pidfile })
        # @!attribute var_path
        #   Path the Monit state directory. Default is /var/lib/monit.
        #   @return [String]
        attribute(:var_path, kind_of: [String, NilClass, FalseClass], default: lazy { default_var_path })
        # @!attribute version
        #   Version of Monit to install.
        #   @return [String, nil, false]
        attribute(:version, kind_of: [String, NilClass, FalseClass], default: nil)

        # @!attribute [r] confd_path
        #   Path to the conf.d/ directory.
        #   @return [String]
        def confd_path
          ::File.join(path, 'conf.d')
        end

        # @!attribute [r] config_path
        #   Path to the Monit configuration file.
        #   @return [String]
        def config_path
          ::File.join(path, 'monitrc')
        end

        # @!attribute [r] password_path
        #   Path to the CLI password state tracking file.
        #   @return [String]
        def password_path
          ::File.join(var_path, '.cli-password')
        end

        # @!attribute [r] httpd_is_unix?
        #   Are we using a Unix socket or TCP socket for Monit's HTTPD?
        #   @return [Boolean]
        def httpd_is_unix?
          httpd_port.to_s[0] == '/'
        end

        # The path to the `monit` binary for this Monit installation. This is
        # an output property.
        #
        # @return [String]
        # @example
        #   execute "#{resources('monit[monit]').monit_binary} start myapp"
        def monit_binary
          provider_for_action(:monit_binary).monit_binary
        end

        private

        # Default HTTP port. Use a Unix socket if possible for security reasons.
        def default_httpd_port
          if monit_version && UNIXSOCKET_VERSION.satisfied_by?(monit_version)
            monit_name_path('/var/run/%{name}.sock')
          else
            2812
          end
        end

        # Default HTTP password for CLI authentication.
        #
        # @return [String]
        def default_httpd_password
          if httpd_is_unix?
            # Unix sockets have ACLs already, don't need a password.
            nil
          elsif ::File.exist?(password_path)
            # Strip is just to be safe in case a user edits the file.
            IO.read(password_path).strip
          else
            # Monit offers no protections against brute force so use a long one.
            SecureRandom.hex(64)
          end
        end

        # Default logfile path.
        #
        # @return [String]
        def default_logfile
          monit_name_path('/var/log/%{name}.log')
        end

        # Default config path.
        #
        # @return [String]
        def default_path
          monit_name_path('/etc/%{name}')
        end

        # Default pidfile path. This MUST NOT be the same as the pidfile used
        # by the sysvinit or dummy providers or monit will refuse to start. It
        # also can't be /dev/null or something tricky because the client uses it
        # to check if the daemon is running. I hate monit.
        #
        # @return [String]
        def default_pidfile
          monit_name_path('/var/run/%{name}_real.pid')
        end

        # Default var files path.
        #
        # @return [String]
        def default_var_path
          monit_name_path('/var/lib/%{name}')
        end

        # Find the version of Monit installed. Returns nil if monit is not
        # installed.
        #
        # @api private
        # @return [String, nil]
        def monit_version
          @monit_version ||= begin
            cmd = shell_out([monit_binary, '-V'])
            if !cmd.error? && /version ([0-9.]+)$/ =~ cmd.stdout
              Gem::Version.create($1)
            else
              nil
            end
          end
        end

        # Interpolate the name of this monit instance in to a path.
        #
        # @api private
        # @param path [String] A string with a %{name} template in it.
        # @return [String]
        def monit_name_path(path)
          name = if service_name == 'monit'
            'monit'
          else
            # If we are using a non-default service name, put that in the path.
            "monit-#{service_name}"
          end
          path % {name: name}
        end

      end
    end
  end
end
