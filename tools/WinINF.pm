#/.../
# Copyright (c) 2000 SuSE GmbH Nuernberg, Germany.  All rights reserved.
#
# Author: Marcus Schaefer <sax@suse.de>, 2000
# WinINF.pm  read windows inf file ( especially monitor inf files )
#
# CVS ID:
# --------
# Status: Up-to-date
#

$NOJOIN=0;

#---[ VerifyFormat ]------#
sub VerifyFormat {
#--------------------------------------------
# this function verify if there is correct
# inf format or not 
# -- 
# 0 ->  wrong format
# X ->  correct format ( X = class line )
#
 my @file = @_;

 my $regex     = "^Class\\s*=\\s*Monitor\\s*\$";
 my $startline = 0;

 my $i=$startline;
 while($i <= $#file) {
  if($file[$i] =~ /$regex/i) {
   return $i+1;
  }
  $i++;
 }
 return 0;
}


#---[ ReadManufacturerTable ]------#
sub ReadManufacturerTable {
#--------------------------------------------
# this function read the manufacturer table
# located in the inf file
#
 my @file = @_;

 my %vendor;
 my $i;
 my $manustring;
 my $manunext;
 my $manusec;
 my $manukey;
 my %monis;
 my $monstring;
 my $installsec;
 my $found;
 my $monikey;
 my $firs;
 my $secname;
 my $searchname;
 my $j;
 my %cdb;
 my $v;
 my $n;

 # Look up Strings section...
 # ----------------------------
 $i=FindExpression(@file,"\\[Strings\\]",0);
 if ($i == 0) {
  # Couldn't find [Strings] section
  return(-1)
 }

 # Copy string table to hash %strings
 # ----------------------------------- 
 while( $i <= $#file && (! ($file[$i] =~ /^\[/ )) ) {
  if($file[$i] =~ /=/) {
   $file[$i] =~ /([^= ]*)\s*=(\s*")?([^"]*)("|\s*\x0d*$)/;
   # KEY = DESCRIPTION...
   # ---------------------
   $strings{$1}=$3;
  }
  $i++;
 }

 # Find manufacturer table
 # ------------------------
 $i=FindExpression(@file,"\\[Manufacturer\\]",0);
 if ($i == 0) {
  # Couldn't find [Manufacturer] section
  return(-1);
 }
 # Find manufacturer name table
 # -----------------------------
 if ($file[$i] =~ /%(.*)%=(.*)/) {
  $manuname = $1;
  $manunext = $2;
  $i=FindExpression(@file,"\\[$manuname\\]",0);
  if ($i == 0) {
   $i=FindExpression(@file,"\\[$manunext\\]",0);
   if ($i == 0) {
    # Couldn't find [...] section
    return(-1);
   }
  } 
 }

 # copy manufacturer table to hash %vendor
 # ----------------------------------------
 while ( $i <= $#file && (! ($file[$i] =~ /^\[/ )) ) {
  if($file[$i] =~ /=/) {
   SWITCH: for ($file[$i]) {   
    # first regex...
    # ----------------
    /^%([^%]*)%=([^=;\x0d\x0a]*)/  && do {
     $manustring = $1;
     $manusec    = $2;
     if ($manusec =~ /(.*),(.*)/) {
      $manusec = $1;
      $manusec =~ s/^ +//g;
      $manusec =~ s/ +$//g;
     }
     last SWITCH;
    };
    # second regex...
    # ------------------
    /^\"(.*)\".=.(.*),.*/          && do {
     $manustring = $1;
     $manusec    = $2;
     last SWITCH;
    };
   }
   while( $manusec =~ /\s+$/ ) {
    chop $manusec;
   }
   # KEY = INSTALLSECTION...
   # -------------------------
   $vendor{$manustring}=$manusec;
  }
  $i++;
 }

 foreach $manukey (keys(%vendor)) {
  %monis=();
  $i = FindExpression(@file,"\\[$vendor{$manukey}\\]",0);
  if ($i == 0) {
   # Couldn't find section for $vendor{$manukey}
   return(-1);
  }

  while( $i <= $#file && (! ($file[$i] =~ /^\[/ )) ) {
   if($file[$i] =~ /^[^;]*=/) {
    # print "found = at $i, line is $file[$i]";
    # -----------------------------------------
    if ($file[$i] =~ /%([^%]*)%[ \t]*=[ \t]*([^;,\t\x0d]*)(,|\s*;|\x0d*$)/) {
     $monstring  = $1;
     $installsec = $2;
     while( $installsec =~ /\s+$/ ) {
      chop $installsec;
     }
    } else { 
     $monstring  = $manukey;
     $installsec = $vendor{$manukey};
    }
    $installsec=verbatim($installsec);
    if (! ($j=FindExpression(@file,"\\[$installsec\\]",0)) ) {
     # Couldn't find installsec $installsec
     # --------------------------------------
    } else {
     $found=0;
     while ( $j <= $#file && (! ($file[$j] =~ /^\[/ )) ) {
      if($file[$j] =~ /^AddReg=([^=\s,]*)/) {
       # print "found AddReg $1\n";
       # ---------------------------
       $found=1;
       # KEY = ADD-REG-SECTION...
       # ---------------------------
       $monis{$monstring}=$1;
      }
      $j++;
     }
     if (!$found) {
      # Couldn't find AddReg entry in $installsec
      # ------------------------------------------
     }
    }
   }
   $i++;
  }
 
  $first = 1;
  foreach $monikey (keys(%monis)) {
   # find AddReg sections
   # ---------------------
   $secname=verbatim($monis{$monikey});

   $i=FindExpression(@file,"\\[$secname\\]",0);
   if ( $i == 0 ) {
    # Couldn't find AddReg section $monis{$monikey} for $monikey
    # attempting brute-force search...
    # ---------------------------------
    $secname    =~ /^([^\\\.]*)/;
    $searchname = $1;

    $j     = 0;
    $found = 0;
    while(! $found) {
     $j=FindExpression(@file,$searchname,$j);
     if($j == 0) {
      $found=-1;
     } else {
      $k=$j;
      while ( $k <= $#file && (! ($file[$k] =~ /^\[/ )) ) {
       if ( $file[$k] =~ /^HKR/) {
        $found=1;
       }
       $k++;
      }
     }
    }
    if($found==1) {
     # success...
     # -----------
     $i=$j;
    } else {
     # failed...
     # -----------
    }
   }

   @hf=();
   @vf=();

   while ( $i <= $#file && (! ($file[$i] =~ /^\[/ )) ) {
    if ( $file[$i] =~ /^HKR/ ) {
     if ( $file[$i] =~ /^HKR,".*",.*,.*,"([0-9\.-]*)\s*,\s*([0-9\.-]*)\s*(,\s*[+-],[+-])?"\x0d*$/ ) {
      AddValue(\@hf,$1);
      AddValue(\@vf,$2);
     }
    }
    $i++;
   }
   if ( $#hf > -1 && $#vf > -1 ) {
    # save data to cdb hash
    # -----------------------
    ($lhf, $hhf) = split( /\s*-\s*/, $hf[0] );
    $hhf = $lhf unless( defined( $hhf ));

    ($lvf, $hvf) = split( /\s*-\s*/, $vf[0] );
    $hvf = $lvf unless( defined( $hvf ));

    $v = $strings{$manukey};
    $n = $strings{$monikey};
    if (($v eq "") && ($n eq "")) {
     @list = split(/ /,$monikey);
     $v = $list[0];
     $n = $monikey;
     $n =~ s/$v//;
     $n =~ s/^ +//g;
     $n =~ s/ +$//g;
     $n =~ s/\t+//g;
     $n =~ s/ +/-/g;
    } else {
     $v =~ s/^ +//g;
     $v =~ s/ +$//g;
     $v =~ s/\t+//g;
     @list = split(/ +/,$v);
     
     $v = shift(@list);
     $n = join("-",@list);
     $n =~ s/,+//g;
    }
    $lhf = int($lhf); $hhf = int($hhf);
    $lvf = int($lvf); $hvf = int($hvf);

    if ($n ne "") {
     $cdb{$v}{$n}{Hsync} = "$lhf-$hhf";
     $cdb{$v}{$n}{Vsync} = "$lvf-$hvf";
    }

    $first = 0;
   } else {
    # invalid HF/VF ranges for $manukey/$monikey
    # -------------------------------------------
   }
  }
 }
 return(%cdb);
}

#--[ FindExpression ]---#
sub FindExpression {
#-----------------------------------------
# helper function to find line which 
# contains a single regular expression
#
 my @file      = @_;
 my $startline = pop(@file);
 my $regex     = pop(@file);

 my $i=$startline;
 while($i <= $#file) {
  if($file[$i] =~ /$regex/i) {
   return $i+1;
  }
  $i++;
 }
 return 0;
}


#--[ verbatim ]----#
sub verbatim {
#----------------------------------------
# helper function to prepare strings
#
 my $string=$_[0];

 $string =~ s/[^A-Za-z0-9-_]/\\$&/g;
 return $string;
}


#--[ AddValue ]----#
sub AddValue {
#----------------------------------------
# merges a value (2nd param) into a 
# list (1st param)
#
 my $lref = $_[0];
 my $nuv  = $_[1];

 my @nulist=();
 my $succ;
 my $res;
 my $v;
 my $joinflag=0;

 if($NOJOIN) {
  @$lref = (@$lref,$_[1]);
  return;
 }

 foreach $v (@$lref) {
  if($joinflag) {
   @nulist=(@nulist,$v);
  } else {
   if(isrange($v)) {
    if(isrange($nuv)) {
     ($succ,$res)=joinranges($nuv,$v);
     if ($succ == 1) {
      @nulist=(@nulist,$res);
      $joinflag=1;
     } else {
      @nulist=(@nulist,$v);
     }
    } else {
     ($succ,$res)=joinvalrange($nuv,$v);
     if($succ == 1) {
      $joinflag=1;
     }
     @nulist=(@nulist,$v);
    }
   } else {
    if(isrange($nuv)) {
     ($succ,$res)=joinvalrange($v,$nuv);
     if ($succ == 1) {
      $joinflag=1;
      @nulist=(@nulist,$nuv);
     } else {
      @nulist=(@nulist,$v);
     }
    } else {
     if($v == $nuv) {
      $joinflag=1;
     }
     @nulist=(@nulist,$v);
    }
   }
  }
 }
 if ($joinflag == 0) {
  @nulist=(@nulist,$nuv);
 } 
 @$lref=@nulist;
}

#--[ joinvalrange ]---#
sub joinvalrange {
#------------------------------------------
# merges a value into a range if possible
# returns a list containing a number 
# (true if join succeeded) and the resulting
# range
#
 my $val=$_[0];

 (my $rlow,my $rhigh)=extractvals($_[1]);
 if($val >= $rlow && $val <= $rhigh) {
  return (1,$_[1]);
 }

 my $result=$_[1] . "," . $_[0];
 return (0,$result);
}


#---[ extractvals ]-----#
sub extractvals {
#-------------------------------------------------
# returns a list containing the values of a range
#
 $_[0] =~ /([0-9\.]+)-([0-9\.]+)/;
 return ($1,$2);
}


#--[ isrange ]---#
sub isrange {
#-------------------------------------------------
# true if parameter is in range syntax ("x-y"), 
# otherwise false
#
 if($_[0] =~ /-/) {
  return 1;
 }
 return 0;
}


#--[ joinranges ]-----#
sub joinranges {
#----------------------------
# merges two ranges
#
 (my $low1,my $high1)=extractvals($_[0]);
 (my $low2,my $high2)=extractvals($_[1]);

 if (($high1 < $low2) || ($high2 < $low1)) {
  my $result=$_[0] . "," . $_[1];
  return (0,$result);
 }

 if ($low2 < $low1) {
  my $result= $low2 . "-" . $high1;
  return (1,$result);
 }

 if ($low1 < $low2) {
  my $result= $low1 . "-" . $high2;
  return (1,$result);
 }

 if ($low1 <= $low2 && $high2 <= $high1) {
  my $result= $_[0];
  return (1,$result);
 }

 if ($low2 <= $low1 && $high1 <= $high2) {
  my $result= $_[1];
  return (1,$result);
 }

 # ups, this should not happen
 # -----------------------------
 return(-1);
}

1;
