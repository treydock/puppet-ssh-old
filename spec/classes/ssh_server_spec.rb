require 'spec_helper'

describe 'ssh::server' do
  include_context :defaults

  let(:facts) { default_facts }

  it { should create_class('ssh::server') }
  it { should contain_class('ssh::params') }
  it { should contain_class('ssh::server::install') }

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

  it { should have_sshd_config_resource_count(7) }

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

  [
    {'name' => 'AllowUsers', 'ensure' => 'absent', 'value' => nil},
    {'name' => 'AllowGroups', 'ensure' => 'absent', 'value' => nil},
  ].each do |h|
    it do
      should contain_sshd_config(h['name']).with({
        'ensure'  => h['ensure'],
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

  context "when allow_users => ['foo','bar']" do
    let(:params) {{ :allow_users => ['foo','bar'] }}
    it { should contain_sshd_config('AllowUsers').with_ensure('present') }
    it { should contain_sshd_config('AllowUsers').with_value(['foo','bar']) }
  end

  context "when allow_groups => ['foo','bar']" do
    let(:params) {{ :allow_groups => ['foo','bar'] }}
    it { should contain_sshd_config('AllowGroups').with_ensure('present') }
    it { should contain_sshd_config('AllowGroups').with_value(['foo','bar']) }
  end

  context "when allow_users is an empty Array" do
    let(:params) {{ :allow_users => [] }}
    it { should contain_sshd_config('AllowUsers').with_ensure('absent') }
    it { should contain_sshd_config('AllowUsers').without_value }
  end

  context "when allow_groups is an empty Array" do
    let(:params) {{ :allow_groups => [] }}
    it { should contain_sshd_config('AllowGroups').with_ensure('absent') }
    it { should contain_sshd_config('AllowGroups').without_value }
  end

  context "with sshd_configs defined" do
    let :params do
      {
        :sshd_configs => {'DenyUsers' => { 'value' => ['foo', 'bar'] }},
      }
    end

    it { should have_sshd_config_resource_count(8) }

    it do
      should contain_sshd_config('DenyUsers').with({
        'ensure'  => 'present',
        'target'  => '/etc/ssh/sshd_config',
        'notify'  => 'Service[ssh]',
        'value'   => ['foo','bar'],
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

  # Test validate_bool parameters
  [
    'service_autorestart',
  ].each do |param|
    context "with #{param} => 'foo'" do
      let(:params) {{ param.to_sym => 'foo' }}
      it { expect { should create_class('ssh::server') }.to raise_error(Puppet::Error, /is not a boolean/) }
    end
  end

  # Test validate_hash parameters
  [
    'sshd_configs',
  ].each do |param|
    context "with #{param} => 'foo'" do
      let(:params) {{ param.to_sym => 'foo' }}
      it { expect { should create_class('ssh::server') }.to raise_error(Puppet::Error, /is not a Hash/) }
    end
  end
end
