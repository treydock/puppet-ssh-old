require 'spec_helper'

describe 'ssh::server' do
  include_context :defaults

  let(:facts) { default_facts }

  it { should create_class('ssh::server') }
  it { should contain_class('ssh::params') }
  it { should include_class('ssh::server::install') }

  it do
    should contain_service('ssh').with({
      'ensure'      => 'running',
      'enable'      => 'true',
      'name'        => 'sshd',
      'hasstatus'   => 'true',
      'hasrestart'  => 'true',
    })
  end

  it do
    should contain_file('/etc/ssh/sshd_config').with({
      'ensure'  => 'present',
      'path'    => '/etc/ssh/sshd_config',
      'owner'   => 'root',
      'group'   => 'root',
      'mode'    => '0600',
    })
  end

  it { should have_sshd_config_resource_count(5) }

  [
    {'name' => 'PasswordAuthentication', 'value' => 'yes'},
    {'name' => 'PermitEmptyPasswords', 'value' => 'no'},
    {'name' => 'PermitRootLogin', 'value' => 'without-password'},
    {'name' => 'UsePAM', 'value' => 'yes'},
    {'name' => 'X11Forwarding', 'value' => 'yes'},
  ].each do |h|
    it do
      should contain_sshd_config(h['name']).with({
        'ensure'  => 'present',
        'target'  => '/etc/ssh/sshd_config',
        'notify'  => 'Service[ssh]',
        'value'   => h['value'],
      })
    end

    context 'with service_authrestart => false' do
      let(:params) {{ :service_autorestart => false }}
      it { should contain_sshd_config(h['name']).with_notify(nil) }
    end
  end


  it { should have_sshd_config_subsystem_resource_count(1) }

  [
    {'name' => 'sftp', 'command' => '/usr/libexec/openssh/sftp-server'},
  ].each do |h|
    it do
      should contain_sshd_config_subsystem(h['name']).with({
        'ensure'  => 'present',
        'target'  => '/etc/ssh/sshd_config',
        'notify'  => 'Service[ssh]',
        'command' => h['command'],
      })
    end
    
    context 'with service_authrestart => false' do
      let(:params) {{ :service_autorestart => false }}
      it { should contain_sshd_config_subsystem(h['name']).with_notify(nil) }
    end
  end

  context "with sshd_configs defined" do
    let :params do
      {
        :sshd_configs => {'AllowUsers' => { 'value' => ['foo', 'bar'] }},
      }
    end

    it { should have_sshd_config_resource_count(6) }

    it do
      should contain_sshd_config('AllowUsers').with({
        'ensure'  => 'present',
        'target'  => '/etc/ssh/sshd_config',
        'notify'  => 'Service[ssh]',
        'value'   => ['foo','bar'],
      })
    end
  end

  context "with sshd_config_subsystems defined" do
    let :params do
      {
        :sshd_config_subsystems => {'sftp' => { 'command' => 'internal-sftp' }},
      }
    end

    it { should have_sshd_config_subsystem_resource_count(1) }

    it do
      should contain_sshd_config_subsystem('sftp').with({
        'ensure'  => 'present',
        'target'  => '/etc/ssh/sshd_config',
        'notify'  => 'Service[ssh]',
        'command' => 'internal-sftp',
      })
    end
  end

  # Test service ensure and enable 'magic' values
  [
    'undef',
    'UNSET',
  ].each do |v|
    context "with service_ensure => '#{v}'" do
      let(:params) {{ :service_ensure => v }}
      it { should contain_service('ssh').with_ensure(nil) }
    end

    context "with service_enable => '#{v}'" do
      let(:params) {{ :service_enable => v }}
      it { should contain_service('ssh').with_enable(nil) }
    end
  end

  # Test verify_boolean parameters
  [
    'service_autorestart',
  ].each do |bool_param|
    context "with #{bool_param} => 'foo'" do
      let(:params) {{ bool_param.to_sym => 'foo' }}
      it { expect { should create_class('ssh') }.to raise_error(Puppet::Error, /is not a boolean/) }
    end
  end
end
