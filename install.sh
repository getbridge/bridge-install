#!/bin/sh
ARCH=`uname -p`
BRIDGE_URL="https://github.com/getbridge/bridge-server/tarball/"
RABBIT_URL="https://github.com/downloads/getbridge/bridge-server/rabbitmq-server-2.8.1u."

GET_TO_IT=0
GOT_RABBIT=0

TMP_DIR=$HOME/.bridge

err() {
    echo $1 > 2&
    exit 1
}

if [[ $ARCH =~ ^(x86|i[3-6]86)$ ]]; then
    $ARCH = "x86"
elif [ $ARCH != "x86_64" ]; then
    err "My sincerest apologies. I do not know how to deal with your computer's architecture."
fi

prompt() {
    read -r -p "$1 [y/N] " response
    response=${response,,}
    [[ $response =~ ^(yes|y)$ ]]
}

if [ ! -x `which rabbitmq-server 2>&1` ]; then
    err "You don't seem to have tar installed and/or in your path. Why don't you come back a little later once this has been amended?"
fi

if [ ! -d "$TMP_DIR" ]; then
    if prompt "May I set up in $TMP_DIR?"; then
	mkdir $TMP_DIR
    else
	err "That is unfortunate. Where, then, may I set up?"
    fi
fi

if [ ! -d "${TMP_DIR}/tmp" ]; then
    mkdir -p $TMP_DIR/tmp
fi
cd $TMP_DIR/tmp

if [ ! -x `which rabbitmq-server 2>&1` ]; then
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
    err "If you won't let me do even this for you, what was the point of asking for my assistance in the first place?"
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
