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

require 'poise_service/service_providers/sysvinit'


module PoiseMonit
  module ServiceProviders
    # A `monit` provider for `poise_service`. This uses the sysvinit code to
    # generate the underlying service script, but Monit to manage the service
    # runtime.
    #
    # @since 1.0.0
    # @provides monit
    class Monit < PoiseService::ServiceProviders::Sysvinit
      provides(:monit)

      def action_start
      end

      def action_stop
      end

      def action_restart
      end

      def action_reload
      end

      private

      # Patch Monit behavior in to service creation.
      def create_service
        super
        create_monit_config
      end

      # Create the Monit configuration file.
      def create_monit_config
        # Scope closureeeeeee.
        _options = options
        _pid_file = pid_file
        monit_config new_resource.service_name do
          template 'monit_service.conf.erb'
          options service_resource: new_resource, options: _options, pid_file: _pid_file
          # Don't trigger a restart if the template doesn't already exist, this
          # prevents restarting on the run that first creates the service.
          restart_on_update = _options.fetch('restart_on_update', new_resource.restart_on_update)
          if restart_on_update && ::File.exist?(path) # Path here is accessing MonitConfig::Resource#path.
            mode = restart_on_update.to_s == 'immediately' ? :immediately : :delayed
            notifies :restart, new_resource, mode
          end
        end
      end

      # Patch Monit behavior in to service teardown.
      def destroy_service
        delete_monit_config
        super
      end

      # Delete the Monit configuration file.
      def delete_monit_config
        create_monit_config.tap do |r|
          r.action(:delete)
        end
      end

      # This space left intentionally blank.
      def enable_service
      end

      # This space left intentionally blank.
      def disable_service
      end

      # Find the parent `monit` resource, creating it if needed.
      #
      # @api private
      # @return [PoiseMonit]
      # def monit_parent
      #   @monit_parent ||= begin

    end
  end
end

