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
      DISABLED_STATUSES = /^Not monitored$/
      # Values from `monit status` that mean the service is running.
      RUNNING_STATUSES = /^(Accessible|Running|Online with all services|Status ok|UP)$/
      # Value from monit action subcommands that mean the service doesn't exist.
      NO_SERVICE_ERROR = /There is no service/

      # Default time to wait for a monit command to succeed.
      DEFAULT_TIMEOUT = 20
      # Default time to sleep between tries.
      DEFAULT_WAIT = 1

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
          {restart: true}
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
              status = find_monit_status
              Chef::Log.debug("[#{new_resource}] Status is #{status.inspect}")
              case status
              when nil, false
                # Unable to find a status at all.
                r.enabled(false)
                r.running(false)
              when /^Does not exist/
                # It is monitored but we don't know the status yet, assume the
                # worst (run start and stop always).
                r.enabled(true)
                r.running(self.action != :start)
              when DISABLED_STATUSES
                r.enabled(false)
                # It could be running, but we don't know.
                r.running(false)
              when RUNNING_STATUSES
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
          monit_shell_out!('unmonitor') do |cmd|
            # Command fails if it has an error and does not include the service
            # error message.
            cmd.error? && cmd.stdout !~ NO_SERVICE_ERROR && cmd.stderr !~ NO_SERVICE_ERROR
          end
        end

        def start_service
          monit_shell_out!('start')
        end

        def stop_service
          if new_resource.monit_config_path && !::File.exist?(new_resource.monit_config_path)
            Chef::Log.debug("[#{new_resource}] Config file #{new_resource.monit_config_path} does not exist, not trying to stop")
            return
          end
          monit_shell_out!('stop') do |cmd|
            # Command fails if it has an error and does not include the service
            # error message. Then check that it is really stopped.
            cmd.error? && cmd.stdout !~ NO_SERVICE_ERROR && cmd.stderr !~ NO_SERVICE_ERROR
          end
        end

        def restart_service
          monit_shell_out!('restart')
        end

        def find_monit_status
          re = /^Process '#{new_resource.service_name}'\s+status\s+(\w.+)$/
          status_cmd = monit_shell_out!('status') do |cmd|
            # Command fails if it has an error, does't have Process line, or
            # does have Initializing.
            cmd.error? || cmd.stdout !~ re || cmd.stdout =~ /Initializing/
          end
          status_cmd.stdout =~ re && $1
        end

        def monit_shell_out!(monit_cmd, timeout: DEFAULT_TIMEOUT, wait: DEFAULT_WAIT, &block)
          while true
            cmd_args = [new_resource.parent.monit_binary, '-c', new_resource.parent.config_path, monit_cmd, new_resource.service_name]
            Chef::Log.debug("[#{new_resource}] Running #{cmd_args.join(' ')}")
            cmd = poise_shell_out(cmd_args, user: new_resource.parent.owner, group: new_resource.parent.group)
            error = block ? block.call(cmd) : cmd.error?
            # If there was an error (or error-like output), sleep and try again.
            if error
              # We fell off the end of the timeout, doneburger.
              if timeout <= 0
                Chef::Log.debug("[#{new_resource}] Timeout while running `monit #{monit_cmd}`")
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
