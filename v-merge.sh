#!/bin/sh
# shellcheck disable=1090

# ------------------
# Basic settings
_SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
_SCRIPT_NAME=$(basename "$0")
. "${_SCRIPT_DIR}/.v-common.rc"
[ "${_LOG_PREFIX}" ] || _LOG_PREFIX="[${_SCRIPT_NAME}] "

# ------------------
# Default values
optDepth=1

# ------------------
# Help
if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat << _EOF_

Usage: [VARIABLES] ${_SCRIPT_NAME} [OPTIONS] v-FILE

Merge a differencing vdisk's content to its parents.

    v-FILE      Path to the differencing vdisk file.

OPTIONS:

    -d,--depth DEPTH    Depth to merge. Default is 1.

${_HELP_VARIABLES}

Example:

    ${_SCRIPT_NAME} x:/some/diff.vhdx
    _VERBOSE=4 _NO_COLOR=0 ${_SCRIPT_NAME} -d 2 x:/some/diff.vhdx
_EOF_
    exit
fi

# ------------------
# Parse arguments
# Ref: https://www.tutorialspoint.com/unix_commands/getopt.htm
GETOPT=$(getopt -o d: -l depth: -- "$@")
eval set -- "$GETOPT"
while true; do
    case "$1" in
    -d|--depth)
        optDepth=$2; shift 2;;
    --)
        shift; break;;
    *)
        echo "getopt error"; exit 1;;
    esac
done

# ------------------
# Preparation
_check_file_exist "$1"
vdiskFile=$(realpath "$1")

vdiskFile=$(toWindowsPath "${vdiskFile}")
diskpartScript=$(cat << _EOF_
select vdisk file="${vdiskFile}"
merge vdisk depth=${optDepth}
_EOF_
)

# ------------------
# Action
_log_highlight "Creating '${vdiskFile}' ..."

_log_info "--- Diskpart script: begin"
_LOG_PREFIX="" _log_info "${diskpartScript}"
_log_info "--- Diskpart script: end"

_log_info "Running diskpart ..."

# ${_LOG_INFO_FD} is 3 (default), and >&3 is POSIX compliant.
# shellcheck disable=2039,2086
echo "${diskpartScript}" | ${_DISKPART} >&${_LOG_INFO_FD}
