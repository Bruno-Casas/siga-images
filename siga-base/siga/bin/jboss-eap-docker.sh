#!/bin/bash
#
# JBoss EAP Docker Control
#
# description: JBoss EAP startup script for docker
# processname: siga-jboss-eap
# pidfile: /var/run/siga-jboss-eap/siga-jboss-eap.pid
# config: /siga/bin/siga-jboss-eap.conf
#

if [ -z "$JBOSS_NAME" ]; then
  JBOSS_NAME='siga-jboss-eap'
fi

if [ -z "$JBOSS_CONF" ]; then
	JBOSS_CONF="$SIGA_DIR/bin/$JBOSS_NAME.conf"
fi

[ -r "$JBOSS_CONF" ] && . "${JBOSS_CONF}"

if [ -z "$STARTUP_WAIT" ]; then
	STARTUP_WAIT=30
fi

if [ -z "$SHUTDOWN_WAIT" ]; then
	SHUTDOWN_WAIT=30
fi

if [ -z "$JBOSS_CONSOLE_LOG" ]; then
	JBOSS_CONSOLE_LOG=/var/log/$JBOSS_NAME/console.log
fi

if [ -z "$JBOSS_LOCKFILE" ]; then
	JBOSS_LOCKFILE=/var/lock/subsys/$JBOSS_NAME
fi

if [ -z "$JBOSS_MODE" ]; then
	JBOSS_MODE=standalone
fi

if [ -z "$JBOSS_BASE_DIR" ]; then
	JBOSS_BASE_DIR="$JBOSS_HOME/$JBOSS_MODE"
else
	JBOSS_OPTS="$JBOSS_OPTS -Djboss.server.base.dir=$JBOSS_BASE_DIR"
fi

JBOSS_MARKERFILE=$JBOSS_BASE_DIR/tmp/startup-marker

# Startup mode script
if [ "$JBOSS_MODE" = "standalone" ]; then
	JBOSS_SCRIPT=$JBOSS_HOME/bin/standalone.sh
	if [ -z "$JBOSS_CONFIG" ]; then
		JBOSS_CONFIG=standalone.xml
	fi
else
	JBOSS_SCRIPT=$JBOSS_HOME/bin/domain.sh
	if [ -z "$JBOSS_DOMAIN_CONFIG" ]; then
		JBOSS_DOMAIN_CONFIG=domain.xml
	fi
	if [ -z "$JBOSS_HOST_CONFIG" ]; then
		JBOSS_HOST_CONFIG=host.xml
	fi
fi

prog=$JBOSS_NAME
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

syncVolumeOwner $JBOSS_HOME "$SIGA_DIR/deployments"
bash "$SIGA_DIR/bin/startup.sh"
runStartupScritps

command=""
if [ "$JBOSS_MODE" = "standalone" ]; then
	command="standalone.sh -c $JBOSS_CONFIG $JBOSS_OPTS"
else
	command="standalone.sh --domain-config=$JBOSS_DOMAIN_CONFIG --host-config=$JBOSS_HOST_CONFIG $JBOSS_OPTS"
fi
$command &
PID=$!

trap "kill -TERM $PID" SIGINT
trap "kill -TERM $PID" SIGTERM

while true
do	
	grep 'WFLYUT0006:' $JBOSS_BASE_DIR/log/server.log > /dev/null
	if [ $? -eq 0 ] ; then
		break
	fi
	sleep 1
done
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
bash "$SIGA_DIR/bin/deploy-manager.sh" &

wait $PID
