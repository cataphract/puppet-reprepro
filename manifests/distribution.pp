# == Definition: reprepro::distribution
#
# Adds a "Distribution" to manage.
#
# === Parameters
#
#   - *ensure* present/absent, defaults to present
#   - *basedir* reprepro basedir
#   - *repository*: the name of the distribution
#   - *origin*: package origin
#   - *label*: package label
#   - *suite*: package suite
#   - *architectures*: available architectures
#   - *components*: available components
#   - *description*: a short description
#   - *sign_with*: email of the gpg key
#   - *deb_indices*: file name and compression
#   - *dsc_indices*: file name and compression
#   - *update*: update policy name
#   - *uploaders*: who is allowed to upload packages
#   - *snapshots*: create a reprepro snapshot on each update
#   - *install_cron*: install cron job to automatically include new packages
#   - *not_automatic*: automatic pined to 1 by using NotAutomatic,
#                      value are "yes" or "no"
#   - *but_automatic_upgrades*: in conjunction with not_automatic, pins the
#                               packages to 100 instead of 1. Values are "yes"
#                               or "no". Only considered if not_automatic is
#                               "yes". See man 5 apt_preferences
#
# === Requires
#
#   - Class["reprepro"]
#
# === Example
#
#   reprepro::distribution {"lenny":
#     ensure        => present,
#     repository    => "my-repository",
#     origin        => "Camptocamp",
#     label         => "Camptocamp",
#     suite         => "stable",
#     architectures => "i386 amd64 source",
#     components    => "main contrib non-free",
#     description   => "A simple example of repository distribution",
#     sign_with     => "packages@camptocamp.com",
#   }
#
#
define reprepro::distribution (
  $repository,
  $origin,
  $label,
  $suite,
  $architectures,
  $components,
  $description,
  $sign_with,
  $codename               = $name,
  $ensure                 = present,
  $basedir                = $::reprepro::basedir,
  $udebcomponents         = $components,
  $deb_indices            = 'Packages Release .gz .bz2',
  $dsc_indices            = 'Sources Release .gz .bz2',
  $update                 = '',
  $uploaders              = '',
  $snapshots              = false,
  $install_cron           = true,
  $not_automatic          = 'yes',
  $but_automatic_upgrades = 'no',
) {

  include reprepro::params
  include concat::setup

  $notify = $ensure ? {
    present => Exec["export distribution ${name}"],
    default => undef,
  }

  concat::fragment { "distribution-${name}":
    ensure  => $ensure,
    target  => "${basedir}/${repository}/conf/distributions",
    content => template('reprepro/distribution.erb'),
    notify  => $notify,
  }

  exec {"export distribution ${name}":
    command     => "su -c 'reprepro -b ${basedir}/${repository} export ${codename}' reprepro",
    path        => ['/bin', '/usr/bin'],
    refreshonly => true,
    logoutput   => on_failure,
    require     => [
      User['reprepro'],
      Reprepro::Repository[$repository]
    ],
  }

  # Configure system for automatically adding packages
  file { "${basedir}/${repository}/tmp/${name}":
    ensure => directory,
    mode   => '0755',
    owner  => $::reprepro::params::user_name,
    group  => $::reprepro::params::group_name,
  }

  if $install_cron {

    if $snapshots {
      $command = "${::reprepro::homedir}/bin/update-distribution.sh -r ${repository} -d ${suite} -c ${name} -s"
    } else {
      $command = "${::reprepro::homedir}/bin/update-distribution.sh -r ${repository} -d ${suite} -c ${name}"
    }

    cron { "${name} cron":
      command     => $command,
      user        => $::reprepro::params::user_name,
      environment => 'SHELL=/bin/bash',
      minute      => '*/5',
      require     => File["${::reprepro::homedir}/bin/update-distribution.sh"],
    }
  }

  if $update {
    concat { "${basedir}/${repository}/conf/updates":
      owner   => $::reprepro::params::user_name,
      group   => $::reprepro::params::group_name,
      mode    => '0640',
      require => File["${basedir}/${repository}/conf"],
    }
  }

}
