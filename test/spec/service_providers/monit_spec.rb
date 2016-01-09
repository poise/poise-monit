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

require 'spec_helper'

describe PoiseMonit::ServiceProviders::Monit do
  step_into(:poise_service)

  context 'with no default monit' do
    recipe do
      poise_service 'myapp' do
        command 'myapp.rb'
        provider :monit
      end
    end

    it { is_expected.to create_monit_config('myapp').with(path: '/etc/monit/conf.d/myapp.conf') }
  end # /context with no default monit

  context 'with an existing default monit' do
    recipe do
      monit 'other'
      poise_service 'myapp' do
        command 'myapp.rb'
        provider :monit
      end
    end

    it { is_expected.to create_monit_config('myapp').with(path: '/etc/monit-other/conf.d/myapp.conf') }
  end # /context with an existing default monit

  context 'with an explicit monit via options' do
    recipe do
      monit 'one'
      monit 'two'
      poise_service 'myapp' do
        command 'myapp.rb'
        provider :monit
        options :monit, parent: 'one'
      end
    end

    it { is_expected.to create_monit_config('myapp').with(path: '/etc/monit-one/conf.d/myapp.conf') }
  end # /context with an explicit monit via options

  context 'with default provider' do
    recipe do
      poise_service 'myapp' do
        action :nothing
      end
    end
    subject { chef_run.poise_service('myapp').provider_for_action(:enable) }
    before do
      begin
        PoiseService::ServiceProviders::Base.remove_class_variable(:@@service_resource_hints)
      rescue NameError
        # This space left intentionally blank.
      end
      allow(Chef::Platform::ServiceHelpers).to receive(:service_resource_providers).and_return([:systemd, :upstart, :debian])
    end

    it { is_expected.to_not be_a described_class }
  end # /context with default provider
end
