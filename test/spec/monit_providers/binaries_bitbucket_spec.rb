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

describe PoiseMonit::MonitProviders::BinariesBitBucket do
  let(:monit_version) { nil }
  let(:chefspec_options) { {platform: 'ubuntu', version: '14.04'} }
  let(:default_attributes) { {poise_monit_version: monit_version} }
  let(:monit_resource) { chef_run.monit('monit') }
  step_into(:monit)
  recipe do
    monit 'monit' do
      httpd_port false
      version node['poise_monit_version']
    end
  end

  shared_examples_for 'binaries provider' do |base, url|
    it { expect(monit_resource.provider_for_action(:enable)).to be_a described_class }
    it { is_expected.to install_poise_languages_static(File.join('', 'opt', base)).with(source: url) }
    it { expect(monit_resource.monit_binary).to eq File.join('', 'opt', base, 'bin', 'monit') }
  end

  context 'with no version' do
    it_behaves_like 'binaries provider', 'monit-5.15', 'https://bitbucket.org/tildeslash/monit/downloads/monit-5.15-linux-x64.tar.gz'
  end # /context with no version

  context 'with version 5.15' do
    let(:monit_version) { '5.15' }
    it_behaves_like 'binaries provider', 'monit-5.15', 'https://bitbucket.org/tildeslash/monit/downloads/monit-5.15-linux-x64.tar.gz'
  end # /context with version 5.14

  context 'with version 5.14' do
    let(:monit_version) { '5.14' }
    it_behaves_like 'binaries provider', 'monit-5.14', 'https://bitbucket.org/tildeslash/monit/downloads/monit-5.14-linux-x64.tar.gz'
  end # /context with version 5.14
end
