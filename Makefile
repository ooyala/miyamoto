# Copyright 2012 Ooyala, Inc.
# Author: Joe Block <jpb@ooyala.com>
# License: BSD
#
# Create a pkg that installs the current manifests into /etc/ooyala/puppet
#
# You must have already installed the luggage (available from
# https://github.com/unixorn/luggage) for this to work.

include /usr/local/share/luggage/luggage.make

TITLE=${BRANCH}
REVERSE_DOMAIN=com.example.corp
PUPPET_BASE=modules/puppet_support/files
MANIFEST_VERSION:=$(shell date +%Y%m%d%H%M)
MANIFEST_D=${WORK_D}/etc/miyamoto/puppet
PACKAGE_VERSION=$(shell date +%Y%m%d%H%M)
PAYLOAD=pack_manifests puppet_environment_version puppet_environment_flavor pack_puppet_engine

manifest_d: l_private_etc
	@sudo mkdir -p ${MANIFEST_D}

# can't sudo echo > file if the user doesn't have write perms, cope
puppet_environment_flavor: scratchdir manifest_d
	@sudo touch ${SCRATCH_D}/puppet_environment_flavor
	@sudo chown ${USER} ${SCRATCH_D}/puppet_environment_flavor
	@echo ${BRANCH} > ${SCRATCH_D}/puppet_environment_flavor
	@sudo mv ${SCRATCH_D}/puppet_environment_flavor ${MANIFEST_D}/puppet_environment_flavor
	@sudo chown root:wheel ${MANIFEST_D}/puppet_environment_flavor

puppet_environment_version: scratchdir
	@sudo touch ${SCRATCH_D}/puppet_environment_version
	@sudo chown ${USER} ${SCRATCH_D}/puppet_environment_version
	@echo ${MANIFEST_VERSION} > ${SCRATCH_D}/puppet_environment_version
	@echo "Setting version to ${MANIFEST_VERSION}"
	@sudo cp -f ${SCRATCH_D}/puppet_environment_version ${MANIFEST_D}/puppet_environment_version
	@sudo chown root:wheel ${MANIFEST_D}/puppet_environment_version

pack_manifests: manifest_d
	@sudo rsync -av --progress --stats nodeless_site.pp modules classes ${MANIFEST_D}
	@sudo chown -R root:admin ${MANIFEST_D}

pack_puppet_engine: pack_aws \
	pack_install_from_dmg \
	pack_install_dmg_from_s3 \
	pack_oo_sync_facts \
	pack_oo_update_puppet_manifests \
	pack_puppet_plist \
	pack_puppetstarter

pack_aws: l_usr_local_bin pack_aws_credentials
	@sudo ${CP} ${PUPPET_BASE}/aws ${WORK_D}/usr/local/bin
	@sudo chown root:wheel ${WORK_D}/usr/local/bin/aws
	@sudo chmod 755 ${WORK_D}/usr/local/bin/aws

pack_aws_credentials: manifest_d
	@sudo ${CP} ${PUPPET_BASE}/puppet_aws_credentials ${MANIFEST_D}
	@sudo ${CP} ${PUPPET_BASE}/.awssecret ${MANIFEST_D}
	@sudo chown root:wheel ${MANIFEST_D}/puppet_aws_credentials
	@sudo chmod 600 ${MANIFEST_D}/puppet_aws_credentials
	@sudo chown root:wheel ${MANIFEST_D}/.awssecret
	@sudo chmod 600 ${MANIFEST_D}/.awssecret

pack_fctr: l_usr_local_bin
	@sudo ${CP} ${PUPPET_BASE}/fctr ${WORK_D}/usr/local/bin
	@sudo chown root:admin ${WORK_D}/usr/local/bin/fctr
	@sudo chmod 755 ${WORK_D}/usr/local/bin/fctr

pack_install_dmg_from_s3: l_usr_local_sbin
	@sudo ${CP} ${PUPPET_BASE}/install_dmg_from_s3 ${WORK_D}/usr/local/sbin/install_dmg_from_s3
	@sudo chown root:admin ${WORK_D}/usr/local/sbin/install_dmg_from_s3
	@sudo chmod 755 ${WORK_D}/usr/local/sbin/install_dmg_from_s3

pack_install_from_dmg: l_usr_local_sbin
	@sudo ${CP} ${PUPPET_BASE}/install_from_dmg.py ${WORK_D}/usr/local/sbin/install_from_dmg
	@sudo chown root:admin ${WORK_D}/usr/local/sbin/install_from_dmg
	@sudo chmod 755 ${WORK_D}/usr/local/sbin/install_from_dmg

pack_oo_sync_facts: l_usr_local_sbin
	@sudo ${CP} ${PUPPET_BASE}/oo_sync_facts ${WORK_D}/usr/local/sbin
	@sudo chown root:admin ${WORK_D}/usr/local/sbin/oo_sync_facts
	@sudo chmod 755 ${WORK_D}/usr/local/sbin/oo_sync_facts

pack_oo_update_puppet_manifests: l_usr_local_sbin
	@sudo ${CP} ${PUPPET_BASE}/oo_update_puppet_manifests ${WORK_D}/usr/local/sbin
	@sudo chown root:admin ${WORK_D}/usr/local/sbin/oo_update_puppet_manifests
	@sudo chmod 755 ${WORK_D}/usr/local/sbin/oo_update_puppet_manifests

pack_puppet_plist: l_Library_LaunchDaemons
	@sudo ${CP} ${PUPPET_BASE}/puppetstarter.plist ${WORK_D}/Library/LaunchDaemons/com.example.corp.puppetclient.plist
	@sudo chown root:admin ${WORK_D}/Library/LaunchDaemons/com.example.corp.puppetclient.plist
	@sudo chmod 644 ${WORK_D}/Library/LaunchDaemons/com.example.corp.puppetclient.plist

pack_puppetstarter: l_usr_local_sbin
	@sudo ${CP} ${PUPPET_BASE}/puppetstarter ${WORK_D}/usr/local/sbin
	@sudo chown root:admin ${WORK_D}/usr/local/sbin/puppetstarter
	@sudo chmod 755 ${WORK_D}/usr/local/sbin/puppetstarter
