#!/usr/bin/env bash
# This script

function help(){
    echo "Usage: generate_version [ update | build | deploy ]"
}

function generate_current_versions(){
    find . -name "PKGBUILD" -print0 | xargs -0 grep '^pkgver=' | \
        sed -E 's%^\./([^/]+)/.*pkgver="([^"]+)"%\1 \2%' | sort
}

function ver2pkgver(){
    local pkgver
    pkgver=$(echo "${2}" | sed -E 's/^v(.*)/\1/')
    if [[ "${2}" != "${pkgver}" ]]; then
        echo "$1" >> ./ver2pkgver.list
        echo "${pkgver}"
    else
        echo "${2}"
    fi
}

function pkgver2ver(){
    if [ -f ./ver2pkgver.list ]; then
        cat ./ver2pkgver.list | xargs -I{} sed -i -E 's/({}) (.*)/\1 v\2/' "$1"
    fi
}

# Public funcitons
function update(){
    generate_current_versions 2>/dev/null >versions
    pkgver2ver versions
    echo -n "" > ./ver2pkgver.list

    while read -r line
    do
        is_updated=$(echo "$line" | jq .event | tr -d \")
        pkg=$(echo "$line" | jq .name | tr -d \")
        ver=$(echo "$line" | jq .version | tr -d \" )
        pkgver=$(ver2pkgver "$pkg" "$ver")

        if [ "$is_updated" = "updated" ]; then
            pkgold=$(echo "$line" | jq .old_version | tr -d \")
            sed -i.__"${pkgold}" "s/pkgver=.*/pkgver=\"${pkgver}\"/" "${pkg}/PKGBUILD"
            echo "$pkg updated to $pkgver"
        fi
    done < <(nvchecker --logger=json -c source_version.toml)
}


function build(){
    set -e
    pacur_bin=`which pacur`
    eval sudo "${pacur_bin}" project build $@
    eval sudo "${pacur_bin}" project repo
    set +e
}

function deploy(){
    sudo rm -rf /srv/mirror
    sudo cp -a ./mirror /srv/mirror
    sudo dnf clean all
}

if [ $# = 0 ]; then
    help
fi
"$@"
