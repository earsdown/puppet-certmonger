# Class: certmonger::scripts
class certmonger::scripts {
  file { '/etc/ipa/verify_certmonger_request.sh':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/certmonger/verify_certmonger_request.sh',
  }
  file { '/usr/local/bin/change-perms-restart':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/certmonger/change-perms-restart',
  }
}
