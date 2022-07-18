/**
 * Copyright (c) 2022 SUSE LLC
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
 * This tool reads and sets the "Xft.dpi" X resource property.
 *
 * Alternatively we could use the "xrdb" tool but unfortunately it depends on the
 * C pre-processor (~22MB!) and increases size of the installed system a lot.
 *
 * Usage:
 *
 *   xftdpi [DPI]
 *
 * Without any parameter it prints the current setting (and also the size of the
 * default screen), with a parameter it sets that DPI resolution.
 *
 *
 * This tool uses a simplified implementation because it is supposed to be
 * called only by the YaST starting script, it:
 *
 * - does not validate the argument, make sure it is an integer number with
 *   a reasonable value
 *   (YaST sets a value in a predefined range, ignoring too high or too low values)
 *
 * - does not merge the X resources, it simply appends the option at the end
 *   regardless it is already present or not, calling it several times results
 *   in multiple setting present
 *   (it should be called just once by the YaST starting script, there are
 *    no resources defined in the inst-sys and the last setting wins anyway,
 *    see "man XrmGetDatabase")
 *
 * - does not check the maximum size of the X request, we set just a single short
 *   value (too long string would need to be split into several calls)
 *
 * Resources, links:
 *
 * - man pages for XOpenDisplay, XrmGetDatabase, XResourceManagerString, ...
 *   and other Xlib calls
 * - xrdb sources (https://gitlab.freedesktop.org/xorg/app/xrdb/-/blob/master/xrdb.c)
 **/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <X11/Xlib.h>
#include <X11/Xresource.h>
#include <X11/Xatom.h>

// compute DPI resolution from pixels and milimeters
int resolution(int width_px, int width_mm);
int resolution(int width_px, int width_mm)
{
  // avoid division by zero
  if (width_mm == 0)
    return 0;
  else
    return (double)(width_px) / ((double)(width_mm) / 25.4);
}

int main(int argc, char **argv)
{
  // connect to the X server, NULL = use the $DISPLAY env
  Display *display = XOpenDisplay(NULL);
  if (!display)
  {
    return 1;
  }

  // an argument has been passed, set the "Xft.dpi" resource
  if (argc > 1)
  {
    // append "Xfti.dpi: " with the command line argument to the X resources
    const char *xft = "Xft.dpi: ";
    // allocate buffer for the new string, 2 = newline separator + NULL terminator
    char *new_data = malloc(strlen(xft) + strlen(argv[1]) + 2);
    char *ptr = new_data;

    // the existing resources might miss the trailing new line, add it just to be sure
    // (if it already is there then it does not harm, an empty line is allowed)
    ptr[0] = '\n';
    ptr = ptr + 1;

    // append "Xft.dpi: "
    strcpy(ptr, xft);
    ptr = ptr + strlen(xft);

    // append the command line argument
    strcpy(ptr, argv[1]);

    // append the the data to the X server resource property
    XChangeProperty(display, XDefaultRootWindow(display), XA_RESOURCE_MANAGER,
                    // 8 = the data is 8 bits per item (8, 16 and 32 are possible)
                    XA_STRING, 8, PropModeAppend, (unsigned char *)new_data, strlen(new_data));

    free(new_data);
  }
  else
  // no command line argument, just dump the current configuration
  {
    Screen *screen = ScreenOfDisplay(display, DefaultScreen(display));
    printf("Width: %d px, %d mm, %d dpi\n", screen->width, screen->mwidth,
           resolution(screen->width, screen->mwidth));
    printf("Height: %d px, %d mm, %d dpi\n", screen->height, screen->mheight,
           resolution(screen->height, screen->mheight));

    // initialize database
    XrmInitialize();
    XGetDefault(display, "", "");

    XrmDatabase xrdb = XrmGetDatabase(display);
    char *type = NULL;
    XrmValue value;

    // search for the "Xft.dpi" value
    Bool found = XrmGetResource(xrdb, "Xft.dpi", "Xft.Dpi", &type, &value);

    printf("Xft.dpi: ");
    if (found == True && value.addr != NULL)
      printf("%s dpi\n", value.addr);
    else
      printf("not defined\n");
  }

  XCloseDisplay(display);
  return 0;
}
