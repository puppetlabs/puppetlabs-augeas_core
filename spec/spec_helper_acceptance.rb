require 'beaker-rspec'
require 'beaker-puppet'
require 'beaker/module_install_helper'
require 'beaker/puppet_install_helper'

RSpec.configure do |c|
  c.before :suite do
    unless ENV['BEAKER_provision'] == 'no'
      # Until solaris gets new image we need to add to the cert chain on solaris, call a beaker-puppet setup script to handle this
      bp_path, _status = Open3.capture2('bundler info beaker-puppet --path')
      bp_path.strip!
      solaris_patch_path = bp_path + '/setup/common/003_solaris_cert_fix.rb'
      require solaris_patch_path
      run_puppet_install_helper
      install_module_on(hosts)
      install_module_dependencies_on(hosts)
    end
  end
end
