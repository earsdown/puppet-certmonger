# 2015-10-22: This is a work in progress.
module Puppet

  Type.type(:certmonger_request).provide(:ipagetcert) do
    desc "Manage certmonger certificates using the ipa-getcert binary."

    commands :ipagetcert => "ipa-getcert"

    def self.instances
      ipagetcert(:list).split("\n").select{|i| i =~ /certificate: type=FILE/}.collect do |line|
        junk1,certfile,junk2 = line.split(/'/)
        new({:certfile => certfile, :ensure => :present})
      end
    end

  end
end
