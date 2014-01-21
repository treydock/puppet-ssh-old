# == Class: ssh::server::install
#
# Installs SSH server.
#
# === Authors
#
# Trey Dockendorf <treydock@gmail.com>
#
# === Copyright
#
# Copyright 2013 Trey Dockendorf
#
class ssh::server::install {

  include ssh::server

  $package_name = $ssh::server::package_name

  package { 'openssh-server':
    ensure  => present,
    name    => $package_name,
    before  => [ Service['ssh'], File['/etc/ssh/sshd_config'] ],
  }
}
