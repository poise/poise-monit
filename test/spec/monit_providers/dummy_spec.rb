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

require 'spec_helper'

describe PoiseMonit::MonitProviders::Dummy do
  let(:monit_resource) { chef_run.monit('test') }
  step_into(:monit)
  recipe do
    monit 'test' do
      httpd_port false
      provider :dummy
    end
  end

  describe '#monit_binary' do
    subject { monit_resource.monit_binary }

    it { is_expected.to eq '/usr/bin/monit' }
  end # /describe #monit_binary

  describe 'action :enable' do
    # Just make sure it doesn't error.
    it { run_chef }
  end # /describe action :enable

  describe 'action :disable' do
    recipe do
      monit 'test' do
        action :disable
        httpd_port false
        provider :dummy
      end
    end

    # Just make sure it doesn't error.
    it { run_chef }
  end # /describe action :disable
end
