node 'agent2.example.com' {
# Test message
  notify { "Including packages ${hostname} node.": }
  $package_list = ['git','nginx']
  package {$package_list:
   ensure => present,
  }
  include java
}

node 'agent1.example.com'{

notify{"Deploying iTrust on ${hostname}":}

# JAVA INSTALLATION 

class {'java':
}

# TOMCAT INSTALLATION 
tomcat::install{'/opt/tomcat':
  source_url => 'https://www-us.apache.org/dist/tomcat/tomcat-9/v9.0.0.M19/bin/apache-tomcat-9.0.0.M19.tar.gz',
  require => Class['java'],
}

tomcat::instance { 'default' :
 catalina_home => '/opt/tomcat',
 before => Exec['move-iTrust.war']
}

# Installing dependencies
package { ['mysql-server','maven']:
    ensure => present,
    before => Exec['run-iTrust']
  }

# Using service resource to restart mysql service
service { 'mysql':
    ensure  => 'running',
    enable  => true,
    require => Package['mysql-server'],
  }

package { 'git' :
  ensure => present,
}
# Using vcsrepo module to clone iTrust repo
vcsrepo { '/home/vagrant/iTrust':
  ensure   => present,
  provider => git,
  source   => 'https://github.com/smsejwan/iTrust.git',
  before => Exec['run-iTrust'],
  require => Package['git'],
}

file { '/etc/mysql/my.cnf':
ensure => present,
require => Package['mysql-server'],
}
# Updating config file and notifying mysql service.
file_line { 'Update my.cnf':
  ensure => present,
  path   => '/etc/mysql/my.cnf',
  line   => 'lower-case-table-names=1',
  after  => 'skip-external-locking',
  require => Package['mysql-server'],
  notify => Service['mysql'],
}

# Executing iTrust
exec {'run-iTrust':

  cwd  => '/home/vagrant/iTrust',
  path   => '/usr/bin:/usr/sbin:/bin',
  command =>'mvn clean package'
}

# Move iTrust webapps folder.
exec {'move-iTrust.war':

  cwd  => '/home/vagrant/iTrust/target/',
  path   => '/usr/bin:/usr/sbin:/bin',
  command =>'mv iTrust-23.0.0.war /opt/tomcat/webapps/iTrust.war',
  require => Exec['run-iTrust'],
}

#tomcat::war{'iTrust.war':
#  catalina_base => '/opt/tomcat/',
#  war_source    => '/opt/tomcat/webapps/iTrust.war',
#  require => Exec['move-iTrust.war'],
#}

# Restart tomcat
#exec {'Restart Tomcat':

#  path   => '/usr/bin:/usr/sbin:/bin',
#  command =>'sudo chmod 777 /opt/tomcat/ && /opt/tomcat/bin/startup.sh',
#  require => Exec['move-iTrust.war'],
#}


}

# Class for java installations.
class java{
  package { "python-software-properties": }

  exec { "apt-get update":
    command => "/usr/bin/apt-get update"
  }
  exec { "add-apt-repository-oracle":
    command => "/usr/bin/add-apt-repository -y ppa:webupd8team/java",
}

  exec {
    'set-licence-selected':
      command => '/bin/echo debconf shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections';

     'set-licence-seen':
      command => '/bin/echo debconf shared/accepted-oracle-license-v1-1 seen true | /usr/bin/debconf-set-selections';
  }

  package { 'oracle-java8-installer':
    ensure => "latest",
    require => [Exec['add-apt-repository-oracle'], Exec['set-licence-selected'], Exec['set-licence-seen'], Exec['apt-get update']],
  }
}
