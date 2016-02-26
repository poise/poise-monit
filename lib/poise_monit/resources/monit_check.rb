#
# Copyright 2016, Noah Kantrowitz
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

require 'poise_languages/utils'
require 'poise_monit/resources/monit_config'


module PoiseMonit
  module Resources
    # (see MonitCheck::Resource)
    # @since 1.2.0
    module MonitCheck
      # A `monit_check` resource to write out a Monit configuration file with a
      # service check.
      #
      # @provides monit_check
      # @action create
      # @action delete
      # @example
      #   monit_check 'httpd' do
      #     check 'if failed port 80 protocol http request "/_status" then restart'
      #   end
      class Resource < MonitConfig::Resource
        provides(:monit_check)

        attribute('', template: true, default_source: 'monit_check.conf.erb')
        # @!attribute check_type
        #   Type of check. Not making this an explicit array to allow for new
        #   check types in Monit without a cookbook release.
        #   @return [String]
        attribute(:check_type, kind_of: String, default: 'process')
        # @!attribute with
        #   WITH-ish string for this check. This is the part that goes after the
        #   check name. Set to false to disable. Defaults to an automatic PID
        #   file for process checks and disabled for others.
        #   @return [String, nil, false]
        #   @example Process check
        #     monit_check 'httpd' do
        #        with 'PIDFILE /var/run/apache2.pid'
        #     end
        #   @example File check
        #     monit_check 'httpd_log' do
        #       check_type 'file'
        #       with 'PATH /var/log/apache2/error.log'
        #     end
        attribute(:with, kind_of: [String, NilClass, FalseClass], default: lazy { default_with })
        # @!attribute start_program
        #   Command to use to start the service for process checks. Set to false
        #   to disable. Defaults to an auto-detect using `systemctl`, `service`
        #   or `/etc/init.d/$name`.
        #   @return [String, nil, false]
        attribute(:start_program, kind_of: [String, NilClass, FalseClass], default: lazy { default_start_program })
        # @!attribute stop_program
        #   Command to use to stop the service for process checks. Set to false
        #   to disable. Defaults to an auto-detect using `systemctl`, `service`
        #   or `/etc/init.d/$name`.
        #   @return [String, nil, false]
        attribute(:stop_program, kind_of: [String, NilClass, FalseClass], default: lazy { default_stop_program })
        # @!attribute check
        #   Service health check or checks. `'IF '` will be prepended if not
        #   given.
        #   @return [String, Array<String>]
        attribute(:check, kind_of: [String, Array], default: [])
        # @!attribute extra
        #   Line or lines to be added to the service definition as is.
        #   @return [String, Array<String>]
        attribute(:extra, kind_of: [String, Array], default: [])

        # An alias for #check_name to make things more semantically meaningful.
        alias_method :check_name, :config_name

        # An alias for #if_ to allow writing things like look more like Monit
        # configuration files. This can't be `if` because that's a keyword.
        #
        # @example
        #   monit_check 'httpd' do
        #     if_ 'failed port 80 protocol http request "/_status" then restart'
        #   end
        alias_method :if_, :check

        private

        # Default WITH-ish value.
        #
        # @return [String]
        def default_with
          _if_process("PIDFILE /var/run/#{check_name}.pid")
        end

        # Default start program value.
        #
        # @return [String]
        def default_start_program
          _init_command('start')
        end

        # Default stop program value.
        #
        # @return [String]
        def default_stop_program
          _init_command('stop')
        end

        # Helper for default values that only apply to process checks.
        #
        # @param value [Object] Value to return for process checks.
        # @return [Object, nil]
        def _if_process(value)
          if check_type.to_s.downcase == 'process'
            value
          else
            nil
          end
        end

        # Find the right command to control the init system. This checks
        # systemctl, service, and then gives up and uses /etc/init.d.
        #
        # @param action [String] Init action to run.
        # @return [String, nil]
        def _init_command(action)
          cmd = if systemctl = PoiseLanguages::Utils.which('systemctl')
            "#{systemctl} #{action} #{check_name}"
          elsif service = PoiseLanguages::Utils.which('service')
            "#{service} #{check_name} #{action}"
          else
            # ¯\_(ツ)_/¯
            "/etc/init.d/#{check_name} #{action}"
          end
          _if_process(cmd)
        end
      end

      # The provider for `monit_check`.
      #
      # @see Resource
      # @provides monit_check
      class Provider < MonitConfig::Provider
        provides(:monit_check)

        # This space left intentionally blank. All behaviors are in the base.
      end
    end
  end
end
