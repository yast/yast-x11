#
# Makefile.am for x11/agent-isax/src
#

AM_CXXFLAGS = -DY2LOG=\"agent-isax\"

plugin_LTLIBRARIES = libpy2ag_xf86config.la
noinst_LTLIBRARIES = liby2ag_xf86config.la

liby2ag_xf86config_la_SOURCES = 			\
	Xf86ConfigAgent.cc Xf86ConfigAgent.h
liby2ag_xf86config_la_LDFLAGS = -version-info 2:0

libpy2ag_xf86config_la_SOURCES =			\
	$(liby2ag_xf86config_la_SOURCES)		\
	Y2CCXf86Config.cc 	Y2CCXf86Config.h	\
	Y2Xf86ConfigComponent.cc Y2Xf86ConfigComponent.h
libpy2ag_xf86config_la_LDFLAGS = -version-info 2:0

INCLUDES = -I$(includedir)

install-data-hook:
	rm -f $(DESTDIR)$(plugindir)/*.la
