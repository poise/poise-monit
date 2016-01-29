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


module PoiseMonit
  autoload :Error, 'poise_monit/error'
  autoload :MonitProviders, 'poise_monit/monit_providers'
  autoload :Resources, 'poise_monit/resources'
  autoload :ServiceProviders, 'poise_monit/service_providers'
  autoload :VERSION, 'poise_monit/version'
end
