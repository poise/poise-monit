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

describe PoiseMonit::Resources::MonitConfig do
  step_into(:monit_config)
  before do
    default_attributes['poise-monit'] ||= {}
    # TODO update this when I write a dummy provider.
    default_attributes['poise-monit']['provider'] = 'system'
  end

  context 'action :create' do
    recipe do
      monit 'monit' do
        provider :system # REMOVE THIS
      end
      monit_config 'httpd' do
        content 'check process httpd'
      end
    end

    it { is_expected.to render_file('/etc/monit/conf.d/httpd.conf').with_content('check process httpd') }
  end # /context action :create
end
