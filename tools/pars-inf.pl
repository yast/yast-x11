#!/usr/bin/perl

use lib '/usr/lib/YaST2/bin';
use WinINF;

# read .inf file from stdin...
# ------------------------------
while(<>) {
 if ($_ !~ /^;/) {
  push(@line,$_);
 }
}

# check format specifications...
# --------------------------------
$check = VerifyFormat(@line);
if ($check == 0) {
 exit (-1);
}

# read the information now...
# ------------------------------
%cdb = ReadManufacturerTable(@line);


# give me a YCP list...
# ----------------------
$size  = 0;
$count = 0;
foreach $v (keys %cdb) {
 foreach $n (keys %{$cdb{$v}}) {
  $size++;
 }
}
print "\[\n";
foreach $v (keys %cdb) {
 foreach $n (keys %{$cdb{$v}}) {
  print "\$\[\n";
  print "vendor:       \"$v\",\n";
  print "model:        \"$n\",\n";
  ($lhf, $hhf) = split( /\s*-\s*/, $cdb{$v}{$n}{Hsync} );

  $hhf = $lhf unless( defined( $hhf ));
  print "min_hsync:       $lhf,\n";
  print "max_hsync:       $hhf,\n";
  ($lvf, $hvf) = split( /\s*-\s*/, $cdb{$v}{$n}{Vsync} );
  $hvf = $lvf unless( defined( $hvf ));

  print "min_vsync:       $lvf,\n";
  print "max_vsync:       $hvf\n";
  print "]\n";

  $count++;
  if ($count < $size) {  
   print ", ";
  }
 }
}
print "\]\n";

