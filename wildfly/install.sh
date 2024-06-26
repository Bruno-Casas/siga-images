#!/bin/bash

set -e
FILE="wildfly-$WILDFLY_VERSION.tar.gz"
URL="https://github.com/wildfly/wildfly/releases/download/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz"

addgroup -g 1000 jboss
adduser -u 1000 -S -G jboss -h /opt/jboss -s /bin/ash jboss

cd /opt/jboss

echo "Downloading WildFly..."
attempts=0
while [  $attempts -lt 2 ]; do
    echo "Downloading $FILE:"
    curl --connect-timeout 10 --progress-bar -L -O $URL 2>&1

    echo -n "Health check for $FILE: "
    sha1sum $FILE | grep $WILDFLY_SHA1 > /dev/null
    if [ $? = 0 ]
    then
        echo "SUCCESS"
        attempts=0
        break
    fi
    ((attempts++))
    echo "FAIL"
    echo "Trying to download again..."
done

tar xf $FILE
mv wildfly-$WILDFLY_VERSION $WILDFLY_HOME
rm $FILE

chown -R jboss:0 ${WILDFLY_HOME}
chmod -R g+rw ${WILDFLY_HOME}

rm $0
