#!/bin/bash
set -e

# Generic software installation routine
#
## Parameters:
#    List of packages to install
function install_software() {
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
#    wget, unzip
function install_java8() {
    cd /tmp/
    wget -O /tmp/jdk.rpm -k \
        --header="Cookie: oraclelicense=accept-securebackup-cookie" \
        "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}-${JAVA_BUILD_NUMBER}/${JAVA_DL_PATH}jdk-${JAVA_VERSION}-linux-x64.rpm"
    wget -O /tmp/jce_policy-8.zip -k \
        --header="Cookie: oraclelicense=accept-securebackup-cookie" \
        http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip
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
#    wget, gpg
function get_gosu() {
    wget -O /usr/local/bin/gosu https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64
    local GPG=$(type -p gpg)
    if [ -n "${GPG}" ]; then
        wget -o /tmp/gosu.asc https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64.asc
        ${GPG} --keyservers pgp.mit.edu --recv-keys '0x036a9c25bf357dd4'
        ${GPG} --verify /tmp/gosu.asc /usr/local/bin/gosu
    fi
    chmod a+x /usr/local/bin/gosu
}

# Generic cleanup function. This uninstalls software no longer needed and cleans
# the directory /tmp/
#
## Parameters:
#    List of packages to uninstall
function cleanup() {
    yum -y erase $@
    yum clean all
    /bin/rm -rf /tmp/* 
}

