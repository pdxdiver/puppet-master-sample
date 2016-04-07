## Instructions for executing the solution

1 - Clone the repository
```
https://github.com/pdxdiver/puppet-master-sample.git
```
2 - Verify Puppetmaster is up (puppet.example.com)
```
vagrant up # brings up all VMs
vagrant ssh puppet.example.com
sudo service puppetserver status
```
3 - Initiate certificate signing request (node01.example.com)
```
vagrant ssh node01.example.com
sudo puppet agent --test --waitforcert=60 # initiate certificate signing request (CSR)
```
4 - Sign the certs on Puppet Master server (puppet.example.com)
```
sudo /opt/puppetlabs/bin/puppet cert list # should see 'node01.example.com' cert waiting for signature
sudo /opt/puppetlabs/bin/puppet cert sign --all # sign the agent node(s) cert(s)
sudo /opt/puppetlabs/bin/puppet cert list --all # check for signed cert(s)
```
6 - Execute the rake file to test the config
```
rake -f /vagrant/rakefile
```

## My solution
In short, I chose to use an approach that provides a flexible framework for
managing configurations that allows "roles" to be assigned to nodes. I believe this
approach provides an extensible model that reflects real world scenarios

### hiera.yaml
Hiera configuration that defines data source and hierarchy
```
---
:backends:
  - yaml
:yaml:
  :datadir: /etc/puppetlabs/code/environments/%{environment}/hieradata
:hierarchy:
  - "nodes/%{::trusted.certname}"
  - "roles/%{::role}"
  - common
```

### node01.example.com.yaml
Hiera data that defines the node's config options and behavior
```
---
roles:
  - roles::www

http:
  vdomain: funkenstein.example.com
  port: 8000
  www_home_dir: /opt/www/
  index_file: index.html
  home_page_src: http://raw.githubusercontent.com/puppetlabs/exercise-webpage/master/index.html

nginx::config::vhost_purge: true
nginx::config::confd_purge: true
nginx::nginx_vhosts:
 "%{hiera('http.vdomain')}":
    ensure: present
    www_root: "%{hiera('http.www_home_dir')}"
    listen_port: "%{hiera('http.port')}"
```

###  site.pp
Instruct puppet to use the "role" classes
```
node default {
  hiera_include('roles')
}
```

###  www.pp
Define the profiles used in the www role
```
class roles::www{
  include profiles::nginx
  include profiles::http_resources
}
```

###  http_resource.pp
Define directory and file resources. Ensure we have the latest index.html
```
class profiles::http_resources{
  $http = hiera_hash('http')

  file { $http[www_home_dir]:
    ensure => directory,
    recurse => true,
  }
  file { sprintf("%s%s", $http[www_home_dir], $http[index_file]):
    ensure => present,
    source => $http[home_page_src],
  }
}
```

###  nginx.pp
Install ngnix
```
class profiles::nginx {
  class{ '::nginx':
  }
}
```

## Additional Solution Elements

### JSON Configuration File
The Vagrantfile retrieves multiple VM configurations from a separate `nodes.json` file.

### bootstrap-master.sh & bootstrap-node.sh
First time startup scripts to prepare each server

## Sources of inspiration
1. [Bootstrapping Puppet Master Multi-node](http://wp.me/p1RD28-1kX)
2. [Deploying nginix with Puppet](https://blog.serverdensity.com/deploying-nginx-with-puppet/)
