
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

require 'poise_languages/static'

require 'poise_monit/monit_providers/binaries'


module PoiseMonit
  module MonitProviders
    class BinariesBitBucket < Binaries
      provides(:binaries_bitbucket)
      include PoiseLanguages::Static(
        name: superclass.static_name,
        versions: %w{5.15 5.14},
        machines: superclass.static_machines,
        url: 'https://bitbucket.org/tildeslash/monit/downloads/monit-%{version}-%{machine_label}.tar.gz',
      )

      # We don't want the name dispatch behavior here, just version filtering.
      #
      # @api private
      def self.provides_auto?(node, resource)
        (!resource.version || static_versions.any? {|ver| ver.start_with?(resource.version) } ) && static_machines.include?(static_machine_label(node))
      end
    end
  end
end


