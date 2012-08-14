# Copyright 2012 Ooyala, Inc
# Author: Joe Block <jpb@ooyala.com>
#
# This is released under the BSD license.

require 'rubygems'
require 'fileutils'
require 'json'
require 'pp'

# Store config in config.json to make the Rakefile more portable.

config_file = File.open 'config.json'
$config = JSON.parse config_file.read
config_file.close

BUCKET_BASE="s3://#{$config['bucket']}"
BINARIES_D="s3://#{$config['bucket']}/#{$config['binaries']}"
FLAVOR_D="#{$config['bucket']}/#{$config['environments']}"
MANIFEST_D="#{$config['bucket']}/#{$config['manifests']}"

# We have to run as root when making debs or pkgs, but we want to blame the
# appropriate person :-)
if ENV['USER'] == 'root'
  WHICHUSER=ENV['SUDO_USER']
else
  WHICHUSER=ENV['USER']
end

# We want this to be the same for an entire rake invocation and not have
# weird breakages when a run crosses a minute boundary
VERSION_STAMP=%x[ date +%Y%m%d%H%M ].chomp!

# git helpers
def git_checkout!(branch_name)
  `git checkout #{branch_name}`
end

def git_merge!(branch_name)
  `git merge #{branch_name}`
end

def git_push(branch_name)
  `git push #{branch_name}`
end

def current_branch?
  return %x[ git branch | grep '^\*' | cut -d ' ' -f2 ].chomp
end

# Helper function for constructing the package root for fpm
def copy_base_files(the_d)
  puppet_support = 'modules/puppet_support/files'
  local_d = "#{the_d}/usr/local"
  bin_d = "#{local_d}/bin"
  sbin_d = "#{local_d}/sbin"
  root_home_d = "#{the_d}/root"
  FileUtils.mkdir_p(bin_d)
  FileUtils.mkdir_p(sbin_d)
  FileUtils.mkdir_p(root_home_d)
  FileUtils.cp "#{puppet_support}/.awssecret", "#{root_home_d}/.awssecret", :preserve => true
  FileUtils.chmod 0600, "#{puppet_support}/.awssecret"
  FileUtils.cp "#{puppet_support}/fctr.rb", "#{bin_d}/fctr", :preserve => true
  FileUtils.cp "#{puppet_support}/aws", "#{bin_d}", :preserve => true
  FileUtils.cp "#{puppet_support}/assimilate_server", sbin_d, :preserve => true
  FileUtils.cp "#{puppet_support}/mm_puppet_cronjob", sbin_d, :preserve => true
  FileUtils.cp "#{puppet_support}/mm_update_puppet_manifests", sbin_d, :preserve => true
  FileUtils.cp "#{puppet_support}/puppetstarter", sbin_d, :preserve => true
  FileUtils.chown_R 0, 0, the_d
end

def create_deb(flavor)
  temp_d = "/tmp/miyamoto_#{flavor}_#{$$}"
  knob_d = "#{temp_d}/etc/knobs"
  company_d = "#{temp_d}/#{$config['base_directory']}"
  puppet_d = "#{company_d}/puppet/#{flavor}"
  output_deb = "#{flavor}-#{VERSION_STAMP}.deb"
  puts "Packaging branch #{flavor} version #{VERSION_STAMP}..."
  FileUtils.mkdir_p(knob_d)
  FileUtils.mkdir_p(puppet_d)
  # We assume the classes and modules directory trees will be at the root level
  # of the checkout
  if File.directory?('classes')
    FileUtils.cp_r 'classes', puppet_d, :preserve => true
  end
  if File.directory?('modules')
    FileUtils.cp_r 'modules', puppet_d, :preserve => true
  end
  FileUtils.cp_r 'nodeless_site.pp', puppet_d, :preserve => true
  FileUtils.cp 'modules/puppet_support/files/puppet_aws_credentials.sh', company_d, :preserve => true
  %x[ echo #{VERSION_STAMP} > #{puppet_d}/puppet_environment_version ]
  %x[ echo #{flavor} > #{puppet_d}/puppet_environment_flavor ]
  # Set the environment knob on the target machine
  %x[ echo #{flavor} > #{knob_d}/puppet_masterless_environment ]
  copy_base_files(temp_d)
  # OSX doesn't have group root, so use a numeric gid
  puts "fixing file permissions..."
  FileUtils.chown_R 0, 0, temp_d
  %x[ sudo find #{temp_d} -type d -exec chmod -v 755 '{}' ';' ]
  puts "building deb: #{output_deb} from #{temp_d}"
  puts %x[ fpm -s dir -t deb -C #{temp_d} -n ooyala_manifests_#{flavor} -p #{output_deb} -v #{VERSION_STAMP} --description "Version #{VERSION_STAMP} of #{flavor}" --vendor Ooyala etc usr root ]
  FileUtils.rm_rf temp_d
  return output_deb
end

def snapshot_branch_to_dmg(branch)
  dmg_output = %x[ BRANCH=#{branch} make dmg | tail -1 | cut -d':' -f2 ]
  filename = %x[ basename #{dmg_output} ].chomp
  return filename
end

def package_flavor(flavor)
  if $config['os_target'] == 'osx'
    snapshot_branch_to_dmg(flavor)
  end
  if $config['os_target'] == 'ubuntu'
    create_deb(flavor)
  end
end

desc "Ensure we're running as root"
task :running_as_root do
  if ENV['USER'] != 'root'
    fail "You must be root to build packages or debs"
  end
end

desc "Create a package of the current working directory without switching git branches"
task :experimental_checkout => :running_as_root do
  if $config['os_target'] == 'ubuntu'
    create_deb(WHICHUSER)
  end
  if $config['os_target'] == 'osx'
    snapshot_branch_to_dmg(WHICHUSER)
  end
end

desc "Create a package of the stable branch"
task :snapshot_stable => :running_as_root do
  current_checkout = current_branch?
  git_checkout! $config['branches']['stable']
  package_flavor($config['branches']['stable'])
  git_checkout!(current_checkout)
end

desc "Create a package of the testing branch"
task :snapshot_testing => :running_as_root do
  current_checkout = current_branch?
  git_checkout! $config['branches']['testing']
  package_flavor($config['branches']['testing'])
  git_checkout!(current_checkout)
end

def publish_branch(branch)
  filename = publish_flavor(branch)
  flavor_label = "/tmp/flavor_label_#{$$}"
  %x[ s3cmd put #{filename} #{MANIFEST_D}/#{branch}/#{filename} ]
  %x[ echo #{VERSION_STAMP} > #{flavor_label} ]
  %x[ s3cmd put #{flavor_label} #{FLAVOR_D}/#{branch} ]
  FileUtils.rm_rf flavor_label
end

desc "publish the stable branch to s3"
task :publish_stable => :running_as_root do
  current_checkout = current_branch?
  git_checkout! $config['branches']['stable']
  publish_branch $config['branches']['stable']
  git_checkout!(current_checkout)
end

desc "publish the testing branch to s3"
task :publish_testing => :running_as_root do
  current_checkout = current_branch?
  git_checkout! $config['branches']['testing']
  publish_branch $config['branches']['testing']
  git_checkout!(current_checkout)
end

desc "publish stable & testing configs to s3"
task 'publish_all' => [:publish_testing, :publish_stable]

desc "Promote development -> stable, working -> development"
task :promote_environments do
  %x[rake promote_development_to_stable]
  %x[rake promote_master_to_development]
end

# Automate branch promotions

desc "Promote master -> development"
task :promote_master_to_development do
  puts "promoting #{$config['branches']['working']} to #{$config['branches']['testing']}"
  current_checkout = current_branch?
  git_checkout! $config['branches']['testing']
  git_merge! $config['branches']['working']
  git_push "origin #{$config['branches']['testing']}"
  git_checkout! current_checkout
end

desc "Promote development -> stable"
task :promote_development_to_stable do
  current_checkout = current_branch?
  puts "promoting #{$config['branches']['testing']} to #{$config['branches']['stable']}"
  git_checkout! $config['branches']['stable']
  git_merge! $config['branches']['testing']
  git_push "origin #{$config['branches']['stable']}"
  git_checkout! current_checkout
end

# Confirm your json says what you think it says.
desc "Display config from config.json in human-readable format"
task :display_json_config do
  pp $config
  puts
  puts "BUCKET_BASE: #{BUCKET_BASE}"
  puts "BINARIES_D: #{BINARIES_D}"
  puts "FLAVOR_D: #{FLAVOR_D}"
  puts "MANIFEST_D: #{MANIFEST_D}"
  puts "WHICHUSER: #{WHICHUSER}"
end

# cleanup

desc "zap all debs, pkgs and dmgs"
task :zap_all_debs do
  %x[ rm -rf *.deb *.pkg *.dmg ]
end

desc "Clean"
task :clean do
  `find . -name .DS_Store -exec rm -v '{}' ';'`
  `find . -name '.*~' -exec rm -v '{}' ';'`
end
