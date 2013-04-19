#
# Makefile.am for x11/src/tools
#

ybin_PROGRAMS = testX

sbin_SCRIPTS = xkbctrl

man_MANS = xkbctrl.1

testX_SOURCES = \
	testX.c

testX_LDFLAGS = \
	-L/usr/X11R6/lib -L/usr/X11R6/lib64 -lX11 -lXmu

EXTRA_DIST = $(sbin_SCRIPTS) $(man_MANS)
