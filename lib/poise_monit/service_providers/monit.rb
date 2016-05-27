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

      # Override the provides_auto? from Sysvinit. Always supported.
      def self.provides_auto?(_node, _resource)
        true
      end

      # Override the default reload action because monit_service doesn't
      # support reload itself.
      def action_reload
        return if options['never_reload']
        if running?
          converge_by("reload service #{new_resource}") do
            Process.kill(new_resource.reload_signal, pid)
            Chef::Log.info("#{new_resource} reloaded")
          end
        end
      end

      private

      def service_resource
        @service_resource ||= PoiseMonit::Resources::MonitService::Resource.new(new_resource.service_name, run_context).tap do |r|
          # Set standard resource parameters
          r.enclosing_provider = self
          r.source_line = new_resource.source_line
          # Make sure we have a parent.
          if options['parent']
            r.parent options['parent']
          else
            begin
              # Try to find a default parent, trigger an exception if not.
              r.parent
            rescue Poise::Error
              # Use the default recipe to give us a parent the next time we ask.
              include_recipe(node['poise-monit']['default_recipe'])
            end
          end
          # Set some params on the service resource.
          r.init_command(script_path)
          # Mild encapulsation break, this is an internal detail of monit_config. :-/
          r.monit_config_path(::File.join(r.parent.confd_path, "#{new_resource.service_name}.conf"))
        end
      end

      def running?
        begin
          # Check if the PID is running.
          pid && Process.kill(0, pid)
        rescue Errno::ESRCH
          false
        end
      end

      # Patch Monit behavior in to service creation.
      def create_service
        super.tap do |service_template|
          service_template.cookbook('poise-service')
          create_monit_config
        end
      end

      # Create the Monit configuration file.
      def create_monit_config
        # Scope closureeeeeee.
        _options = options
        _pid_file = pid_file
        _parent = service_resource.parent
        _script_path = script_path
        monit_config new_resource.service_name do
          if _options['monit_template']
            # If we have a template override, allow specifying a cookbook via
            # "cookbook:template".
            parts = _options['monit_template'].split(/:/, 2)
            if parts.length == 2
              source parts[1]
              cookbook parts[0]
            else
              source parts.first
              cookbook new_resource.cookbook_name.to_s
            end
          else
            source 'monit_service.conf.erb'
            cookbook 'poise-monit'
          end
          parent _parent
          variables service_resource: new_resource, options: _options, pid_file: _pid_file, script_path: _script_path
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
        _parent = service_resource.parent
        monit_config new_resource.service_name do
          action :delete
          parent _parent
        end
      end

    end
  end
end

