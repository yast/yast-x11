#!/usr/bin/perl
# Copyright (c) 2001 SuSE GmbH Nuernberg, Germany
# Copyright (c) 2002 SuSE Linux AG Nuernberg, Germany
# All rights reserved.
#
# Author: Marcus Schaefer <sax@suse.de>, 2001
# y2xr40.pl: YaST2 X11 workflow
# ----------
# This script asks the XFree86 loader for DDC / Panel data
# and create a YCP map with resolutions available for the
# specified colordepth according to the installed video memory
#
# Requires:
# ----------
# requires sax2 and saxtools to be installed !
# CVS ID:
# --------
# $Id$
#
use lib   '/usr/X11R6/lib/sax/modules';
use strict;

use Env;
use Getopt::Long;
use PLogData;
use Secure;

# Globals...
# -----------
our %var;
our $Option;

#---[ init ]------#
sub init {
#-----------------------------------------
# get options and init main variables
#
 my $Colors;
 my $Server;

 # get options...
 # ----------------
 my $result = GetOptions(
  "colors|c=s"        => \$Colors,             
  "server|s=s"        => \$Server,
  "option|o=s"        => \$Option,
  "help|h"            => \&usage,
  "<>"                => \&usage
 );
 if ( $result != 1 ) {
  usage();
 }
 # root check...
 # ---------------
 my $user = qx(whoami);
 if ($user !~ /root/i) {
  print "y2xr: only root can do this\n";
  exit(1);
 }
 # option check...
 # ----------------
 if (! defined $Colors) {
  print "y2xr: no color list specified... abort\n";
  usage();
 }
 if (! defined $Server) {
  print "y2xr: no server module given... abort\n";
  usage();
 } 
 # init variables...
 # ------------------
 $var{ISaX}   = "/usr/X11R6/lib/sax/tools/isax";
 $var{X}      = "/usr/X11R6/bin/XFree86";
 $var{Colors} = $Colors;
 $var{Server} = $Server;
}

#---[ CreateConfig ]----------#
sub CreateLog {
#----------------------------------------------
# create configuration file to start the
# loader with
#
 my $display = ":99";
 my $dir     = Secure->CreateSecureDir("xr");
 my $config  = "/tmp/$dir/config";
 my $busid   = qx(sysp -c);
 $busid      =~ /([0-9]+:[0-9]+:[0-9]+).*/;
 $busid      = $1;
 
 open(FD,">/tmp/$dir/isaxcfg") || 
  die "could not create file: /tmp/$dir/isaxcfg";

 print FD "Keyboard {\n";
 print FD " 0 XkbLayout        =    us\n";
 print FD " 0 Identifier       =    Keyboard[0]\n";
 print FD " 0 Driver           =    keyboard\n";
 print FD "}\n";
 print FD "Mouse {\n";
 print FD " 0 Identifier       =    Mouse[1]\n";
 print FD " 0 Driver           =    mouse\n";
 print FD " 0 Device           =    /dev/mouse\n";
 print FD "}\n";
 print FD "Card {\n";
 print FD " 0 Identifier       =    Device[0]\n";
 print FD " 0 Driver           =    $var{Server}\n";
 # /.../
 # if --option [...] is specified we have to include
 # this options now. Otherwhise only option noaccel 
 # is set
 # -------
 if (defined $Option) {
 print FD " 0 Option           =    $Option\n";
 } else {
 print FD " 0 Option           =    noaccel\n";
 }
 if (
  ($var{Server} eq "vmware") || 
  ($var{Server} eq "glint" ) ||
  ($var{Server} eq "r128"  )
 ) {
  print FD " 0 BusID            =    $busid\n";
 }
 print FD "}\n";
 print FD "Desktop {\n";
 print FD " 0 Device           =    Device[0]\n";
 print FD " 0 Identifier       =    Screen[0]\n";
 print FD " 0 VertRefresh      =    50-72\n";
 print FD " 0 HorizSync        =    30-42\n";
 print FD " 0 CalcModelines    =    no\n";
 print FD " 0 Modes:8          =    640x480\n";
 print FD " 0 Modes:15         =    640x480\n";
 print FD " 0 Modes:16         =    640x480\n";
 print FD " 0 Modes:24         =    640x480\n";
 print FD " 0 Modes:32         =    640x480\n";

 # for rage128 based cards we need the color depth, otherwhise
 # the memory manager got problems...
 # -----------------------------------
 if ($var{Server} eq "r128") {
  print FD " 0 ColorDepth      =    8\n";
 }

 print FD " 0 Monitor          =    Monitor[0]\n";
 print FD "}\n";
 print FD "Path {\n";
 print FD " 0 RgbPath          =    /usr/X11R6/lib/X11/rgb\n";
 print FD " 0 ModulePath       =    /usr/X11R6/lib/modules\n";
 print FD " 0 FontPath         =    /usr/X11R6/lib/X11/fonts/misc\n";
 print FD " 0 ModuleLoad       =    dbe,type1,speedo,extmod\n";
 print FD " 0 ServerFlags      =    AllowMouseOpenFail\n";
 print FD "}\n";
 print FD "Layout {\n";
 print FD " 0 Screen:Screen[0] =    <none> <none> <none> <none>\n";
 print FD " 0 InputDevice      =    Mouse[1]\n";
 print FD " 0 Keyboard         =    Keyboard[0]\n";
 print FD " 0 Identifier       =    Layout[all]\n";
 print FD " 0 Xinerama         =    off\n";
 print FD "}\n";
 close(FD);

 qx($var{ISaX} -f /tmp/$dir/isaxcfg -c $config);
 qx($var{X} -probeonly -xf86config $config $display 2>/dev/null);
 Secure->RemoveDir();

 # return name of log file...
 # ---------------------------
 return("/var/log/XFree86.99.log");
}

#---[ usage ]-----#
sub usage {
#---------------------------------------------
# usage message...
#
 print "\n";
 print "Linux YaST2 (X11 module y2xr v. 4.3)\n";
 print "(C) Copyright 2001 - SuSE Linux AG\n";
 print "\n"; 
 print "usage: y2xr40 [ options ]\n";
 print "options:\n";
 print "[ -h | --help ]\n";
 print "  show this message and exit\n";
 print "[ -c | --colors ]\n";
 print "  list of supported color bits\n";
 print "  specify a comma separated list\n";
 print "[ -s | --server ]\n";
 print "  basename of X-Server module\n";
 exit(1);
}


#---[ CheckResolution ]-----#
sub CheckResolution {
#-------------------------------------------
# this function checks the resolution if
# it is valid according to the installed
# memory
#
 my $res = $_[0];
 my $ram = $_[1];
 my $col = $_[2];

 # is valid if ram is not specified...
 # ------------------------------------
 if ($ram !~ /[0-9]+/) {
  return(1);
 }

 my @c = split(/x/,$res);
 my $need = $c[0] * $c[1] * ( $col / 8);
 my $need = $need / 1024;

 if ($ram >= $need) {
  return(1);
 }
 return(0);
}

#---[ main ]------------#
sub main {
#----------------------------------------------
# just do it now :-)
#
 my $log;   # log file after CreateLog function
 my $ptr;   # Log file pointer after parsing
 my $ram;   # Video Ram
 my @res;   # DDC / Panel Resolution list
 my @col;   # list of color depths
 my $val;   # number of detected resolutions
 my $r;     # resolution string
 my @list;  # YCP element
 my $panel; # indicate the panel type CRT or LCD/TFT
 my $vmd;   # vmware default color depth

 # predefined resolution list...
 # ------------------------------
 my @predef = (
  "640x480",
  "800x600",
  "1024x768",
  "1152x864",
  "1280x960",
  "1280x1024",
  "1400x1050",
  "1600x1000",
  "1600x1024",
  "1600x1200"
 );

 $log = CreateLog();
 if (! -f $log) {
  die "y2xr40: could not open file: $log -> $!";
 }
 $ptr   = ParseLog($log);
 $ram   = GetVideoRam($ptr);
 $panel = CheckDisplayType($ptr);
 $vmd   = GetVMwareColorDepth($ptr);

 # check if the connected display a NoteBook
 # panel or a ordinary CRT ray tube
 # ---------------------------------
 if ($panel ne "CRT") {
  @res   = GetResolution($ptr);
 } else {
  # we can use the DDC data from the X-Server here
  # but YaST2 requires not to do so.
  # --------------------------------
  $res[0] = "none";
 }
 
 # check if we are in a vmware session. If yes
 # there is only one colordepth available
 # ---------------------------------------
 if ($vmd ne "0") {
  $var{Colors} = $vmd;
  $ram=32768;
 }

 # big hack for fireGL cards: Simulate enough 
 # video memory to enable all resolutions. If the
 # firegl driver is able to output the video ram
 # we can remove this hack...
 # ----------------------------
 if ($var{Server} =~ /firegl.*|fglr200/) {
  $ram=32768;
 }

 $val = @res;
 @col = split(/,/,$var{Colors});
 print "\$\[\n";
 foreach (@col) {
  
  if ($_ eq $col[0]) {
   print "$_:\[";
  } else {
   print ",$_:\[";
  }
  @list = ();

  if ($res[0] ne "none") {
   # we got DDC information and use them now...
   # --------------------------------------------
   # print STDERR "using DDC info from server...\n";
   foreach $r (@res) {
    if (CheckResolution($r,$ram,$_)) {
     my @xy = split(/x/,$r);
     push(@list,"\$\[\"height\":$xy[1], \"width\":$xy[0]\]");
    }
   }
  } else {
   # sorry we got not DDC info and use the predefined
   # resolution list...
   # -------------------
   # print STDERR "using predefined resolution list...\n";
   foreach $r (@predef) {
    if (CheckResolution($r,$ram,$_)) {
     my @xy = split(/x/,$r);
     push(@list,"\$\[\"height\":$xy[1], \"width\":$xy[0]\]");
    }
   }
  }

  my $ycp = join(",",@list);
  print "$ycp\]\n";
 }
 print "\]\n";
}

init();
main();
