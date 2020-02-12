#!/bin/sh

# ------------------
# Basic settings
_SCRIPT_DIR=`dirname "$(readlink -f "$0")"`
_SCRIPT_NAME=`basename "$0"`
source "${_SCRIPT_DIR}/.v-common.rc"

# ------------------
# Help
if [[ $# -lt 1 || "$1" == "-h" || "$1" == "--help" ]]; then
    cat << _EOF_

Usage: [VARIABLES] ${_SCRIPT_NAME} v-FILE

Un-mount a vdisk file.

    v-FILE      Path to the vdisk file.

${_HELP_VARIABLES}

Example:

    ${SCRIPT_NAME} x:/some/vdisk.vhdx
    _VERBOSE=4 _NO_COLOR=0 ${_SCRIPT_NAME} x:/some/vdisk.vhdx
_EOF_
    exit
fi

# ------------------
# Preparation
_check_file_exist "$1"
vdiskFile=$(realpath "$1")

diskpartScript=$(cat << _EOF_
select vdisk file="${vdiskFile//\//\\}"
detach vdisk
_EOF_
)

# ------------------
# Action
_log_highlight "Un-mounting '${vdiskFile}' ..."
_log_info "----- Script to be run by diskpart:"
_log_info "${diskpartScript}"

_log_info "----- Running diskpart ..."
echo "${diskpartScript}" | ${_DISKPART} >&${_LOG_INFO_FD}
