miyamoto
========

# Why bother with masterless?

We had two different use cases at my work that led to my writing
Miyamoto. First, we manage our Macintoshes with puppet, and we have
users in remote locations that don't always need to connect to the
VPN. When their machines aren't on the VPN or corp network, they
can't connect to the puppetmaster and don't receive updates. Miyamoto
allows them to get their manifests from an S3 bucket, so as long
as they have internet, they get puppet updates.

Secondly, we have some compute-intensive tasks that we do in EC2.
As the load on the cluster rises and falls, we add and remove
instances. Hundreds of thousands of instances over time. Way more
than I care to have to deal with when cleaning stale certs out of
the ca certs directory. By using an S3 bucket, we eliminate the
SPOF of a single puppetmaster, or the maintenance hassle of a cluster
of puppetmasters and ca boxes.

## But we're losing reporting

Miyamoto writes the facts collected by facter to a status file in
the S3 bucket, so you still can see what is happening with our fleet
by scraping those files and loading them into your reporting system
of choice. They're in json format so they're easy to parse.

# Base setup

If you're going to go masterless for both your macs and your servers,
I recommend that you use different directory trees in S3. I use

bucket/ubuntu/binaries, bucket/ubuntu/manifests, and bucket/ubuntu/status

for my servers, and

bucket/osx/binaries, bucket/osx/manifests, and bucket/osx/status

for my OS X machines.

## Security

I use a different AWS user for each architecture tree, and separate
AWS groups to control the acls for the trees. The machine users
only have write permission on the status subdirectory of their
architecture subtree, and read-only access to the rest of their
architecture tree. A compromised machine can't push new manifests
to its own architecture, and it can't view the manifests or statuses
of the other architectures.

I've included an example AWS policy that enforces this. It assumes
that you're dedicating an entire AWS bucket to your masterless
setup, and I recommend that you do so so you don't have to worry
about problems in the policy leaving the rest of the files in your
bucket vulnerable to attack if someone gets their hands on one of
your masterless machines.

## Requirements:

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

## Fun with Rake

The Rakefiles assume that you are going to have a stable and a development
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
