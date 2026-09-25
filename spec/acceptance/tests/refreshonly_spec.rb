require 'spec_helper_acceptance'

RSpec.context 'Augeas refreshonly' do
  agents.each do |agent|
    context "on #{agent}" do
      let(:test_dir) { on(agent, 'mktemp -d /tmp/augeas-refreshonly.XXXXXX').stdout.strip }

      before(:each) do
        create_remote_file(agent, "#{test_dir}/services", "ssh 22/tcp\n")
      end

      after(:each) do
        on(agent, "rm -rf '#{test_dir}'")
      end

      def manifest(relationship: '~>', refreshonly: true, extra: '')
        <<~PUPPET
          file { '#{test_dir}/trigger':
            content => 'bar',
          } #{relationship}
          augeas { 'add_services_entry':
            incl        => '#{test_dir}/services',
            lens        => 'Services.lns',
            changes     => [
              'ins service-name after service-name[last()]',
              'set service-name[last()] "Doom"',
              'set service-name[last()]/port "666"',
              'set service-name[last()]/protocol "udp"',
            ],
            refreshonly => #{refreshonly},
            #{extra}
          }
        PUPPET
      end

      it 'inserts exactly once on notification and makes no changes on the second run' do
        pp = manifest
        on(agent, puppet_apply('--detailed-exitcodes'), stdin: pp, acceptable_exit_codes: [2])
        first = on(agent, "cat '#{test_dir}/services'").stdout
        expect(first.scan(%r{^Doom\s+666/udp$}).size).to eq(1)

        on(agent, puppet_apply('--detailed-exitcodes'), stdin: pp, acceptable_exit_codes: [0])
        expect(on(agent, "cat '#{test_dir}/services'").stdout).to eq(first)

        # A later, real event must still trigger another insertion.
        on(agent, puppet_apply('--detailed-exitcodes'), stdin: pp.sub("content => 'bar'", "content => 'baz'"), acceptable_exit_codes: [2])
        expect(on(agent, "cat '#{test_dir}/services'").stdout.scan(%r{^Doom\s+666/udp$}).size).to eq(2)
      end

      it 'does not execute for an ordering relationship, even with force' do
        pp = manifest(relationship: '->', extra: 'force => true,')
        on(agent, puppet_apply('--detailed-exitcodes'), stdin: pp, acceptable_exit_codes: [2])
        on(agent, puppet_apply('--detailed-exitcodes'), stdin: pp, acceptable_exit_codes: [0])
        expect(on(agent, "cat '#{test_dir}/services'").stdout).to eq("ssh 22/tcp\n")
      end

      it 'respects onlyif when notified, even with force' do
        pp = manifest(extra: "onlyif => 'match service-name size == 0', force => true,")
        on(agent, puppet_apply('--detailed-exitcodes'), stdin: pp, acceptable_exit_codes: [2])
        on(agent, puppet_apply('--detailed-exitcodes'), stdin: pp, acceptable_exit_codes: [0])
        expect(on(agent, "cat '#{test_dir}/services'").stdout).to eq("ssh 22/tcp\n")
      end

      it 'executes on refresh with force enabled' do
        pp = manifest(extra: 'force => true,')
        on(agent, puppet_apply('--detailed-exitcodes'), stdin: pp, acceptable_exit_codes: [2])
        on(agent, puppet_apply('--detailed-exitcodes'), stdin: pp, acceptable_exit_codes: [0])
        expect(on(agent, "cat '#{test_dir}/services'").stdout.scan(%r{^Doom\s+666/udp$}).size).to eq(1)
      end

      it 'does not modify files in noop mode or consume the future event' do
        pp = manifest
        on(agent, puppet_apply('--noop --detailed-exitcodes'), stdin: pp, acceptable_exit_codes: [0])
        expect(on(agent, "cat '#{test_dir}/services'").stdout).to eq("ssh 22/tcp\n")
        on(agent, "test ! -e '#{test_dir}/trigger'")
        on(agent, puppet_apply('--detailed-exitcodes'), stdin: pp, acceptable_exit_codes: [2])
        on(agent, puppet_apply('--detailed-exitcodes'), stdin: pp, acceptable_exit_codes: [0])
        expect(on(agent, "cat '#{test_dir}/services'").stdout.scan(%r{^Doom\s+666/udp$}).size).to eq(1)
      end

      it 'still executes without events when refreshonly is false' do
        pp = manifest(relationship: '->', refreshonly: false)
        2.times do
          on(agent, puppet_apply('--detailed-exitcodes'), stdin: pp, acceptable_exit_codes: [2])
        end
        expect(on(agent, "cat '#{test_dir}/services'").stdout.scan(%r{^Doom\s+666/udp$}).size).to eq(2)
      end
    end
  end
end
