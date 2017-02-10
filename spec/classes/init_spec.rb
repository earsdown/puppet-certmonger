require 'spec_helper'

describe 'certmonger' do
  it 'includes certmonger' do
    should contain_package('certmonger')
    should contain_service('certmonger')
  end
end
