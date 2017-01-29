#!/bin/bash

set -e

CONTAINER_NAME="$1"
. $(dirname ${BASH_SOURCE[0]})/common.sh
. ${RESTY_BUILDER_SCRIPTS_DIR}/detail/load_build_env.sh
. ${RESTY_BUILDER_SCRIPTS_DIR}/detail/lib.sh

download-missing-tarballs
configure-build-install-to-local ${RESTY_BUILDER_BUILD_DIR}/local-build
