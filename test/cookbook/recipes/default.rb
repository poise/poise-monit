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

if platform_family?('rhel')
  # Set up EPEL the simple way.
  repo = file '/etc/yum.repos.d/epel.repo' do
    mode '644'
    content <<-EOH
[epel]
name=Extra Packages for #{node['platform_version'][0]} - $basearch
enabled=1
failovermethod=priority
fastestmirror_enabled=0
gpgcheck=1
gpgkey=https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{node['platform_version'][0]}
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=epel-#{node['platform_version'][0]}&arch=$basearch
EOH
  end

  execute "yum clean metadata epel" do
    command "yum clean metadata --disablerepo=* --enablerepo=epel"
    action :nothing
    subscribes :run, repo, :immediately
  end

  execute "yum-makecache-epel" do
    command "yum -q -y makecache --disablerepo=* --enablerepo=epel"
    action :nothing
    subscribes :run, repo, :immediately
  end

  ruby_block "yum-cache-reload-epel" do
    block { Chef::Provider::Package::Yum::YumCache.instance.reload }
    action :nothing
    subscribes :create, repo, :immediately
  end
end

require 'poise_monit/resources/monit_test'

monit_test 'monit' do
  base_port 5000
end

monit_test 'system' do
  base_port 6000
  monit_provider :system
end

monit_test 'binaries' do
  base_port 7000
  monit_provider :binaries
end
