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

describe PoiseMonit::Resources::MonitCheck do
  step_into(:monit_check)
  let(:systemctl) { nil }
  let(:service) { nil }
  before do
    allow(PoiseLanguages::Utils).to receive(:which).with('systemctl').and_return(systemctl)
    allow(PoiseLanguages::Utils).to receive(:which).with('service').and_return(service)
  end

  context 'action :create' do
    recipe do
      monit 'monit'
      monit_check 'httpd'
    end

    it { is_expected.to render_file('/etc/monit/conf.d/httpd.conf').with_content(<<-EOH) }
CHECK PROCESS httpd PIDFILE /var/run/httpd.pid
  start program = "/etc/init.d/httpd start"
  stop program = "/etc/init.d/httpd stop"
EOH

    context 'with systemd' do
      let(:systemctl) { '/sbin/systemctl' }

      it { is_expected.to render_file('/etc/monit/conf.d/httpd.conf').with_content(<<-EOH) }
CHECK PROCESS httpd PIDFILE /var/run/httpd.pid
  start program = "/sbin/systemctl start httpd"
  stop program = "/sbin/systemctl stop httpd"
EOH
    end # /context with systemd

    context 'with service' do
      let(:service) { '/sbin/service' }

      it { is_expected.to render_file('/etc/monit/conf.d/httpd.conf').with_content(<<-EOH) }
CHECK PROCESS httpd PIDFILE /var/run/httpd.pid
  start program = "/sbin/service httpd start"
  stop program = "/sbin/service httpd stop"
EOH
    end # /context with service

    context 'with check string' do
      recipe do
        monit 'monit'
        monit_check 'httpd' do
          check 'if failed port 80 protocol http request "/_status" then restart'
        end
      end

      it { is_expected.to render_file('/etc/monit/conf.d/httpd.conf').with_content(<<-EOH) }
CHECK PROCESS httpd PIDFILE /var/run/httpd.pid
  start program = "/etc/init.d/httpd start"
  stop program = "/etc/init.d/httpd stop"
  if failed port 80 protocol http request "/_status" then restart
EOH
    end # /context with check string

    context 'with check array' do
      recipe do
        monit 'monit'
        monit_check 'httpd' do
          check [
            'if failed port 80 protocol http request "/_status" then restart',
            'if failed port 443 protocol https and certificate valid > 30 days then alert',
          ]
        end
      end

      it { is_expected.to render_file('/etc/monit/conf.d/httpd.conf').with_content(<<-EOH) }
CHECK PROCESS httpd PIDFILE /var/run/httpd.pid
  start program = "/etc/init.d/httpd start"
  stop program = "/etc/init.d/httpd stop"
  if failed port 80 protocol http request "/_status" then restart
  if failed port 443 protocol https and certificate valid > 30 days then alert
EOH
    end # /context with check array

    context 'with if_ string' do
      recipe do
        monit 'monit'
        monit_check 'httpd' do
          if_ 'failed port 80 protocol http request "/_status" then restart'
        end
      end

      it { is_expected.to render_file('/etc/monit/conf.d/httpd.conf').with_content(<<-EOH) }
CHECK PROCESS httpd PIDFILE /var/run/httpd.pid
  start program = "/etc/init.d/httpd start"
  stop program = "/etc/init.d/httpd stop"
  IF failed port 80 protocol http request "/_status" then restart
EOH
    end # /context with if_ string

    context 'with extra string' do
      recipe do
        monit 'monit'
        monit_check 'httpd' do
          extra 'MODE ACTIVE'
        end
      end

      it { is_expected.to render_file('/etc/monit/conf.d/httpd.conf').with_content(<<-EOH) }
CHECK PROCESS httpd PIDFILE /var/run/httpd.pid
  start program = "/etc/init.d/httpd start"
  stop program = "/etc/init.d/httpd stop"
  MODE ACTIVE
EOH
    end # /context with extra string

    context 'with extra array' do
      recipe do
        monit 'monit'
        monit_check 'httpd' do
          extra [
            'MODE ACTIVE',
            'GROUP www',
          ]
        end
      end

      it { is_expected.to render_file('/etc/monit/conf.d/httpd.conf').with_content(<<-EOH) }
CHECK PROCESS httpd PIDFILE /var/run/httpd.pid
  start program = "/etc/init.d/httpd start"
  stop program = "/etc/init.d/httpd stop"
  MODE ACTIVE
  GROUP www
EOH
    end # /context with extra array

    context 'with start_program' do
      recipe do
        monit 'monit'
        monit_check 'httpd' do
          start_program 'apachectl start'
        end
      end

      it { is_expected.to render_file('/etc/monit/conf.d/httpd.conf').with_content(<<-EOH) }
CHECK PROCESS httpd PIDFILE /var/run/httpd.pid
  start program = "apachectl start"
  stop program = "/etc/init.d/httpd stop"
EOH
    end # /context with start_program

    context 'with stop_program' do
      recipe do
        monit 'monit'
        monit_check 'httpd' do
          stop_program 'apachectl stop'
        end
      end

      it { is_expected.to render_file('/etc/monit/conf.d/httpd.conf').with_content(<<-EOH) }
CHECK PROCESS httpd PIDFILE /var/run/httpd.pid
  start program = "/etc/init.d/httpd start"
  stop program = "apachectl stop"
EOH
    end # /context with stop_program
  end # /context action :create

  context 'action :delete' do
    recipe do
      monit 'monit'
      monit_check 'httpd' do
        action :delete
      end
    end

    it { is_expected.to delete_file('/etc/monit/conf.d/httpd.conf') }
  end # /context action :delete
end
