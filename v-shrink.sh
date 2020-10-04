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
optDesired=""
optPartition=1
optWorkspace="z:"

# ------------------
# Help
if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat << _EOF_

Usage: [VARIABLES] ${_SCRIPT_NAME} [OPTIONS] v-FILE

Shrink the partition in a vdisk file.
Note: This operation does not change the vdisk file size. It merely changes the partition's logical size.

    v-FILE      Path to the vdisk file.

OPTIONS:
    -p,--partition N    Operate on the N'th partition. Default is 1.
    -d,--desired S      Reduce the partition by S MB. Default is the maximum possible amount.
    -w,--workspace SPACE    A drive or a directory to mount the vdisk while working. 
                            It should not already exist and will be removed afterwards. Default is "z:".


${_HELP_VARIABLES}

Example:

    ${_SCRIPT_NAME} x:/some/vdisk.vhdx
    _VERBOSE=4 _NO_COLOR=0 ${_SCRIPT_NAME} --partition 2 --desired 100 --workspace y: x:/some/vdisk.vhdx
_EOF_
    exit
fi

# ------------------
# Parse arguments
# Ref: https://www.tutorialspoint.com/unix_commands/getopt.htm
GETOPT=$(getopt -o d:w:p: -l desired:,workspace:,partition: -- "$@")
eval set -- "$GETOPT"
while true; do
    case "$1" in
    -d|--desired)
        optDesired="DESIRED=$2"; shift 2;;
    -w|--workspace)
        optWorkspace="$2"; shift 2;;
    -p|--partition)
        optPartition=$2; shift 2;;
    --)
        shift; break;;
    *)
        echo "getopt error"; exit 1;;
    esac
done

# ------------------
# Preparation
_check_file_exist "$1"
_check_dir_not_exist "${optWorkspace}/"

vdiskFile=$(realpath "$1")

# ------------------
# Action
_log_highlight "Shrinking '$1' ..."

shrinkCmd="shrink ${optDesired}"
_LOG_PREFIX="${_LOG_PREFIX}${_LOG_PREFIX_INDENT}" "${_SCRIPT_DIR}/v-mount.sh" -p "${optPartition}" -m -c "${shrinkCmd}" "${vdiskFile}" "${optWorkspace}"
_LOG_PREFIX="${_LOG_PREFIX}${_LOG_PREFIX_INDENT}" "${_SCRIPT_DIR}/v-umount.sh" "${vdiskFile}"
