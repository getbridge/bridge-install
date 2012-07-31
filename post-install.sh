#!/bin/sh

args=($@)

BRIDGE_DIR=$HOME/.bridge
API_KEYS=$BRIDGE_DIR/keys

err() {
    echo $1 2>1&
    exit 1
}

confirm() {
    read -r -p "$1 [Y/n] " _
    _="`echo $_ | tr '[:upper:]' '[:lower:]'`"
    [[ $_ =~ ^(y|yes)$ || -z $_ ]]
}

prompt() {
    read -r -p "$1
" _
}

print_info() {
    echo "To see your API keys again, type \`setup --keys\`. To change your API keys, type
\`setup --set-keys pubkey privkey\`. To view this message, type \`setup --help\`.
"
}

print_keys() {
    echo "Here are your API keys:"
    cat $API_KEYS
}

set_keys() {
    echo -e '{public, "$1"}.\n{private, "$2"}.' > $API_KEYS
}

el=${args[0]}
if [ -n $el ]; then
    if [[ $el = "--keys" ]]; then
	print_keys
	exit 0
    elif [[ $el = "--help" ]]; then
	print_info
	exit 0
    elif [[ $el = "-h" ]]; then
	print_info
	exit 0
    elif [[ $el = "--set-keys" ]]; then
	if [ "3" != "$#" ]; then
	    err "Proper usage: \`setup --set-keys pubkey privkey\`."
	fi
	set_keys ${args[1]} ${args[2]}
	exit 0
    fi
fi

if [ ! -r $API_KEYS ]; then
    if confirm "
You need a public & private API key to use Bridge. Would you like me to generate
some for you [y], or do you have existing API keys I should use [n]? "; then
	echo -e "\nYour keys will be generated the first time you run the Bridge \
server.\n"
    else
	prompt "What is your public API key?"
	_first=$_
	prompt "What is your private API key?"
	_second=$_
	set_keys _first _second

	print_info
	print_keys
    fi

    echo -e "I recommend that you read some Bridge example code. They're available at
https://www.getbridge.com/examples."

fi
