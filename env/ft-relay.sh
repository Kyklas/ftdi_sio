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

GPIOCHIP_NAME=
PIN_PWR=
PIN_INP=
PIN_BOOT=
PIN_IGN=

function ft_find_gpiochip() {

   # set -x

    local SERIAL=$1
    ftlog "Searching GPIOCHIP for serial : ${SERIAL}"

    declare -A FTDI_TTY
    declare -A FTDI_GPIOCHIP

    for ftdi in $(find /sys/bus/usb/drivers/ftdi_sio -type l); do

        # ftlog "FTDI $ftdi" 
        
        FTDI_PATH=
        FTDI_SERIAL_PATH=$(find $(cd -P $ftdi && pwd)/.. -name serial)
        [ -z "${FTDI_SERIAL_PATH}" ] && continue

        FTDI_SERIAL_VALUE=$(cat ${FTDI_SERIAL_PATH})

        if [ ! -z "${FTDI_SERIAL_VALUE}" ]; then
            # use printf formating for a nice list
            FTDI_TTY[${FTDI_SERIAL_VALUE}]=$(ls -1 $ftdi | grep ttyUSB)
            FTDI_GPIOCHIP[${FTDI_SERIAL_VALUE}]=$(ls -1 $ftdi | grep gpiochip)

            printf -v FTDI_INFO "FTDI: %16s - %10s - %10s" "'${FTDI_SERIAL_VALUE}'" "${FTDI_GPIOCHIP[${FTDI_SERIAL_VALUE}]}" "${FTDI_TTY[${FTDI_SERIAL_VALUE}]}"
            ftlog "${FTDI_INFO}"
        fi
    done

    echo "${FTDI_GPIOCHIP[${SERIAL}]}"
} 

function ft_config() {
	
	ftlog "Setup Relay Config"
	local OPTIND flag
	
	while getopts hlc:p:i:b:g: flag
	do
		case "${flag}" in
            l)
                # listing ftdi
                ft_find_gpiochip
                ;;
			c)
				case "${OPTARG}" in
					1)
						echo "Using Config 1"
						GPIOCHIP_NAME=$(ft_find_gpiochip FTRelay1)
						PIN_PWR=1
						PIN_INP=0
						PIN_BOOT=3
						PIN_IGN=2
						PIN_INP_INV=1
						;;
					2|Orange|Blue)
						echo "Using Config 2"
						GPIOCHIP_NAME=$(ft_find_gpiochip FTRelay${OPTARG})
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

    if [ -z "${GPIOCHIP_NAME}" ]; then
        ftlog "No FTDI found matching serial";
        return 1
    else
        echo "Relay ${GPIOCHIP_NAME}"
        echo "- Power   : ${PIN_PWR}"
        echo "- Input   : ${PIN_INP}"
        echo "- Boot    : ${PIN_BOOT}"
        echo "- Ignition: ${PIN_IGN}"
        return 0
    fi
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
    gpioset ${GPIOCHIP_NAME} ${PIN_PWR}=${state}
    echo ${state}
}

function ftinput()
{
	local PARAM=
	[ ${PIN_INP_INV} -eq 1 ] && PARAM=-l
    input=$(gpioget ${PARAM} ${GPIOCHIP_NAME} ${PIN_INP})
    ftlog "Input reads: $input"
    echo $input
}

function ftblink()
{
    local PARAM=
	[ ${PIN_INP_INV} -eq 1 ] && PARAM=-l

    for v in 1 0 1 0 1 0
    do
        gpioset ${PARAM} ${GPIOCHIP_NAME} ${PIN_INP}=$v
        sleep 0.2
    done

    ftinput
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
    gpioset ${GPIOCHIP_NAME} ${PIN_IGN}=${state}
    echo ${state}
}

function ftboot() {
    state=$(ft_arg $1)
    [ -z "${state}" ] && return
    ftlog "Boot set ${state}"
    gpioset ${GPIOCHIP_NAME} ${PIN_BOOT}=${state}
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

function ftcycle() {

    ftig 0
    ftboot 0
    ftpwr 0
    ftinput

    ftig 1
    sleep 0.5
    ftboot 1
    sleep 0.5
    ftpwr 1
    sleep 0.5

    ftblink

    ftig 0
    sleep 0.5
    ftboot 0
    sleep 0.5
    ftpwr 0
    sleep 0.5
}
