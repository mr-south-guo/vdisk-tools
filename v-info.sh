#!/bin/sh
# shellcheck disable=1090

# ------------------
# Basic settings
_SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
_SCRIPT_NAME=$(basename "$0")
. "${_SCRIPT_DIR}/.v-common.rc"
[ "${_LOG_PREFIX}" ] || _LOG_PREFIX="[${_SCRIPT_NAME}] "

# ------------------
# Help
if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat << _EOF_

Usage: [VARIABLES] ${_SCRIPT_NAME} v-FILE

Show information on a vdisk file.

    v-FILE      Path to the vdisk file.

${_HELP_VARIABLES}

Example:

    ${_SCRIPT_NAME} x:/some/vdisk.vhdx
    _VERBOSE=4 _NO_COLOR=0 ${_SCRIPT_NAME} x:/some/vdisk.vhdx
_EOF_
    exit
fi

# ------------------
# Preparation
_check_file_exist "$1"
vdiskFile=$(realpath "$1")

vdiskFile=$(toWindowsPath "${vdiskFile}")
diskpartScript=$(cat << _EOF_
select vdisk file="${vdiskFile}"
detail vdisk
_EOF_
)

# ------------------
# Action
_log_highlight "Showing information on '${vdiskFile}' ..."

_log_info "--- Diskpart script: begin"
_LOG_PREFIX="" _log_info "${diskpartScript}"
_log_info "--- Diskpart script: end"

_log_info "Running diskpart ..."
echo "${diskpartScript}" | ${_DISKPART}
