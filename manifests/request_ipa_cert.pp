# define: certmonger::request_ipa_cert
# Request a new certificate from IPA (via certmonger) using a puppet define
#
# # Parameters:
# * `certfile`    (required; String) - Full path of certificate to be managed by certmonger. e.g. `/path/to/certificate.crt`
# * `keyfile`     (required; String) - Full path to private key file to be manaegd by certmonger. e.g. `/path/to/key.pem`
# * `hostname`    (optional; String) - Hostname to use (appears in subject field of cert). e.g. `webserver.example.com`
# * `principal`   (optional; String) - IPA service principal certmonger should use when requesting cert.
#                                      e.g. `HTTP/webserver.example.com`.
# * `dns`         (optional; String or Array) - DNS subjectAltNames to be present in the certificate request.
#                                      Can be a string (use commas or spaces to separate values) or an array.
#                                      e.g. `ssl.example.com webserver01.example.com`
#                                      e.g. `ssl.example.com, webserver01.example.com`
#                                      e.g. `["ssl.example.com","webserver01.example.com"]`
# * `presavecmd`  (optional; String) - Command certmonger should run before saving the certificate
# * `postsavecmd` (optional; String) - Command certmonger should run after saving the certificate
# * `profile`     (optional; String) - Ask the CA to process request using the named profile. e.g. `caIPAserviceCert`
#
define certmonger::request_ipa_cert (
  $certfile,
  $keyfile,
  $hostname    = undef,
  $principal   = undef,
  $dns         = undef,
  $presavecmd  = undef,
  $postsavecmd = undef,
  $profile     = undef,
) {
  include ::certmonger
  include ::certmonger::scripts
  include ::stdlib

  validate_string($certfile, $keyfile)
  validate_absolute_path($certfile)
  validate_absolute_path($keyfile)

  $options = "-f ${certfile} -k ${keyfile}"
  $options_certfile = "-f ${certfile}"

  if $hostname {
    $subject = "CN=${hostname}"
    $options_subject = "-N ${subject}"
  } else {
    $subject = ''
    $options_subject =  ''
  }

  if $principal {
    $options_principal = "-K ${principal}"
  } elsif $hostname {
    $options_principal = "-K host/${hostname}"
  } else {
    $options_principal = ''
  }

  if $dns {
    if is_array($dns) {
      $options_dns_joined = join($dns, ' -D ')
      $dns_csv = join($dns, ',')
    } elsif is_string($dns) {
      $dns_array = split(regsubst(strip($dns),'[ ,]+',','), ',')
      $options_dns_joined = join($dns_array, ' -D ')
      $dns_csv = join($dns_array, ',')
    } else {
      fail('certmonger::request_ipa_cert: dns parameter must be either a string or array.')
    }
    $options_dns = regsubst($options_dns_joined, '^', '-D ')
    $options_dns_csv = "-D ${dns_csv}"
  } else {
    $options_dns = ''
    $options_dns_csv = ''
  }

  if $presavecmd { $options_presavecmd = "-B '${presavecmd}'" } else { $options_presavecmd = '' }
  if $postsavecmd { $options_postsavecmd = "-C '${postsavecmd}'" } else { $options_postsavecmd = '' }
  if $profile { $options_profile = "-T '${profile}'" } else { $options_profile = '' }

  exec { "ipa-getcert-${certfile}-trigger":
    path    => '/usr/bin:/bin',
    command => '/bin/true',
    unless  => "${::certmonger::scripts::verifyscript} ${options} ${options_subject} ${options_principal} \
                ${options_dns_csv} ${options_presavecmd} ${options_postsavecmd}",
    onlyif  => '/usr/bin/test -s /etc/ipa/default.conf',
    require => [Service['certmonger'], File[$::certmonger::scripts::verifyscript]],
    notify  => [Exec["ipa-getcert-request-${certfile}"],Exec["ipa-getcert-resubmit-${certfile}"]],
  }

  exec { "ipa-getcert-request-${certfile}":
    refreshonly => true,
    path        => '/usr/bin:/bin',
    provider    => 'shell',
    command     => "rm -rf ${keyfile} ${certfile} ; mkdir -p `dirname ${keyfile}` `dirname ${certfile}` ;
                    ipa-getcert stop-tracking ${options_certfile} ;
                    ipa-getcert request ${options} ${options_subject} ${options_principal} ${options_dns} \
                    ${options_presavecmd} ${options_postsavecmd} ${options_profile}",
    unless      => "${::certmonger::scripts::verifyscript} ${options}",
    notify      => Exec["ipa-getcert-${certfile}-verify"],
    require     => [Service['certmonger'],File[$::certmonger::scripts::verifyscript]],
  }

  exec { "ipa-getcert-resubmit-${certfile}":
    refreshonly => true,
    path        => '/usr/bin:/bin',
    provider    => 'shell',
    command     => "ipa-getcert resubmit ${options_certfile} ${options_subject} ${options_principal} ${options_dns} \
                    ${options_presavecmd} ${options_postsavecmd} ${options_profile}",
    unless      => "${::certmonger::scripts::verifyscript} ${options_certfile} ${options_subject} ${options_principal} ${options_dns_csv} \
                    ${options_presavecmd} ${options_postsavecmd}",
    onlyif      => ["${::certmonger::scripts::verifyscript} ${options}","openssl x509 -in ${certfile} -noout"],
    notify      => Exec["ipa-getcert-${certfile}-verify"],
    require     => [Service['certmonger'], File[$::certmonger::scripts::verifyscript]],
  }

  exec {"ipa-getcert-${certfile}-verify":
    refreshonly => true,
    path        => '/usr/bin:/bin',
    command     => "${::certmonger::scripts::verifyscript} ${options} ${options_subject} ${options_principal} -w 8 \
                    ${options_dns_csv} ${options_presavecmd} ${options_postsavecmd}",
    require     => [Service['certmonger'],File[$::certmonger::scripts::verifyscript]],
  }

}
