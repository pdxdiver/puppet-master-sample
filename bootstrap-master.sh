#!/bin/sh

# Author Dan Carr (ddcarr@gmail.com)
# Based on https://github.com/garystafford/multi-vagrant-puppet-vms.git

# config
puppet_bin="/opt/puppetlabs/bin"
puppet_env="/etc/puppetlabs/code/environments/production"
hiera_dir="/etc/puppetlabs/code"

# Run on VM to bootstrap Puppet Master server

echo "# Get appropriate packages and install puppet"
wget https://apt.puppetlabs.com/puppetlabs-release-pc1-precise.deb
sudo dpkg -i puppetlabs-release-pc1-precise.deb && \
sudo apt-get update -yq && sudo apt-get upgrade -yq && \
sudo apt-get install -yq puppetserver

# Configure /etc/hosts file
echo "" | sudo tee --append /etc/hosts 2> /dev/null && \
echo "# Host config for Puppet Master and Agent Nodes" | sudo tee --append /etc/hosts 2> /dev/null && \
echo "192.168.32.5    puppet.example.com  puppet" | sudo tee --append /etc/hosts 2> /dev/null && \
echo "192.168.32.10   node01.example.com  node01" | sudo tee --append /etc/hosts 2> /dev/null && \
echo "192.168.32.10   funkenstein.example.com  funkenstein" | sudo tee --append /etc/hosts 2> /dev/null && \

# Add optional alternate DNS names to /etc/puppet/puppet.conf
sudo sed -i 's/.*\[main\].*/&\ndns_alt_names = puppet,puppet.example.com/' /etc/puppetlabs/puppet/puppet.conf

echo "# Install puppet modules we will be using"
sudo $puppet_bin/puppet module install jfryman-nginx --modulepath $puppet_env/modules

echo "# Create directories for classes"
sudo mkdir -p $puppet_env/modules/profiles/manifests
sudo mkdir -p $puppet_env/modules/roles/manifests

echo "# create directory for nodes"
sudo mkdir -p $puppet_env/hieradata/nodes

# symlink manifest and yaml configs from Vagrant synced folder location
echo "# Symlink for site.pp" |sudo ln -s /vagrant/site.pp $puppet_env/manifests/site.pp
echo "# Delete stock hiera config" |sudo rm $hiera_dir/hiera.yaml
echo "# Symlink to our custom hiera config" |sudo ln -s /vagrant/hiera.yaml $hiera_dir/hiera.yaml
echo "# Symlink to www manifest" |sudo ln -s /vagrant/www.pp $puppet_env/modules/roles/manifests/www.pp
echo "# Symlink to http resources manifest" |sudo ln -s /vagrant/http_resources.pp $puppet_env/modules/profiles/manifests/http_resources.pp
echo "# Symlink to ngnix manifest" |sudo ln -s /vagrant/nginx.pp $puppet_env/modules/profiles/manifests/nginx.pp
echo "# Symlink to node01 yaml config" |sudo ln -s /vagrant/node01.example.com.yaml $puppet_env/hieradata/nodes/node01.example.com.yaml
echo "# Symlink to common yaml config" |sudo ln -s /vagrant/common.yaml $puppet_env/hieradata/common.yaml
# Start puppetserver
echo "# Starting the puppetserver" | sudo service puppetserver start
