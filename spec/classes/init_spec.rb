require 'spec_helper'

describe 'certmonger' do
  it 'includes certmonger' do
    is_expected.to contain_package('certmonger')
    is_expected.to contain_service('certmonger')
  end
end
