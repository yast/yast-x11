#
# Makefile.am for y2c_x11/src
#

SUBDIRS = include modules

clientsdir = $(YAST2DIR)/clients
configdir = $(YAST2DIR)/config

clients_DATA =				\
	inst_x11.ycp			\
	x11.ycp				\
	x11_write.ycp			\
	inst_sunfb.ycp

config_DATA = x11.y2cc

EXTRA_DIST = $(clients_DATA) $(config_DATA)
