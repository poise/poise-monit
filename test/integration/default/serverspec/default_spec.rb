# #
# # Copyright 2015, Noah Kantrowitz
# #
# # Licensed under the Apache License, Version 2.0 (the "License");
# # you may not use this file except in compliance with the License.
# # You may obtain a copy of the License at
# #
# # http://www.apache.org/licenses/LICENSE-2.0
# #
# # Unless required by applicable law or agreed to in writing, software
# # distributed under the License is distributed on an "AS IS" BASIS,
# # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# # See the License for the specific language governing permissions and
# # limitations under the License.
# #

require 'serverspec'
set :backend, :exec

require 'poise_service/spec_helper'

# Set up the shared example for monit_test.
RSpec.shared_examples 'a monit_test' do |monit_name, base_port|
  let(:monit_name) { monit_name }
  let(:monit_path) { File.join('', 'root', "monit_test_#{monit_name}") }
  # Helper for all the file checks.
  def self.assert_file(rel_path, should_exist=true, &block)
    describe rel_path do
      subject { file(File.join(monit_path, rel_path)) }
      # Do nothing for nil.
      if should_exist == true
        it { is_expected.to be_a_file }
      elsif should_exist == false
        it { is_expected.to_not exist }
      end
      instance_eval(&block) if block
    end
  end

  # Tests for direct monit commands.
  assert_file('version')
  assert_file('status') do
    its(:content) { is_expected.to include 'file_test' }
    its(:content) { is_expected.to include 'process_test' }
  end

  # Tests for monit_config and monit_service.
  assert_file('check')
  assert_file('pid')

  it_should_behave_like 'a poise_service_test', 'monit_'+monit_name, base_port, false
end

describe 'default' do
  it_should_behave_like 'a monit_test', 'monit', 5000
end

# Wait at least the default daemon interval.
Kernel.sleep 180

describe 'system provider', unless: File.exist?('/no_system') do
  it_should_behave_like 'a monit_test', 'system', 6000
end

describe 'binaries provider', unless: File.exist?('/no_binaries') do
  it_should_behave_like 'a monit_test', 'binaries', 7000
end
