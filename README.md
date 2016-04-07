## Instructions for executing the solution
1 - Clone the repository
```Shell
https://github.com/pdxdiver/puppet-master-sample.git
```
2 - Verify Puppetmaster is up (puppet.example.com)
```Shell
vagrant up # brings up all VMs
vagrant ssh puppet.example.com # Log into puppet master server
sudo service puppetserver status # Make sure puppet master is up
```
3 - Initiate certificate signing request (node01.example.com)
```Shell
vagrant ssh node01.example.com
sudo /opt/puppetlabs/bin/puppet agent --test --waitforcert=60 # initiate certificate signing request (CSR)
```
4 - Sign the certs on Puppet Master server (puppet.example.com)
```Shell
sudo /opt/puppetlabs/bin/puppet cert list # should see 'node01.example.com' cert waiting for signature
sudo /opt/puppetlabs/bin/puppet cert sign --all # sign the agent node(s) cert(s)
sudo /opt/puppetlabs/bin/puppet cert list --all # check for signed cert(s)
```
6 - Execute the rake file to test the config
```Shell
rake -f /vagrant/Rakefile # Cleans up, runs the agent and tests the web server
```

## Assumptions
This solution is stand alone and can be executed from any workstation with the following installed:
- [Vagrant](https://www.vagrantup.com/downloads.html)
- [Virtualbox](https://www.vagrantup.com/downloads.html) or
- [VMware Fusion](https://www.vmware.com/go/try-fusion-en) or
- [VMware Workstation](http://www.vmware.com/products/workstation/)

## The solution
This solution demonstrates a multi-server puppet master / agent node configuration. It provides a flexible framework for managing configurations that allows "roles" to be assigned to nodes. It provides an extensible model that reflects real world scenarios.

### hiera.yaml
Hiera configuration that defines data source and hierarchy
```YAML
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
```YAML
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
```Puppet
node default {
  hiera_include('roles')
}
```
### <span>www.pp</span>
Define the profiles used in the www role
```Puppet
class roles::www{
  include profiles::nginx
  include profiles::http_resources
}
```
###  http_resource.pp
Define directory and file resources. Ensure we have the latest index.html
```Puppet
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
```Puppet
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
