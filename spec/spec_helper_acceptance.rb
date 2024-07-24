require 'beaker-rspec'
require 'beaker-puppet'
require 'beaker/module_install_helper'
require 'voxpupuli/acceptance/spec_helper_acceptance'

RSpec.configure do |c|
  c.before :suite do
    unless ENV['BEAKER_provision'] == 'no'

      DIGICERT = <<-EOM.freeze
-----BEGIN CERTIFICATE-----
MIIFkDCCA3igAwIBAgIQBZsbV56OITLiOQe9p3d1XDANBgkqhkiG9w0BAQwFADBi
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3Qg
RzQwHhcNMTMwODAxMTIwMDAwWhcNMzgwMTE1MTIwMDAwWjBiMQswCQYDVQQGEwJV
UzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQu
Y29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqG
SIb3DQEBAQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3y
ithZwuEppz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1If
xp4VpX6+n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDV
ySAdYyktzuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiO
DCu3T6cw2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQ
jdjUN6QuBX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/
CNdaSaTC5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCi
EhtmmnTK3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADM
fRyVw4/3IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QY
uKZ3AeEPlAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXK
chYiCd98THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t
9dmpsh3lGwIDAQABo0IwQDAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIB
hjAdBgNVHQ4EFgQU7NfjgtJxXWRM3y5nP+e6mK4cD08wDQYJKoZIhvcNAQEMBQAD
ggIBALth2X2pbL4XxJEbw6GiAI3jZGgPVs93rnD5/ZpKmbnJeFwMDF/k5hQpVgs2
SV1EY+CtnJYYZhsjDT156W1r1lT40jzBQ0CuHVD1UvyQO7uYmWlrx8GnqGikJ9yd
+SeuMIW59mdNOj6PWTkiU0TryF0Dyu1Qen1iIQqAyHNm0aAFYF/opbSnr6j3bTWc
fFqK1qI4mfN4i/RN0iAL3gTujJtHgXINwBQy7zBZLq7gcfJW5GqXb5JQbZaNaHqa
sjYUegbyJLkJEVDXCLG4iXqEI2FCKeWjzaIgQdfRnGTZ6iahixTXTBmyUEFxPT9N
cCOGDErcgdLMMpSEDQgJlxxPwO5rIHQw0uA5NBCFIRUBCOhVMt5xSdkoF1BN5r5N
0XWs0Mr7QbhDparTwwVETyw2m+L64kW4I1NsBm9nVX9GtUw/bihaeSbSpKhil9Ie
4u1Ki7wb/UdKDd9nZn6yW0HQO+T0O/QEY+nvwlQAUaCKKsnOeMzV6ocEGLPOr0mI
r/OSmbaz5mEP0oUA51Aa5BuVnRmhuZyxm7EAHu/QD09CbMkKvO5D+jpxpchNJqU1
/YldvIViHTLSoCtU7ZpXwdv6EM8Zt4tKG48BtieVU+i2iW1bvGjUI+iLUaJW+fCm
gKDWHrO8Dw9TdSmq6hN35N6MgSGtBxBHEa2HPQfRdbzP82Z+
-----END CERTIFICATE-----
EOM

      def run_puppet_install_helper
        return unless ENV['PUPPET_INSTALL_TYPE'] == 'agent'
        if ENV['BEAKER_PUPPET_COLLECTION'].match? %r{/-nightly$/}
          # Workaround for RE-10734
          options[:release_apt_repo_url] = 'http://nightlies.puppet.com/apt'
          options[:win_download_url] = 'http://nightlies.puppet.com/downloads/windows'
          options[:mac_download_url] = 'http://nightlies.puppet.com/downloads/mac'
        end

        agent_sha = ENV['BEAKER_PUPPET_AGENT_SHA'] || ENV['PUPPET_AGENT_SHA']
        if agent_sha.nil? || agent_sha.empty?
          install_puppet_agent_on(hosts, options.merge(version: version))
        else
          # If we have a development sha, assume we're testing internally
          dev_builds_url = ENV['DEV_BUILDS_URL'] || 'http://builds.delivery.puppetlabs.net'
          install_from_build_data_url('puppet-agent', "#{dev_builds_url}/puppet-agent/#{agent_sha}/artifacts/#{agent_sha}.yaml", hosts)
        end

        # XXX install_puppet_agent_on() will only add_aio_defaults_on when the
        # nodeset type == 'aio', but we don't want to depend on that.
        add_aio_defaults_on(hosts)
        add_puppet_paths_on(hosts)
      end

      # Until solaris gets new image we need to add to the cert chain on solaris, call a beaker-puppet setup script to handle this
      hosts.each do |host|
        next unless host.platform.match? %r{solaris-11(\.2)?-(i386|sparc)}
        create_remote_file(host, 'DigiCertTrustedRootG4.crt.pem', DIGICERT)
        on(host, 'chmod a+r /root/DigiCertTrustedRootG4.crt.pem')
        on(host, 'cp -p /root/DigiCertTrustedRootG4.crt.pem /etc/certs/CA/')
        on(host, 'rm /root/DigiCertTrustedRootG4.crt.pem')
        on(host, '/usr/sbin/svcadm restart /system/ca-certificates')
        timeout = 60
        counter = 0
        until on(host, 'svcs -x ca-certificates').output.include?('State: online')
          raise 'ca-certificates services failed start up' if counter > timeout
          sleep 5
          counter += 5
        end
      end
      hosts.each { |host| host[:type] = 'aio' }
      run_puppet_install_helper
      install_module_on(hosts)
      install_module_dependencies_on(hosts)
    end
  end
end
