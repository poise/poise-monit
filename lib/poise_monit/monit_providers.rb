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

require 'chef/platform/provider_priority_map'

require 'poise_monit/monit_providers/binaries'
require 'poise_monit/monit_providers/dummy'
require 'poise_monit/monit_providers/system'


module PoiseMonit
  # Inversion providers for the poise_monit resource.
  #
  # @since 1.0.0
  module MonitProviders
    # Set up priority maps
    Chef::Platform::ProviderPriorityMap.instance.priority(:monit, [
      PoiseMonit::MonitProviders::Dummy,
      PoiseMonit::MonitProviders::Binaries,
      PoiseMonit::MonitProviders::System,
    ])
  end
end
