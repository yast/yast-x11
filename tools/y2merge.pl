#!/usr/bin/perl
# Copyright (c) 2000-2001 SuSE GmbH Nuernberg, Germany.
# Copyright (c) 2002 SuSE Linux AG Nuernberg, Germany.  
# All rights reserved.
#
# Author: Marcus Schaefer <ms@suse.de>, 2000
# y2merge -r <resolution> -a <apidata> -c <X11-config-name>
#

use Getopt::Long;

#---[ main ]----#
sub main {
#---------------------------------------------
# main function to find out the lower modes 
# and calculate modelines for it
#
 my $result;
 my @lower;
 
 my @line;
 my $refresh = 70;
 my $x;
 my $y;

 # global modeline tool
 # ---------------------
 $xmode   = "/usr/X11R6/lib/sax/tools/xmode";

 # global resolver list
 # ---------------------
 @resolve = (
  "640x480",            # 640x480   standard mode Nr 1
  "800x600",            # 800x600   standard mode Nr 2
  "1024x768",           # 1024x768  standard mode Nr 3
  "1152x864",           # 1152x864  standard mode Nr 4
  "1280x960",           # 1280x960  standard mode Nr 5 
  "1280x1024",          # 1280x1024 standard mode Nr 6
  "1600x1200"           # 1600x1200 standard mode Nr 7
 );

 undef($Resolution);
 undef($ApiFile);
 undef($Config);

 $result = GetOptions(
   "resolution|r=s"    => \$Resolution,
   "apifile|a=s"       => \$ApiFile,
   "config|c=s"        => \$Config,
   "help|h"            => \&usage,
   "<>"                => \&usage
 );
 if ( $result != 1 ) {
  usage();
 }

 # prove parameters...
 # --------------------
 if ((TestCritical($Resolution,$ApiFile,$Config)) == 1) {
  exit(1);
 }


 # ok provements are ok lets start...
 # -----------------------------------
 # first get the resolutions 
 # missing
 $Resolution =~ s/ +//g;
 foreach (@resolve) {
  if ($_ ne $Resolution) {
   push(@lower,$_);
   push(@modes,"\"$_\"");
  } else {
   last;
  } 
 }
 $size = @lower;
 if ($size == 0) {
  print "no changes...\n";
  exit(0);
 }

 # create mode list enhancement...
 # ---------------------------------
 $enhance = join(" ",@modes);

 # lookup refresh rate within 
 # apifile
 # --
 # 4.0    --> VertRefresh
 # 3.3.x  --> RESOLUTION
 $Config =~ s/ +//g;
 if ((-f $Config) && (-f $ApiFile)) {
  if ($Config eq "/etc/XF86Config") {
   # 3.3.x interface...
   # --------------------
   $sync = qx(cat $ApiFile | grep RESOLUTION);
   $sync =~ s/RESOLUTION//;
   $sync =~ s/\"//g;
   $sync =~ s/=//g;
   $sync = lc($sync);
   @list = split(/:/,$sync);
   foreach (@list) {
    if ($_ =~ /$Resolution/) {
     $sync = $_; last;
    }
   }
   if ($sync =~ /$Resolution\@(.*)/) {
    $sync = $1;
    @list = ();
    @list = split(/,/,$sync);
    sub numeric { $b <=> $a; }
    @list = sort numeric @list;
    if ($list[0] ne "") {
     $refresh = $list[0];
    }
   }

  } else {
   # 4.0 interface...
   # -----------------
   $sync = qx(cat $ApiFile | grep VertRefresh);
   $sync =~ s/^.*VertRefresh//;
   $sync =~ s/=//g;
   $sync =~ s/ +//g;
   if ($sync =~ /(.*)-(.*)/) {
    $sync = ($1 + $2) / 2;
    $refresh = int($sync);
    if ($refresh < 50) {
     $refresh = 70;
    }
   } 
  }
 }


 # calculate modelines using
 # xmode from SaX2
 @line = ();
 foreach (@lower) {
  $_ =~ /(.*)x(.*)/;
  $x = $1;
  $y = $2;

  @mode = qx($xmode -x $x -y $y -r $refresh);
  $mode[2] =~ s/\n//;
  push(@line,$mode[2]);
 }

 # open config file and add
 # modelines to the top
 @file = ();
 $size = @line;
 $done = 0;
 if ($size > 0) {
  open(FD,"$Config") || die "y2merge: could not open $Config";
  while($l = <FD>) {
   chomp($l);

   # Modelines
   # ----------
   if (($l =~ /^.*Modeline.*/) && ($done == 0)) {
    foreach (@line) {
     push(@file,"  $_");
    }
    $done = 1;
   }

   # Modes
   # ------
   if ($l =~ /^ +Modes.*\".*\".*/) {
    $l = "$l $enhance"; 
   }

   push(@file,$l);
  }
  close(FD);

  # write changes...
  # -----------------
  open(FD,">$Config") || die "y2merge: could not open $Config for writing";
  foreach (@file) {
   print FD "$_\n";
  }
  close(FD);
 }
}



#---[ TestCritical ]----# 
sub TestCritical {
#----------------------------------------------
# this function test all possible failures
#
 my ($res,$api,$config) = @_;
 my $found;

 # is xmode there
 # ---------------
 if (! -f $xmode) {
  print "y2merge: $xmode does not exist... SaX2 installed ? \n";
  return(1);
 }

 # is resolution given...
 # ------------------------
 if (! defined $res) {
  print "y2merge: no resolution given\n";
  return(1);
 }

 # is config file given...
 # -------------------------
 if (! defined $config) {
  print "y2merge: no config file given\n";
  return(1);
 }

 # test wheteher config file exist
 # -------------------------------
 if (! -f $config) {
  print "y2merge: file $config does not exist\n";
  return(1);
 } else {
  $config =~ s/ +//g;
  if (($config ne "/etc/XF86Config") && ($config ne "/etc/X11/XF86Config")) {
   print "y2merge: $config not an allowed file type\n";
   return(1);
  }
 }

 # test format of resolution string
 # ----------------------------------
 if ($res !~ /([0-9]+x[0-9]+)(.*)/) {
  print "y2merge: $res format error\n";
  return(1);
 } else {
  $Resolution = $1;
  $res        = $1;
 }

 # is resolution part of resolve list
 # ------------------------------------
 $res   =~ s/ +//g;
 $found = 0;
 foreach (@resolve) {
  if ($_ eq $res) {
   $found = 1; last;
  } 
 }
 if ($found == 0) {
  print "y2merge: $res is not part of resolver list\n";
  return(1);
 }
 return(0);
}


#---[ usage ]----#
sub usage {
#----------------------------------------------
# how to use this program
#
 print "usage: y2merge [ options ]\n";
 print "options:\n";
 print "[ -r | --resoluton ]\n";
 print "  set maximum resolution as XxY string\n";
 print "[ -a | --apifile ]\n";
 print "  set the configuration parameter file\n";
 print "  containing XFree86 3.3.x or 4.0 file format\n";
 print "[ -c | --config ]\n";
 print "  set full file name of configuration\n";
 print "  Note: This file will be changed\n";
 exit(0);
}


main();
