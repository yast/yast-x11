#
# Makefile.am for y2a_xf86/testsuite
#

AUTOMAKE_OPTIONS = dejagnu

INCLUDES = -I$(includedir)

noinst_PROGRAMS = runxf86config
runxf86config_SOURCES = runxf86config.cc

runxf86config_LDADD = -lscr -ly2 -lycp -lcrypt
runxf86config_LDFLAGS = -L$(libdir)	\
	-Xlinker --whole-archive	\
	$(plugindir)/libpy2stdio.la	\
	$(plugindir)/libpy2script.la	\
	../src/libpy2ag_xf86config.la	\
	-Xlinker --no-whole-archive
