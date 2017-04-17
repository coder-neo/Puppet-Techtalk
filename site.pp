node 'agent2.example.com' {
# Test message
  notify { "Including packages ${hostname} node.": }

  class {'packages':
   package_list => ['git','nginx']
  }

}

node 'agent1.example.com'{

notify{"Including packages module on ${hostname}":}

# JAVA INSTALLATION 

include java

# TOMCAT INSTALLATION 
tomcat::install{'/opt/tomcat':
  source_url => 'http://mirror.symnds.com/software/Apache/tomcat/tomcat-9/v9.0.0.M18/bin/apache-tomcat-9.0.0.M18.tar.gz',
}

tomcat::instance { 'default' :
 catalina_home => '/opt/tomcat',
}

# Installing dependencies
package { ['mysql-server','maven']:
    ensure => present,
  }

# Using service resource to restart mysql service
service { 'mysql':
    ensure  => 'running',
    enable  => true,
    require => Package['mysql-server'],
  }

# Using vcsrepo module to clone iTrust repo
vcsrepo { '/home/vagrant/iTrust':
  ensure   => present,
  provider => git,
  source   => 'https://github.com/smsejwan/iTrust.git',
}

file { '/etc/mysql/my.cnf':
ensure => present,
}

# Updating config file and notifying mysql service.
file_line { 'Update my.cnf':
  ensure => present,
  path   => '/etc/mysql/my.cnf',
  line   => 'lower-case-table-names=1',
  after  => 'skip-external-locking',
  notify => Service['mysql'],
}

# Executing iTrust
exec {'Run iTrust':

  cwd  => '/home/vagrant/iTrust',
  path   => '/usr/bin:/usr/sbin:/bin',
  command =>'mvn clean package'
}

# Move iTrust webapps folder.
exec {'Move iTrust.war':

  cwd  => '/home/vagrant/iTrust/target/',
  path   => '/usr/bin:/usr/sbin:/bin',
  command =>'mv iTrust-23.0.0.war /opt/tomcat/webapps/iTrust.war'
}

# Restart tomcat
exec {'Restart Tomcat':

  path   => '/usr/bin:/usr/sbin:/bin',
  command =>'sudo chmod 777 /opt/tomcat/ && /opt/tomcat/bin/startup.sh',
}


}

# Class for java installations.
class java{
  package { "python-software-properties": }

  exec { "apt-get update":
    command => "/usr/bin/apt-get update"
  }
  exec { "add-apt-repository-oracle":
    command => "/usr/bin/add-apt-repository -y ppa:webupd8team/java",
    notify  => Exec['apt-get update'],
}

  exec {
    'set-licence-selected':
      command => '/bin/echo debconf shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections';

    'set-licence-seen':
      command => '/bin/echo debconf shared/accepted-oracle-license-v1-1 seen true | /usr/bin/debconf-set-selections';
  }

  package { 'oracle-java8-installer':
    ensure => "latest",
    require => [Exec['add-apt-repository-oracle'], Exec['set-licence-selected'], Exec['set-licence-seen']],
  }
}
                                                                                                                                                                                          89,1          Bot
