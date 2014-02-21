require 'spec_helper_acceptance'

describe 'ssh::server class:' do
  context 'default parameters' do
    it 'should run successfully' do
      pp =<<-EOS
        class { 'ssh::server': }
      EOS

      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
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
      its(:content) { should_not match /^AllowUsers.*$/ }
      its(:content) { should_not match /^AllowGroups.*$/ }
      its(:content) { should match /^Subsystem\s+sftp\s+\/usr\/libexec\/openssh\/sftp-server$/ }
      it { should be_file }
      it { should be_mode 600 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
    end
  end

  context 'when allow_users is set' do
    it 'should run successfully' do
      pp =<<-EOS
        class { 'ssh::server':
          allow_users => ['root','vagrant'],
        }
      EOS

      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
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
      its(:content) { should_not match /^AllowGroups.*$/ }
      its(:content) { should match /^Subsystem\s+sftp\s+\/usr\/libexec\/openssh\/sftp-server$/ }
      it { should be_file }
      it { should be_mode 600 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
    end
  end
end
