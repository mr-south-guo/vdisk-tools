#!/bin/sh

_SCRIPT_DIR=`dirname "$(readlink -f "$0")"`

export HOME="${_SCRIPT_DIR}"
export PATH="${_SCRIPT_DIR}:${PATH}"
export _CONSOLE_TITLE='v-sh - \u - \w'
export _BUSYBOX_STARTUP_DIR="${_SCRIPT_DIR}"

sh -l
