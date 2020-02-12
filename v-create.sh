#!/bin/sh

# ------------------
# Basic settings
_SCRIPT_DIR=`dirname "$(readlink -f "$0")"`
_SCRIPT_NAME=`basename "$0"`
source "${_SCRIPT_DIR}/.v-common.rc"

# ------------------
# Default values
vdiskType="expandable"  # fixed, expandable
fileSystem="ntfs"       # ntfs, fat32
label=""            # (anything)
optOverwrite=""     # overwrite, (anything else)
optMkDir=""         # mkdir, (anything else)

# ------------------
# Help
if [[ $# -lt 2 || "$1" == "-h" || "$1" == "--help" ]]; then
    cat << _EOF_

Usage: [VARIABLES] ${_SCRIPT_NAME} [OPTIONS] v-FILE FILE-SIZE

Create a vdisk of specified size and filesystem.

    v-FILE      Path to the vdisk file.
    FILE-SIZE       File size in megabytes (MB).

OPTIONS:

    -s,--file-system SYS    Format the vdisk as SYS. Default is NTFS.
    -L,--label LABEL        Label the vdisk. Default is "" (empty).
    -f,--fixed              Fixed size vdisk file, i.e. non-expandable.
    -o,--overwrite          Overwrite the vdisk file if already exists.
    -m,--mkdir              Create parent directory if not exists.

${_HELP_VARIABLES}

Example:

    ${_SCRIPT_NAME} x:/some/vdisk.vhdx 1024
    _VERBOSE=4 _NO_COLOR=0 ${_SCRIPT_NAME} -fm --file-system fat32 --label "new-vdisk" x:/some/vdisk.vhdx 512
_EOF_
    exit
fi

# ------------------
# Parse arguments
# Ref: https://www.tutorialspoint.com/unix_commands/getopt.htm
GETOPT=`getopt -o fs:L:om -l fixed,file-system:,label:,overwrite,mkdir -- "$@"`
eval set -- "$GETOPT"
while true; do
    case "$1" in
    -f|-fixed)
        vdiskType="fixed"; shift;;
    -s|--file-system)
        fileSystem=$2; shift 2;;
    -L|--label)
        label="$2"; shift 2;;
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
_check_dir_exist "$(dirname "$1")" $optMkDir
_check_file_not_exist "$1" $optOverwrite
vdiskFile=$(realpath "$1")

if [[ "$2" == "" ]]; then
    _log_error "No size specified."
    exit 1
fi
vdiskSize=$2

diskpartScript=$(cat << _EOF_
create vdisk file="${vdiskFile//\//\\}" maximum=${vdiskSize} type=${vdiskType}
attach vdisk
create partition primary
format fs=${fileSystem} label="${label}" quick
detach vdisk
_EOF_
)

# ------------------
# Action
_log_highlight "Creating '${vdiskFile}' ..."
_log_info "----- Script to be run by diskpart:"
_log_info "${diskpartScript}"

_log_info "----- Running diskpart ..."
echo "${diskpartScript}" | ${_DISKPART} >&${_LOG_INFO_FD}
