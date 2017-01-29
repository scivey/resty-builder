#!/bin/bash

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

RESTY_BUILDER_SCRIPTS_DIR=$(dirname ${BASH_SOURCE[0]})
pushd ${RESTY_BUILDER_SCRIPTS_DIR}
RESTY_BUILDER_SCRIPTS_DIR=$(pwd)
popd
pushd ${RESTY_BUILDER_SCRIPTS_DIR}/..
RESTY_BUILDER_ROOT_DIR=$(pwd)
popd

export RESTY_BUILDER_SCRIPTS_DIR=${RESTY_BUILDER_SCRIPTS_DIR}
export RESTY_BUILDER_ROOT_DIR=${RESTY_BUILDER_ROOT_DIR}
export RESTY_BUILDER_BUILD_DIR=${RESTY_BUILDER_ROOT_DIR}/build
export RESTY_BUILDER_TEMP_DIR=${RESTY_BUILDER_ROOT_DIR}/.tmp
export RESTY_BUILDER_CONF_DIR=${RESTY_BUILDER_ROOT_DIR}/conf
export RESTY_BUILDER_OPENRESTY_INSTALL_ROOT=/usr/local/openresty
export RESTY_CONTAINER_BUILDS_DIR=${RESTY_BUILDER_BUILD_DIR}/container-builds
export RESTY_DEBS_DEST_DIR=${RESTY_BUILDER_BUILD_DIR}/debs
