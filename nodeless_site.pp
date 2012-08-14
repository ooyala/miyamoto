# Masterless and nodeless puppet.

import "classes/*"

node default {

  include puppet_support::base

}

schedule { daily:
    period => daily,
}

Exec {
  path => "/usr/bin:/usr/sbin/:/bin:/sbin:/usr/local/bin:/usr/local/sbin",
  logoutput => on_failure,
}

File {
  owner  => 'root',
  group  => 'root',
  mode   => 664,
  ensure => present,
}
