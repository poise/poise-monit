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
require 'chef/resource'
require 'poise'
require 'poise_service/service_mixin'


module PoiseMonit
  module Resources
    # (see Monit::Resource)
    # @since 1.0.0
    module Monit
      # A `monit` resource to install and configure Monit.
      #
      # @provides monit
      # @action enable
      # @action disable
      # @action start
      # @action stop
      # @action restart
      # @action reload
      # @example
      #   monit 'monit'
      class Resource < Chef::Resource
        include Poise(container: true, inversion: true)
        provides(:monit)
        include PoiseService::ServiceMixin

        attribute(:httpd_port, kind_of: [String, Integer, NilClass, FalseClass], default: lazy { default_httpd_port })
        attribute(:httpd_password, kind_of: [String, NilClass, FalseClass], default: nil)
        attribute(:httpd_username, kind_of: [String, NilClass, FalseClass], default: 'cli')
        attribute(:config, option_collector: true)
        attribute(:config, template: true, default_source: 'monit.conf.erb', default_options: lazy { default_config_options })
        attribute(:group, kind_of: [String, NilClass], default: nil)
        attribute(:owner, kind_of: [String, NilClass], default: nil)
        attribute(:path, kind_of: String, default: lazy { default_path })
        attribute(:version, kind_of: [String, NilClass, FalseClass], default: nil)

        def config_path
          ::File.join(path, 'monit.conf')
        end

        def confd_path
          ::File.join(path, 'conf.d')
        end

        # The path to the `monit` binary for this Monit installation. This is
        # an output property.
        #
        # @return [String]
        # @example
        #   execute "#{resources('monit[monit]').monit_binary} start myapp"
        def monit_binary
          provider_for_action(:monit_binary).monit_binary
        end

        private

        # Default config path.
        #
        # @return [String]
        def default_path
          directory = if service_name == 'monit'
            'monit'
          else
            # If we are using a non-default service name, put that in the path.
            "monit-#{service_name}"
          end
          ::File.join('', 'etc', directory)
        end

        # Default template options for the config file.
        #
        # @return [Hash]
        def default_config_options
          {}
        end
      end

    end
  end
end
