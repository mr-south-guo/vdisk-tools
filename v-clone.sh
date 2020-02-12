#!/bin/sh

# ------------------
# Basic settings
_SCRIPT_DIR=`dirname "$(readlink -f "$0")"`
_SCRIPT_NAME=`basename "$0"`
source "${_SCRIPT_DIR}/.v-common.rc"

# ------------------
# Default values
vdiskType="expandable"  # fixed, expandable
optOverwrite=""         # overwrite, (anything else)
optMkDir=""             # mkdir, (anything else)

# ------------------
# Help
if [[ $# -lt 2 || "$1" == "-h" || "$1" == "--help" ]]; then
    cat << _EOF_

Usage: [VARIABLES] ${_SCRIPT_NAME} [OPTIONS] SOURCE DEST

Clone a source vdisk to a destination vdisk.

    SOURCE      Path to the source vdisk file.
    DEST        Path to the destination vdisk file.

OPTIONS:

    -f,--fixed      Create fixed size DEST, i.e. non-expandable.
    -o,--overwrite  Overwrite the DEST if already exists.
    -m,--mkdir      Create parent directory of the DEST if not exists.

${_HELP_VARIABLES}

Example:

    ${_SCRIPT_NAME} x:/dir1/source.vhdx y:/dir2/dest.vhdx
    _VERBOSE=4 _NO_COLOR=0 ${_SCRIPT_NAME} -fom x:/dir1/source.vhdx y:/dir2/dest.vhdx
_EOF_
    exit
fi

# ------------------
# Parse arguments
# Ref: https://www.tutorialspoint.com/unix_commands/getopt.htm
GETOPT=`getopt -o fom -l fixed,overwrite,mkdir -- "$@"`
eval set -- "$GETOPT"
while true; do
    case "$1" in
    -f|-fixed)
        vdiskType="fixed"; shift;;
    -o|--overwrite)
        optOverwrite="overwrite"; shift;;
    -m|--mkdir)
        optMkDir="mkdir"; shift;;
    --)
        shift; break;;
    *)
        echo "getopt error"; exit 1;;
    esac
done

# ------------------
# Preparation
_check_file_exist "$1"
vdiskSource=$(realpath "$1")

_check_dir_exist "$(dirname "$2")" $optMkDir
_check_file_not_exist "$2" $optOverwrite
vdiskDest=$(realpath "$2")

diskpartScript=$(cat << _EOF_
create vdisk file="${vdiskDest//\//\\}" source="${vdiskSource//\//\\}" type=${vdiskType}
_EOF_
)

# ------------------
# Action
_log_highlight "Cloning '${vdiskSource}' to '${vdiskDest}' ..."
_log_info "----- Script to be run by diskpart:"
_log_info "${diskpartScript}"

_log_info "----- Running diskpart ..."
echo "${diskpartScript}" | ${_DISKPART} >&${_LOG_INFO_FD}
