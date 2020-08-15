#!/usr/bin/env bash

(find . -name "PKGBUILD" -print0 | xargs -0 grep 'pkgver=' | \
    sed -E 's%^\./([^/]+)/.*pkgver="([^"]+)"%\1 \2%' | sort) 2>/dev/null >versions
