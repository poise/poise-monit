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

require 'chef/resource'

require 'poise_monit/error'
require 'poise_monit/monit_providers/base'


module PoiseMonit
  module MonitProviders
    class System < Base
      provides(:system)

      # Enable by default on Debian-oids.
      #
      # @api private
      def self.provides_auto?(node, _resource)
        node.platform_family?('debian', 'rhel')
      end

      # Output value for the Monit binary we are installing.
      #
      # @return [String]
      def monit_binary
        # Until I run into a counter example, probably always true.
        '/usr/bin/monit'
      end

      private

      def install_monit
        include_recipe 'yum-epel' if node.platform_family?('rhel')

        # We're taking care of the init system.
        init_file = file '/etc/init.d/monit' do
          action :nothing
        end

        package 'monit' do
          notifies :delete, init_file, :immediately
          version new_resource.version
        end
      end

      def uninstall_monit
        package 'monit' do
          action(platform_family?('debian') ? :purge : :remove)
        end
      end

    end
  end
end
