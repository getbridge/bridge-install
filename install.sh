#!/bin/sh
ARCH=`uname -p`
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

if [[ -n "`uname -p | grep -P '^i.86$'`" ]]; then
    ARCH="x86"
elif [ $ARCH != "x86_64" ]; then
    err "My sincerest apologies. I do not know how to deal with your computer's architecture."
fi

prompt() {
    if [ -n "${GET_TO_IT}" ]; then
	return 0
    fi

    read -r -p "$1 [Y/n] " response
    response=${response,,}
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
	curl -L "${RABBIT_URL}${ARCH}.tar.gz" -o tmp/rabbitmq.tar.gz
	tar -xzf tmp/rabbitmq.tar.gz
	mv rabbitmq-server-* "${TMP_DIR}/rabbitmq";
    else
	err "Very well, then. I will respect your decision."
    fi
fi

if [ -d $TMP_DIR/bridge-server ]; then
    mv $TMP_DIR/bridge-server $TMP_DIR/bridge-server.old`date +%m%d%H%M%Y.%S`
fi

echo "Downloading and unpacking Bridge from ${BRIDGE_URL}/${ARCH}."
curl -L "${BRIDGE_URL}/${ARCH}" -o tmp/bridge.tar.gz

tar -xzf tmp/bridge.tar.gz
if [ $? != "0" ]; then
    err "tar failed!"
fi

mv getbridge-bridge-server-* bridge-server

rm -rf tmp

echo "The installation is now complete. Have a good day, and do put in a good word, will you?"

curl -L POST_INSTALL_URL -o setup.sh

echo -e "\n Run the post-install script via \`sh ~/.bridge/setup.sh`."

echo -e "\n To use Bridge, first run the rabbitmq-server:"

if [[ $GOT_RABBIT != "" ]]; then
    echo "#!/bin/sh" > $TMP_DIR/rabbitmq-server
    echo "cd ~/.bridge/rabbitmq; ./bin/start_epmd; sleep 0.5; ./sbin/rabbitmq-server" >> $TMP_DIR/rabbitmq-server
    chmod +x $TMP_DIR/rabbitmq-server
    echo "  Execute \`~/.bridge/rabbitmq-server\`"
else
    echo "  Execute \`rabbitmq-server\` (if you want, run it with the -detached flag)."
fi

echo -e "\n Then start the bridge server:\n  Execute \`~/.bridge/bridge-server/bin/server start\`"

echo -e "\n To stop the bridge server, simply run \`~/.bridge/bridge-server/bin/server stop\`"
