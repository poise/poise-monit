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
require 'chef/provider'
require 'poise'


module PoiseMonit
  module Resources
    # (see MonitConfig::Resource)
    # @since 1.0.0
    module MonitConfig
      # A `monit_config` resource to write out a Monit configuration file.
      #
      # @provides monit_config
      # @action create
      # @action delete
      # @example
      #   monit_config 'httpd'
      class Resource < Chef::Resource
        include Poise(parent: :monit)
        provides(:monit_config)
        actions(:create, :delete)

        attribute('', template: true, required: true)
        # @attribute config_name
        #   Name of the configuration file. Default value is the name of the
        #   resource.
        #   @return [String]
        attribute(:config_name, kind_of: String, name_attribute: true)
        # @attribute path
        #   Path to the configuration file. Default is auto-generated.
        #   @return [String]
        attribute(:path, kind_of: String, default: lazy { default_path })

        private

        # Default configuration path.
        #
        # @return [String]
        def default_path
          ::File.join(parent.confd_path, "#{config_name}.conf")
        end
      end

      # The provider for `monit_config`.
      #
      # @see Resource
      # @provides monit_config
      class Provider < Chef::Provider
        include Poise
        provides(:monit_config)

        # A `create` action for `monit_config`.
        #
        # @return [void]
        def action_create
          notifying_block do
            create_config
          end
        end

        # A `delete` action for `monit_config`.
        #
        # @return [void]
        def action_delete
          notifying_block do
            delete_config
          end
        end

        private

        # Write out the file under conf.d/.
        def create_config
          file new_resource.path do
            content new_resource.content
            group new_resource.parent.group if new_resource.parent.group
            mode '600'
            notifies :reload, new_resource.parent, :immediately
            owner new_resource.parent.owner if new_resource.parent.owner
            verify "#{new_resource.parent.monit_binary} -t -c #{Poise::Backports::VERIFY_PATH}" if defined?(verify)
          end
        end

        # Remove the config file.
        def delete_config
          file new_resource.path do
            action :delete
            notifies :reload, new_resource.parent, :immediately
          end
        end

      end
    end
  end
end
