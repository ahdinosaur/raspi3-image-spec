#!/bin/bash -e

umask 022
mkdir -p output
mkdir -p work
env -i LC_CTYPE=C.UTF-8 PATH="/usr/sbin:/sbin:$PATH" \
    vmdb2 --output output/raspi3.img raspi3.yaml --log work/build.log
