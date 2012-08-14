class puppet_support::helpers {

  file { '/usr/local/sbin/mm_lock_puppetstarter':
    owner => 'root',
    group => 'root',
    mode  => 755,
    require => File['/usr/local/sbin'],
    source  => 'puppet:///modules/puppet_support/mm_lock_puppetstarter',
  }

  file { '/usr/local/sbin/mm_unlock_puppetstarter':
    owner => 'root',
    group => 'root',
    mode  => 755,
    require => File['/usr/local/sbin'],
    source  => 'puppet:///modules/puppet_support/mm_unlock_puppetstarter',
  }

  # helper apps to check the local catalog yaml file
  file { '/usr/local/sbin/mm_dump_puppet_catalog':
    owner => 'root',
    group => 'root',
    mode  => 755,
    require => File['/usr/local/sbin'],
    source  => 'puppet:///modules/puppet_support/mm_dump_puppet_catalog',
  }

  file { '/usr/local/sbin/mm_parselocalpuppetconfig':
    owner => 'root',
    group => 'root',
    mode  => 755,
    require => File['/usr/local/sbin'],
    source  => 'puppet:///modules/puppet_support/mm_parselocalconfig',
  }

}