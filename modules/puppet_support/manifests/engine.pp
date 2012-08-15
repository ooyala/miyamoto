class puppet_support::engine {

  # puppet cron helper script
  file { '/usr/local/sbin/mm_puppet_cronjob':
    owner => 'root',
    group => 'root',
    mode  => 755,
    require => [ File['/usr/local/sbin'], File['/usr/local/sbin/mm_update_puppet_manifests'], ],
    source  => 'puppet:///modules/puppet_support/mm_puppet_cronjob',
  }

  # Tim Kay's AWS tool http://timkay.com/aws/ - we use this to pull crap from s3
  file { '/usr/local/bin/aws':
    owner => 'root',
    group => 'root',
    mode  => 755,
    source  => 'puppet:///modules/puppet_support/aws',
    require => [ File['/usr/local/sbin'], ],
  }

  file { '/root/.awssecret':
    owner => 'root',
    group => 'root',
    mode  => 400,
    source => 'puppet:///modules/puppet_support/.awssecret',
  }

  file { '/usr/local/sbin/mm_update_puppet_manifests':
    owner => 'root',
    group => 'root',
    mode  => 755,
    require => File['/usr/local/sbin'],
    source  => 'puppet:///modules/puppet_support/mm_update_puppet_manifests',
  }

  # helper app that runs puppet and stores the exit status for use by plan B
  file { '/usr/local/sbin/puppetstarter':
    owner => 'root',
    group => 'root',
    mode  => 755,
    require => File['/usr/local/sbin'],
    source  => 'puppet:///modules/puppet_support/puppetstarter',
  }

  # facter wrapper that deals with facter bug where you can't do
  # 'facter factname' if factname relies on other facts to compute the value
  file { '/usr/local/bin/fctr':
    owner => 'root',
    group => 'root',
    mode  => 755,
    require => File['/usr/local/bin'],
    source  => 'puppet:///modules/puppet_support/fctr.rb',
  }

  file { '/usr/local/sbin/assimilate_server':
    owner => 'root',
    group => 'root',
    mode  => 755,
    require => [ File['/usr/local/sbin'], File['/usr/local/bin/aws'], ],
    source  => 'puppet:///modules/puppet_support/assimilate_server',
  }

  file {'/etc/miyamoto':
    owner => 'root',
    group => 'root',
    ensure => directory,
  }

  file { '/etc/miyamoto/puppet_aws_credentials.sh':
    owner => 'root',
    group => 'root',
    mode  => 644,
    require => [ File['/etc/miyamoto'], ],
    source  => 'puppet:///modules/puppet_support/puppet_aws_credentials.sh',
  }

  # run every 30 minutes
  cron { puppet_cron:
    command => '/usr/local/sbin/mm_puppet_cronjob > /dev/null',
    user => 'root',
    minute => '*/30',
    require => [File['/usr/local/sbin/mm_puppet_cronjob'], ],
  }

}
