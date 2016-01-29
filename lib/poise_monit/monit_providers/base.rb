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

require 'chef/provider'
require 'poise'
require 'poise_service/service_mixin'


module PoiseMonit
  module MonitProviders
    # The provider base class for `monit`.
    #
    # @see PoiseMonit::Resources::PoiseMonit::Resource
    # @provides monit
    class Base < Chef::Provider
      include Poise(inversion: :monit)
      include PoiseService::ServiceMixin

      # The `enable` action for the `monit` resource.
      #
      # @return [void]
      def action_enable
        notifying_block do
          install_monit
        end
        # Split into two converges because we need to know what version is
        # installed to write the config in some cases.
        notifying_block do
          create_directory
          create_confd_directory
          create_var_directory
          create_events_directory
          # Only write out a state if we are actually going to use it.
          write_password_state if new_resource.httpd_port && new_resource.httpd_password
          write_config
        end
        super
      end

      # The `enable` action for the `monit` resource.
      #
      # @return [void]
      def action_disable
        super
        notifying_block do
          uninstall_monit
          delete_directory
          delete_var_directory
        end
      end

      # Return the path to the Monit binary. Must be implemented by subclasses.
      #
      # @abstract
      # @return [String]
      def monit_binary
        raise NotImplementedError
      end

      private

      # Install Monit. Must be implemented by subclasses.
      #
      # @abstract
      def install_monit
        raise NotImplementedError
      end

      # Uninstall Monit. Must be implemented by subclasses.
      #
      # @abstract
      def uninstall_monit
        raise NotImplementedError
      end

      # Create the configuration directory for Monit.
      def create_directory
        directory new_resource.path do
          group new_resource.group
          mode '700'
          owner new_resource.owner
        end
      end

      # Create the conf.d/ directory for Monit.
      def create_confd_directory
        directory new_resource.confd_path do
          group new_resource.group
          mode '700'
          owner new_resource.owner
        end
      end

      # Create the /var/lib directory. This is used for the idfile, statefile,
      # and events buffer.
      def create_var_directory
        directory new_resource.var_path do
          group new_resource.group
          mode '700'
          owner new_resource.owner
        end
      end

      # Create the events buffer directory.
      def create_events_directory
        directory ::File.join(new_resource.var_path, 'events') do
          group new_resource.group
          mode '700'
          owner new_resource.owner
        end
      end

      # Record the password for next time do we don't regenerate the config.
      def write_password_state
        file new_resource.password_path do
          content new_resource.httpd_password
          group new_resource.group
          mode '600'
          owner new_resource.owner
        end
      end

      # Write the primary config file for Monit.
      def write_config
        file new_resource.config_path do
          content new_resource.config_content
          group new_resource.group
          mode '600'
          notifies :reload, new_resource, :immediately
          owner new_resource.owner
          verify "#{monit_binary} -t -c #{Poise::Backports::VERIFY_PATH}" if defined?(verify)
        end
      end

      # Delete the configuration directory for Monit.
      def delete_directory
        create_directory.tap do |r|
          r.action(:delete)
          r.recursive(true)
        end
      end

      # Delete the state directory for Monit.
      def delete_var_directory
        create_var_directory.tap do |r|
          r.action(:delete)
          r.recursive(true)
        end
      end

      # Configure properties for Monit service resource.
      def service_options(r)
        cmd = "#{monit_binary} -c #{new_resource.config_path} -I"
        cmd << " -d #{new_resource.daemon_interval}" unless new_resource.daemon_delay
        cmd << ' -v' if new_resource.daemon_verbose
        r.command(cmd)
        r.provider_no_auto('monit')
        r.user(new_resource.owner)
      end

    end
  end
end
