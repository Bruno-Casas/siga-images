#!/bin/bash

set -e

mkdir -p $SIGA_DIR/logs
mkdir -p $SIGA_DIR/configs
mkdir -p $SIGA_DIR/deployments

WORK_DIR="${SIGA_DIR}/tmp"
cd $WORK_DIR

echo -n "Performing initial setups on Wildfly. "
jboss-cli.sh <<EOF
embed-server --std-out=echo
batch

module add --name=com.mysql --resources=$SIGA_DIR/tmp/mysql-connector-j-8.2.0.jar --dependencies=javax.api,javax.transaction.api
/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql,driver-class-name=com.mysql.cj.jdbc.Driver)
/subsystem=undertow/server=default-server/http-listener=default/:write-attribute(name=max-post-size,value=117440512)
/subsystem=undertow/server=default-server/https-listener=https/:write-attribute(name=max-post-size,value=117440512)
/subsystem=sar/:remove

run-batch
stop-embedded-server
exit
EOF

if [ $? -eq 0 ]; then
    echo "SUCCESS"
else
    echo "FAIL"
    exit 1
fi

echo -n "Creating wildfly management user. "
add-user.sh admin Password@123 >/dev/null

if [ $? -eq 0 ]; then
    echo "SUCCESS"
else
    echo "FAIL"
    exit 1
fi

echo -n "extracting the ckeditor: "
unzip -q ckeditor_4.15.0_full.zip -d $WILDFLY_HOME/welcome-content/ckeditor/

if [ $? -eq 0 ]; then
    echo "SUCCESS"
else
    echo "FAIL"
    exit 1
fi

rm -rf $WORK_DIR/*
