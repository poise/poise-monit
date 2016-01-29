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

describe 'poise-monit::default' do
  recipe { include_recipe 'poise-monit' }
  before do
    allow_any_instance_of(PoiseMonit::Resources::Monit::Resource).to receive(:monit_version).and_return(Gem::Version.create('5.15'))
  end

  context 'with defaults' do
    it { is_expected.to enable_monit('monit').with(httpd_port: '/var/run/monit.sock', event_slots: 100, daemon_interval: 120) }
  end # /context with defaults

  context 'with attributes' do
    before do
      override_attributes['poise-monit'] = {}
      override_attributes['poise-monit']['recipe'] = {}
      override_attributes['poise-monit']['recipe']['httpd_port'] = 3000
      override_attributes['poise-monit']['recipe']['event_slots'] = 0
      override_attributes['poise-monit']['recipe']['daemon_interval'] = 60
    end

    it { is_expected.to enable_monit('monit').with(httpd_port: 3000, event_slots: 0, daemon_interval: 60) }
  end # /context with attributes
end
