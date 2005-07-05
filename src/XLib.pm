#/.../
# Copyright (c) 2005 SUSE LINUX Products GmbH.  All rights reserved.
#
# Author: Marcus Schaefer <ms@suse.de>, 2005
#
# XLib.pm YAPI interface module to access libsax
# functions to handle the X11 configuration
#
use lib "/usr/share/YaST2/modules";

package XLib;

use strict;
use YaST::YCP qw(:LOGGING Boolean sformat);;
use YaPI;
use Data::Dumper;
use Time::localtime;
use SaX;

textdomain("x11");

our %TYPEINFO;

use strict;
use Errno qw(ENOENT);

#==========================================
# Globals
#------------------------------------------
my $init = 0;
my %section;
my $config;
my %cdb;

#==========================================
# isInitialized
#------------------------------------------
BEGIN{ $TYPEINFO{isInitialized} = ["function","boolean"]; }
sub isInitialized {
	return $init;
}

#==========================================
# loadApplication
#------------------------------------------
BEGIN{ $TYPEINFO{loadApplication} = ["function","void"]; }
sub loadApplication {
	my $class  = shift;
	my $sinit = new SaX::SaXInit;
	$sinit -> doInit();
	my @importID = (
		$SaX::SAX_CARD,
		$SaX::SAX_DESKTOP,
		$SaX::SAX_POINTERS,
		$SaX::SAX_KEYBOARD,
		$SaX::SAX_LAYOUT,
		$SaX::SAX_PATH,
		$SaX::SAX_EXTENSIONS
	);
	$config = new SaX::SaXConfig;
	foreach my $id (@importID) {
		my $import = new SaX::SaXImport ( $id );
		$import->setSource ( $SaX::SAX_AUTO_PROBE );
		$import->doImport();
		$config->addImport ( $import );
		my $name = $import->getSectionName();
		$section{$name} = $import;
	}
	$init = 1;
}
#==========================================
# writeConfiguration
#------------------------------------------
BEGIN{ $TYPEINFO{writeConfiguration} = ["function","boolean"]; }
sub writeConfiguration {
	my $class = shift;
	$config->setMode ($SaX::SAX_NEW);
	my $status = $config->createConfiguration();
	$config->commitConfiguration();
	return $status;
}
#==========================================
# setResolution
#------------------------------------------
BEGIN{ $TYPEINFO{setResolution} = ["function", "void", "string"]; }
sub setResolution {
	my $class = shift;
	my $resolution = $_[0];
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	my @resList = ();
	my $basePixels  = 0;
	my $basePixelsX = 0;
	my $basePixelsY = 0;
	my %resDict = %{getAvailableResolutions()};
	foreach (keys %resDict) {
		if ($resDict{$_} eq $resolution) {
		if ($_ =~ /(.*)x(.*)/) {
			$basePixelsX = $1;
			$basePixelsY = $2;
			$basePixels = $basePixelsX * $basePixelsY;
			push (@resList,$_);
		}
		}
	}
	if ($basePixels == 0) {
		return;
	}
	foreach (keys %resDict) {
	if ($_ =~ /(.*)x(.*)/) {
		my $x = $1;
		my $y = $2;
		my $pixelSpace = $x * $y;
		if (($pixelSpace < $basePixels) &&
			($x<=$basePixelsX) && ($y<=$basePixelsY)
		) {
			push (@resList,$_);
		}
	}
	}
	my @colors = (8,15,16,24,32);
	foreach my $color ( @colors ) {
		$section{Desktop}->removeEntry ("Modes:$color");
		foreach my $ritem ( sortResolution (@resList)) {
		if ($ritem =~ /(.*)x(.*)/) {
			$mDesktop->addResolution ($color,$1,$2);
		}
		}
	}
}
#==========================================
# setDefaultColorDepth
#------------------------------------------
BEGIN{ $TYPEINFO{setDefaultColorDepth} = ["function", "void","string"]; }
sub setDefaultColorDepth {
	my $class = shift;
	my $color = $_[0];
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	$mDesktop->setColorDepth ( $color );
}
#==========================================
# activate3D
#------------------------------------------
BEGIN{ $TYPEINFO{activate3D} = ["function", "void"]; }
sub activate3D {
	my $class = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	$mDesktop->selectDesktop (0);
	$mDesktop->enable3D();
}
#==========================================
# deactivate3D
#------------------------------------------
BEGIN{ $TYPEINFO{deactivate3D} = ["function", "void"]; }
sub deactivate3D {
	my $class = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	$mDesktop->selectDesktop (0);
	$mDesktop->disable3D();
}
#==========================================
# hasOpenGLFeatures
#------------------------------------------
BEGIN{ $TYPEINFO{hasOpenGLFeatures} = ["function", "boolean"]; }
sub hasOpenGLFeatures {
	my $class = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	$mDesktop->selectDesktop (0);
	if ($mDesktop->is3DEnabled()) {
		return 1;
	}
	return 0;
}
#==========================================
# has3DCapabilities
#------------------------------------------
BEGIN{ $TYPEINFO{has3DCapabilities} = ["function", "boolean"]; }
sub has3DCapabilities {
	my $class = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	my $mCard = new SaX::SaXManipulateCard (
		$section{Card}
	);
	$mDesktop->selectDesktop (0);
	my $has3DCapabilities = $mDesktop->is3DCard();
	my $isMultiheaded = $mCard->getDevices();
	if ((! $has3DCapabilities) || ($isMultiheaded > 1)) {
		return 0;
	}
	return 1;
}
#==========================================
# getCardName
#------------------------------------------
BEGIN{ $TYPEINFO{getCardName} = ["function", "string"]; }
sub getCardName {
	my $class = shift;
	my $mCard = new SaX::SaXManipulateCard (
		$section{Card}
	);
	$mCard->selectCard (0);
	my $vendor = $mCard->getCardVendor();
	my $model  = $mCard->getCardModel();
	my $result = $vendor." ".$model;
	return $result;
}
#==========================================
# getMonitorName
#------------------------------------------
BEGIN{ $TYPEINFO{getMonitorName} = ["function", "string"]; }
sub getMonitorName {
	my $class = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	$mDesktop->selectDesktop (0);
	my $vendor = $mDesktop->getMonitorVendor();
	if ($vendor =~ /Unknonw/i) {
		return "undef";
	}
	my $model  = $mDesktop->getMonitorName();
	my $result = $vendor." ".$model;
	return $result;
}
#==========================================
# getMonitorVendor
#------------------------------------------
BEGIN{ $TYPEINFO{getMonitorVendor} = ["function", "string"]; }
sub getMonitorVendor {
	my $class = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	$mDesktop->selectDesktop (0);
	my $vendor = $mDesktop->getMonitorVendor();
	if ($vendor =~ /Unknonw/i) {
		return "undef";
	}
	return $vendor;
}
#==========================================
# getMonitorModel
#------------------------------------------
BEGIN{ $TYPEINFO{getMonitorModel} = ["function", "string"]; }
sub getMonitorModel {
	my $class = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	$mDesktop->selectDesktop (0);
	my $model  = $mDesktop->getMonitorName();
	if ($model =~ /Unknonw/i) {
		return "undef";
	}
	return $model;
}
#==========================================
# getActiveResolution
#------------------------------------------
BEGIN{ $TYPEINFO{getActiveResolution} = ["function", "string"]; }
sub getActiveResolution {
	my $class   = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	$mDesktop->selectDesktop (0);
	my @list = @{$mDesktop->getResolutions(
		$mDesktop->getColorDepth()
	)};
	my $result = shift (@list);
	return $result;
}
#==========================================
# getActiveResolutionString
#------------------------------------------
BEGIN{ $TYPEINFO{getActiveResolutionString} = ["function", "string"]; }
sub getActiveResolutionString {
	my $resolution = getActiveResolution();
	my @reslist = @{getAvailableResolutionNames()};
	foreach (@reslist) {
	if ($_ =~ /$resolution/) {
		return $_;
	}
	}
	return $resolution;
}
#==========================================
# getActiveColorDepth
#------------------------------------------
BEGIN{ $TYPEINFO{getActiveColorDepth} = ["function", "string"]; }
sub getActiveColorDepth {
	my $class = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	$mDesktop->selectDesktop (0);
	return $mDesktop->getColorDepth();
}
#==========================================
# getHsyncMin
#------------------------------------------
BEGIN{ $TYPEINFO{getHsyncMin} = ["function", "string"]; }
sub getHsyncMin {
	my $class = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	my @hrange = @{$mDesktop->getHsyncRange()};
	return $hrange[0];
}
#==========================================
# getHsyncMax
#------------------------------------------
BEGIN{ $TYPEINFO{getHsyncMax} = ["function", "string"]; }
sub getHsyncMax {
	my $class = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	my @hrange = @{$mDesktop->getHsyncRange()};
	return $hrange[1];
}
#==========================================
# getVsyncMin
#------------------------------------------
BEGIN{ $TYPEINFO{getVsyncMin} = ["function", "string"]; }
sub getVsyncMin {
	my $class = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	my @vrange = @{$mDesktop->getVsyncRange()};
	return $vrange[0];
}
#==========================================
# getVsyncMax
#------------------------------------------
BEGIN{ $TYPEINFO{getVsyncMax} = ["function", "string"]; }
sub getVsyncMax {
	my $class = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	my @vrange = @{$mDesktop->getVsyncRange()};
	return $vrange[1];
}
#==========================================
# setHsyncRange
#------------------------------------------
BEGIN{ $TYPEINFO{setHsyncRange} = ["function", "void","integer","integer"]; }
sub setHsyncRange {
	my $class = shift;
	my $start = shift;
	my $stop  = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	$mDesktop->setHsyncRange ($start,$stop);
}
#==========================================
# setVsyncRange
#------------------------------------------
BEGIN{ $TYPEINFO{setVsyncRange} = ["function", "void","integer","integer"]; }
sub setVsyncRange {
	my $class = shift;
	my $start = shift;
	my $stop  = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	$mDesktop->setVsyncRange ($start,$stop);
}
#==========================================
# getMonitorCDB
#------------------------------------------
BEGIN{ $TYPEINFO{getMonitorCDB} = ["function",["map","string",["list","string"]]]; }
sub getMonitorCDB {
	my $class = shift;
	my $size = keys %cdb;
	if ($size > 0) {
		return \%cdb;
	}
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	$mDesktop->selectDesktop (0);
	my @vendorList = @{$mDesktop->getCDBMonitorVendorList()};
	foreach my $vendor (@vendorList) {
		my $modelList = $mDesktop->getCDBMonitorModelList ($vendor);
		$cdb{$vendor} = $modelList;
	}
	return \%cdb;
}
#==========================================
# setMonitorCDB
#------------------------------------------
BEGIN{ $TYPEINFO{setMonitorCDB} = ["function","void",["list","string"]]; }
sub setMonitorCDB {
	my $class = shift;
	my @list = @{+shift};
	my $group = join (":",@list);
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	$mDesktop->selectDesktop (0);
	$mDesktop->setCDBMonitor ($group);
}
#==========================================
# getAvailableResolutions
#------------------------------------------
BEGIN{ $TYPEINFO{getAvailableResolutions} = ["function",["map","string","string"]]; }
sub getAvailableResolutions {
	my $class = shift;
	my $file = "/usr/share/sax/api/data/MonitorResolution";
	if (! open (FD,$file)) {
		return;
	}
	my %resList;
	while (<FD>) {
	if ($_ =~ /(.*)=(.*)/) {
		$resList{$1} = $2;
	}
	}
	close (FD);
	return \%resList;
}
#==========================================
# getAvailableResolutionNames
#------------------------------------------
BEGIN{ $TYPEINFO{getAvailableResolutionNames} = ["function",["list","string"]]; }
sub getAvailableResolutionNames {
	my $class = shift;
	my $file = "/usr/share/sax/api/data/MonitorResolution";
	my @result = ();
	if (! open (FD,$file)) {
		return \@result;
	}
	while (<FD>) {
	if ($_ =~ /(.*)=(.*)/) {
		push (@result,$2);
	}
	}
	close (FD);
	return \@result;
}
#==========================================
# sortResolution
#------------------------------------------
sub sortResolution {
	my @list = @_;   # list of resolutions
	my %index;       # index hash
	foreach my $i (@list) {
		my @res   = split(/x/,$i);
		my $pixel = $res[0] * $res[1];
		$index{$pixel} = $i;
	}
	@list = ();
	sub numerisch { $b <=> $a; }
	foreach my $i (sort numerisch keys %index) {
		push(@list,$index{$i});
	}
	return @list;
}

#==========================================
# test code
#------------------------------------------
if (0) {
	loadApplication();
	my $resolution = getActiveResolution ();
	my $colordepth = getActiveColorDepth ();
	my $cardname   = getCardName();
	my $monitorname= getMonitorName();
	my $status3D   = hasOpenGLFeatures();
	my $statusCard = has3DCapabilities();
	my $resstring  = getActiveResolutionString();
	print "$resolution: $colordepth: $cardname: $monitorname\n";
	print "3D enabled: $status3D\n";
	print "3D capable: $statusCard\n";
	print "$resstring\n";
}
1;
