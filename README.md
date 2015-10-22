# Certmonger puppet module for integration with IPA CAs

**Request a new certificate from IPA (via certmonger) using a puppet define**

## Simple usage:

```puppet
certmonger::request_ipa_cert { 'server-crt':
  $certfile => '/etc/pki/tls/certs/server.crt',
  $keyfile  => '/etc/pki/tls/private/server.key',
}
```

> Note: there is no need to use the `certmonger` class, it gets included by the define and has no parameters of its own.

## Parameters:
* `$certfile` - (required; String) - Full path of certificate to be managed by certmonger. e.g. `/path/to/certificate.crt`
* `$keyfile` - (required; String) - Full path to private key file to be managed by certmonger. e.g. `/path/to/key.pem`
* `$hostname` - (optional; String) - Hostname to use (appears in subject field of cert). e.g. `webserver.example.com`
* `$principal` - (optional; String) - IPA service principal certmonger should use when requesting cert. 
   e.g. `HTTP/webserver.example.com`.
* `$dns` - (optional; String or Array) - DNS subjectAltNames to be present in the certificate request.
                                     Can be a string (use commas or spaces to separate values) or an array.  
                                     e.g. `ssl.example.com webserver01.example.com`  
                                     e.g. `ssl.example.com, webserver01.example.com`  
                                     e.g. `["ssl.example.com","webserver01.example.com"]`  
* `$presavecmd`  - (optional; String) - Command certmonger should run before saving the certificate
* `$postsavecmd` - (optional; String) - Command certmonger should run after saving the certificate

## Actions:
* Submits a certificate request to an IPA server for a new certificate via `ipa-getcert` utility

## **!!! WARNING !!!!**
* Changing the location of a `$certfile` or `$keyfile` can't be done using `ipa-getcert resubmit`,
  which means this module **will take a more aggressive approach**, i.e. it will stop tracking the existing cert,
  delete the key/certfile and submit a brand new request. If the new request fails, bad luck, the old files are gone.

## Other limitations:
* The current state is determined by calling a custom shell script (supplied). Not ideal, I know.
  (maybe you can help by developing a custom type and provider?)
* Only supports file-based certificates (i.e. no support for NSSDB).
* Does not manage the nickname, IP address, email, keyusage, extusage, etc features.
* Only manages subject, dns (subjectAltNames), principal, pre/post save commands
* Subject is hardcoded to `CN=$hostname`.
* Only works if being run on a system already joined to an IPA domain, and only works against IPA CAs.
* If you specify a hostname and don't specify a principal, this module will assume you want `host/$hostname`.
  This is needed because `ipa-getcert` requires a principal if being passed a subject.
* If you don't specify an optional parameter (eg, if you dont supply `$dns`), this module will not touch that parameter
  of the existing request, even if the request has a value for that parameter present.
* The `$title` or `$namevar` of the define doesn't get used - everything revolves around `$certfile`.
* This module won't fix SELinux AVC denials: make sure certmonger can read/write to the location of `$certfile` and `$keyfile`.
* This module won't attempt to add service principals in IPA if they don't exist. You may need to do this manually.
* Certmonger needs to manage `$keyfile` and `$certfile`, which means you shouldn't create them yourself, but you can change
  their ownership/permissions once they've been created (e.g. via `$postsavecmd` or via a file resource in another puppet manifest).
* Tested only on CentOS 7.

## More elaborate example:

```puppet
  certmonger::request_ipa_cert {'webserver-certificate':
     server      => "${fqdn}",
     principal   => "HTTP/${fqdn}",
     keyfile     => "/etc/pki/tls/private/server.key",
     certfile    => "/etc/pki/tls/certs/server.crt",
     dns         => ['vhost1.example.com','vhost2.example.com'],
     postsavecmd => "chgrp sslcerts /etc/pki/tls/private/server.key /etc/pki/tls/certs/server.crt",
  }
```

## Contributing
* Fork it
* Create a topic branch
* Make your changes
* Submit a PR

## Acknowledgements
Honorable mention goes out to Rob Crittenden for his work on https://github.com/rcritten/puppet-certmonger, which was used as inspiration for this module.
