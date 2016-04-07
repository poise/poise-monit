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

# Seconds before timeout when registering a new service with Monit.
default['poise-monit']['monit_service_timeout'] = 20
# Seconds to wait between attempts when registering a new service with Monit.
default['poise-monit']['monit_service_wait'] = 1

# Recipe to include when a parent is needed for poise_service.
default['poise-monit']['default_recipe'] = 'poise-monit'

# Default inversion options.
default['poise-monit']['provider'] = 'auto'
default['poise-monit']['options'] = {}

# Attributes for recipe[poise-monit]. All values are nil because the actual
# defaults live in the resource.
default['poise-monit']['recipe']['daemon_interval'] = nil
default['poise-monit']['recipe']['daemon_delay'] = nil
default['poise-monit']['recipe']['daemon_verbose'] = nil
default['poise-monit']['recipe']['event_slots'] = nil
default['poise-monit']['recipe']['httpd_port'] = nil
default['poise-monit']['recipe']['httpd_password'] = nil
default['poise-monit']['recipe']['httpd_username'] = nil
default['poise-monit']['recipe']['group'] = nil
default['poise-monit']['recipe']['logfile'] = nil
default['poise-monit']['recipe']['owner'] = nil
default['poise-monit']['recipe']['path'] = nil
default['poise-monit']['recipe']['pidfile'] = nil
default['poise-monit']['recipe']['var_path'] = nil
default['poise-monit']['recipe']['version'] = nil
