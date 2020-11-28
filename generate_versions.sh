#!/usr/bin/env bash
# This script


function generate_current_versions(){
    find . -name "PKGBUILD" -print0 | xargs -0 grep 'pkgver=' | \
        sed -E 's%^\./([^/]+)/.*pkgver="([^"]+)"%\1 \2%' | sort
}

# Public funcitons
function update(){
    mkdir -p tmp
    generate_current_versions 2>/dev/null >tmp/versions
    while read -r line
    do
        is_updated=$(echo "$line" | jq .event | tr -d \")
        pkg=$(echo "$line" | jq .name | tr -d \")
        pkgver=$(echo "$line" | jq .version | tr -d \")

        if [ "$is_updated" = "updated" ]; then
            pkgold=$(echo "$line" | jq .old_version | tr -d \")
            # if [ -f "./${pkg}/download.sh" ]; then
            #     (
            #         echo "Download $pkg"
            #         cd "$pkg"
            #         export PGKVER="$pkgver"
            #         ./download.sh
            #     )
            # fi
            sed -i."__${pkgold}" "s/pkgver=.*/pkgver=\"${pkgver}\"/" "${pkg}/PKGBUILD"
            echo "$pkg updated to $pkgver"
        fi
    done < <(nvchecker --logger=json -c source_version.toml)
}


function build(){
    pacur project build
    pacur project repo
}

"$@"
