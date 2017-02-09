#!/bin/bash

set -e

. $(dirname ${BASH_SOURCE[0]})/common.sh
. ${RESTY_BUILDER_SCRIPTS_DIR}/detail/load_build_env.sh
. ${RESTY_BUILDER_SCRIPTS_DIR}/detail/lib.sh

LOCAL_BUILD_DIR=${RESTY_BUILDER_BUILD_DIR}/local-build


function package-it() {
    mkdir -p ${RESTY_DEBS_DEST_DIR}
    local deb_name="${RESTY_BUILDER_DEB_NAME_BASE}-local.deb"
    local deb_output=${RESTY_DEBS_DEST_DIR}/${deb_name}
    rm -f ${deb_output}
    pushd ${LOCAL_BUILD_DIR}/output
    local targets=$(ls)
    fpm -s dir -t deb \
        -n ${RESTY_BUILDER_PARAM__PACKAGE_NAME} \
        -v ${RESTY_BUILDER_PARAM__PACKAGE_VERSION} \
        -a ${RESTY_BUILDER_PARAM__PACKAGE_ARCH} \
        -p ${deb_output} \
        -m ${RESTY_BUILDER_PARAM__PACKAGE_MAINTAINER_EMAIL} \
        --license MIT \
        --description "${RESTY_BUILDER_PARAM__PACKAGE_DESCRIPTION} [${name}]" \
        ${targets}
}

download-missing-tarballs
# configure-build-install-to-local ${LOCAL_BUILD_DIR}
package-it

