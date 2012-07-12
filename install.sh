#!/usr/bin/env bash
ARCH=`uname -m`
BRIDGE_URL="https://github.com/getbridge/bridge-server/tarball"
RABBIT_URL="https://github.com/downloads/getbridge/bridge-server/rabbitmq-server-2.8.1u."
POST_INSTALL_URL="https://raw.github.com/gist/09ed552955d6deedd2be"

GET_TO_IT=""

if [ -z "${PS1}" ]; then
    GET_TO_IT="1"
fi

GOT_RABBIT=""

TMP_DIR=$HOME/.bridge
BIN_DIR=${TMP_DIR}/bridge-server/bc-latest/bin

err() {
    echo "$@" 1>&2
    exit 1
}

if [[ -n "`uname -m | grep -P '^i.86$'`" ]]; then
    ARCH="x86"
elif [ $ARCH != "x86_64" ]; then
    err "My sincerest apologies. I do not know how to deal with your computer's architecture."
fi

if [[ "`uname -s`" = "Darwin" ]]; then
    ARCH="OSX"
fi

prompt() {
    if [ -n "${GET_TO_IT}" ]; then
	return 0
    fi

    read -r -p "$1 [Y/n] " response
    response=`echo $response | tr '[:upper:]' '[:lower:]'`
    [[ $response =~ ^(y|yes)$ ]]
}

echo "Setting up in $TMP_DIR."

mkdir -p $TMP_DIR/tmp

cd $TMP_DIR

if [ -z "`which rabbitmq-server 2>&1 | grep -P '^/'`" ]; then
    # Acquire rabbit.
    if prompt "I can't seem to find rabbitmq-server in your path. Shall I fetch it for you?"; then
	RABBIT_DIR="${TMP_DIR}/rabbitmq"
	GOT_RABBIT="1"
	curl -L "${RABBIT_URL}${ARCH}.tar.gz" > tmp/rabbitmq.tar.gz
	tar -xzf tmp/rabbitmq.tar.gz
	mv rabbitmq-server-* "$RABBIT_DIR";
	cd $RABBIT_DIR
        ./bin/post_install.sh
	cd ..
    else
	err "Very well, then. I will respect your decision."
    fi
fi

if [ -d $TMP_DIR/bridge-server ]; then
    mv $TMP_DIR/bridge-server $TMP_DIR/bridge-server.old`date +%m%d%H%M%Y.%S`
fi

echo "Downloading and unpacking Bridge from ${BRIDGE_URL}/${ARCH}."
curl -L "${BRIDGE_URL}/${ARCH}" > tmp/bridge.tar.gz

tar -xzf tmp/bridge.tar.gz
if [ $? != "0" ]; then
    err "tar failed!"
fi

mv getbridge-bridge-server-* bridge-server

rm -rf tmp

curl -L $POST_INSTALL_URL -o setup.sh

echo "The installation is now complete. Have a good day, and do put in a good word, will you?"

echo -e "\n Run the post-install script via \`sh ~/.bridge/setup.sh\`."

echo "#!/bin/sh" > $TMP_DIR/server
echo "PAR=\$(cd \${0%/*} && pwd)" >> $TMP_DIR/server
echo "OLD_LD_LIBRARY_PATH=\$LD_LIBRARY_PATH" >> $TMP_DIR/server

if [[ $GOT_RABBIT != "" ]]; then
    echo "if [ '\$1'='stop' ]; then $PAR/rabbitmq/bin/stop_server; else" >> $TMP_DIR/server
    echo "cd \$PAR/rabbitmq; ./sbin/rabbitmq-server; fi" >> $TMP_DIR/server
else
    echo -e "\n To use Bridge, first run the rabbitmq-server:"
    echo "  Execute \`rabbitmq-server\` (if you want, run it with the -detached flag)."
fi
echo "export LD_LIBRARY_PATH=\$PAR/bridge-server/local/lib\${LD_LIBRARY_PATH:+:}\$LD_LIBRARY_PATH" >> $TMP_DIR/server
echo "\$PAR/bridge-server/bin/server \$1" >> $TMP_DIR/server

echo "export LD_LIBRARY_PATH=\$OLD_LD_LIBRARY_PATH" >> $TMP_DIR/server

chmod +x $TMP_DIR/server

echo -e "\n Then start the bridge server:\n  Execute \`~/.bridge/server start\`"

echo -e "\n To stop the bridge server, simply run \`~/.bridge/server stop\`"
