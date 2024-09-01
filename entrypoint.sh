#!/command/with-contenv bash

set -e

varRequiresQuotes=(
    "ViaProxyName"
    "DefaultErrorFile"
    "StatFile"
    "StatHost"
    "AddHeader"
    "Filter"
    "Anonymous"
    "ReverseBaseURL"
)

formatForConf() {
    local key="$1"
    local val="$2"

    # If the value resolves to a file, return it with double-quotes
    if [[ -f "$val" ]]; then
        echo "$key \"$val\""
        return 0
    fi

    # If the key is in a list of keys requiring quotes, return it with doube-quotes
    for config in "${varRequiresQuotes[@]}"; do
        if [[ "$config" == "$key" ]]; then
            echo "$key \"$val\"" | sed 's/""/"/g'
            return 0
        fi
    done

    echo "$key $val"
}

if [ ! -f "$TINYPROXY_CONFIG" ]; then

  TINYPROXY_CONFIG=/etc/tinyproxy/tinyproxy.conf
  truncate -s0 "$TINYPROXY_CONFIG"
  printenv | grep "TINYPROXY_CONF_" | sed 's/TINYPROXY_CONF_//' | awk -F '=' '{print $1, $2}' | while read confKey confValue; do
    confKey=$(awk -v var=$confKey 'BEGIN {print tolower(var)}' | sed -r 's/(^|_)([a-zA-Z])/\U\2/g')
    formatForConf "$confKey" "$confValue" >>"$TINYPROXY_CONFIG"
  done

fi

# if filters are set store them to /tmp/filter.txt
if [ ! -z "$TINYPROXY_FILTER" ]; then
  printenv TINYPROXY_FILTER | base64 -d > "/tmp/filter.txt"
  export TINYPROXY_CONF_FILTER="/tmp/filter.txt"
fi


# Show config data
echo "======== $TINYPROXY_CONFIG ========"
cat -n "$TINYPROXY_CONFIG"
echo "======== $TINYPROXY_CONFIG ========"

/usr/bin/tinyproxy -d -c "$TINYPROXY_CONFIG"
