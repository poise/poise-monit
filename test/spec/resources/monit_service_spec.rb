#
# Copyright 2015-2017, Noah Kantrowitz
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
  let(:parent_resource) do
    PoiseMonit::Resources::Monit::Resource.new('monit', chef_run.run_context).tap do |r|
      r.provider(:dummy)
    end
  end
  let(:test_resource) { described_class::Resource.new('myapp', chef_run.run_context).tap {|r| r.parent(parent_resource) } }
  let(:action) { nil }
  let(:status) { nil }
  let(:test_provider) { test_resource.provider_for_action(action) }
  subject { test_provider.run_action }
  before do
    # Force the default log level because it alters the tests.
    chefspec_options.delete(:log_level)
    # Give us some files to work with that won't hit the disk.
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/exists').and_return(true)
    allow(File).to receive(:exist?).with('/not_exists').and_return(false)
    # Override these so our tests don't take forever.
    override_attributes['poise-monit'] ||= {}
    override_attributes['poise-monit']['monit_service_timeout'] = 2
    override_attributes['poise-monit']['monit_service_wait'] = 0.01
    # Status for simple cases.
    stub_status(status) if status
  end
  def stub_cmd(cmd, error: false, stdout: '', stderr: '', verbose: false, &block)
    fake_cmd = double("output of monit #{cmd}", error?: error, stdout: stdout, stderr: stderr)
    if error
      allow(fake_cmd).to receive(:error!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
    else
      allow(fake_cmd).to receive(:error!)
    end
    matcher = receive(:poise_shell_out).with(['/usr/bin/monit', (verbose ? '-v' : []), '-c', '/etc/monit/monitrc', cmd, 'myapp'].flatten, user: nil, group: nil).and_return(fake_cmd).ordered
    matcher = block.call(matcher) if block
    expect(test_provider).to matcher
  end
  def stub_status(status, verbose: false)
    stub_cmd('status', stdout: "Process 'myapp'\n  status       #{status}", verbose: verbose)
  end

  describe 'action :enable' do
    let(:action) { :enable }

    context 'with status Not monitored' do
      let(:status) { 'Not monitored' }
      it do
        stub_cmd('monitor')
        subject
      end
    end # /context with status Not monitored

    context 'with status Running' do
      let(:status) { 'Running' }
      it do
        # Does not call monitor.
        subject
      end
    end # /context with status Running

    context 'with monit_verbose' do
      before do
        test_resource.monit_verbose(true)
      end
      it do
        stub_status('Not monitored', verbose: true)
        stub_cmd('monitor', verbose: true)
        subject
      end
    end # /context with monit_verbose

    context 'with log_level debug' do
      before do
        chefspec_options[:log_level] = :debug
        # Don't actually show debug or info logs.
        allow(Chef::Log).to receive(:info)
        allow(Chef::Log).to receive(:debug)
      end
      it do
        stub_status('Not monitored', verbose: true)
        stub_cmd('monitor', verbose: true)
        subject
      end
    end # /context with log_level debug
  end # /describe action :enable

  describe 'action :disable' do
    let(:action) { :disable }

    context 'with status Running' do
      let(:status) { 'Running' }
      it do
        stub_cmd('unmonitor')
        subject
      end
    end # /context with status Running

    context 'with status Not monitored' do
      let(:status) { 'Not monitored' }
      it do
        # Does not call unmonitor.
        subject
      end
    end # /context with status Running

    context 'with error' do
      let(:status) { 'Running' }
      it do
        stub_cmd('unmonitor', error: true)
        stub_cmd('unmonitor')
        subject
      end
    end # /context with error

    context 'with There is no service' do
      let(:status) { 'Running' }
      it do
        stub_cmd('unmonitor', error: true, stdout: 'There is no service')
        subject
      end
    end # /context with There is no service

    context 'with an existing config file' do
      let(:status) { 'Running' }
      before { test_resource.monit_config_path('/exists') }
      it do
        stub_cmd('unmonitor')
        subject
      end
    end # /context with an existing config file

    context 'with an non-existing config file' do
      # Run the action directly because otherwise load_current_resource skips
      # trying to disable anyway.
      subject { test_provider.send(:disable_service) }
      before { test_resource.monit_config_path('/not_exists') }
      it do
        # Does not call unmonitor.
        subject
      end
    end # /context with an non-existing config file
  end # /describe action :disable

  describe 'action :start' do
    let(:action) { :start }

    context 'with status Not monitored' do
      let(:status) { 'Not monitored' }
      it do
        stub_cmd('start')
        stub_cmd('start')
        subject
      end
    end # /context with status Not monitored

    context 'with status Running' do
      let(:status) { 'Running' }
      it do
        # Does not call start.
        subject
      end
    end # /context with status Running

    context 'with status Does not exist' do
      let(:status) { 'Does not exist' }
      it do
        stub_cmd('start')
        stub_cmd('start')
        subject
      end
    end # /context with status Does not exist
  end # /describe action :start

  describe 'action :stop' do
    let(:action) { :stop }

    context 'with status Running' do
      let(:status) { 'Running' }
      it do
        stub_cmd('stop')
        subject
      end
    end # /context with status Running

    context 'with status Not monitored' do
      let(:status) { 'Not monitored' }
      it do
        # Does not call stop.
        subject
      end
    end # /context with status Running

    context 'with error' do
      let(:status) { 'Running' }
      it do
        stub_cmd('stop', error: true)
        stub_cmd('stop')
        subject
      end
    end # /context with error

    context 'with There is no service' do
      let(:status) { 'Running' }
      it do
        stub_cmd('stop', error: true, stdout: 'There is no service')
        subject
      end
    end # /context with There is no service

    context 'with status Does not exist' do
      let(:status) { 'Does not exist' }
      it do
        stub_cmd('stop')
        subject
      end
    end # /context with status Does not exist

    context 'with an existing config file' do
      let(:status) { 'Running' }
      before { test_resource.monit_config_path('/exists') }
      it do
        stub_cmd('stop')
        subject
      end
    end # /context with an existing config file

    context 'with an non-existing config file' do
      # Run the action directly because otherwise load_current_resource skips
      # trying to stop anyway.
      subject { test_provider.send(:stop_service) }
      before { test_resource.monit_config_path('/not_exists') }
      it do
        # Does not call stop.
        subject
      end
    end # /context with an non-existing config file
  end # /describe action :stop

  describe 'action :restart' do
    let(:action) { :restart }
    let(:status) { 'Running' }

    it do
      stub_cmd('restart')
      subject
    end
  end # /describe action :restart

  describe 'load_current_resource' do
    let(:action) { :enable }
    subject { test_provider.load_current_resource }

    context 'with status Running' do
      let(:status) { 'Running' }
      its(:enabled) { is_expected.to be true }
      its(:running) { is_expected.to be true }
    end # /context with status Running

    context 'with status Online with all services' do
      let(:status) { 'Online with all services' }
      its(:enabled) { is_expected.to be true }
      its(:running) { is_expected.to be true }
    end # /context with status Online with all services

    context 'with status Not monitored' do
      let(:status) { 'Not monitored' }
      its(:enabled) { is_expected.to be false }
      its(:running) { is_expected.to be false }
    end # /context with status Not monitored

    context 'with status Error' do
      let(:status) { 'Error' }
      its(:enabled) { is_expected.to be true }
      its(:running) { is_expected.to be false }
    end # /context with status Error

    context 'with a non-existing config file' do
      before { test_resource.monit_config_path('/not_exists') }
      its(:enabled) { is_expected.to be false }
      its(:running) { is_expected.to be false }
    end # /context with a non-existing config file

    context 'with some Initializing' do
      before do
        stub_status('Initializing')
        stub_status('Initializing')
        stub_status('Initializing')
        stub_status('Initializing')
        stub_status('Running')
      end
      its(:enabled) { is_expected.to be true }
      its(:running) { is_expected.to be true }
    end # /context with some Initializing

    context 'with an error' do
      before do
        stub_const('PoiseMonit::Resources::MonitService::DEFAULT_WAIT', 0.5)
        stub_cmd('status', error: true) {|m| m.at_least(:twice) }
      end
      it { expect { subject }.to raise_error Mixlib::ShellOut::ShellCommandFailed }
    end # /context with an error

    context 'with an non-existent service' do
      before do
        stub_const('PoiseMonit::Resources::MonitService::DEFAULT_WAIT', 0.5)
        stub_cmd('status') {|m| m.at_least(:twice) }
      end
      its(:enabled) { is_expected.to be false }
      its(:running) { is_expected.to be false }
    end # /context with an non-existent service
  end # /describe load_current_resource
end
