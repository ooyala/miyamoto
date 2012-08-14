#!/usr/bin/ruby

require 'facter'
require 'puppet'

ENV['FACTERLIB']='/etc/miyamoto/puppet/facter'

Puppet.parse_config
unless $LOAD_PATH.include?(Puppet[:libdir])
  $LOAD_PATH << Puppet[:libdir]
end

facts = Facter.to_hash

if ARGV.size > 0
  ARGV.each do |f|
    if ARGV.size == 1
      # if we are only asking for one fact, we don't need to print what fact it
      # is, so let's make the calling scripts not have to strip off extraneous
      # crap to get at the actual fact value.
      puts "#{facts[f]}" if facts.include?(f)
    else
      puts "#{f} => #{facts[f]}" if facts.include?(f)
    end
  end
else
  facts.keys.sort.each do |k|
    puts "#{k} => #{facts[k]}"
  end
end