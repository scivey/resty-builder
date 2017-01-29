#!/bin/bash

set -e

. $(dirname ${BASH_SOURCE[0]})/common.sh
. ${RESTY_BUILDER_SCRIPTS_DIR}/detail/load_build_env.sh
. ${RESTY_BUILDER_SCRIPTS_DIR}/detail/lib.sh


function __build-one() {
    local name="$1"
    configure-and-build-in-container ${name}
    package-one-container-build ${name}

}

function __build-all() {
    pushd ${RESTY_BUILDER_ROOT_DIR}/containers
    local names=$(ls)
    popd
    for name in ${names}; do
        __build-one ${name}
    done
}

download-missing-tarballs

case "$1" in
all)
    __build-all
    ;;
*)
    __build-one "$1"
    ;;
esac
