require 'spec_helper'

# find all parameters that don't have default values and put in here
# ensure validation occurs
describe Puppet::Type.type(:certmonger_certificate) do
  let(:valid_booleans) {[true, false, "true", "false"]}

  context 'with empty name' do
    let(:name) {''}

    it 'should raise ArgumentError if name is empty' do
      expect {
        Puppet::Type.type(:certmonger_certificate).new(:name => name,
                                                       :ensure => :present)
      }.to raise_error(Puppet::Error)
    end
  end

  context 'with valid name' do
    let(:name) do
       'some_name'
    end

    let(:type_instance) do
      #
      Puppet::Type.type(:certmonger_certificate).new(:name => name)
    end


    describe :name do
      it 'should have a name parameter' do
        expect(
          Puppet::Type.type(:certmonger_certificate).attrtype(:name)
        ).to eq(:param)
      end
      it 'should validate and pass if valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(:name => name,
                                                         :ensure => :present)
        }.to_not raise_error
      end
    end

    describe :force_resubmit do
      it 'should have a force_resubmit parameter' do
        expect(
          Puppet::Type.type(:certmonger_certificate).attrtype(:force_resubmit)
        ).to eq(:param)
      end
      it 'should raise ArgumentError if not valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name,
            :ensure => :present,
            :force_resubmit => 'some_bad_value')
        }.to raise_error(Puppet::Error)
      end
      it 'should validate and pass if valid value' do
        valid_booleans.each do |value|
          expect {
            Puppet::Type.type(:certmonger_certificate).new(
              :name => name,
              :ensure => :present,
              :force_resubmit => value)
          }.to_not raise_error
        end
      end
    end

    describe :wait do
      it 'should have a wait parameter' do
        expect(
          Puppet::Type.type(:certmonger_certificate).attrtype(:wait)
        ).to eq(:param)
      end
      it 'should raise ArgumentError if not valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name,
            :ensure => :present,
            :wait => 'some_bad_value')
        }.to raise_error(Puppet::Error)
      end
      it 'should validate and pass if valid value' do
        valid_booleans.each do |value|
          expect {
            Puppet::Type.type(:certmonger_certificate).new(
              :name => name,
              :ensure => :present,
              :wait => value)
          }.to_not raise_error
        end
      end
    end

    describe :ignore_ca_errors do
      it 'should have a ignore_ca_errors parameter' do
        expect(
          Puppet::Type.type(
            :certmonger_certificate).attrtype(:ignore_ca_errors)
        ).to eq(:param)
      end
      it 'should raise ArgumentError if not valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name,
            :ensure => :present,
            :ignore_ca_errors => 'some_bad_value')
        }.to raise_error(Puppet::Error)
      end
      it 'should validate and pass if valid value' do
        valid_booleans.each do |value|
          expect {
            Puppet::Type.type(:certmonger_certificate).new(
              :name => name,
              :ensure => :present,
              :ignore_ca_errors => value)
          }.to_not raise_error
        end
      end
    end

    describe :cleanup_on_error do
      it 'should have a cleanup_on_error parameter' do
        expect(
          Puppet::Type.type(
            :certmonger_certificate).attrtype(:cleanup_on_error)
        ).to eq(:param)
      end
      it 'should raise ArgumentError if not valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name,
            :ensure => :present,
            :cleanup_on_error => 'some_bad_value')
        }.to raise_error(Puppet::Error)
      end
      it 'should validate and pass if valid value' do
        valid_booleans.each do |value|
          expect {
            Puppet::Type.type(:certmonger_certificate).new(
              :name => name,
              :ensure => :present,
              :cleanup_on_error => value)
          }.to_not raise_error
        end
      end
    end

    describe :certfile do
      it 'should have a certfile property' do
        expect(
          Puppet::Type.type(:certmonger_certificate).attrtype(:certfile)
        ).to eq(:property)
      end
      it 'should raise ArgumentError if not valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name,
            :ensure => :present,
            :certfile => '')
        }.to raise_error(Puppet::Error)
      end
      it 'should validate and pass if valid value' do
        expect {Puppet::Type.type(:certmonger_certificate).new(
          :name => name,
          :ensure => :present,
          :certfile => 'some_value')
        }.to_not raise_error
      end
    end

    describe :keyfile do
      it 'should have a keyfile property' do
        expect(
          Puppet::Type.type(:certmonger_certificate).attrtype(:keyfile)
        ).to eq(:property)
      end
      it 'should raise ArgumentError if not valid value' do
        expect do
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name,
            :ensure => :present,
            :keyfile => '')
        end.to raise_error(Puppet::Error)
      end
      it 'should validate and pass if valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name,
            :ensure => :present,
            :keyfile => 'some_value')
        }.to_not raise_error
      end
    end

    describe :ca do
      it 'should have a ca property' do
        expect(
          Puppet::Type.type(:certmonger_certificate).attrtype(:ca)
        ).to eq(:property)
      end
      it 'should raise ArgumentError if not valid value' do
        expect do
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name,
            :ensure => :present,
            :ca => '')
        end.to raise_error(Puppet::Error)
      end
      it 'should validate and pass if valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name, :ensure => :present, :ca => 'some_value')
        }.to_not raise_error
      end
    end

    describe :hostname do
      it 'should have a hostname property' do
        expect(
          Puppet::Type.type(:certmonger_certificate).attrtype(:hostname)
        ).to eq(:property)
      end
      it 'should validate and pass if valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name, :ensure => :present, :hostname => 'some_value')
        }.to_not raise_error
      end
    end

    describe :principal do
      it 'should have a principal property' do
        expect(
          Puppet::Type.type(:certmonger_certificate).attrtype(:principal)
        ).to eq(:property)
      end
      it 'should validate and pass if valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name, :ensure => :present, :principal => 'some_value')
        }.to_not raise_error
      end
    end

    describe :dnsname do
      it 'should have a dnsname property' do
        expect(
          Puppet::Type.type(:certmonger_certificate).attrtype(:dnsname)
        ).to eq(:property)
      end
      it 'should validate and pass if valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name, :ensure => :present, :dnsname => 'some_value')
        }.to_not raise_error
      end
    end

    describe :status do
      it 'should have a status property' do
        expect(
          Puppet::Type.type(:certmonger_certificate).attrtype(:status)
        ).to eq(:property)
      end
      it 'should validate and pass if valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name, :ensure => :present, :status => 'some_value')
        }.to_not raise_error
      end
    end

    describe :keybackend do
      it 'should have a keybackend property' do
        expect(
          Puppet::Type.type(:certmonger_certificate).attrtype(:keybackend)
        ).to eq(:property)
      end
      it 'should validate and pass if valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name, :ensure => :present, :keybackend => 'some_value')
        }.to_not raise_error
      end
    end

    describe :certbackend do
      it 'should have a certbackend property' do
        expect(
          Puppet::Type.type(:certmonger_certificate).attrtype(:certbackend)
        ).to eq(:property)
      end
      it 'should validate and pass if valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name, :ensure => :present, :certbackend => 'some_value')
        }.to_not raise_error
      end
    end

    describe :presave_cmd do
      it 'should have a presave_cmd property' do
        expect(
          Puppet::Type.type(:certmonger_certificate).attrtype(:presave_cmd)
        ).to eq(:property)
      end
      it 'should validate and pass if valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name, :ensure => :present, :presave_cmd => 'some_value')
        }.to_not raise_error
      end
    end

    describe :postsave_cmd do
      it 'should have a postsave_cmd property' do
        expect(
          Puppet::Type.type(:certmonger_certificate).attrtype(:postsave_cmd)
        ).to eq(:property)
      end
      it 'should validate and pass if valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name, :ensure => :present, :postsave_cmd => 'some_value')
        }.to_not raise_error
      end
    end

    describe :ca_error do
      it 'should have a ca_error property' do
        expect(
          Puppet::Type.type(:certmonger_certificate).attrtype(:ca_error)
        ).to eq(:property)
      end
      it 'should validate and pass if valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name, :ensure => :present, :ca_error => 'some_value')
        }.to_not raise_error
      end
    end

    describe :profile do
      it 'should have a profile parameter' do
        expect(
          Puppet::Type.type(:certmonger_certificate).attrtype(:profile)
        ).to eq(:param)
      end
      it 'should validate and pass if valid value' do
        expect {
          Puppet::Type.type(:certmonger_certificate).new(
            :name => name, :ensure => :present, :ca_error => 'some_value')
        }.to_not raise_error
      end
    end
  end
end
