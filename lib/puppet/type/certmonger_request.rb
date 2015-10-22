# 2015-10-22: This is a work in progress.
module Puppet

  Type.newtype(:certmonger_request) do
    @doc = "Request a new file-based certificate from IPA (via certmonger).
    Note: Support for NSSDB has not been implemented
    Parameters:
    `certfile`  - (required; String) - Full path of certificate to be managed by certmonger. e.g. `/path/to/certificate.crt`
    `keyfile`   - (required; String) - Full path to private key file to be managed by certmonger. e.g. `/path/to/key.pem`
    `hostname`  - (optional; String) - Hostname to use (appears in subject field of cert). e.g. `webserver.example.com`
    `principal` - (optional; String) - IPA service principal certmonger should use when requesting cert.
                                       e.g. `HTTP/webserver.example.com`.
    `dns_alt_names` - (optional; String or Array) - DNS subjectAltNames to be present in the certificate request.
                                          Can be a string (use commas or spaces to separate values) or an array.
                                          e.g. `ssl.example.com webserver01.example.com`
                                          e.g. `ssl.example.com, webserver01.example.com`
                                          e.g. `['ssl.example.com','webserver01.example.com']`
   `presavecmd`  - (optional; String) - Command certmonger should run before saving the certificate
   `postsavecmd` - (optional; String) - Command certmonger should run after saving the certificate"
  
    ensurable
  
    newparam(:certfile, :namevar => true) do
      isrequired
      desc "(Required) Full path of certificate file to be managed by certmonger. 
            Must be a single string. e.g. `/path/to/certificate.crt`."
      validate do |value|
	unless Puppet::Util.absolute_path?(value)
	  fail Puppet::Error, "certfile must be fully qualified, not '#{value}'"
	end
      end
    end
  
    newparam(:keyfile) do
      isrequired
      desc "(Required) Full path of private key file to be managed by certmonger. 
            Must be a single string. e.g. `/path/to/key.pem`."
      validate do |value|
	unless Puppet::Util.absolute_path?(value)
	  fail Puppet::Error, "keyfile must be fully qualified, not '#{value}'"
	end
      end
    end
  
    newproperty(:hostname) do
      desc "Hostname to use (appears in subject field of the certificate).
            e.g. `webserver.example.com`"
    end

    newproperty(:principal) do
      desc "IPA service principal certmonger should use in the certificate request.
            e.g. `HTTP/webserver.example.com`"
    end

    newproperty(:dns_alt_names, :array_matching => :all) do
      desc "DNS subject alternative names to inject into the certificate request
            Can be a string or an array."
    end

    newproperty(:presavecmd) do
      desc "Command certmonger should run before saving the certificate."
    end

    newproperty(:postsavecmd) do
      desc "Command certmonger should run after saving the certificate."
    end

  end
end
