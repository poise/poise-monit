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

require 'poise_languages/static'

require 'poise_monit/monit_providers/base'


module PoiseMonit
  module MonitProviders
    class Binaries < Base
      provides(:binaries)
      include PoiseLanguages::Static(
        name: 'monit',
        versions: %w{5.15},
        machines: %w{aix5.3-ppc aix6.1-ppc freebsd-x64 freebsd-x86 linux-x64 linux-x86 linux-arm macosx-universal openbsd-x64 openbsd-x86 solaris-sparc solaris-x64},
        url: 'https://mmonit.com/monit/dist/binary/%{version}/monit-%{version}-%{machine_label}.tar.gz',
      )

      MACHINE_ALIASES = {
        # Linux.
        'amd64' => 'x64',
        'x86_64' => 'x64',
        'i386' => 'x86',
        'i686' => 'x86',
        # AIX.
        'powerpc' => 'ppc',
        # Solaris.
        'i86pc' => 'x64',
        'sun4v' => 'sparc',
        'sun4u' => 'sparc',
        'sun4us' => 'sparc',
      }

      def self.static_machine_label(node)
        # Get the machine type in the format Monit uses.
        raw_machine = node['kernel']['machine'].downcase
        machine = MACHINE_ALIASES.fetch(raw_machine, raw_machine)

        # And then the OS type.
        raw_kernel = node['kernel']['name'].downcase
        kernel = case raw_kernel
        when 'aix'
          "aix#{node['kernel']['version']}.#{node['kernel']['release']}"
        when 'sunos'
          'solaris'
        when 'darwin'
          # Short circuit, because we don't care about the machine type.
          return 'macosx-universal'
        else
          raw_kernel
        end

        # Put 'em together.
        "#{kernel}-#{machine}"
      end

      def monit_binary
        ::File.join(static_folder, 'bin', 'monit')
      end

      private

      def install_monit
        install_static
      end

      def uninstall_monit
        uninstall_static
      end

    end
  end
end


