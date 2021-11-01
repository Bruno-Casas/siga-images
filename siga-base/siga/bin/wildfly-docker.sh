#!/bin/bash
#
# JBoss EAP Docker Control
#
# description: JBoss EAP startup script for docker
# processname: siga-jboss-eap
# pidfile: /var/run/siga-jboss-eap/siga-jboss-eap.pid
# config: /siga/bin/siga-jboss-eap.conf
#

if [ -z "$WILDFLY_NAME" ]; then
  WILDFLY_NAME='siga-wildfly'
fi

if [ -z "$WILDFLY_CONF" ]; then
	WILDFLY_CONF="$SIGA_DIR/bin/$WILDFLY_NAME.conf"
fi

[ -r "$WILDFLY_CONF" ] && . "${WILDFLY_CONF}"

if [ -z "$WILDFLY_MODE" ]; then
	WILDFLY_MODE=standalone
fi

if [ -z "$WILDFLY_BASE_DIR" ]; then
	WILDFLY_BASE_DIR="$WILDFLY_HOME/$WILDFLY_MODE"
else
	WILDFLY_OPTS="$WILDFLY_OPTS -Djboss.server.base.dir=$WILDFLY_BASE_DIR"
fi

# Startup mode script
if [ "$WILDFLY_MODE" = "standalone" ]; then
	WILDFLY_SCRIPT=$WILDFLY_HOME/bin/standalone.sh
	if [ -z "$WILDFLY_CONFIG" ]; then
		WILDFLY_CONFIG=standalone.xml
	fi
else
	WILDFLY_SCRIPT=$WILDFLY_HOME/bin/domain.sh
	if [ -z "$WILDFLY_DOMAIN_CONFIG" ]; then
		WILDFLY_DOMAIN_CONFIG=domain.xml
	fi
	if [ -z "$WILDFLY_HOST_CONFIG" ]; then
		WILDFLY_HOST_CONFIG=host.xml
	fi
fi

prog=$WILDFLY_NAME
currenttime=$(date +%s%N | cut -b1-13)

runStartupScritps() {
	echo "Running startup scripts..."
	for f in $SIGA_DIR/bin/init.d/*; do
		[ -f "$f" ] || continue
		case "$f" in
			*.sh)     echo "$0: running $f"; . "$f" ;;
			*.jar)    echo "$0: running $f"; java -jar $f ;;
		esac
	echo
	done
}

syncVolumeOwner() {
	reference_uid=`stat -c %u $1`
	current_uid=`stat -c %u $2`

	if [ $current_uid -ne $reference_uid ]
	then
    	chown -R $reference_uid $2
	fi
}

syncVolumeOwner $WILDFLY_HOME "$SIGA_DIR/deployments"
runStartupScritps

if [ -f "$WILDFLY_BASE_DIR/log/server.log" ]; then
	mv $WILDFLY_BASE_DIR/log/server.log "$SIGA_DIR/logs/siga-$(date +%FT%T).log"
	cat /dev/null > $WILDFLY_BASE_DIR/log/server.log
fi

bash startup.sh

export JAVA_OPTS
command=""
if [ "$WILDFLY_MODE" = "standalone" ]; then
	command="standalone.sh -c $WILDFLY_CONFIG $WILDFLY_OPTS"
else
	command="standalone.sh --domain-config=$WILDFLY_DOMAIN_CONFIG --host-config=$WILDFLY_HOST_CONFIG $WILDFLY_OPTS"
fi
$command &
PID=$!

trap "kill -TERM $PID" SIGINT
trap "kill -TERM $PID" SIGTERM

while true
do	
	grep 'WFLYUT0006:' $WILDFLY_BASE_DIR/log/server.log > /dev/null
	if [ $? -eq 0 ] ; then
		break
	fi
	sleep 1
done

sleep 2
if [ -z "$DISABLE_AUTO_DEPLOY" ]; then
	bash deploy-manager.sh &
fi

wait $PID
