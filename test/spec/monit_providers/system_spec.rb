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

describe PoiseMonit::MonitProviders::System do
  let(:monit_version) { '5.15' }
  let(:default_attributes) { {poise_monit_version: monit_version} }
  let(:monit_resource) { chef_run.monit('monit') }
  step_into(:monit)
  recipe do
    monit 'monit' do
      httpd_port false
      provider :system
      version node['poise_monit_version']
    end
  end

  shared_examples_for 'system provider' do |candidates, epel|
    it { expect(monit_resource.provider_for_action(:enable)).to be_a described_class }
    it { is_expected.to install_package('monit').with(version: monit_version) }
  end

  context 'on Ubuntu' do
    let(:chefspec_options) { {platform: 'ubuntu', version: '14.04'} }
    it_behaves_like 'system provider'
  end # /context on Ubuntu

  context 'on CentOS' do
    let(:chefspec_options) { {platform: 'centos', version: '7.0'} }
    it { expect { chef_run }.to raise_error(Chef::Exceptions::RecipeNotFound) }

    context 'with EPEL stubbed out' do
      before do
        expect_any_instance_of(Chef::RunContext).to receive(:unreachable_cookbook?).with(:'yum-epel').and_return(false)
        expect_any_instance_of(described_class).to receive(:include_recipe).with('yum-epel')
      end
      it_behaves_like 'system provider'
    end # /context with EPEL stubbed out

    context 'without EPEL' do
      before do
        default_attributes['poise-monit'] = {monit: {no_epel: true}}
      end
      it_behaves_like 'system provider'
    end # /context without EPEL
  end # /context on CentOS

  context 'action :disable' do
    recipe do
      monit 'monit' do
        action :disable
        httpd_port false
        provider :system
      end
    end

    it { expect(monit_resource.provider_for_action(:disable)).to be_a described_class }
    it { is_expected.to remove_package('monit') }
  end # /context action :disable
end
