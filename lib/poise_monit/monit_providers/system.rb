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

require 'chef/resource'

require 'poise_monit/error'
require 'poise_monit/monit_providers/base'


module PoiseMonit
  module MonitProviders
    # A `system` provider for `monit` to install from system packages. Uses
    # EPEL for RHEL-family platforms.
    #
    # @see PoiseMonit::Resources::PoiseMonit::Resource
    # @provides monit
    class System < Base
      provides(:system)

      # Enable by default on Debian-oids. Doesn't really matter given that
      # binaries outranks this provider.
      #
      # @api private
      def self.provides_auto?(node, _resource)
        node.platform_family?('debian', 'rhel')
      end

      # @api private
      def self.default_inversion_options(node, resource)
        {package: 'monit', no_epel: false}
      end

      # Output value for the Monit binary we are installing.
      #
      # @return [String]
      def monit_binary
        # Until I run into a counter-example, probably always true.
        '/usr/bin/monit'
      end

      private

      def install_monit
        if node.platform_family?('rhel') && !options['no_epel']
          if run_context.unreachable_cookbook?(:'yum-epel')
            raise Chef::Exceptions::RecipeNotFound.new('Could not find recipe yum-epel. Please include it either on your run list or via a metadata.rb depends to install on RHEL or CentOS')
          end
          include_recipe 'yum-epel'
        end

        # We're taking care of the init system.
        init_file = file '/etc/init.d/monit' do
          action :nothing
        end

        package options['package'] do
          notifies :delete, init_file, :immediately
          if node.platform_family?('debian')
            options '-o Dpkg::Options::=--path-exclude=/etc/*'
          end
          version new_resource.version
        end
      end

      def uninstall_monit
        package options['package'] do
          action(platform_family?('debian') ? :purge : :remove)
        end
      end

    end
  end
end
