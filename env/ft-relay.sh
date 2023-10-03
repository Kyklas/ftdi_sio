#!/bin/bash

# Source this script

SOURCED=0
if [ -n "$BASH_VERSION" ]; then
  (return 0 2>/dev/null) && SOURCED=1
else
	echo "Use script from bash"
fi

if [ ${SOURCED} -eq 0 ]; then
	echo "Script should be sourced"
	exit 1
fi

RELAY_NAME=
PIN_PWR=
PIN_INP=
PIN_BOOT=
PIN_IGN=

function ft_config() {
	
	echo "Setup Relay Config"
	local OPTIND flag
	
	while getopts hc:p:i:b:g: flag
	do
		case "${flag}" in
			c)
				case "${OPTARG}" in
					1)
						echo "Using Config 1"
						RELAY_NAME=ftdi-cbus-FTRelay1
						PIN_PWR=1
						PIN_INP=0
						PIN_BOOT=3
						PIN_IGN=2
						PIN_INP_INV=1
						;;
					2)
						echo "Using Config 2"
						RELAY_NAME=ftdi-cbus-FTRelay2
						PIN_PWR=2
						PIN_INP=1
						PIN_BOOT=0
						PIN_IGN=3
						PIN_INP_INV=0
						;;
				esac
			;;
		esac
	done

	echo "Relay ${RELAY_NAME}"
	echo "- Power   : ${PIN_PWR}"
	echo "- Input   : ${PIN_INP}"
	echo "- Boot    : ${PIN_BOOT}"
	echo "- Ignition: ${PIN_IGN}"
}

ft_config $*

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
    gpioset ${RELAY_NAME} ${PIN_PWR}=${state}
    echo ${state}
}

function ftinput()
{
	local PARAM=
	[ ${PIN_INP_INV} -eq 1 ] && PARAM=-l
    input=$(gpioget ${PARAM} ${RELAY_NAME} ${PIN_INP})
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
    gpioset ${RELAY_NAME} ${PIN_IGN}=${state}
    echo ${state}
}

function ftboot() {
    state=$(ft_arg $1)
    [ -z "${state}" ] && return
    ftlog "Boot set ${state}"
    gpioset ${RELAY_NAME} ${PIN_BOOT}=${state}
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
