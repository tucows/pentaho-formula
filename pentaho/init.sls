{%- from "pentaho/envmap.jinja" import env_config as config with context %}
{%- set env_props = salt.pillar.get('environment:' + salt.grains.get('environment')) %}
{%- set environment = salt.grains.get('environment') %}
{%- set version = config['current_version'] %}
{%- set install_loc = config['install_loc'] %}
{%- set s3_loc = 's3://salt-prod/pentaho' %}
{%- set mysql_host = config['mysql_host'] %}
{%- set mysql_hibernate_host = mysql_host %}
{%- set mysql_jcr_host = mysql_host %}
{%- set mysql_hibernate_user = config['hibernate']['mysql_user'] %}
{%- set mysql_jcr_user = config['jackrabbit']['mysql_user'] %}
{%- from 'lib/tomcat.sls' import tomcat_user %}
{{ tomcat_user('pentaho') }}

include:
  - tomcat8-libs
  - prometheus.exporters.jmx

#conf_file_init_default:
#  file.managed:
#    - template: jinja
##    - name: /etc/default/pentaho
#    - source: salt://pentaho/conf/etc/default/pentaho
#    - context:
#        pentaho_license_path: {{ install_loc }}/{{ config['versions'][version]['license-installer.zip']['unzip_loc'] }} 
##        di_home: {{ install_loc }}/pentaho/pentaho/server/pentaho-server/pentaho-solutions/system/kettle
#        java_loc: "/usr/lib/jvm/java-8-oracle"
#        j_opts: |
#          {{ config['j_opts'] }}

dir_pentaho_dot:
  file.directory:
    - name: {{ install_loc }}/.pentaho
    - makdirs: true
    - user: pentaho
    - group: pentaho

dir_pentaho_server:
  file.directory:
    - name: {{ install_loc }}/{{ version }}/server/pentaho-server/
    - makedirs: true
    - user: pentaho
    - group: pentaho

dir_opt_pentaho_tomcat:
  file.recurse:
    - template: jinja
    - name: {{ install_loc }}/{{ version }}/server/pentaho-server/tomcat/
    - source: salt://pentaho/conf/opt/pentaho/server/pentaho-server/tomcat
    - include_empty: True
    - user: pentaho
    - group: pentaho
    - dir_mode: 0755 
    - file_mode: 0744 
    - clean: False
    - replace: False # this means any changes are not replaced! you have to delete the file for salt to recreate the file
    - require:
      - file: dir_pentaho_server
    - context:
        mysql_hibernate_host: {{ mysql_hibernate_host }}
        mysql_hibernate_user: {{ mysql_hibernate_user }}
        mysql_hibernate_password: {{ salt.pillar.get('secrets:pentaho:hibernate:mysql:password') }}

#war files
pentaho_webapp_war:
  file.managed:
    - name: {{ install_loc }}/{{ version }}/server/pentaho-server/tomcat/webapps/pentaho.war
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['pentaho.war']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['pentaho.war']['hash'] }}
    - user: pentaho
    - group: pentaho
    - mode: 644
    - require:
      - file: dir_opt_pentaho_tomcat

pentaho_style_war:
  file.managed:
    - name: {{ install_loc }}/{{ version }}/server/pentaho-server/tomcat/webapps/pentaho-style.war
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['pentaho-style.war']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['pentaho-style.war']['hash'] }}
    - user: pentaho
    - group: pentaho
    - mode: 644
    - require:
      - file: dir_opt_pentaho_tomcat

#TODO: these unzips should be a simple for loop with .iteritems()
unzip_solutions:
  archive.extracted:
    - name: {{ install_loc }}/{{ version }}{{ config['versions'][version]['pentaho-solutions.zip']['unzip_loc'] }} 
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['pentaho-solutions.zip']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['pentaho-solutions.zip']['hash'] }}
    - clean: True
    - user: pentaho
    - group: pentaho
    - archive_format: zip

unzip_pdd_plugin:
  archive.extracted:
    - name: {{ install_loc }}/{{ version }}{{ config['versions'][version]['pdd-plugin.zip']['unzip_loc'] }}  
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['pdd-plugin.zip']['source_loc'] }} 
    - source_hash: {{ config['versions'][version]['pdd-plugin.zip']['hash'] }}
    - enforce_toplevel: False
    - user: pentaho
    - group: pentaho
    - archive_format: zip
    - require:
      - archive: unzip_solutions

unzip_pir_plugin:
  archive.extracted:
    - name: {{ install_loc }}/{{ version }}{{ config['versions'][version]['pir-plugin.zip']['unzip_loc'] }} 
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['pir-plugin.zip']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['pir-plugin.zip']['hash'] }}
    - enforce_toplevel: False
    - user: pentaho
    - group: pentaho
    - archive_format: zip
    - require:
      - archive: unzip_solutions

unzip_paz_plugin:
  archive.extracted:
    - name: {{ install_loc }}/{{ version }}{{ config['versions'][version]['paz-plugin.zip']['unzip_loc'] }} 
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['paz-plugin.zip']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['paz-plugin.zip']['hash'] }}
    - enforce_toplevel: False
    - user: pentaho
    - group: pentaho
    - archive_format: zip
    - require:
      - archive: unzip_solutions

unzip_license_installer:
  archive.extracted:
    - name: {{ install_loc }}/{{ version }}{{ config['versions'][version]['license-installer.zip']['unzip_loc'] }} 
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['license-installer.zip']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['license-installer.zip']['hash'] }}
    - clean: True
    - user: pentaho
    - group: pentaho
    - archive_format: zip

unzip_jdbc_utility:
  archive.extracted:
    - name: {{ install_loc }}/{{ version }}{{ config['versions'][version]['jdbc-distribution-utility.zip']['unzip_loc'] }}
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['jdbc-distribution-utility.zip']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['jdbc-distribution-utility.zip']['hash'] }}
    - clean: True
    - user: pentaho
    - group: pentaho
    - archive_format: zip

unzip_data:
  archive.extracted:
    - name: {{ install_loc }}/{{ version }}{{ config['versions'][version]['pentaho-data.zip']['unzip_loc'] }} 
    - source: {{ s3_loc }}/{{ version }}/{{ config['versions'][version]['pentaho-data.zip']['source_loc'] }}
    - source_hash: {{ config['versions'][version]['pentaho-data.zip']['hash'] }}
    - clean: True
    - user: pentaho
    - group: pentaho
    - archive_format: zip

symlink_current_pentaho_version:
  file.symlink:
    - name: {{ install_loc }}/pentaho
    - target: {{ install_loc }}/{{ version }}
    - user: pentaho
    - group: pentaho

restart_for_pentaho_configs:
  cmd.run:
    - name: service pentaho restart
    - onchanges:
      - file: dir_opt_pentaho_tomcat

#apparently pentaho needs xvfb to generate charts and stuff 
pentaho_required_xvfb:
  pkg.latest:
    - name: xvfb

# configuration changes for mysql backing https://help.pentaho.com/Documentation/8.1/Setup/Installation/Manual/MySQL_Repository
quartz_db_mysql_jobstore_driver:
  file.line:
    - name: {{ install_loc }}/{{ version }}/server/pentaho-server/pentaho-solutions/system/quartz/quartz.properties
    - content: org.quartz.jobStore.driverDelegateClass = org.quartz.impl.jdbcjobstore.StdJDBCDelegate
    - match: org.quartz.jobStore.driverDelegateClass = org.quartz.impl.jdbcjobstore.PostgreSQLDelegate
    - mode: replace
    - user: pentaho
    - group: pentaho
    - file_mode: 664 
    - require:
      - archive: unzip_solutions

hibernate_specify_db_mysql_cnf_file:
  file.line:
    - name: {{ install_loc }}/{{ version }}/server/pentaho-server/pentaho-solutions/system/hibernate/hibernate-settings.xml
    - content: <config-file>system/hibernate/mysql5.hibernate.cfg.xml</config-file>
    - match: <config-file>system/hibernate/postgresql.hibernate.cfg.xml</config-file>
    - mode: replace
    - indent: True
    - user: pentaho
    - group: pentaho
    - file_mode: 644 
    - require:
      - archive: unzip_solutions

hibernate_db_mysql_cnf_file:
  file.managed:
    - name: {{ install_loc }}/{{ version }}/server/pentaho-server/pentaho-solutions/system/hibernate/mysql5.hibernate.cfg.xml
    - template: jinja
    - source: salt://pentaho/conf/opt/pentaho/server/pentaho-server/pentaho-solutions/system/hibernate/mysql5.hibernate.cfg.xml
    - require:
      - archive: unzip_solutions
    - context: 
        mysql_hibernate_host: {{ mysql_hibernate_host }}
        mysql_hibernate_user: {{ mysql_hibernate_user }}
        mysql_hibernate_password: {{ salt.pillar.get('secrets:pentaho:hibernate:mysql:password') }}

audit_sql_cp:
  file.managed:
    - name: {{ install_loc }}/{{ version }}/server/pentaho-server/pentaho-solutions/system/audit_sql.xml
    - source: salt://pentaho/conf/opt/pentaho/server/pentaho-server/pentaho-solutions/system/audit_sql.xml
    - user: pentaho
    - group: pentaho
    - mode: 664
    - require:
      - archive: unzip_solutions

jackrabbit_repository_mysql_config:
  file.managed:
    - name: {{ install_loc }}/{{ version }}/server/pentaho-server/pentaho-solutions/system/jackrabbit/repository.xml
    - template: jinja
    - source: salt://pentaho/conf/opt/pentaho/server/pentaho-server/pentaho-solutions/system/jackrabbit/repository.xml
    - user: pentaho
    - group: pentaho
    - mode: 664
    - require:
      - archive: unzip_solutions
    - context:
        mysql_jcr_host: {{ mysql_jcr_host }}
        mysql_jcr_user: {{ mysql_jcr_user }}
        mysql_jcr_password: {{ salt.pillar.get('secrets:pentaho:jcr:mysql:password') }}

#jdbc driver
jdbc_driver:
  file.symlink:
    - name: {{ install_loc }}/{{ version }}/server/pentaho-server/tomcat/lib/mysql-connector-java.jar
    - target: /usr/share/java/mysql-connector-java.jar
    - force: True
    - user: pentaho
    - group: pentaho
    - mode: 644
    - require:
      - file: dir_opt_pentaho_tomcat

# init script
pentaho_tomcat_private_instance_init:
  file.managed:
    - name: /etc/init.d/pentaho
    - template: jinja
    - source: salt://pentaho/conf/etc/init.d/pentaho
    - user: root
    - group: root
    - mode: 755
    - context:
        install_loc: {{ install_loc }}
        pentaho_license_path: {{ install_loc }}/{{ config['versions'][version]['license-installer.zip']['unzip_loc'] }}
        di_home: {{ install_loc }}/pentaho/pentaho/server/pentaho-server/pentaho-solutions/system/kettle
        java_loc: "/usr/lib/jvm/java-8-oracle"
        j_opts: |
          {{ config['j_opts'] }}

    

#pentaho_jmx_exporter:
#  plos_consul.advertise:
#    - name: tomcat_jmx_exporter
#    - port: 7071
#    - tags:
#      - {{ environment }}
#      - cluster=pentaho
#    - checks:
#      - tcp: {{ grains['fqdn'] }}:7071
#        interval: 10s
