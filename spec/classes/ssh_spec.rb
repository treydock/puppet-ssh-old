require 'spec_helper'

describe 'ssh' do
  include_context :defaults

  let(:facts) { default_facts }

  it { should create_class('ssh') }
end
