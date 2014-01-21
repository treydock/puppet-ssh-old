require 'spec_helper'

describe 'ssh::server::install' do
  include_context :defaults

  let(:facts) { default_facts }

  it { should create_class('ssh::server::install') }
  it { should include_class('ssh::server') }

  it do
    should contain_package('openssh-server').with({
      'ensure'    => 'present',
      'name'      => 'openssh-server',
      'before'    => ['Service[ssh]', 'File[/etc/ssh/sshd_config]'],
    })
  end
end
