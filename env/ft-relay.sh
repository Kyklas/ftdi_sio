#!/bin/bash

# Source this script

function ftlog(){
    echo "FT Relay: $@" >&2
}

function ft_arg(){
    case $1 in
        1|on|ON|On)
        state=1
        ;;
        0|off|OFF|Off)
        state=0
        ;;
        *)
        ftlog "Invalid Input: '$1' "
        state=""
        ;;
    esac
    echo ${state}
}

function ftpwrset() {
    state=$(ft_arg $1)
    [ -z "${state}" ] && return
    ftlog "Power set ${state}"
    gpioset ftdi-cbus-FTRelay1 1=${state}
    echo ${state}
}

function ftinput()
{
    input=$(gpioget -l ftdi-cbus-FTRelay1 0)
    ftlog "Input reads: $input"
    echo $input
}

function ftpwr() {
    state=$(ftpwrset $1)
    sleep 0.2
    input=$(ftinput)
    if [ ${state} -eq ${input} ]; then
        ftlog "Power: OK"
    else
        ftlog "Power: Error"
    fi
}

function ftig() {
    state=$(ft_arg $1)
    [ -z "${state}" ] && return
    ftlog "Ignition set ${state}"
    gpioset ftdi-cbus-FTRelay1 2=${state}
    echo ${state}
}

function ftboot() {
    state=$(ft_arg $1)
    [ -z "${state}" ] && return
    ftlog "Boot set ${state}"
    gpioset ftdi-cbus-FTRelay1 3=${state}
    echo ${state}
}


function ftoff() {
    ftpwrset 0
    ftig 0
    ftboot 0
}

function fton() {
    ftig 1
    ftboot 0
    ftpwr 1
}

function ftusb() {
    ftig 1
    ftboot 1
    ftpwr 1
}
