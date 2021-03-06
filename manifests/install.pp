Exec { path => ["/usr/local/sbin","/usr/local/bin","/usr/sbin","/usr/bin","/bin"]}

class { 'python' :
  version    => 'system',
  pip        => 'present',
  dev        => 'present',
  virtualenv => 'present',
  gunicorn   => 'absent',
}

package { ["unzip", "zip", "default-jdk", "build-essential","automake", "jetty8", "subversion", "git", "libapache2-mod-wsgi", "libblas3", "libblas-dev", "celeryd", "redis-server", "apache2", "libffi-dev", "libssl-dev", "maven"]:
  ensure => "installed"
} ->
file_line { "configure_jetty_start":
  path  => '/etc/default/jetty8',
  line  => 'NO_START=0',
  match => 'NO_START=1',
} ->
file_line { "configure_jetty_java_options":
  path  => '/etc/default/jetty8',
  line  => 'JAVA_OPTIONS="-ea -Xmx4g -server -XX:+UseParallelOldGC -Djava.awt.headless=true -Dorg.eclipse.jetty.server.Request.maxFormContentSize=200000000"',
  match => 'JAVA_OPTIONS=',
} ->
file_line { "configure_jetty_host_options":
  path  => '/etc/default/jetty8',
  line  => 'JETTY_HOST=0.0.0.0',
  match => 'JETTY_HOST=',
} ->
file_line { "configure_java_home":
  path  => '/etc/default/jetty8',
  line  => 'JAVA_HOME=/usr/lib/jvm/default-java',
  match => 'JAVA_HOME=',
} -> wget::fetch { "https://github.com/tetherless-world/whyis/raw/master/resources/blazegraph.war":
  destination => "/tmp/blazegraph.war",
  timeout => 0
} ->
file { "/usr/share/jetty8/webapps/blazegraph":
  ensure => "directory",
} ->
exec { "unzip_blazegraph":
  command => "unzip -u /tmp/blazegraph.war",
  cwd => "/usr/share/jetty8/webapps/blazegraph",
  creates => "/usr/share/jetty8/webapps/blazegraph/WEB-INF/web.xml",
} -> 
file { "/data":
  ensure => directory,
  owner => "jetty"
} ->
file_line { "configure_blazegraph_rule_logging":
  path  => '/usr/share/jetty8/webapps/blazegraph/WEB-INF/classes/log4j.properties',
  line  => 'log4j.appender.ruleLog.File=/data/rules.log',
  match => 'rules\.log',
} ->
file_line { "configure_blazegraph_config_location":
  path => '/usr/share/jetty8/webapps/blazegraph/WEB-INF/web.xml',
  match => 'RWStore.properties</param-value>',
  line => '   <param-value>/usr/share/jetty8/webapps/blazegraph/WEB-INF/RWStore.properties</param-value>',
} ->
file { "/usr/share/jetty8/webapps/blazegraph/WEB-INF/RWStore.properties":
  content => '
com.bigdata.journal.AbstractJournal.file=/data/blazegraph.jnl
com.bigdata.journal.AbstractJournal.bufferMode=DiskRW
com.bigdata.service.AbstractTransactionService.minReleaseAge=1
com.bigdata.journal.Journal.groupCommit=true
com.bigdata.btree.writeRetentionQueue.capacity=4000
com.bigdata.btree.BTree.branchingFactor=128
com.bigdata.journal.AbstractJournal.initialExtent=209715200
com.bigdata.journal.AbstractJournal.maximumExtent=209715200
com.bigdata.rdf.sail.truthMaintenance=false
com.bigdata.rdf.store.AbstractTripleStore.quads=true
com.bigdata.rdf.store.AbstractTripleStore.statementIdentifiers=false
com.bigdata.rdf.store.AbstractTripleStore.textIndex=true
com.bigdata.rdf.store.AbstractTripleStore.axiomsClass=com.bigdata.rdf.axioms.NoAxioms
com.bigdata.namespace.kb.lex.com.bigdata.btree.BTree.branchingFactor=400
com.bigdata.namespace.kb.spo.com.bigdata.btree.BTree.branchingFactor=1024',
} -> 
file { "/usr/share/jetty8/webapps/blazegraph/WEB-INF/GraphStore.properties":
  content => '
com.bigdata.journal.AbstractJournal.file=/data/blazegraph.jnl
com.bigdata.journal.AbstractJournal.bufferMode=DiskRW
com.bigdata.service.AbstractTransactionService.minReleaseAge=1
com.bigdata.journal.Journal.groupCommit=true
com.bigdata.btree.writeRetentionQueue.capacity=4000
com.bigdata.btree.BTree.branchingFactor=128
com.bigdata.journal.AbstractJournal.initialExtent=209715200
com.bigdata.journal.AbstractJournal.maximumExtent=209715200
com.bigdata.rdf.sail.truthMaintenance=false
com.bigdata.rdf.store.AbstractTripleStore.quads=true
com.bigdata.rdf.store.AbstractTripleStore.statementIdentifiers=false
com.bigdata.rdf.store.AbstractTripleStore.textIndex=true
com.bigdata.rdf.store.AbstractTripleStore.axiomsClass=com.bigdata.rdf.axioms.NoAxioms
com.bigdata.namespace.kb.lex.com.bigdata.btree.BTree.branchingFactor=400
com.bigdata.namespace.kb.spo.com.bigdata.btree.BTree.branchingFactor=1024',
} ->
group { 'whyis':
    ensure => 'present',
}
user { 'whyis':
  ensure => present,
  password => '*',
  home => '/apps',
  shell => '/bin/bash',
  gid => 'whyis'
} ->
file { "/apps":
  ensure => "directory",
  owner => "whyis",
  group => "whyis"
} ->
file { "/data/nanopublications":
  ensure => directory,
  owner => "whyis"
} ->
file { "/data/files":
  ensure => directory,
  owner => "whyis"
} ->
vcsrepo { '/apps/whyis':
  ensure   => present,
  provider => git,
  source   => 'https://github.com/tetherless-world/whyis.git',
  user     => 'whyis'
} ->
python::virtualenv { '/apps/whyis/venv' :
  ensure       => present,
  version      => 'system',
  systempkgs   => false,
  distribute   => false,
  venv_dir     => '/apps/whyis/venv',
  owner        => 'whyis',
  cwd          => '/apps/whyis',
  timeout      => 0,
} ->
file { "/apps/.bash_profile" :
  owner => 'whyis',
  content => '
  source /apps/whyis/venv/bin/activate
  ',
} ->
python::pip { 'pip-upgrade' :
  pkgname       => 'pip',
  ensure        => 'latest',
  virtualenv    => '/apps/whyis/venv',
  owner         => 'whyis',
  timeout       => 0,
} ->
python::requirements { '/apps/whyis/requirements/dev.txt' :
  virtualenv => '/apps/whyis/venv',
  owner      => 'whyis',
} ->
file { "/var/log/celery":
    owner => "whyis",
    ensure => directory,
    recurse => true,
    group => "whyis",
} ->
file { "/etc/default/celeryd":
  source => "/apps/whyis/resources/celeryd",
  owner => "root",
  group => "root",
  ensure => present
} ->
exec { "a2enmod wsgi":
  command => "a2enmod wsgi",
} -> 
exec { "a2enmod headers":
  command => "a2enmod headers",
} -> 
file { "/var/log/whyis":
  ensure => directory,
  owner => "whyis",
  group => "whyis",
} ->
file { "/etc/apache2/sites-available/000-default.conf":
  ensure => present,
  source => "/apps/whyis/apache.conf",
  owner => "root"
}


service { apache2:
    ensure => running,
    subscribe => [File["/etc/apache2/sites-available/000-default.conf"]],
}

service { redis-server:
    ensure => running,
    subscribe => [File["/etc/apache2/sites-available/000-default.conf"]],
}

service { jetty8:
    ensure => running,
    subscribe => [File["/usr/share/jetty8/webapps/blazegraph/WEB-INF/GraphStore.properties"]],
} ->
exec { "create_admin_namespace":
  command => "curl -X POST --data-binary @admin.properties -H 'Content-Type:text/plain' http://localhost:8080/blazegraph/namespace > /apps/whyis/admin_namespace.log",
  creates => "/apps/whyis/admin_namespace.log",
  user => "whyis",
  cwd => "/apps/whyis",
} -> 
exec { "create_knowledge_namespace":
  command => "curl -X POST --data-binary @knowledge.properties -H 'Content-Type:text/plain' http://localhost:8080/blazegraph/namespace > /apps/whyis/knowledge_namespace.log",
  creates => "/apps/whyis/knowledge_namespace.log",
  user => "whyis",
  cwd => "/apps/whyis",
}

exec { "compile_java": 
  command => "mvn clean compile assembly:single -PwhyisProfile",
  creates => "/apps/whyis/java_compile.log",
  user => "whyis",
  cwd => "/apps/whyis/whyis-java",
}



include java

class { 'elasticsearch':
  restart_on_change => true,
  api_protocol            => 'http',
  api_host                => 'localhost',
  api_port                => 9200,
  api_timeout             => 10,
  api_basic_auth_username => undef,
  api_basic_auth_password => undef,
  api_ca_file             => undef,
  api_ca_path             => undef,
  validate_tls            => true,  
}

elasticsearch::instance { 'es-01': }
