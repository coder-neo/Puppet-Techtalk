# Puppet-Techtalk

## What is puppet?

Puppet is open source CM tool capable of automating system administration task. It is typically deployed in master-agent architecture where agents periodically poll master server for catalog(desired system state)and send backs report to master.

Puppet is based on ruby, it uses Puppet DSL for writing manifests.

## Installation

Setup master node


    wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb && \
    sudo dpkg -i puppetlabs-release-trusty.deb && \
    sudo apt-get update -yq && sudo apt-get upgrade -yq && \
    sudo apt-get install -yq puppetmaster

    Add dns_alt_names = puppet,puppet.example.com/' in /etc/puppet/puppet.conf

Set up agent node

    sudo apt-get install -yq puppet

    Add following config in agent /etc/puppet/puppet.conf :
    [agent]
    server=puppet

Update host config in /etc/hosts on both agent and master.

    192.168.33.40    puppet.example.com  puppet
    192.168.33.50    agent1.example.com  agent1
    192.168.33.51    agent2.example.com  agent2


Above configuration steps are handled in bootstrap script executed while spawing VMs with vagrant. Execute <b>'vagrant up'</b> command
to spawn VMs. Connect to master node with <b>'vagrant ssh puppet.example.com'</b> and execute the following commands to generate CA certificate and puppet master certificate with appropriate DNS name.

```zsh
sudo service puppetmaster status # test that puppet master was installed
sudo service puppetmaster stop
sudo puppet master --verbose --no-daemonize
# Ctrl+C to kill puppet master
sudo service puppetmaster start
sudo puppet cert list --all # check for 'puppet' cert
```
### Certicate signing
On each agent node execute following command to start Puppet’s Certificate Signing Request.

    sudo puppet agent --test --waitforcert=60

Go to master node and execute following commands to sign certificate from agent nodes.

```zsh
sudo puppet cert list # should see 'agent1.example.com' cert waiting for signature
sudo puppet cert sign --all # sign the agent node certs
sudo puppet cert list --all # check for signed certs
```

Puppet programs are called manifests. Manifests are collection of puppet resources,where each resource describe some ascpect of system. Default manifest file is site.pp located at /etc/puppet/manifests/, puppet master compiles and apply these manisfest to agent node.

Copy the <b>site.pp</b> file in repo to <b>/etc/puppet/manifests/</b>. Here in this manifest we have defined two different catalog for both the agents.

Agent1 shows example of catalog used to deploy iTrust.<br/>
Agent2 shows example of catalog used to install packages like git, nginx.

Agents periodically polls master for catalog. To apply catalog manually execute :

    sudo puppet agent -t