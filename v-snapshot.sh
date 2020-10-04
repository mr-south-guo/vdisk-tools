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
optOverwrite=""     # overwrite, (anything else)
optMkDir=""         # mkdir, (anything else)
optSnapshot=""      # (empty string). Don't change this!

# ------------------
# Help
if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat << _EOF_

Usage: [VARIABLES] ${_SCRIPT_NAME} [OPTIONS] v-FILE

Create a snapshot of a vdisk file.

    v-FILE      Path to the vdisk file.

OPTIONS:

    -s,--snapshot SHOT  Path to the snapshot file. Default is appending a time-stamp to v-FILE.
    -o,--overwrite      Overwrite SHOT if already exists.
    -m,--mkdir          Create parent directory of SHOT if not exists.

${_HELP_VARIABLES}

Basically, this operation involves two step:
1. Rename v-FILE to SHOT.
2. Create a diff named v-FILE to SHOT.

Example:

    ${_SCRIPT_NAME} x:/dir1/vdisk.vhdx
    _VERBOSE=4 _NO_COLOR=0 ${_SCRIPT_NAME} -om -s y:/dir2/shot.vhdx x:/dir1/vdisk.vhdx
_EOF_
    exit
fi

# ------------------
# Parse arguments
# Ref: https://www.tutorialspoint.com/unix_commands/getopt.htm
GETOPT=$(getopt -o oms: -l overwrite,mkdir,snapshot: -- "$@")
eval set -- "$GETOPT"
while true; do
    case "$1" in
    -o|--overwrite)
        optOverwrite="overwrite"; shift;;
    -m|--mkdir)
        optMkDir="mkdir"; shift;;
    -s|--snapshot)
        optSnapshot="$2"; shift 2;;
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

if [ "${optSnapshot}" = "" ]; then
    vdiskSource="${vdiskFile%.*}.$(date +%Y%m%d_%H%M%S).${vdiskFile##*.}"
else
    _check_dir_exist "$(dirname "${optSnapshot}")" $optMkDir
    vdiskSource=$(realpath "${optSnapshot}")
fi
_check_file_not_exist "${vdiskSource}" $optOverwrite

# ------------------
# Action
_log_highlight "Snapshoting '${vdiskFile}' to '${vdiskSource}' ..."

mv "${vdiskFile}" "${vdiskSource}"
_LOG_PREFIX="${_LOG_PREFIX}${_LOG_PREFIX_INDENT}" "${_SCRIPT_DIR}/v-diff.sh" "${vdiskSource}" "${vdiskFile}"
