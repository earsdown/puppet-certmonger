require 'spec_helper'

describe 'certmonger' do
  it 'should include certmonger' do
    should contain_package('certmonger')
    should contain_service('certmonger')
  end
end
