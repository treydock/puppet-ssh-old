# == Class: ssh::params
#
# The ssh configuration settings.
#
# === Authors
#
# Trey Dockendorf <treydock@gmail.com>
#
# === Copyright
#
# Copyright 2013 Trey Dockendorf
#
class ssh::params {

  case $::osfamily {
    'RedHat': {
      $server_package_name  = 'openssh-server'
      $service_name         = 'sshd'
      $service_hasstatus    = true
      $service_hasrestart   = true
      $server_config_path   = '/etc/ssh/sshd_config'
    }

    default: {
      fail("Unsupported osfamily: ${::osfamily}, module ${module_name} only support osfamily RedHat")
    }
  }

}