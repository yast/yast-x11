#!/usr/bin/perl
# Copyright (c) 2001 SuSE GmbH Nuernberg, Germany.  
# Copyright (c) 2002 SuSE Linux AG Nuernberg, Germany.  
# All rights reserved.
#
# Author: Marcus Schaefer <sax@suse.de>, 2001
# y2xr.pl: YaST2 X11 workflow ( 3.3.6 )
# --------
# this script is used to generate a generic configuration 
# using isax which is used to query some information about the
# X-Server 
#
# Requires:
# ----------
# requires sax to be installed !
# CVS ID:
# --------
# $Id$
#

use Env;
use Getopt::Long;

my $TmpDir;
my %var;

#---[ usage ]-----#
sub usage {
#---------------------------------------------
# usage message...
#
 print "\n";
 print "Linux YaST2 (X11 module y2xr v. 4.3)\n";
 print "(C) Copyright 2001 - SuSE Linux AG\n";
 print "\n"; 
 print "usage: y2xr [ options ]\n";
 print "options:\n";
 print "[ -h | --help ]\n";
 print "  show this message and exit\n";
 print "[ -c | --colors ]\n";
 print "  list of supported color bits\n";
 print "  specify a comma separated list\n";
 print "[ -s | --server ]\n";
 print "  basename of X-Server\n";
 exit(1);
}

#---[ CreateSecureDir ]-----#
sub CreateSecureDir {
#----------------------------------------------
# this function create a secure tmp directory
# and return the name of the directory
#
 my $prefix = $_[0];
 
 if ($prefix eq "") {
  $prefix = "sysp";
 }
 
 $TmpDir = "$prefix-$$";
 qx(rm -rf /tmp/$TmpDir);
 $result = mkdir("/tmp/$TmpDir",0700);
 if ($result == 0) {
  print "secure: could not create tmp dir... abort\n";
  exit(1);
 }
 return($TmpDir);
}      

#---[ RemoveDir ]-----#
sub RemoveDir {
#----------------------------------------------
# this function removes the secure dir and
# all its contents
#
 qx(rm -rf /tmp/$TmpDir);
}     

#---[ main ]-----#
sub main {
#-----------------------------------------------
# just do it now :-)
#
 my $dir     = CreateSecureDir("xr");
 my $config  = "/tmp/$dir/isaxcfg";
 my $display = ":99";

 my $data;   # the whole data from ParseXerr 
 my $ram;    # the  videoram part of data

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

 open(FD,">/tmp/$dir/isaxcfg") ||
  die "could not create file: /tmp/$dir/isaxcfg";

 print FD "SERVER      = \"$var{Server}\"\n";
 print FD "LANGUAGE    = \"de\"\n";
 print FD "COLORDEPTH  = \"8\"\n";
 print FD "CONFIG      = \"/tmp/$dir/isaxcfg\"\n";
 print FD "KBDPROT     = \"Standard\"\n";
 print FD "XKBRULES    = \"xfree86\"\n";
 print FD "SYMBOLS     = \"en_US(pc104)+de(nodeadkeys)\"\n";
 print FD "GEOMETRY    = \"pc(pc104)\"\n";
 print FD "CARDOPTS    = \"noaccel\"\n";
 
 close(FD);
 qx($var{ISaX} -f $config);
 $data = qx($var{X} -probeonly -xf86config $config $display 2>&1 | $var{PLog});
 RemoveDir();  

 # handle the stuff...
 # --------------------
 my @list = split(/\n/,$data);
 foreach (@list) {
  if ($_ =~ /videoram:([0-9]+).*/) {
   $ram = $1; last;
  }
 }

 my @col = split(/,/,$var{Colors});
 print "\$\[\n";
 foreach (@col) {
 
  if ($_ eq $col[0]) {
   print "$_:\[";
  } else {
   print ",$_:\[";
  }
  @list = ();
  # sorry we got not DDC for XFree86 3.3.x using
  # the predefined resolution list...
  # ----------------------------------
  foreach $r (@predef) {
   if (CheckResolution($r,$ram,$_)) {
    my @xy = split(/x/,$r);
    push(@list,"\$\[\"height\":$xy[1], \"width\":$xy[0]\]");
   }
  }
  my $ycp = join(",",@list);
  print "$ycp\]\n";
 }
 print "\]\n"; 
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

#---[ init ]--------#
sub init {
#--------------------------------------------------
# init some variables and get the options
#
 my $Colors;
 my $Server;
 
 # get options...
 # ----------------
 my $result = GetOptions(
  "colors|c=s"        => \$Colors,
  "server|s=s"        => \$Server,
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
  print "y2xr: no XFree86 server given... abort\n";
  usage();
 }
 # init variables...
 # ------------------
 $var{X}      = "/usr/X11R6/bin/$Server";
 $var{Colors} = $Colors;
 $var{ISaX}   = "/usr/X11R6/bin/isax";
 $var{PLog}   = "/var/X11R6/sax/bin/ParseXerr";
}
 
init();
main();
