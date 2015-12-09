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
          create_directory
          create_confd_directory
          write_config
        end
        super
      end

      # The `enable` action for the `monit` resource.
      #
      # @return [void]
      def action_disable
        super # TODO
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

      # Write the primary config file for Monit.
      def write_config
        file new_resource.config_path do
          content new_resource.config_content
          group new_resource.group
          mode '600'
          owner new_resource.owner
          verify "#{monit_binary} -t -c %{path}"
        end
      end

      # Configure properties for Monit service resource.
      def service_options(r)
        r.command("#{monit_binary} -c #{new_resource.config_path} -I")
        r.user(new_resource.owner)
      end

    end
  end
end
