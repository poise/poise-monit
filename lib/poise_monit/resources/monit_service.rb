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

require 'chef/resource/service'
require 'chef/provider/service'
require 'poise'


module PoiseMonit
  module Resources
    # (see MonitService::Resource)
    # @since 1.0.0
    module MonitService
      # Values from `monit status` that mean the service is disabled.
      DISABLED_STATUSES = Set.new(['Not monitored', 'Initializing'])
      # Values from `monit status` that mean the service is running.
      RUNNING_STATUSES = Set.new(['Accessible', 'Running', 'Online with all services', 'Status ok', 'UP'])

      # A `monit_service` resource to control Monit-based services.
      #
      # @provides monit_service
      # @action enable
      # @action disable
      # @action start
      # @action stop
      # @action restart
      # @example
      #   monit_service 'httpd'
      class Resource < Chef::Resource::Service
        include Poise(parent: :monit)
        provides(:monit_service)
        actions(:enable, :disable, :start, :stop, :restart)

        attribute(:monit_config_path, kind_of: [String, NilClass, FalseClass])

        # Unsupported properties.
        %w{pattern reload_command priority timeout parameters run_levels}.each do |name|
          define_method(name) do |*args|
            raise NoMethodError.new("Property #{name} is not supported on monit_service")
          end
        end

        # Lie about supports.
        # @api private
        def supports(arg={})
          {restart: true, reload: true}
        end
      end

      # The provider for `monit_service`.
      #
      # @see Resource
      # @provides monit_service
      class Provider < Chef::Provider::Service
        include Poise
        provides(:monit_service)

        def load_current_resource
          super
          @current_resource = MonitService::Resource.new(new_resource.name).tap do |r|
            r.service_name(new_resource.service_name)
            if new_resource.monit_config_path && !::File.exist?(new_resource.monit_config_path)
              Chef::Log.debug("[#{new_resource}] Config file #{new_resource.monit_config_path} does not exist, not checking status")
              r.enabled(false)
              r.running(false)
            else
              Chef::Log.debug("[#{new_resource}] Checking status for #{new_resource.service_name}")
              status = /^\s*status\s+(\w+)$/ =~ monit_shell_out!('status', wait_for_output: 'Process').stdout && $1
              Chef::Log.debug("[#{new_resource}] Status is #{status.inspect}")
              if DISABLED_STATUSES.include?(status)
                r.enabled(false)
                # It could be running, but we don't know.
                r.running(false)
              elsif RUNNING_STATUSES.include?(status)
                r.enabled(true)
                r.running(true)
              else
                r.enabled(true)
                r.running(false)
              end
            end
          end
        end

        private

        def enable_service
          monit_shell_out!('monitor')
        end

        def disable_service
          if new_resource.monit_config_path && !::File.exist?(new_resource.monit_config_path)
            Chef::Log.debug("[#{new_resource}] Config file #{new_resource.monit_config_path} does not exist, not trying to unmonitor")
            return
          end
          monit_shell_out!('unmonitor', allowed_fail: 'There is no service')
        end

        def start_service
          monit_shell_out!('start')
        end

        def stop_service
          if new_resource.monit_config_path && !::File.exist?(new_resource.monit_config_path)
            Chef::Log.debug("[#{new_resource}] Config file #{new_resource.monit_config_path} does not exist, not trying to stop")
            return
          end
          monit_shell_out!('stop', allowed_fail: 'There is no service')
        end

        def restart_service
          monit_shell_out!('restart')
        end

        def monit_shell_out!(monit_cmd, timeout: 20, wait: 1, wait_for_output: nil, allowed_fail: nil)
          while true
            cmd = shell_out([new_resource.parent.monit_binary, '-c', new_resource.parent.config_path, monit_cmd, new_resource.service_name])
            # Check if we had an error, but allow errors with specific strings
            # if one was requested. Then check if we had the required output.
            # Yes this could be one big conditional, but it looks gross.
            error = if cmd.error?
              if allowed_fail && (cmd.stdout.include?(allowed_fail) || cmd.stderr.include?(allowed_fail))
                false # Allowed failure
              else
                true # Normal failure
              end
            elsif wait_for_output && !(cmd.stdout.include?(wait_for_output) || cmd.stderr.include?(wait_for_output))
              true # Didn't have requested output
            else
              false
            end
            # If there was an error, sleep and try again.
            if error
              # We fell off the end of the timeout, doneburger.
              if timeout <= 0
                # If there was a run error, raise that first.
                cmd.error!
                # Otherwise we just didn't have the requested output, which is fine.
                break
              end
              # Wait and try again.
              Chef::Log.debug("[#{new_resource}] Failure running `monit #{monit_cmd}`, retrying in #{wait}")
              timeout -= Kernel.sleep(wait)
            else
              # All's quiet on the western front.
              break
            end
          end
          cmd
        end

      end
    end
  end
end
