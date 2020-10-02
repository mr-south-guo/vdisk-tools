#!/bin/sh

# ------------------
# Basic settings
_SCRIPT_DIR=`dirname "$(readlink -f "$0")"`
_SCRIPT_NAME=`basename "$0"`
source "${_SCRIPT_DIR}/.v-common.rc"
[[ ${_LOG_PREFIX} ]] || _LOG_PREFIX="[${_SCRIPT_NAME}] "

# ------------------
# Default values
optDefrag="yes"
optRebound="yes"
optZero="yes"
optWorkspace="z:"
optPartition=1

# ------------------
# Help
if [[ $# -lt 1 || "$1" == "-h" || "$1" == "--help" ]]; then
    cat << _EOF_

Usage: [VARIABLES] ${_SCRIPT_NAME} [OPTIONS] v-FILE

Defrag, rebound(shrink & extend), zero-out free space and then compact an expandable vdisk file.

    v-FILE      Path to the vdisk file.

OPTIONS:

    -d,--no-defrag          Do not defrag.
    -r,--no-rebound         Do not rebound.
    -z,--no-zero            Do not zero-out free space.
    -w,--workspace SPACE    A drive or a directory to mount the vdisk while working. 
                            It should not already exist and will be removed afterwards. Default is "z:".
    -p,--partition N        Compact the N'th partition. Default is 1.

${_HELP_VARIABLES}

Example:

    ${_SCRIPT_NAME} x:/some/vdisk.vhdx
    _VERBOSE=4 _NO_COLOR=0 ${_SCRIPT_NAME} -w t:/workspace x:/some/vdisk.vhdx
_EOF_
    exit
fi

# ------------------
# Parse arguments
# Ref: https://www.tutorialspoint.com/unix_commands/getopt.htm
GETOPT=`getopt -o drzw:p: -l no-defrag,no-zero,no-rebound,workspace:,partition: -- "$@"`
eval set -- "$GETOPT"
while true; do
    case "$1" in
    -d|--no-defrag)
        optDefrag="no"; shift;;
    -r|--no-rebound)
        optRebound="no"; shift;;
    -z|--no-zero)
        optZero="no"; shift;;
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

if [[ "${optDefrag}" == "yes" ]]; then
    _log_highlight "Defraging '${optWorkspace}' ..."
    _LOG_PREFIX="${_LOG_PREFIX}${_LOG_PREFIX_INDENT}" "${_SCRIPT_DIR}/v-mount.sh" -p ${optPartition} -m "${vdiskFile}" "${optWorkspace}"
    defrag ${optWorkspace} /U >&${_LOG_INFO_FD}
    _LOG_PREFIX="${_LOG_PREFIX}${_LOG_PREFIX_INDENT}" "${_SCRIPT_DIR}/v-umount.sh" "${vdiskFile}"
    _log_empty_line
fi

if [[ "${optRebound}" == "yes" ]]; then
    _log_highlight "Rebounding '${optWorkspace}' ..."
    _LOG_PREFIX="${_LOG_PREFIX}${_LOG_PREFIX_INDENT}" "${_SCRIPT_DIR}/v-shrink.sh" -p ${optPartition} -w "${optWorkspace}" "${vdiskFile}"
    _log_empty_line
    _LOG_PREFIX="${_LOG_PREFIX}${_LOG_PREFIX_INDENT}" "${_SCRIPT_DIR}/v-extend.sh" -p ${optPartition} -w "${optWorkspace}" "${vdiskFile}"
    _log_empty_line
fi

if [[ "${optZero}" == "yes" ]]; then
    _log_highlight "Zeroing-out free space on '${optWorkspace}' ..."
    _LOG_PREFIX="${_LOG_PREFIX}${_LOG_PREFIX_INDENT}" "${_SCRIPT_DIR}/v-mount.sh" -p ${optPartition} -m "${vdiskFile}" "${optWorkspace}"
    dd if=/dev/zero of="${optWorkspace}/.zeros" bs=4k 2>/dev/null 1>&${_LOG_INFO_FD}
    rm "${optWorkspace}/.zeros"
    _LOG_PREFIX="${_LOG_PREFIX}${_LOG_PREFIX_INDENT}" "${_SCRIPT_DIR}/v-umount.sh" "${vdiskFile}"
    _log_empty_line
fi

# Remove the workspace if it is a directory.
[[ "${optWorkspace: -1}" == ":" ]] || rmdir "${optWorkspace}"

# ----- Compact
diskpartScript=$(cat << _EOF_
select vdisk file="${vdiskFile//\//\\}"
compact vdisk
_EOF_
)
_log_highlight "Compacting '${vdiskFile}' ..."
_log_info "----- Script to be run by diskpart:"
_LOG_PREFIX="" _log_info "${diskpartScript}"

_log_info "----- Running diskpart ..."
echo "${diskpartScript}" | ${_DISKPART} >&${_LOG_INFO_FD}
