# SPDX-License-Identifier: GPL-2.0

obj-$(CONFIG_USB_SERIAL_FTDI_SIO)		+= ftdi_sio.o

$(info KERNEL_SRC $(KERNEL_SRC))

all:
	$(MAKE) -C $(KERNEL_SRC) M=$(CURDIR) modules

modules_install:
	$(MAKE) -C $(KERNEL_SRC) M=$(CURDIR) modules_install

clean:
	rm -f *.o *~ core .depend .*.cmd *.ko *.mod.c
	rm -f Module.markers Module.symvers modules.order
	rm -rf .tmp_versions Modules.symversa

