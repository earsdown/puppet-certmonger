# Class: certmonger::scripts
#
# # Parameters:
# * `verifyscript` (optional; String) - Full path of the script used for
#                                       verification of certificate requests
#   Defaults to '/etc/ipa/verify_certmonger_request.sh'
class certmonger::scripts (
  $verifyscript = '/etc/ipa/verify_certmonger_request.sh',
) {

  file { $verifyscript:
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
