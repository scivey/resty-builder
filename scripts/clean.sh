#!/bin/bash

. $(dirname ${BASH_SOURCE[0]})/common.sh

set -e

function bad-dir() {
    echo "bad dir: '${1}'" >&2
    exit 1
}

function clean-py-dir() {
    local target="$1"
    if [[ "${target}" == "" ]]; then
        bad-dir ${target}
        return
    elif [[ ! -d "${target}" ]]; then
        bad-dir ${target}
        return
    fi
    find $target -name "*.pyc" -exec rm -f {} +
    find $target -name "__pycache__" -exec rm -rf {} +
}

function clean-all() {
    pushd ${RESTY_BUILDER_ROOT_DIR}
    rm -rf build
    popd
}

clean-all
