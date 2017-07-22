#!/bin/bash
set -e

# Generic software installation routine
#
## Parameters:
#    List of packages to install
function install_software() {
    sed -e 's/enabled=.*/enabled=0/' -i /etc/yum/pluginconf.d/fastestmirror.conf
    yum -y clean all
    yum -y update 
    yum -y install $@
}

# Install oracle java 8 based on environment variables
#
## Required environment:
#    JAVA_VERSION (e.g. 8u131), JAVA_BUILD_NUMBER /e.g. b11)
#    JAVA_HOME (e.g./usr/java/jdk1.8.0_131) and JAVA_DL_PATH (e.g. 
#    d54c1d3a095b4ff2b6607d096fa80163/), this is the hash part of the download
#    URL including a trailing slash (to be downwards compatible the URLs without
#    that URL component, this can be set to "")
#
## Required packages:
#    curl, unzip
function install_java8() {
    cd /tmp/
    curl -jkLsS -H "Cookie: oraclelicense=accept-securebackup-cookie" \
         "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}-${JAVA_BUILD_NUMBER}/${JAVA_DL_PATH}jdk-${JAVA_VERSION}-linux-x64.rpm" \
         -o /tmp/jdk.rpm
    curl -jkLsS -H "Cookie: oraclelicense=accept-securebackup-cookie" \
         http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip \
         -o /tmp/jce_policy-8.zip
    if [ -n "${JAVA_CHECKSUM}" ]; then
        echo "${JAVA_CHECKSUM}  /tmp/jdk.rpm" >/tmp/jdk.rpm.sha256sum
        if [ -n "${JCE_CHECKSUM}" ]; then
            echo "${JCE_CHECKSUM}  /tmp/jce_policy-8.zip" >>/tmp/jdk.rpm.sha256sum
        fi
        sha256sum -c /tmp/jdk.rpm.sha256sum
    fi
    yum -y install /tmp/jdk.rpm
    cd ${JAVA_HOME}/jre/lib/security
    unzip /tmp/jce_policy-8.zip
}

# Get the sudo alternative gosu and install it to /usr/local/bin
#
## Required environment variables:
#    GOSU_VERSION (e.g. 1.10)
#
## Required packages:
#    curl, gpg
function get_gosu() {
    curl -sSL https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64 -o /usr/local/bin/gosu 
    local GPG=$(type -p gpg)
    if [ -n "${GPG}" ]; then
        curl -sSL https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64.asc -o /tmp/gosu.asc
        ${GPG} --keyserver keys.gnupg.net --recv-keys '0x036a9c25bf357dd4'
        ${GPG} --verify /tmp/gosu.asc /usr/local/bin/gosu
    fi
    chmod a+x /usr/local/bin/gosu
}

# Create an application user
#
## Required environment variables:
#    APP_USER (e.g. myapp)
#    APP_UID (e.g. 20000)
#    APP_GROUP ( e.g. mygroup)
#    APP_GID (e.g. 20000)
#    APP_HOME (e.g. /opt/myapp)

function create_user_and_group() {
    groupadd -g ${APP_GID} ${APP_GROUP}
    useradd -c "Application user" -d ${APP_HOME} -g ${APP_GROUP} -m -s /bin/bash -u ${APP_UID} ${APP_USER}
    if [ ! -d ${APP_HOME} ]; then
        mkdir -p ${APP_HOME}
    fi
    chown -R ${APP_USER}:${APP_GROUP} ${APP_HOME}
}

# Generic cleanup function. This uninstalls software no longer needed and cleans
# the directory /tmp/
#
## Parameters:
#    List of packages to uninstall
function cleanup() {
    if [ $# -ne 0 ]; then
        yum -y erase $@
    fi
    yum clean all
    /bin/rm -rf /tmp/* /var/cache/yum/*
}
