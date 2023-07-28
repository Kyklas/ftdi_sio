#!/bin/bash -ex

export ARCH=x86

export KERNEL_SRC="/lib/modules/$(uname -r)/build"
export CONFIG_USB_SERIAL_FTDI_SIO=m

ls ${KERNEL_SRC}

export src=${PWD}

make $@


