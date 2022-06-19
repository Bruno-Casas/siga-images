#!/bin/sh

set -e

reset_variables() {
	POSTFIX=""
    DB_URL=""
    DB_USER=""
    DB_PASSWORD=""
    PROPERTIES_FILE=""
}

validate_variables() {
    if [ -z "$POSTFIX" ]; then
        echo "POSTFIX has not been defined."
        exit 1
    fi

    if [ -z "$DB_URL" ]; then
        echo "DB_URL has not been defined."
        exit 1
    fi

    if [ -z "$DB_USER" ]; then
        echo "DB_USER has not been defined."
        exit 1
    fi

    if [ -z "$DB_PASSWORD" ]; then
        echo "DB_PASSWORD has not been defined."
        exit 1
    fi

    if [ -z "$PROPERTIES_FILE" ]; then
        echo "PROPERTIES_FILE has not been defined."
        exit 1
    fi
}

make_properties() {
    while IFS='=' read -ra PROP || [ -n "$PROP" ]; do
        key=${PROP[0]}
        [[ "$key" =~ ^#.*$ ]] && continue
        value="$(eval echo \"${PROP[1]}\")"

        cat >>$SIGA_DIR/commands.cli <<EOF
if (outcome != success) of /system-property=$key:read-resource
    /system-property=$key:add(value="$value")
else
    /system-property=$key:write-attribute(name=value,value="$value")
end-if

EOF
    done < $PROPERTIES_FILE
}

make_config() {
    [ -r "$PROPERTIES_FILE" ] && make_properties

    datasource_name="Siga${POSTFIX}DS"
    cat >>$SIGA_DIR/commands.cli <<EOF
if (outcome != success) of /subsystem=datasources/data-source=${datasource_name}/:read-resource
    data-source add --jndi-name=java:jboss/datasources/${datasource_name} --name=${datasource_name}\\
        --connection-url=jdbc:$DB_URL\\
        --driver-name=mysql\\
        --user-name=$DB_USER\\
        --password=$DB_PASSWORD\\
        --min-pool-size = 2\\
        --max-pool-size = 10\\
        --idle-timeout-minutes = 5
end-if

EOF
}

generated=""
PROPERTIES_FILE="$SIGA_DIR/props/default.properties"

echo -e 'embed-server --std-out=echo\n' >$SIGA_DIR/commands.cli

if [ -r "$PROPERTIES_FILE" ]
then
    make_properties
    generated='true'
    PROPERTIES_FILE=""
fi

for file in ${SIGA_DIR}/configs/*.config; do
    if [ -f "$file" ]
    then
        . $file
        validate_variables
        make_config
        reset_variables
        generated='true'
    fi
done

if [ ! -z "$generated" ]
then
    cat >>$SIGA_DIR/commands.cli <<EOF
stop-embedded-server
exit
EOF

jboss-cli.sh --file=$SIGA_DIR/commands.cli > /dev/null
else
    echo '' >$SIGA_DIR/commands.cli
fi
