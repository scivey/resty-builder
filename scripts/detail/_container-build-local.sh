#!/bin/bash

set -e

. $(dirname ${BASH_SOURCE[0]})/../common.sh
. ${RESTY_BUILDER_SCRIPTS_DIR}/detail/load_build_env.sh
. ${RESTY_BUILDER_SCRIPTS_DIR}/detail/lib.sh

configure-build-install-to-local $@
