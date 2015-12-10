#
# Copyright 2015, Noah Kantrowitz
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

        attribute(:config, template: true, default_source: 'monit.conf.erb')
        attribute(:daemon_interval, kind_of: Integer, default: 120)
        attribute(:event_slots, kind_of: Integer, default: 100)
        attribute(:httpd_port, kind_of: [String, Integer, NilClass, FalseClass], default: lazy { default_httpd_port })
        attribute(:httpd_password, kind_of: [String, NilClass, FalseClass], default: lazy { default_httpd_password })
        attribute(:httpd_username, kind_of: [String, NilClass, FalseClass], default: 'cli')
        attribute(:group, kind_of: [String, NilClass, FalseClass], default: nil)
        attribute(:logfile, kind_of: [String, NilClass, FalseClass], default: '/var/log/monit.')
        attribute(:owner, kind_of: [String, NilClass, FalseClass], default: nil)
        attribute(:path, kind_of: String, default: lazy { default_path })
        attribute(:pidfile, kind_of: String, default: lazy { default_pidfile })
        attribute(:var_path, kind_of: String, default: lazy { default_var_path })
        attribute(:version, kind_of: [String, NilClass, FalseClass], default: nil)

        # @!attribute [r] Path to the conf.d/ directory.
        def confd_path
          ::File.join(path, 'conf.d')
        end

        def config_path
          ::File.join(path, 'monitrc')
        end

        def password_path
          ::File.join(path, '.cli-password')
        end

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
