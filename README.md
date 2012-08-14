miyamoto
========

# Base setup
If you're going to go masterless for both your macs and your servers,
I recommend that you use different directory trees in S3. I use

bucket/ubuntu/binaries
bucket/ubuntu/manifests
bucket/ubuntu/status

for my servers, and

bucket/osx/binaries
bucket/osx/manifests
bucket/osx/status

for my OS X machines.

I use a different AWS user for each architecture tree, and separate
AWS groups to control the acls for the trees. The machine users only
have write permission on the status subdirectory of their architecture
subtree, and RO access to the rest of their architecture tree. A
compromised machine can't push new manifests to its own architecture,
and it can't view the manifests or statuses of the other architectures.

I've included an example AWS policy that enforces this. It assumes
that you're dedicating an entire AWS bucket to your masterless
setup, and I recommend that you do so so you don't have to worry
about problems in the policy leaving the rest of the files in your
bucket vulnerable to attack if someone gets their hands on one of
your masterless machines.

# Requirements:
* AWS account
* Tim Kay's aws script (get the latest version from http://timkay.com/aws/)
* s3cmd
* Dedicated S3 bucket

If you're planning to administer Debian/Ubuntu clients, you'll need
Jordan Sissel's fpm gem. If you're administering OS X clients,
you'll need to install my Luggage tool (http://github.com/unixorn/luggage).

If you're planning to use this with RedHat/Centos, it shouldn't
take much tweaking to have fpm spit out rpms instead of debs and
have mm_update_manifests cope accordingly.

# Fun with Rake

The Rakefile assumes that you are going to have a stable and a development
environment, and that they'll be in separate git branches. Set stable in
config.json to the name of your stable branch, and development to your
development environment.

rake -T for all the available rake tasks

# Quick Start
1. Create an S3 bucket (masterless-puppet.example.com)
2. Create the directory tree you want in your bucket as shown in the Base Setup
3. Create an AWS user for your machines with iam-usercreate. If you're puppeting more than one architecture, I recommend one user per architecture, and keep the architectures in separate repositories
4. Create an AWS group for each architecture with iam-groupcreate
5. Modify the enclosed policy to use your bucket and directory tree, then apply it to your AWS group
6. Copy base_config.json to config.json, edit appropriately for your setup
7. sudo rake experimental_checkout will create a deb of the current configuration without changing branches