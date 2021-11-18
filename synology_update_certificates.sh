#!/usr/bin/env bash
#
##########################################
##										##
##     Update server certificates		##
##			(for Synology)				##
##										##
##########################################
#
# (C) 2021 Branislav Susila
# Purpose: Update Server certificates
#
# Script updates certificate used for Synology services. The certificate is a wildcard certificate
# from Let'sEncrypt, which is renewed and stored at my docker server.
# Script connects to the docker server, checks for new certificates, downloads and installs on Synology.

set -e

# DECLARE HERE:
	REMOTE_FILE_BASE="/home/frodo/docker/shared/letsencrypt/live/susilafamily.com/"
	REMOTE_FILES="${REMOTE_FILE_BASE}*.pem"
	REMOTE_CONN="user@FQDN.of.server"	# Update to actual user and FQDN (check ssh login rules at server)
	LOCAL_DEST="/volume1/documents/tmp_certs"
	LOG_FILE="/volume1/documents/update_certificates.log"

	declare -a CERT_FILES
	CERT_FILES=(\
	'cert.pem' \
	'chain.pem' \
	'fullchain.pem' \
	'privkey.pem'
	)

	# define certificates that might need an update (this may change depending on applications used)
	declare -a CERT_DIRS
	CERT_DIRS=(\
	'/usr/local/etc/certificate/SynologyDrive/SynologyDrive/' \
	'/usr/local/etc/certificate/DirectoryServerForWindowsDomain/ldaps/' \
	'/usr/local/etc/certificate/WebDAVServer/webdav/' \
	'/usr/local/etc/certificate/DirectoryServer/slapd/' \
	'/usr/local/etc/certificate/CardDAVServer/carddav/' \
	'/usr/local/etc/certificate/RadiusServer/radiusd/' \
	'/usr/syno/etc/certificate/btrfsreplica/snapshot_receiver/' \
	'/usr/syno/etc/certificate/AppPortal/Chat_AltPort/' \
	'/usr/syno/etc/certificate/system/default/' \
	'/usr/syno/etc/certificate/smbftpd/ftpd/'
	)

	# define apps to reload (may change depending on applications used)
	declare -a SERVICES_TO_RELOAD
	SERVICES_TO_RELOAD=(\
	'pkgctl-WebStation' \
	'pkgctl-Chat' \
	'pkgctl-RadiusServer' \
	'pkgctl-DirectoryServer' \
	'pkgctl-DirectoryServerForWindowsDomain' \
	'pkgctl-CardDAVServer' \
	'pkgctl-WebDAVServer' \
	'pkgctl-SynologyDrive' \
	'ftpd-ssl' \
	'nginx' \
	'ldap-server'
	)

# End of Declarations

# FUNCTIONS
function download_certificates() {
	for f in "${CERT_FILES[@]}"
	do
		ssh "${REMOTE_CONN}" "sudo cat ${REMOTE_FILE_BASE}${f}" > "${LOCAL_DEST}/${f}"
	done
}

function update_all_locations() {
	for d in "${CERT_DIRS[@]}"
	do
		for f in "${CERT_FILES[@]}"
		do
			cp "${LOCAL_DEST}/${f}" "$d"
			chmod 400 "${d}${f}"
		done

		case "${d}" in
			*SynologyDrive*)
				for f in "${CERT_FILES[@]}"
				do
					chown SynologyDrive:SynologyDrive "${d}${f}"
				done
			;;
			*CardDAV*)
				for f in "${CERT_FILES[@]}"
				do
					chown CardDAV:CardDAVServer "${d}${f}"
				done
			;;
		esac
	done
}

function restart_services() {
	# synoservicecfg --list
	set +e

	for rs in "${SERVICES_TO_RELOAD[@]}"
	do
		synoservicectl --reload "${rs}" >> ${LOG_FILE}
	done

	set -e
}

# Main part starts here #
  echo ">>>  $(date) - START" >> "${LOG_FILE}"

# Check if new certs are deployed
  if ssh "${REMOTE_CONN}" "test -e /home/frodo/docker/shared/new_certs_deployed"; then
      mkdir -p "${LOCAL_DEST}"
      download_certificates
      # Leave note at dkhost that certificates were grabbed
        ssh "${REMOTE_CONN}" "install -m 777 /dev/null /home/frodo/docker/shared/synology_grabbed_certs"
      update_all_locations
      restart_services
      rm -r "${LOCAL_DEST}/"
  else
      echo "No new certificates found" >> "${LOG_FILE}"
  fi

  echo ">>>  $(date) - Done" >> "${LOG_FILE}"
