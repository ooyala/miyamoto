class puppet_support::heartbeat {
  # show what the last environment we puppeted against was.

  exec { "echo $puppet_masterless_environment > /etc/knobs/last_puppet_environment":
  }

}
