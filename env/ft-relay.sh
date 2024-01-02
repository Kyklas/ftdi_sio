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
PIN_PWR2=-1
PIN_INP=
PIN_INP2=-1
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
						PIN_PWR_INV=0
						;;
					2)
						echo "Using Config 2"
						RELAY_NAME=ftdi-cbus-FTRelay2
						PIN_PWR=2
						PIN_INP=1
						PIN_BOOT=0
						PIN_IGN=3
						PIN_INP_INV=0
						PIN_PWR_INV=0
						;;
					3)
						echo "Using Config 3"
						RELAY_NAME=ftdi-cbus-FT-EPC-20-12-23
						PIN_PWR=0
						PIN_INP=2
						PIN_BOOT=-1
						PIN_IGN=-1
						PIN_INP_INV=1
						PIN_PWR_INV=1
						PIN_PWR2=1
						PIN_INP2=3
						PIN_INP2_INV=1
						PIN_PWR2_INV=1
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

	echo "- Power 2  : ${PIN_PWR2}"
	echo "- Input 2  : ${PIN_INP2}"
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
	local PARAM=
    state=$(ft_arg $1)
    [ -z "${state}" ] && return
    ftlog "Power set ${state}"
	[ ${PIN_PWR_INV} -eq 1 ] && PARAM=-l
    gpioset ${PARAM} ${RELAY_NAME} ${PIN_PWR}=${state}
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
		return 1
    fi
}

function ftpwrwait() {
	state=$(ftpwrset $1)
	loop=0
	while true; do
		sleep 0.5
		((loop++))
		printf "%d - Wait Power %d - " $loop $state
		input=$(ftinput)
		if [ ${state} -eq ${input} ]; then
			break;
		fi
		if [ ${loop} -eq 60 ]; then
			ftlog "Power state did not reach $state"
			break;
		fi
	done
}

# POWER 2 / INPUT 2

function ftpwr2set() {
	local PARAM=
    state=$(ft_arg $1)
    [ -z "${state}" ] && return
    ftlog "Power2 set ${state}"
	[ ${PIN_PWR2_INV} -eq 1 ] && PARAM=-l
    gpioset ${PARAM} ${RELAY_NAME} ${PIN_PWR2}=${state}
    echo ${state}
}

function ftinput2()
{
	local PARAM=
	[ ${PIN_INP2_INV} -eq 1 ] && PARAM=-l
    input=$(gpioget ${PARAM} ${RELAY_NAME} ${PIN_INP2})
    ftlog "Input2 reads: $input"
    echo $input
}

function ftpwr2() {
    state=$(ftpwrset2 $1)
    sleep 0.2
    input=$(ftinput2)
    if [ ${state} -eq ${input} ]; then
        ftlog "Power2: OK"
    else
        ftlog "Power2: Error"
		return 1
    fi
}

function ftpwr2wait() {
	state=$(ftpwr2set $1)
	loop=0
	while true; do
		sleep 0.5
		((loop++))
		printf "%d - Wait Power2 %d - " $loop $state
		input=$(ftinput2)
		if [ ${state} -eq ${input} ]; then
			break;
		fi
		if [ ${loop} -eq 60 ]; then
			ftlog "Power2 state did not reach $state"
			break;
		fi
	done
}

# Ignition

function ftig() {
	if [ ${PIN_IGN} -eq -1 ]; then
		ftlog Skipping Ignition
		return
	fi

    state=$(ft_arg $1)
    [ -z "${state}" ] && return
    ftlog "Ignition set ${state}"
    gpioset ${RELAY_NAME} ${PIN_IGN}=${state}
    echo ${state}
}

function ftboot() {
	if [ ${PIN_BOOT} -eq -1 ]; then
		ftlog Skipping Boot
		return
	fi

    state=$(ft_arg $1)
    [ -z "${state}" ] && return
    ftlog "Boot set ${state}"
    gpioset ${RELAY_NAME} ${PIN_BOOT}=${state}
    echo ${state}
}


function ftoff() {
    ftig 0 > /dev/null
    ftboot 0 > /dev/null
    ftpwrwait 0
}

function fton() {
    ftig 1 > /dev/null
    ftboot 0 > /dev/null
    ftpwr 1 > /dev/null
}

function ftusb() {
    ftboot 1 > /dev/null
	sleep 0.1
	ftig 1 > /dev/null
    ftpwr 1 > /dev/null
}
