# == Class: ssh::server
#
# Full description of class ssh here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Examples
#
#  class { 'ssh::server': }
#
# === Authors
#
# Trey Dockendorf <treydock@gmail.com>
#
# === Copyright
#
# Copyright 2013 Trey Dockendorf
#
class ssh::server (
  $package_name             = $ssh::params::server_package_name,
  $service_name             = $ssh::params::service_name,
  $service_ensure           = 'running',
  $service_enable           = true,
  $service_hasstatus        = $ssh::params::service_hasstatus,
  $service_hasrestart       = $ssh::params::service_hasrestart,
  $service_autorestart      = true,
  $config_path              = $ssh::params::server_config_path,
  $password_authentication  = 'yes',
  $permit_empty_passwords   = 'no',
  $permit_root_login        = 'without-password',
  $use_pam                  = 'yes',
  $x11_forwarding           = 'yes',
  $sshd_configs             = {},
  $subsystem_sftp           = '/usr/libexec/openssh/sftp-server'
) inherits ssh::params {

  validate_bool($service_autorestart)
  validate_hash($sshd_configs)

  # This gives the option to not manage the service 'ensure' state.
  $service_ensure_real  = $service_ensure ? {
    /UNSET|undef/ => undef,
    default       => $service_ensure,
  }

  # This gives the option to not manage the service 'enable' state.
  $service_enable_real  = $service_enable ? {
    /UNSET|undef/ => undef,
    default       => $service_enable,
  }

  if $service_autorestart {
    $sshd_config_notify           = 'Service[ssh]'
    $sshd_config_subsystem_notify = 'Service[ssh]'
  } else {
    $sshd_config_notify           = undef
    $sshd_config_subsystem_notify = undef
  }

  include ssh::server::install

  service { 'ssh':
    ensure      => $service_ensure_real,
    enable      => $service_enable_real,
    name        => $service_name,
    hasstatus   => $service_hasstatus,
    hasrestart  => $service_hasrestart,
  }

  file { '/etc/ssh/sshd_config':
    ensure  => present,
    path    => $config_path,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }

  # sshd_config resource creation
  Sshd_config {
    ensure  => present,
    target  => $config_path,
    notify  => $sshd_config_notify,
  }

  sshd_config { 'PasswordAuthentication': value => $password_authentication }
  sshd_config { 'PermitEmptyPasswords': value => $permit_empty_passwords }
  sshd_config { 'PermitRootLogin': value => $permit_root_login }
  sshd_config { 'UsePAM': value => $use_pam }
  sshd_config { 'X11Forwarding': value => $x11_forwarding }

  if $sshd_configs and !empty($sshd_configs) {
    create_resources(sshd_config, $sshd_configs)
  }

  # sshd_config_subsystem resource creation
  Sshd_config_subsystem {
    ensure  => present,
    target  => $config_path,
    notify  => $sshd_config_subsystem_notify,
  }

  sshd_config_subsystem { 'sftp': command => $subsystem_sftp }
}
