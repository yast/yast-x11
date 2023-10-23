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
#include <signal.h>
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
void RunWindowManager(void);
void SigChildHandler(int sig_num);


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
    signal(SIGCHLD, SigChildHandler);
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
	fprintf(stderr, "\ntestX: unknown color or bad color format: %s\n", name);
	exit(1);
    }

    return c;
}


void RunWindowManager(void)
{
    int wm_pid = fork();

    switch ( wm_pid )
    {
	case -1:
            // fork() failed
	    fprintf(stderr, "\ntestX: FATAL: fork() failed\n");
            exit(2);

	case 0:
            // Child process: Start a window manager.

	    setenv("ICEWM_PRIVCFG", "/etc/icewm/yast2", 1);
	    execlp(ICEWM, "icewm", "-c", ICEWMPREFS, "-t", "yast2", NULL);

	    execlp(FVWM, "fvwm2", "-f", FVWMRC, NULL);
	    execlp(MWM, "mwm", NULL);
	    execlp(TWM, "twm", NULL);

            // exec..() only returns if the process could not be started.
	    fprintf(stderr, "\ntestX: Could not run any windowmanager\n");

            // Exit, don't return. We don't want to return to main() in the
            // child process to do more X11 calls with the parent process's X
            // connection.
            exit(1);

	default:
            // Parent process

            // fprintf(stderr, "\ntestX: Started child process %d to start a window manager\n", wm_pid);
            break;
    }
}


void SigChildHandler(int sig_num)
{
    int exit_status = -1;
    int pid = waitpid(0, &exit_status, WNOHANG | WUNTRACED);

    if (pid != 0 && exit_status > 0)
    {
        fprintf(stderr, "\ntestX: Child process %d exited with %d\n", pid, exit_status);
    }
}
