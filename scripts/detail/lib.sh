. $(dirname ${BASH_SOURCE[0]})/../common.sh
. $(dirname ${BASH_SOURCE[0]})/env_fixed.sh

set -e

function build-one-docker-image() {
    local name="$1"
    pushd ${RESTY_BUILDER_ROOT_DIR}
    sudo docker build -t restybuilder/${name} ./containers/${name}
    popd
}

function build-all-docker-images() {
    pushd ${RESTY_BUILDER_ROOT_DIR}/containers
    local names=$(ls)
    popd
    for name in ${names}; do
        build-one-docker-image ${name}
    done
}

function configure-and-build-in-container() {
    local name="$1"
    pushd ${RESTY_BUILDER_ROOT_DIR}
    build-one-docker-image ${name}
    local image_tag="restybuilder/${name}"
    local host_dest=${RESTY_CONTAINER_BUILDS_DIR}/${name}
    local guest_dest="/builder/dest"
    mkdir -p ${host_dest}
    sudo docker run \
        --tty -i \
        -v `pwd`/.tmp:/builder/.tmp \
        -v `pwd`/conf:/builder/conf \
        -v `pwd`/scripts:/builder/scripts \
        -v ${host_dest}:${guest_dest} \
        ${image_tag} \
        /builder/scripts/detail/_container-build-local.sh ${guest_dest}
    popd
}

function make-temp-dirs() {
    mkdir -p ${RESTY_BUILDER_TEMP_DIR} ${RESTY_BUILDER_BUILD_DIR}    
}


function download-missing-tarballs() {
    make-temp-dirs
    pushd ${RESTY_BUILDER_TEMP_DIR}
    if [[ ! -f ${AUTH_PAM_TAR_NAME} ]]; then
        wget -O ${AUTH_PAM_TAR_NAME} \
            https://github.com/sto/ngx_http_auth_pam_module/archive/v${AUTH_PAM_VERSION}.tar.gz
    fi
    if [[ ! -f ${CACHE_PURGE_TAR_NAME} ]]; then
        wget -O ${CACHE_PURGE_TAR_NAME} \
            https://github.com/FRiCKLE/ngx_cache_purge/archive/${CACHE_PURGE_VERSION}.tar.gz
    fi
    if [[ ! -f ${RESTY_TAR_NAME} ]]; then
        wget https://openresty.org/download/${RESTY_TAR_NAME}
    fi
    if [[ ! -f ${NAXSI_TAR_NAME} ]]; then
        wget -O ${NAXSI_TAR_NAME} \
            https://github.com/nbs-system/naxsi/archive/${NAXSI_VERSION}.tar.gz
    fi
    popd
}

function copy-missing-sources() {
    download-missing-tarballs
    pushd ${RESTY_BUILDER_BUILD_DIR}
    local dir_names="${NAXSI_DIR_NAME}  ${RESTY_DIR_NAME}  ${CACHE_PURGE_DIR_NAME}  ${AUTH_PAM_DIR_NAME}"
    for dname in ${dir_names}; do
        if [[ ! -d ${dname} ]]; then
            local tar_name=${dname}.tar.gz
            cp ${RESTY_BUILDER_TEMP_DIR}/${tar_name} .
            tar -xaf ${tar_name} && rm ${tar_name}
        fi
    done
    popd
}

function install-to-tmp() {
    local tmp_dest="$1"
    local tmp_dest_dir="${tmp_dest}/output"
    pushd ${RESTY_BUILDER_BUILD_DIR}/${RESTY_DIR_NAME}
    rm -rf ${tmp_dest_dir} && mkdir -p ${tmp_dest_dir}
    make install DESTDIR=${tmp_dest_dir}
    local conf_dest=${tmp_dest_dir}/${RESTY_BUILDER_PARAM__PREFIX}/nginx/conf
    cp -r ${RESTY_BUILDER_CONF_DIR}/naxsi ${conf_dest}/naxsi
    cp ${RESTY_BUILDER_BUILD_DIR}/${NAXSI_DIR_NAME}/naxsi_config/naxsi_core.rules ${conf_dest}/naxsi/core.rules
    popd
}


function configure-build() {
    pushd ${RESTY_BUILDER_BUILD_DIR}/${RESTY_DIR_NAME}
    ./configure \
        --prefix=${RESTY_BUILDER_PARAM__PREFIX} \
        --user=${RESTY_BUILDER_PARAM__USER} \
        --group=${RESTY_BUILDER_PARAM__GROUP} \
        --add-module=../${NAXSI_DIR_NAME}/naxsi_src \
        --add-module=../${AUTH_PAM_DIR_NAME} \
        --add-module=../${CACHE_PURGE_DIR_NAME} \
        \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_auth_request_module \
        --with-http_slice_module \
        --with-http_stub_status_module \
        --with-http_v2_module \
        --with-stream \
        --with-stream_ssl_module \
        \
        --with-pcre-jit \
        --with-ipv6 \
        --with-file-aio
    popd
}


function configure-build-install-to-local() {
    local temp_dest="$1"
    make-temp-dirs
    copy-missing-sources
    pushd ${RESTY_BUILDER_BUILD_DIR}/${RESTY_DIR_NAME}
    if [[ ! -f Makefile ]]; then
        configure-build
    fi
    make all -j8
    if [[ "${temp_dest}" == "" ]]; then
        echo "no temp_dest specified; not copying output." >&2
    else
        install-to-tmp ${temp_dest}
    fi
    popd
}

function package-one-container-build() {
    local name="$1"
    local build_dir=${RESTY_CONTAINER_BUILDS_DIR}/${name}
    if [[ ! -d ${build_dir} ]]; then
        echo "no builds found for '${name}'" >&2
        exit 1
    fi
    mkdir -p ${RESTY_DEBS_DEST_DIR}
    local deb_name="${RESTY_BUILDER_DEB_NAME_BASE}-${name}.deb"
    local deb_output=${RESTY_DEBS_DEST_DIR}/${deb_name}
    rm -f ${deb_output}
    pushd ${build_dir}
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


function package-all-container-builds() {
    pushd ${RESTY_CONTAINER_BUILDS_DIR}
    local names=$(ls)
    popd
    for name in ${names}; do
        package-one-container-build ${name}
    done
}
