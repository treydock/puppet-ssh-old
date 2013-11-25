require 'spec_helper_system'

describe 'ssh::server class:' do
  context 'should run successfully' do
    pp =<<-EOS
class { 'ssh::server': }
    EOS
  
    context puppet_apply(pp) do
       its(:stderr) { should be_empty }
       its(:exit_code) { should_not == 1 }
       its(:refresh) { should be_nil }
       its(:stderr) { should be_empty }
       its(:exit_code) { should be_zero }
    end
  end

  describe package('openssh-server') do
    it { should be_installed }
  end

  describe service('sshd') do
    it { should be_enabled }
    it { should be_running }
  end

  describe file('/etc/ssh/sshd_config') do
    its(:content) { should match /^PasswordAuthentication yes$/ }
    its(:content) { should match /^PermitEmptyPasswords no$/ }
    its(:content) { should match /^PermitRootLogin without-password$/ }
    its(:content) { should match /^UsePAM yes$/ }
    its(:content) { should match /^X11Forwarding yes$/ }
    its(:content) { should match /^Subsystem\s+sftp\s+\/usr\/libexec\/openssh\/sftp-server$/ }
    it { should be_file }
    it { should be_mode 600 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
  end

  context 'should set AllowUsers' do
    pp =<<-EOS
class { 'ssh::server':
  sshd_configs => {
    'AllowUsers' => {
      'value' => ['root','vagrant'],
    }
  }
}
    EOS
  
    context puppet_apply(pp) do
       its(:stderr) { should be_empty }
       its(:exit_code) { should_not == 1 }
       its(:refresh) { should be_nil }
       its(:stderr) { should be_empty }
       its(:exit_code) { should be_zero }
    end

    describe package('openssh-server') do
      it { should be_installed }
    end

    describe service('sshd') do
      it { should be_enabled }
      it { should be_running }
    end

    describe file('/etc/ssh/sshd_config') do
      its(:content) { should match /^PasswordAuthentication yes$/ }
      its(:content) { should match /^PermitEmptyPasswords no$/ }
      its(:content) { should match /^PermitRootLogin without-password$/ }
      its(:content) { should match /^UsePAM yes$/ }
      its(:content) { should match /^X11Forwarding yes$/ }
      its(:content) { should match /^AllowUsers root vagrant$/ }
      its(:content) { should match /^Subsystem\s+sftp\s+\/usr\/libexec\/openssh\/sftp-server$/ }
      it { should be_file }
      it { should be_mode 600 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
    end
  end
end
