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


isax information
----------------
o	Location:	isax: /usr/sbin/isax

o	Input file is /tmp/rc_... (command line -f) with the
	following format:

	isax:	The input file has to be a file similar but not identically to
		an XF86Config file with contents organized in sections. This file
		must contain a lot more information than the one provided for
		isax1. Most of this information is static and beyond the scope
		of information interchange between inst_xf86config.ycp and the
		agent. Therefore Xf86ConfigAgent.cc has a template of such
		a file hardcoded and "pokes" the values from the map into it.

o	The output file is /tmp/isax_config 
	isax: The output file has to be specified on the command line using
		the -c option.
