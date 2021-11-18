#!/bin/bash
#
##########################################
##					##
##     Zip files and erase backups	##
##	     (for Synology)		##
##					##
##########################################
#
# (C) 2021 Branislav Susila
#
# > Script compresses and moves files in a directory into a zip file.
# > ZIPs in directory are ignored.
# > ZIP files older than given threshold are erased.
#
# Parameters (in particular order):
# $1 -> directory with files (if empty string than use present working directory)
# $2 -> number "days ago" -> zip files created X or more days ago (default 6)
# $3 -> number "days ago" -> erase zip files created X or more days ago (default 35 [5 weeks])
#
# Note: Consider Hard-coding options to the 3 variables before if you intend to run the script from cron
#       due to problematic passing of command line arguments in cron.... or use a wrapper script.

WORK_DIR="$(pwd)"
DAYS_AGO=6
ERASE_AGO=35

function _add_trailing_slash {
  STR="$1"
  length=${#STR}
  last_char=${STR:length-1:1}
  [ $last_char != "/" ] && STR="$STR/"
  echo "${STR}"
}

# Process command line arguments:
  [ "$1" != "" ] && WORK_DIR="$1"
  [ "$2" != "" ] && DAYS_AGO="$2"
  [ "$3" != "" ] && ERASE_AGO="$3"

# Normalize dir path and Check WORK_DIR exists
  WORK_DIR=$(_add_trailing_slash "${WORK_DIR}")
  [ ! -d "${WORK_DIR}" ] && exit 1

# ZIP files that match criteria
  FILENAME="backup_$(date +%F)_files_${DAYS_AGO}_or_more_days_old.zip"
  zip "${WORK_DIR}${FILENAME}" "${WORK_DIR}"* -m -tt $(date --date="${DAYS_AGO} days ago" +%F) --exclude "*.zip"

# Erase ZIPs which are beyond threshold (double check the workdir exists)
  [ -d "${WORK_DIR}" ] && find "${WORK_DIR}" -name "*.zip" -mtime +${ERASE_AGO} -type f -delete
