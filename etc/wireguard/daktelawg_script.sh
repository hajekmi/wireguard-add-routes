#!/bin/bash

action=$1
wg_interface=$2
wg_server=$3
url_get_routes=$4
metric=8;

add_route() {
    local net=$1
    local via_gw=$2
    local dev=$3
    local metric=$4

    if [ -n "${via_gw}" ]; then
        via_gw="via ${via_gw}"
    else
        via_gw="";
    fi

    ip r add ${net} ${via_gw} dev ${dev} metric ${metric}
    if [ $? -ge 1 ]; then
        echo "Unable add route ${net} via ${via_gw} dev ${dev} metric ${metric}";
        return 1;
    else
        return 0;
    fi
}

download_routes() {
    local tmp=$(mktemp -p /tmp)
    local line=""
    local ipmask=""
    for i in {1..10}; do
        echo "Download ${url_get_routes}"
        curl "${url_get_routes}" --output ${tmp}
        if [ $? -ge 1 ]; then
            sleep 0.5s
        else
            while read -r line; do
                ipmask=$(echo "${line}" | sed -n 's~.*route destination="\([0-9.]*\)" mask="\([0-9.]*\)".*~\1/\2~p')
                if [ -n "${ipmask}" ]; then
                    echo "run func add_route ${ipmask} \"\" ${wg_interface} ${metric}"
                    add_route ${ipmask} "" ${wg_interface} ${metric}
                    if [ $? -ge 1 ]; then
                        return 2;
                    fi
                fi
            done < ${tmp}

            echo "Success added all routes"
            rm -f "${tmp}"
            return 0;
        fi
    done
    
    rm -f "${tmp}"
    return 1;
}

wg_server_default_route() {
    if [ "$1" -ge 1 ]; then
        local default_gw=$( ip r | grep default | sed 's~.* via \([0-9.]*\) .*~\1~' 2> /dev/null )
        local default_dev=$( ip r | grep default | sed 's~.* dev \([^ ]*\) .*~\1~' 2> /dev/null )
        ip r del ${wg_server} metric $((${metric}-1)) > /dev/null 2>&1
        add_route "${wg_server}/32" "${default_gw}" "${default_dev}" "$((${metric}-1))";
        return $?
    else
        ip r del ${wg_server} metric $((${metric}-1))
        return 0;
    fi
    return;
}

run_up() {
    
    # Route for private site VPN
    add_route "100.64.0.0/16" "" "${wg_interface}" "${metric}" || exit 1;

    # Route for WG server public
    wg_server_default_route 1 || exit 2;

    # Download all routes
    download_routes || exit 3;

    ## Custom add routes here:

    ## end custom
  
    # Firewall
    #/michals/fw_rules.sh

    return;
}

run_down() {
    wg_server_default_route 0

    return;
}

if [ "${action}" == "up" ]; then
    run_up || exit $?
else
    run_down || exit $?
fi
