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

describe PoiseMonit::Resources::MonitService do
  let(:parent_resource) { PoiseMonit::Resources::Monit::Resource.new('monit', chef_run.run_context) }
  let(:test_resource) { described_class::Resource.new('myapp', chef_run.run_context).tap {|r| r.parent(parent_resource) } }
  let(:action) { nil }
  let(:test_provider) { test_resource.provider_for_action(action) }
  subject { test_provider.run_action }
  def stub_cmd(cmd, error: false, stdout: '', stderr: '')
    fake_cmd = double("output of monit #{cmd}", error?: error, stdout: stdout, stderr: stderr)
    if error
      allow(fake_cmd).to receive(:error!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
    else
      allow(fake_cmd).to receive(:error!)
    end
    expect(test_provider).to receive(:poise_shell_out).with(['/bin/monit', '-c', '/etc/monit/monitrc', cmd, 'myapp'], user: nil, group: nil).and_return(fake_cmd).ordered
  end
  def stub_status(status)
    stub_cmd('status', stdout: "Process 'myapp'\n  status       #{status}")
  end


  describe 'action :enable' do
    let(:action) { :enable }

    context 'with status Not monitored' do
      it do
        stub_status('Not monitored')
        stub_cmd('monitor')
        subject
      end
    end # /context with status Not monitored

    context 'with status Running' do
      it do
        stub_status('Running')
        # Does not call monitor.
        subject
      end
    end # /context with status Running
  end # /describe action :enable
end
