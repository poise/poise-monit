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

require 'poise_service/resources/poise_service_test'


module PoiseMonit
  module Resources
    # (see PoiseMonitTest::Resource)
    module PoiseMonitTest
      # A `monit_test` resource for integration testing monit providers.
      # This is used in Test-Kitchen tests to ensure all providers behave
      # similarly.
      #
      # @since 1.0.0
      # @provides monit_test
      # @action run
      # @example
      #   monit_test 'system' do
      #     monit_provider :system
      #     base_port 5000
      #   end
      class Resource < Chef::Resource
        include Poise
        provides(:monit_test)
        actions(:run)

        # @!attribute monit_provider
        #   Monit provider to set for the test group.
        #   @return [Symbol]
        attribute(:monit_provider, kind_of: Symbol)
        # @!attribute path
        #   Path for writing files for this test group.
        #   @return [String]
        attribute(:path, kind_of: String, default: lazy { "/root/monit_test_#{name}" })
        # @!attribute base_port
        #   Port number to start from for the test group.
        #   @return [Integer]
        attribute(:base_port, kind_of: Integer)
      end

      # Provider for `monit_test`.
      #
      # @see Resource
      # @provides monit_test
      class Provider < Chef::Provider
        include Poise
        provides(:monit_test)

        # `run` action for `poise_service_test`. Create all test services.
        #
        # @return [void]
        def action_run
          notifying_block do
            # Make the test output root.
            directory new_resource.path

            # Install Monit.
            r = monit new_resource.name do
              provider new_resource.monit_provider if new_resource.monit_provider
            end

            # Write out some config files.
            monit_config 'file_test' do
              content <<-EOH
CHECK FILE file_test PATH #{new_resource.path}/check
  start = "/bin/touch #{new_resource.path}/check"
EOH
              parent r
            end
            monit_service 'file_test' do
              action :enable
              parent r
            end
            file "#{new_resource.path}/service" do
              content <<-EOH
#!/bin/bash
nohup /bin/bash -c 'echo $$ >> #{new_resource.path}/pid; while sleep 1; do true; done' &
EOH
              mode '700'
            end
            monit_config 'process_test' do
              content <<-EOH
check process process_test with pidfile #{new_resource.path}/pid
  start program = "#{new_resource.path}/service"
EOH
              parent r
            end
            monit_service "process_test" do
              action [:enable, :start]
              parent r
            end

            # Run some monit commands.
            execute "#{r.monit_binary} -V -c '#{r.config_path}' > #{new_resource.path}/version"
            execute "#{r.monit_binary} status -c '#{r.config_path}' > #{new_resource.path}/status"

            # Run poise_service_test for the service provider.
            poise_service_test "monit_#{new_resource.name}" do
              base_port new_resource.base_port
              service_provider :monit
              service_options parent: r
            end
          end
        end

      end
    end
  end
end
