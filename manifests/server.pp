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
  $subsystem_sftp           = '/usr/libexec/openssh/sftp-server',
  $sshd_config_subsystems   = {}
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
  $sshd_config_parameters = {
    'PasswordAuthentication' => { 'value' => $password_authentication },
    'PermitEmptyPasswords' => { 'value' => $permit_empty_passwords },
    'PermitRootLogin' => { 'value' => $permit_root_login },
    'UsePAM' => { 'value' => $use_pam },
    'X11Forwarding' => { 'value' => $x11_forwarding },
  }

  $sshd_config_resources = merge($sshd_config_parameters, $sshd_configs)

  $sshd_config_defaults = {
    'ensure'  => 'present',
    'target'  => $config_path,
    'notify'  => $sshd_config_notify,
  }

  create_resources(sshd_config, $sshd_config_resources, $sshd_config_defaults)

  # sshd_config_subsystem resource creation
  $sshd_config_subsystem_parameters = {
    'sftp' => { 'command' => $subsystem_sftp },
  }

  $sshd_config_subsystem_resources = merge($sshd_config_subsystem_parameters, $sshd_config_subsystems)

  $sshd_config_subsystem_defaults = {
    'ensure'  => 'present',
    'target'  => $config_path,
    'notify'  => $sshd_config_subsystem_notify,
  }

  create_resources(sshd_config_subsystem, $sshd_config_subsystem_resources, $sshd_config_subsystem_defaults)
}
