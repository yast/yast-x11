This text deals with the peculiarities of the XF86Config agent
--------------------------------------------------------------

Purpose
-------
The purpose of the XF86Config agent is to contrive the production of a valid
XF86Config file. To do so it uses "isax", a part from SaX suitable for
integration with YaST2, to generate an intermediate file for xfine which
in turn writes an incarnation of the XF86Config file.


How it is done
--------------
To generate an XF86config file that reflects the hardware and the users wishes
it is necessary to have the information at hand that has been collected
during the earlier stages of the installation. This information is passed to
the agent from YCP module inst_xf86config.ycp. All data is contained in a
YCP map and evaluated by the agent to write a temporary input file for isax.
isax then reads this data and magically produces another intermediate file
/tmp/isax_config which in turn is used by xfine to produce the final
XF86config file.


XFree86  version 3 and version 4 peculiarities
----------------------------------------------
Things used to be (rather) simple up to SuSE Release 6.4 where only XFree86 3
was used. From Release 7.0 on there is also XFree86 4 to be handled and
unfortunately there are some "tiny" differences to be followed that mainly
result from a redesign of SaX. SaX (and isax and xfine) now come in two different
flavours with different behaviour. For XFree 3 there is a standalone binary isax
referred to as isax1 in this document. For XFree4 SaX has been redesigned and
became SaX2. Here isax is a module of SaX2 referred to as isax2 in this document.
xfine also does exist in two versions referred to as xfine1 and xfine2.

isax differences
----------------
o	Location:	isax1: /usr/X11R6/bin/isax
			isax2: /usr/X11R6/lib/sax/tools/isax

o	The commandline for both versions is different.
	(see SaX documentation and source of Xf86ConfigAgent.cc.)

o	Input file is in both cases /tmp/rc_... (command line -f) but the
	format is different:

	isax1:	The values from the map are all written into the file as
		<KEY>=<VALUE> eg. COLORDEPTH=16

	isax2:	The input file has to be a file similar but not identically to
		an XF86Config file with contents organized in sections. This file
		must contain a lot more information than the one provided for
		isax1. Most of this information is static and beyond the scope
		of information interchange between inst_xf86config.ycp and the
		agent. Therefore Xf86ConfigAgent.cc has a template of such
		a file hardcoded and "pokes" the values from the map into it.

o	The output file is in both cases /tmp/isax_config but both versions of
	isax get informed about the output file in different ways.

	isax1:  The input file has to contain a key "CONFIG" with a respective
		value eg. CONFIG=/tmp/isax_config.

	isax2:	The output file has to be specified on the command line using
		the -c option.

xfine differences
-----------------
Being an issue for inst_xf86config.ycp it is well out of scope here but JFYI
it should be mentioned that xfine behaves different too in both versions.

xfine1:	  The input file /tmp/isax_config is converted directly to the
	  XF86config file which is located in /etc (XFree 3 case).

xfine2:	  The input file /tmp/isax_config is only _ALTERED_ by xfine2 so
	  it has to be copied to it's final location manually. This location is
	  /etc/X11 in this case (XFree 4).

TODO
----
Currently the font paths to be written into XF86config are hardcoded in
Xf86ConfigAgent.cc. This was done as a quick workaround since the SaX2 modules
don't write this information on their own anymore. A durable and flexible
mechanism for providing this kind of information is yet to be defined.
