#!/usr/bin/perl
# Copyright (c) 2000-2001 SuSE GmbH Nuernberg, Germany.  
# Copyright (c) 2002 SuSE Linux AG Nuernberg, Germany.  
# All rights reserved.
#
# Author: Marcus Schaefer <ms@suse.de>, 2000
#
# y2accel.pl YaST2 script to remove the noaccel statement
# within the final config file
#

use Getopt::Long;

#----[ main ]-----#
sub main {
 undef($File); 

 # get options...
 # ---------------
 $result = GetOptions(
   "file|f=s" => \$File,
   "help|h"   => \&usage,
   "<>"       => \&usage
 );
 if ( $result != 1 ) {
  usage();
 }

 # test file...
 # -------------
 if ($File eq "") {
  print "no input file specified\n";
  usage();
 } elsif (! -f $File) {
  print "file $File does not exist\n";
  exit(1);
 }

 open (FD,"$File");
 while ($line=<FD>) {
  if ($line !~ /noaccel/i) {
   push(@list,$line);
  }
 }
 close(FD);
 open (FD,">$File");
 print FD @list;  
 close(FD);
 exit(0);
}

#---[ usage ]----#
sub usage {
 print "usage: y2accel [ options ]\n";
 print "options:\n";
 print "[ -f | --file ]\n";
 print "  file to change\n";
 exit(0);
}


main();
