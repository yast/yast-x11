#
# Makefile.am for x11/src/tools
#

ybin_PROGRAMS = testX active_window

ybin_SCRIPTS = set_videomode

sbin_SCRIPTS = xkbctrl

man_MANS = xkbctrl.1

testX_SOURCES = \
	testX.c

testX_LDFLAGS = \
	-L/usr/X11R6/lib -L/usr/X11R6/lib64 -lX11 -lXmu

active_window_SOURCES = \
	active_window.c

active_window_LDFLAGS = \
	-L/usr/X11R6/lib -L/usr/X11R6/lib64 -lX11

EXTRA_DIST = $(sbin_SCRIPTS) $(man_MANS)
