#!/usr/bin/perl
# Copyright (c) 2002 SuSE GmbH Nuernberg, Germany.  All rights reserved.
#
# Author: Marcus Schaefer <sax@suse.de>, 2002
# xapi script: add or modify vga value for GrUB kernel line
# --
#
# CVS ID:
# --------
# Status: Up-to-date
#
use strict;
use Env;

$ENV{LC_ALL} = "POSIX";

#=================================
# Globals...
#---------------------------------
my $kernel = $ARGV[0];
my $vga    = $ARGV[1];

#---[ update ]-----#
sub update {
#------------------------------------------------
# check if the current kernel line contains
# the vga value and update it with the new vga
# value
# 
	if ($kernel =~ /.*vga=([0-9]+|normal|ext)/) {
		$kernel =~ s/$1/$vga/;
	} else {
		$kernel = $kernel." vga=".$vga;
	}
	return (
		$kernel
	);
}

my $newLine = update();
print "$newLine\n";
