[![Puppet
Forge](http://img.shields.io/puppetforge/v/earsdown/certmonger.svg)](https://forge.puppetlabs.com/earsdown/certmonger)
[![Build Status](https://travis-ci.org/earsdown/puppet-certmonger.svg?branch=master)](https://travis-ci.org/earsdown/puppet-certmonger)

# Certmonger puppet module

This puppet modules enable some resources and providers that you can use to
request certificates using certmonger.

## Request a certificate from IPA using a puppet define

### Simple usage:

```puppet
certmonger::request_ipa_cert { 'server-crt':
  certfile => '/etc/pki/tls/certs/server.crt',
  keyfile  => '/etc/pki/tls/private/server.key',
}
```

Note: there is no need to use the `certmonger` class, it gets included by the define and has no parameters of its own.

### Parameters:
* `certfile`    (required; String) - Full path of certificate to be managed by certmonger. e.g. `/path/to/certificate.crt`
* `keyfile`     (required; String) - Full path to private key file to be managed by certmonger. e.g. `/path/to/key.pem`
* `hostname`    (optional; String) - Hostname to use (appears in subject field of cert). e.g. `webserver.example.com`
* `principal`   (optional; String) - IPA service principal certmonger should use when requesting cert.
                                     e.g. `HTTP/webserver.example.com`.
* `dns`         (optional; String or Array) - DNS subjectAltNames to be present in the certificate request.
                                     Can be a string (use commas or spaces to separate values) or an array.
                                     e.g. `ssl.example.com webserver01.example.com`
                                     e.g. `ssl.example.com, webserver01.example.com`
                                     e.g. `["ssl.example.com","webserver01.example.com"]`
* `presavecmd`  (optional; String) - Command certmonger should run before saving the certificate
* `postsavecmd` (optional; String) - Command certmonger should run after saving the certificate
* `profile`     (optional; String) - Ask the CA to process request using the named profile. e.g. `caIPAserviceCert`


### Actions:
* Submits a certificate request to an IPA server for a new certificate via `ipa-getcert` utility

### **!!! WARNING !!!!**
* Changing the location of a `certfile` or `keyfile` can't be done using `ipa-getcert resubmit`,
  which means this module **will take a more aggressive approach**, i.e. it will stop tracking the existing cert,
  delete the key/certfile and submit a brand new request. If the new request fails, bad luck, the old files are gone.

### Fixing file/folder permissions after certificate issuance
A notable limitation of `ipa-getcert` is that the `postsavecmd` can only take a single command. This means changing file ownership/modes and restarting services requires the use of a separate helper utility. This module includes a creatively named script called `change-perms-restart`, which gets installed by the `certmonger` class as `/usr/local/bin/change-perms-restart`. Usage is as follows:
```
/usr/local/bin/change-perms-restart [ -R] [ -r 'service1 service2' ] [ -s facility.severity ] owner:group:modes:/path/to/file [ ... ]

   -R     change ownership/group/modes recursively (e.g. when specifying a folder)
   -r     space separated list of services to restart via systemctl
   -s     log output (if any) to syslog with specified facility/severity
```
For example: `change-perms-restart -R -s daemon.notice -r 'httpd postgresql' root:pkiuser:0644:/etc/pki/tls/certs/localhost.crt root:pkiuser:0600:/etc/pki/tls/private/localhost.key`

### Other limitations:
* The current state is determined by calling a custom shell script (supplied). Not ideal, I know.
* Only supports file-based certificates (i.e. no support for NSSDB).
* Does not manage the nickname, IP address, email, keyusage, extusage, etc features.
* Only manages subject, dns (subjectAltNames), principal, pre/post save commands.
* Only manages the principal if it appears in the issued certificate - which depends on your CA profile.
* Subject is hardcoded to `CN=$hostname`.
* Only works if being run on a system already joined to an IPA domain, and only works against IPA CAs.
* If you specify a hostname and don't specify a principal, this module will assume you want `host/$hostname`.
  This is needed because `ipa-getcert` requires a principal if being passed a subject.
* If you don't specify an optional parameter (eg, if you dont supply `$dns`), this module will not touch that parameter
  of the existing request, even if the request has a value for that parameter present.
* The `title` or `namevar` of the define doesn't get used - everything revolves around `certfile`.
* This module won't fix SELinux AVC denials: make sure certmonger can read/write to the location of `certfile` and `keyfile`.
* This module won't attempt to add service principals in IPA if they don't exist. You may need to do this manually.
* Certmonger needs to manage `keyfile` and `certfile`, which means you shouldn't create them yourself, but you can change
  their ownership/permissions once they've been created (e.g. via `postsavecmd` or via a file resource in another puppet manifest).
  See example below on how to use the supplied `change-perms-restart` script to achieve this and restart httpd as one command.
* Tested only on CentOS 7.

### More elaborate example:

```puppet
  certmonger::request_ipa_cert {'webserver-certificate':
     server      => "${fqdn}",
     principal   => "HTTP/${fqdn}",
     keyfile     => "/etc/pki/tls/private/server.key",
     certfile    => "/etc/pki/tls/certs/server.crt",
     dns         => ['vhost1.example.com','vhost2.example.com'],
     postsavecmd => "/usr/local/bin/change-perms-restart -s daemon.notice -r httpd root:pkiuser:0640:/etc/pki/tls/private/server.key root:pkiuser:0644:/etc/pki/tls/certs/server.crt",
  }
```

## Request a certificate from IPA using the certmonger provider

This will create a certificate request with the given hostname (which will be
used in the subject as the CN) and the given principal. It will use the key
specified by 'keyfile'. And if it succeeds it will track the certificate where
'certfile' specifies the resource to do so.

```puppet
  certmonger_certificate { 'my-cert':
    ensure    => 'present',
    ca        => 'IPA'
    certfile  => '/path/to/certs/my-cert.pem',
    keyfile   => '/path/to/certs/my-key.pem',
    hostname  => 'hostname.example.com'
    principal => 'HTTP/hostname.example.com',
  }
```

If the certificate already exists it will simply take the values and add it to
the resource catalog. However, you can tell the provider to resubmit the
certificate if it already exists. This is done by setting the 'force_resubmit'
flag. Currently the aforementioned flag is needed if the parameters for the
request have changed and you wish to resubmit it.

If, for some reason, the CA rejects your request, you can still see the
certificate resource, and the status will reflect the rejection. So, when
viewing the resource, you'll see the following:

```puppet
  certmonger_certificate { 'my-cert':
    ensure      => 'present',
    ca          => 'local'
    certbackend => 'FILE',
    certfile    => '/path/to/certs/my-cert.pem',
    keybackend  => 'FILE',
    keyfile     => '/path/to/certs/my-key.pem',
    status      => 'CA_REJECTED',
  }
```

The default behavior is to throw an error if the CA rejects the request. But
errors can be ignored with the 'ignore_ca_errors' parameter.

One can also automatically stop tracking the certificate request if it's
rejected by the CA. This is done by setting the 'cleanup_on_error' flag.


## Contributing
* Fork it
* Create a topic branch
* Make your changes
* Submit a PR

## Acknowledgements
Honorable mention goes out to:
* Rob Crittenden for his work on https://github.com/rcritten/puppet-certmonger, which was used as inspiration for this module.
* Juan Antonio Osorio for his work on the certmonger type/provider and setting up rpsec tests/travis-ci integration.
