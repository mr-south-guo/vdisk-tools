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
optPartition=1
optMkDir="no"
optCommand=""

# ------------------
# Help
if [ $# -lt 2 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat << _EOF_

Usage: [VARIABLES] ${_SCRIPT_NAME} [OPTIONS] v-FILE MOUNT-POINT

Mount a vdisk file at a mount-point

    v-FILE      Path to the vdisk file.
    MOUNT-POINT     Can be either a driver letter or a directory.
                    For drive letter, it must ends with a colon (:).
                    For directory, it must be on a NTFS parition.
                    Ending with '/' or not does not matter.

OPTIONS:

    -m,--mkdir          Create the mount-point directory if not exists. (Does not apply to drive letter.)
    -p,--partition N    Mount the N'th partition. Default is 1.
    -c,--command "CMD"  Run diskpart command right after mounting (while the volume is still selected).

${_HELP_VARIABLES}

Example:

    ${_SCRIPT_NAME} x:/some/vdisk.vhdx y:
    _VERBOSE=4 _NO_COLOR=0 ${_SCRIPT_NAME} --mkdir --partition 2 x:/some/vdisk.vhdx y:/some/dir
_EOF_
    exit
fi

# ------------------
# Parse arguments
# Ref: https://www.tutorialspoint.com/unix_commands/getopt.htm
GETOPT=$(getopt -o mp:c: -l mkdir,partition:,command: -- "$@")
eval set -- "$GETOPT"
while true; do
    case "$1" in
    -m|--mkdir)
        optMkDir="mkdir"; shift;;
    -p|--partition)
        optPartition=$2; shift 2;;
    -c|--command)
        optCommand="$2"; shift 2;;
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

# Remove the trailing '/' if exists.
mountPoint=${2%/}

# Check whether the mount-point is a drive letter or a directory.
if [ "$(str_right "${mountPoint}" 1)" = ":" ]; then
    # It is a drive letter.
    _check_drive_exist "${mountPoint}"
    mountLetter=$(str_sub "${mountPoint}" 0 1)
    diskpartScript=$(cat << _EOF_
select vdisk file="${vdiskFile}"
attach vdisk
select partition=${optPartition}
assign letter=${mountLetter}
${optCommand}
_EOF_
    )
else
    # It is a directory.
    _check_dir_exist "${mountPoint}" $optMkDir
    diskpartScript=$(cat << _EOF_
select vdisk file="${vdiskFile}"
attach vdisk
select partition=${optPartition}
remove all
assign mount="${mountPoint}"
${optCommand}
_EOF_
    )
fi

# ------------------
# Action
_log_highlight "Mounting '$1' to '$2' ..."

_log_info "--- Diskpart script: begin"
_LOG_PREFIX="" _log_info "${diskpartScript}"
_log_info "--- Diskpart script: end"

_log_info "Running diskpart ..."

# ${_LOG_INFO_FD} is 3 (default), and >&3 is POSIX compliant.
# shellcheck disable=2039,2086
echo "${diskpartScript}" | ${_DISKPART} >&${_LOG_INFO_FD}
