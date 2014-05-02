# == Class: reprepro
#
#   Configures reprepro on a server
#
# === Parameters
#
#   - *basedir*: The base directory to house the repository.
#   - *homedir*: The home directory of the reprepro user.
#
# === Example
#
#   class { 'reprepro': }
#
class reprepro (
  $basedir = $::reprepro::params::basedir,
  $homedir = $::reprepro::params::homedir,
) inherits reprepro::params {

  package { $::reprepro::params::package_name:
    ensure => $::reprepro::params::ensure,
  }

  group { 'reprepro':
    ensure => present,
    name   => $::reprepro::params::group_name,
  }

  user { 'reprepro':
    ensure     => present,
    name       => $::reprepro::params::user_name,
    home       => $homedir,
    shell      => '/bin/bash',
    comment    => 'Reprepro user',
    gid        => 'reprepro',
    managehome => true,
    require    => Group['reprepro'],
  }

  file { $basedir:
    ensure  => directory,
    owner   => $::reprepro::params::user_name,
    group   => $::reprepro::params::group_name,
    mode    => '0755',
    require => User['reprepro'],
  }

  file { "${homedir}/.gnupg":
    ensure  => directory,
    owner   => $::reprepro::params::user_name,
    group   => $::reprepro::params::group_name,
    mode    => '0700',
    require => User['reprepro'],
  }

  file { "${::reprepro::homedir}/bin":
    ensure  => directory,
    mode    => '0755',
    owner   => $::reprepro::params::user_name,
    group   => $::reprepro::params::group_name,
    require => User['reprepro'],
  }
  ->
  file { "${::reprepro::homedir}/bin/update-distribution.sh":
    ensure  => file,
    mode    => '0755',
    content => template('reprepro/update-distribution.sh.erb'),
    owner   => $::reprepro::params::user_name,
    group   => $::reprepro::params::group_name,
  }

}

