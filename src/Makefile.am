yncludedir = @yncludedir@/x11

YCPCFLAGS = -M . -I .

module_DATA =		\
	XMessages.ycp   \
	XLib.pm

client_DATA =       \
	x11.ycp         \
	XMain.ycp

EXTRA_DIST = $(client_DATA) $(module_DATA)

include $(top_srcdir)/Makefile.am.common

SUBDIRS = config proposal dialog autoyast
