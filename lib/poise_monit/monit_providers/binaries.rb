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

require 'poise_languages/static'

require 'poise_monit/monit_providers/base'


module PoiseMonit
  module MonitProviders
    # A `binaries` provider for `monit` to install from static binaries hosted
    # at mmonit.com.
    #
    # @see PoiseMonit::Resources::PoiseMonit::Resource
    # @provides monit
    class Binaries < Base
      provides(:binaries)
      include PoiseLanguages::Static(
        name: 'monit',
        versions: %w{5.17.1},
        machines: %w{aix5.3-ppc aix6.1-ppc freebsd-x64 freebsd-x86 linux-x64 linux-x86 linux-arm macosx-universal openbsd-x64 openbsd-x86 solaris-sparc solaris-x64},
        url: 'https://bitbucket.org/tildeslash/monit/downloads/monit-%{version}-%{machine_label}.tar.gz'
      )

      # Translation lookup for Chef/Ohai machine types vs. Monit packages.
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

      # Allow anything we have a build for.
      #
      # @api private
      def self.provides_auto?(node, resource)
        static_machines.include?(static_machine_label(node))
      end

      # Compute the machine label in the format Monit uses.
      #
      # @api private
      def self.static_machine_label(node, resource=nil)
        # Get the machine type in the format Monit uses.
        raw_machine = (node['kernel']['machine'] || 'unknown').downcase
        machine = MACHINE_ALIASES.fetch(raw_machine, raw_machine)

        # And then the OS type.
        raw_kernel = (node['kernel']['name'] || 'unknown').downcase
        kernel = case raw_kernel
        when 'aix'
          # Monit 5.16 and higher just use "aix". If we don't have a version,
          # assume it's going to be the latest version.
          if !resource || !resource.version  || ::Gem::Version.create(resource.version) >= ::Gem::Version.create('5.16')
            'aix'
          # Less correct than "aix#{node['kernel']['version']}.#{node['kernel']['release']}"
          # but more likely to work on more systems. Notably we think the 6.1
          # build should work on AIX 7 just fine.
          elsif node['kernel']['version'].to_i <= 5
            'aix5.3'
          else
            'aix6.1'
          end
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

      # (see Base#monit_binary)
      def monit_binary
        ::File.join(static_folder, 'bin', 'monit')
      end

      private

      # (see Base#install_monit)
      def install_monit
        install_static
      end

      # (see Base#uninstall_monit)
      def uninstall_monit
        uninstall_static
      end

    end
  end
end


