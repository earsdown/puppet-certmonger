Puppet::Type.type(:certmonger_certificate).provide :certmonger_certificate do
  desc "Provider for certmonger certificates."

  confine :exists => "/usr/sbin/certmonger"
  commands :getcert => "/bin/getcert"

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def create
    @property_flush[:ensure] = :present
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def self.get_list_of_certs
    output = getcert('list')
    return parse_cert_list(output)
  end

  def self.parse_cert_list(list_output)
    output_array = list_output.split("\n")
    cert_list = []
    current_cert = {}
    output_array.each do |line|
      case line
      when /^Number of certificates and requests/
        # skip preamble
        next
      when /^Request ID.*/
        # New certificate info. Append previous one.
        if current_cert[:name]
          current_cert[:ensure] = :present
          cert_list << current_cert
          current_cert = {}
        end
        current_cert[:name] = line.match(/Request ID '(.+)':/)[1]
      else
        if not current_cert[:name]
          raise Puppet::Error, "Invalid data coming from 'getcert list'."
        end

        case line
        when /^\s+status: .*/
          current_cert[:status] = line.match(/status: (.+)/)[1]
        when /^\s+key pair storage: .*/
          key_match = line.match(/type=([A-Z]+),.*location='(.+?)'/)
          current_cert[:keybackend] = key_match[1]
          current_cert[:keyfile] = key_match[2]
        when /^\s+certificate: .*/
          cert_match = line.match(/type=([A-Z]+),.*location='(.+?)'/)
          current_cert[:certbackend] = cert_match[1]
          current_cert[:certfile] = cert_match[2]
        when /^\s+CA: .*/
          current_cert[:ca] = line.match(/CA: (.*)/)[1]
        when /^\s+subject: .*/
          # FIXME(jaosorior): This is hacky! Use an actual library to parse
          # the subject.
          subj_match = line.match(/subject: (.*)/)
          if subj_match[1].empty?
            current_cert[:hostname] = ''
          else
            cn_match = line.match(/subject: .*CN=(.*?)(?:,.*|$)/)
            current_cert[:hostname] = cn_match[1]
          end
        when /^\s+dns: .*/
          current_cert[:dnsname] = line.match(/dns: (.*)/)[1]
        when /^\s+ca-error: .*/
          current_cert[:ca_error] = line.match(/ca-error: (.*)/)[1]
        when /^\s+pre-save command: .*/
          current_cert[:presave_cmd] = line.match(/pre-save command: (.*)/)[1]
        when /^\s+post-save command: .*/
          current_cert[:postsave_cmd] = line.match(
            /post-save command: (.*)/)[1]
        end
      end
    end
    if current_cert[:name]
      current_cert[:ensure] = :present
      cert_list << current_cert
    end
    return cert_list
  end

  def self.instances
    get_list_of_certs.collect do |cert|
      new(cert)
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    if @property_flush[:ensure] == :absent
      getcert(['stop-tracking', '-i', resource[:name]])
    else
      if not @property_hash.empty?
        if resource[:force_resubmit]
          request_args = ['resubmit', '-i', resource[:name]]
          request_args.concat get_base_args(resource)
          getcert request_args
        end
      else
        request_args = ['request', '-I', resource[:name]]
        request_args.concat get_base_args(resource)
        request_args.concat get_request_args(resource)

        begin
          Puppet.debug("Issuing getcert command with args: #{request_args}")
          getcert request_args
        rescue Exception => msg
          Puppet.warning("Could not get certificate: #{msg}")
        end

      end

      refresh resource
      cleanup resource
    end
  end

  def get_base_args(resource)
    request_args = []
    if resource[:certfile]
      request_args << '-f'
      request_args << resource[:certfile]
    else
      raise ArgumentError, "An empty value for the certfile is not allowed"
    end
    if resource[:ca]
      request_args << '-c'
      request_args << resource[:ca]
    else
      raise ArgumentError, "You need to specify a CA"
    end
    if resource[:hostname]
      request_args << '-N'
      request_args << "CN=#{resource[:hostname]}"
    end
    if resource[:principal]
      request_args << '-K'
      request_args << resource[:principal]
    end
    if resource[:dnsname]
      request_args << '-D'
      request_args << resource[:dnsname]
    end
    if resource[:presave_cmd]
      request_args << '-B'
      request_args << resource[:presave_cmd]
    end
    if resource[:postsave_cmd]
      request_args << '-C'
      request_args << resource[:postsave_cmd]
    end

    if resource[:wait]
      request_args << '-w'
    end
    return request_args
  end

  def get_request_args(resource)
    request_args = []
    if resource[:keyfile]
      request_args << '-k'
      request_args << resource[:keyfile]
    else
      raise ArgumentError, "An empty value for the keyfile is not allowed"
    end
    if resource[:profile]
      request_args << '-T'
      request_args << resource[:profile]
    end
    return request_args
  end

  def refresh(resource)
    begin
      output = getcert(['list', '-i', resource[:name]])
      @property_hash = self.class.parse_cert_list(output)[0]
    rescue
      raise Puppet::Error, ("The certificate '#{resource[:name]}' wasn't " +
                            "found in the list.")
    end
  end

  def cleanup(resource)
    if @property_hash[:ca_error]
      if resource[:cleanup_on_error]
        getcert(['stop-tracking', '-i', resource[:name]])
      end
      if not resource[:ignore_ca_errors]
        raise Puppet::Error, ("Could not get certificate: " +
                              "#{@property_hash[:ca_error]}")
      end
    end
  end
end
