# Class: certmonger
class certmonger {

  package { 'certmonger':
    ensure => 'present',
  } ->
  service { 'certmonger':
    ensure => 'running',
    enable => true,
  }

  file { '/etc/ipa/verify_certmonger_request.sh':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/certmonger/verify_certmonger_request.sh',
  }

}
