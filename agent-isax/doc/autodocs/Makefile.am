#
# Makefile.am for x11/agent-isax/doc/autodocs
#

htmldir = $(docdir)/autodocs

html_DATA = index.html $(wildcard *.html)
CLEANFILES = $(html_DATA)

index.html: $(srcdir)/../../src/*.h
	cd $(srcdir)/../../src && @ybindir@/ydoc agent-isax *.h
	mv -f $(srcdir)/../../src/*.html .
