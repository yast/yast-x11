/**
 * Copyright (c) 2021 SUSE LLC
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
 **/

/**
 * This tool reads or sets the active window. It can be used for restoring back
 * the currently active window later.
 *
 * Usage:
 *
 *   active_window [WID]
 *
 * Without any parameter it prints the active window ID, with a parameter
 * it activates the window with that ID [WID].
 *
 *
 * It uses the Extended Window Manager Hints (EWMH) to read and set the active window.
 * The IceWM used in the installer supports this.
 *
 * Resources, links:
 *
 * - man pages for XOpenDisplay, XGetWindowProperty and other Xlib calls
 * - https://specifications.freedesktop.org/wm-spec/wm-spec-latest.html
 * - https://github.com/leahneukirchen/tools/blob/490cf61021a5d73202f260229d6157d4d11341f3/wmtitle.c
 * - https://stackoverflow.com/questions/30192347/how-to-restore-a-window-with-xlib
 * - https://stackoverflow.com/questions/31800880/xlib-difference-between-net-active-window-and-xgetinputfocus
 * - https://github.com/jordansissel/xdotool/blob/dd45db42f16954f22b445a2c2c928fec202314c4/xdo.c#L686
 **/

#include <stdio.h>
#include <stdlib.h>

#include <X11/Xlib.h>

int main(int argc, char **argv) {
    // connect to the X server, NULL = use the $DISPLAY env
    Display *display = XOpenDisplay(NULL);
    if (!display) {
	      return(1);
    }

    Window root = XDefaultRootWindow(display);
    // this is the WM property for the currently active window
    Atom property = XInternAtom(display, "_NET_ACTIVE_WINDOW", False);

    // an argument has been passed, activate the requested window
    if (argc > 1)
    {
        // convert the argument to a window
        Window window = (Window)strtoul(argv[1], NULL, 0);

        // build an X event, see the links at the top
        XClientMessageEvent ev;
        ev.type = ClientMessage;
        ev.window = window;
        ev.message_type = property;
        ev.format = 32;
        ev.data.l[0] = 1;
        ev.data.l[1] = CurrentTime;
        ev.data.l[2] = 0;
        ev.data.l[3] = 0;
        ev.data.l[4] = 0;

        // send it to the X server
        XSendEvent(display, root, False, SubstructureRedirectMask | SubstructureNotifyMask, (XEvent*) &ev);
        // wait until it is processed
        XSync(display, False);
    }
    // read mode, print the currently active window
    else
    {
        // build the parameters for reading the WM property
        long offset = 0;
        long length = ~0;
        Bool delete = False;
        Atom req_type = AnyPropertyType;
        Atom actual_type_return;

        int actual_format_return;
        unsigned long nitems_return;
        unsigned long bytes_after_return;
        unsigned char *prop_return;

        // read the property, see the links at the top
        if (XGetWindowProperty(display, root, property, offset, length, delete,
            req_type, &actual_type_return, &actual_format_return,
            &nitems_return, &bytes_after_return, &prop_return) != Success)
        {
            XCloseDisplay(display);
            return(1);
        }

        // print the window ID
        printf("%lu\n", *(unsigned long *) prop_return);
        XFree(prop_return);
    }

    XCloseDisplay(display);
    return 0;
}
