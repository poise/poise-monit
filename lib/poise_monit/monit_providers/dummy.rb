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

require 'poise_service/service_providers/dummy'

require 'poise_monit/monit_providers/base'


module PoiseMonit
  module MonitProviders
    class Dummy < Base
      provides(:dummy)

      # Manual overrides for dummy data.
      #
      # @api private
      def self.default_inversion_options(node, resource)
        super.merge({
          monit_binary: '/usr/bin/monit',
        })
      end

      # Enable by default on ChefSpec.
      #
      # @api private
      def self.provides_auto?(node, _resource)
        node.platform?('chefspec')
      end

      # Output value for the Monit binary we are installing.
      #
      # @return [String]
      def monit_binary
        options['monit_binary']
      end

      private

      def install_monit
      end

      def uninstall_monit
      end

      def service_options(r)
        super
        r.provider(:dummy)
      end

    end
  end
end
