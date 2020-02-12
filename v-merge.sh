#!/bin/sh

# ------------------
# Basic settings
_SCRIPT_DIR=`dirname "$(readlink -f "$0")"`
_SCRIPT_NAME=`basename "$0"`
source "${_SCRIPT_DIR}/.v-common.rc"

# ------------------
# Default values
optDepth=1

# ------------------
# Help
if [[ $# -lt 1 || "$1" == "-h" || "$1" == "--help" ]]; then
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
GETOPT=`getopt -o d: -l depth: -- "$@"`
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

diskpartScript=$(cat << _EOF_
select vdisk file="${vdiskFile//\//\\}"
merge vdisk depth=${optDepth}
_EOF_
)

# ------------------
# Action
_log_highlight "Creating '${vdiskFile}' ..."
_log_info "----- Script to be run by diskpart:"
_log_info "${diskpartScript}"

_log_info "----- Running diskpart ..."
echo "${diskpartScript}" | ${_DISKPART} >&${_LOG_INFO_FD}
