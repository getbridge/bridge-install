#!/bin/sh
ARCH=`uname -p`
BRIDGE_URL="https://github.com/getbridge/bridge-server/tarball/"
RABBIT_URL="https://github.com/downloads/getbridge/bridge-server/rabbitmq-server-2.8.1u."

GET_TO_IT=0
GOT_RABBIT=0

TMP_DIR=$HOME/.bridge
if [[ $ARCH =~ ^(x86|i[3-6]86)$ ]]; then
    $ARCH = "x86"
elif [ $ARCH != "x86_64" ]; then
    echo "My sincerest apologies. I do not know how to deal with your computer's architecture."
    exit 1
fi

prompt() {
    read -r -p "$1 [y/N] " response
    response=${response,,}
    [[ $response =~ ^(yes|y)$ ]]
}

if [ ! -d "$TMP_DIR" ]; then
    if prompt "May I set up in $TMP_DIR?"; then
	mkdir $TMP_DIR
    else
	echo "That is unfortunate. Where, then, may I set up?"
    fi
fi

if [ ! -d "${TMP_DIR}/tmp" ]; then
    mkdir -p $TMP_DIR/tmp
fi
cd $TMP_DIR/tmp

if [ -z "`which rabbitmq-server 2>&1 | grep -P '^/'`" ]; then
    # Acquire rabbit.
    if prompt "I can't seem to find rabbitmq-server in your path. Shall I fetch it for you?"; then
	RABBIT_DIR="${TMP_DIR}/rabbitmq"
	GOT_RABBIT=1
	curl -o rabbitmq.tar.gz "${RABBIT_URL}/${ARCH}.tar.gz"; tar -xzf rabbitmq.tar.gz -o ../rabbitmq
    else
	echo "Very well, then. I will respect your decision."
    fi
fi

if prompt "Our next event involves acquiring a copy of the Bridge gateway. Is that all right?"; then
    curl -o bridge.tar.gz "${BRIDGE_URL}/${ARCH}"; tar -xzf bridge.tar.gz -o ../bridge
else
    echo "If you won't let me do even this for you, what was the point of asking for my assistance in the first place?"
    exit 1;
fi

cd ..

rm -rf tmp/*

echo "The installation is now complete. Have a good day, and do put in a good word, will you?"

echo "\n To use Bridge, first run the rabbitmq-server:"
if [[ GOT_RABBIT = 1 ]]; then
    echo "  Execute \`cd ${RABBIT_DIR}; ./bin/start_epmd; ./bin/start_server\`".
fi

echo "\n Then start the bridge server:\n  Execute \`${TMP_DIR}/bridge/bc-latest/bin/server start\`"

echo "\n To stop the bridge server, simply run \`${TMP_DIR}/bridge/bc-latest/bin/server stop\`"
