/*
 * Copyright (c) 2012 Novell, Inc.
 * Copyright (c) 2023 SUSE Linux LLC
 *
 * All Rights Reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of version 2 of the GNU General Public License as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, contact Novell, Inc.
 *
 * To contact Novell about this file by physical or electronic mail, you may
 * find current contact information at www.novell.com.
 */


#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/Xmu/CurUtil.h>
#include <sys/types.h>
#include <sys/wait.h>

#define ICEWM     "icewm"
#define FVWM      "fvwm2"
#define MWM       "mwm"
#define TWM       "twm"

#define ICEWMPREFS "preferences.yast2"
#define FVWMRC     "fvwmrc.yast2"

int screen;

Cursor CreateCursorFromName(Display* dpy, const char* name);
XColor NameToXColor(Display* dpy, const char* name, unsigned long pixel);
int RunWindowManager(void);

int main(int argc, char** argv)
{
    Cursor cursor;
    Display *display;
    Window root;
    unsigned long pixel;
    char* cname;
    XColor color;
    Atom prop;
    Pixmap save_pixmap = (Pixmap) None;

    //============================================
    // open display and check if we got a display
    //--------------------------------------------
    display = XOpenDisplay(NULL);

    if (!display)
    {
	exit (1);
    }

    if ((argc == 2) && (strcmp(argv[1], "--fast") == 0))
    {
	XCloseDisplay(display);
	exit (0);
    }

    //============================================
    // install color map for background pixels
    //--------------------------------------------
    cname = argc == 2 ? argv[1] : "black";
    screen = DefaultScreen(display);
    root = RootWindow(display, screen);
    pixel = BlackPixel(display, screen);

    if (XParseColor(display, DefaultColormap(display, screen), cname, &color))
    {
	if (XAllocColor(display, DefaultColormap(display, screen), &color))
        {
	    pixel = color.pixel;
	}
    }
    XSetWindowBackground(display, root, pixel);
    XClearWindow(display, root);

    //============================================
    // set the cursor
    //--------------------------------------------
    cursor = CreateCursorFromName(display, "top_left_arrow");
    if (cursor)
    {
	XDefineCursor(display, root, cursor);
	XFreeCursor(display, cursor);
    }

    //============================================
    // start a window manager
    //--------------------------------------------
    RunWindowManager();

    //============================================
    // save background as pixmap
    //--------------------------------------------
    save_pixmap = XCreatePixmap(display, root, 1, 1, 1);
    prop = XInternAtom(display, "_XSETROOT_ID", False);
    XChangeProperty(display, root, prop, XA_PIXMAP, 32, PropModeReplace,
		    (unsigned char*) &save_pixmap, 1);
    XSetCloseDownMode(display, RetainPermanent);

    //============================================
    // Shut down
    //--------------------------------------------
    XCloseDisplay(display);
    exit(0);
}


Cursor CreateCursorFromName(Display* dpy, const char* name)
{
    XColor fg, bg;
    int i;
    Font fid;
    char* fore_color = NULL;
    char* back_color = NULL;

    fg = NameToXColor(dpy, fore_color, BlackPixel(dpy, screen));
    bg = NameToXColor(dpy, back_color, WhitePixel(dpy, screen));

    i = XmuCursorNameToIndex(name);

    if (i == -1)
	return (Cursor) 0;
    fid = XLoadFont (dpy, "cursor");
    if (!fid)
	return (Cursor) 0;

    return XCreateGlyphCursor(dpy, fid, fid, i, i+1, &fg, &bg);
}


XColor NameToXColor(Display* dpy, const char* name, unsigned long pixel)
{
    XColor c;

    if (!name || !*name)
    {
	c.pixel = pixel;
	XQueryColor(dpy, DefaultColormap(dpy, screen), &c);
    }
    else if (!XParseColor(dpy, DefaultColormap(dpy, screen), name, &c))
    {
	fprintf(stderr, "testX: unknown color or bad color format: %s\n", name);
	exit(1);
    }

    return c;
}

int RunWindowManager(void)
{
    int wmpid = fork();
    switch (wmpid)
    {
	case -1:
	    return 0;
	    break;
	case 0:
	    setenv("ICEWM_PRIVCFG", "/etc/icewm/yast2", 1);
	    execlp(ICEWM, "icewm", "-c", ICEWMPREFS, "-t", "yast2", NULL);
	    execlp(FVWM, "fvwm2", "-f", FVWMRC, NULL);
	    execlp(MWM, "mwm", NULL);
	    execlp(TWM, "twm", NULL);
	    fprintf(stderr, "testX: could not run any windowmanager");
	    return 0;
	    break;
	default:
	    waitpid(wmpid, NULL, WNOHANG | WUNTRACED);
    }
    return 1;
}
