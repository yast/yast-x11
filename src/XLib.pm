#/.../
# Copyright (c) 2005 SUSE LINUX Products GmbH.  All rights reserved.
#
# Author: Marcus Schaefer <ms@suse.de>, 2005
#
# XLib.pm YAPI interface module to access libsax
# functions to handle the X11 configuration
#
package XLib;

#use lib '/usr/share/YaST2/modules';

use strict;
use YaST::YCP qw(:LOGGING Boolean sformat);;
use YaPI;
use Data::Dumper;
use Time::localtime;
use SaX;
use FBSet;
use Env;

textdomain("x11");

our %TYPEINFO;

use strict;
use Errno qw(ENOENT);

#==========================================
# Globals
#------------------------------------------
my %profileDriverOptions = ();
my $init = 0;
my $fbdev= 0;
my %section;
my $config;
my %cdb;

#==========================================
# GetFbColor
#------------------------------------------
sub GetFbColor {
	my $data = FBSet::FbGetData();
	my $cols = $data->swig_depth_get();
	return $cols;
}

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
	$ENV{HW_UPDATE} = 1;
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
	if (isExternalVGANoteBook()) {
		activateExternalVGA();
	}
	$fbdev= isFbdevBased();
	$init = 1;
}
#==========================================
# getKernelFrameBufferMode
#------------------------------------------
BEGIN{ $TYPEINFO{getKernelFrameBufferMode} = ["function", "integer"]; }
sub getKernelFrameBufferMode {
	my $class = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	my $mode = $mDesktop -> getFBKernelMode (
		getActiveResolution(),getActiveColorDepth()
	);
	return $mode;
}
#==========================================
# setKernelFrameBufferMode
#------------------------------------------
BEGIN{ $TYPEINFO{setKernelFrameBufferMode} = ["function","boolean","integer"]; }
sub setKernelFrameBufferMode {
	my $class = shift;
	my $mode  = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	if (! $mDesktop -> setFBKernelMode ( $mode )) {
		return 0;
	}
	return 1;
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
# testConfiguration
#------------------------------------------
BEGIN{ $TYPEINFO{testConfiguration} = ["function","boolean"]; }
sub testConfiguration {
	my $ok = 1;
	$config->setMode ($SaX::SAX_NEW);
	my $status = $config->testConfiguration();
	if ($status == -1) {
		$ok = 0;
	}
	if ($status == 0) {
		$ok = writeConfiguration();
	}
	return $ok;
}
#==========================================
# isExternalVGANoteBook
#------------------------------------------
BEGIN{ $TYPEINFO{isExternalVGANoteBook} = ["function","boolean"]; }
sub isExternalVGANoteBook {
	my $ok = 0;
	my $saxCard = new SaX::SaXManipulateCard (
		$section{Card}
	);
	my $saxDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	if ($saxCard->isNoteBook()) {
		my $profile = $saxDesktop->getDualHeadProfile();
		if (defined $profile) {
			if ($profile ne "") {
				$ok = 1;
			}
		}
	}
	return $ok;
}
#==========================================
# isNoteBookHardware
#------------------------------------------
BEGIN{ $TYPEINFO{isNoteBookHardware} = ["function","boolean"]; }
sub isNoteBookHardware {
	my $saxCard = new SaX::SaXManipulateCard (
		$section{Card}
	);
	if ($saxCard->isNoteBook()) {
		return 1;
	}
	return 0;
}
#==========================================
# isExternalVGAactive
#------------------------------------------
BEGIN{ $TYPEINFO{isExternalVGAactive} = ["function","boolean"]; }
sub isExternalVGAactive {
	my $ok = 0;
	my $saxCard = new SaX::SaXManipulateCard ( $section{Card} );
	my %options = %{$saxCard->getOptions()};
	if (defined $options{SaXDualHead}) {
		$ok = 1;
	}
	return $ok;
}
#==========================================
# activateExternalVGA
#------------------------------------------
BEGIN{ $TYPEINFO{activateExternalVGA} = ["function", "void"]; }
sub activateExternalVGA {
	my $class = shift;
	my $saxCard = new SaX::SaXManipulateCard ( $section{Card} );
	if ((keys %profileDriverOptions) == 0) {
		%profileDriverOptions = readProfile();
	}
	foreach my $key (sort keys %profileDriverOptions) {
		$saxCard->removeCardOption ( $key );
	}
	foreach my $key (sort keys %profileDriverOptions) {
		$saxCard->addCardOption ( $key,$profileDriverOptions{$key} );
	}
}
#==========================================
# deactivateExternalVGA
#------------------------------------------
BEGIN{ $TYPEINFO{deactivateExternalVGA} = ["function", "void"]; }
sub deactivateExternalVGA {
	my $class = shift;
	my $saxCard = new SaX::SaXManipulateCard ( $section{Card} );
	if ((keys %profileDriverOptions) == 0) {
		%profileDriverOptions = readProfile();
	}
	foreach my $key (sort keys %profileDriverOptions) {
		$saxCard->removeCardOption ( $key );
	}
}
#==========================================
# setDisplaySize
#------------------------------------------
BEGIN{ $TYPEINFO{setDisplaySize} = ["function","void",["list","string"]]; }
sub setDisplaySize {
	my $class = shift;
	my @list  = @{+shift};
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	my $traversal = $list[0];
	my @ratios = split (/\//,$list[1]);
	my $aspect = $ratios[0];
	my $ratio  = $ratios[1];
	$mDesktop->setDisplayRatioAndTraversal (
		$traversal,$aspect,$ratio
	);
}
#==========================================
# getDisplaySize
#------------------------------------------
BEGIN{ $TYPEINFO{getDisplaySize} = ["function", ["list","string"]]; }
sub getDisplaySize {
	my $class = shift;
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	my @result = ("undef");
	my $traversal = $mDesktop->getDisplayTraversal();
	my @ratio  = @{$mDesktop->getDisplayRatio()};
	if (defined $traversal) {
		$traversal = sprintf ("%.1f",$traversal);
		if ($traversal < 12.2) {
			$traversal = 10.0;
		} elsif (($traversal >= 12.2) && ($traversal < 13.3)) {
			$traversal = 12.2;
		} elsif (($traversal >= 13.3) && ($traversal < 14.1)) {
			$traversal = 13.3;
		} elsif (($traversal >= 14.1) && ($traversal < 14.5)) {
			$traversal = 14.1;
		} elsif (($traversal >= 14.5) && ($traversal < 15.4)) {
			$traversal = 15;
		} elsif (($traversal >= 15.4) && ($traversal < 16.5)) {
			$traversal = 15.4;
		} elsif (($traversal >= 16.5) && ($traversal < 18.0)) {
			$traversal = 17;
		} elsif (($traversal >= 18.0) && ($traversal < 18.3)) {
			$traversal = 18;
		} elsif (($traversal >= 18.3) && ($traversal < 18.5)) {
			$traversal = 18.1;
		} elsif (($traversal >= 18.5) && ($traversal < 19.5)) {
			$traversal = 19;
		} elsif (($traversal >= 19.5) && ($traversal < 20.5)) {
			$traversal = 20;
		} elsif (($traversal >= 20.5) && ($traversal < 21.3)) {
			$traversal = 21.1;
		} elsif (($traversal >= 21.3) && ($traversal < 21.5)) {
			$traversal = 21.3;
		} elsif (($traversal >= 21.5) && ($traversal < 22.2)) {
			$traversal = 22.2;
		} elsif (($traversal >= 22.2) && ($traversal < 23.5)) {
			$traversal = 23;
		} elsif (($traversal >= 23.5) && ($traversal < 24.5)) {
			$traversal = 24;
		} elsif (($traversal >= 24.5) && ($traversal < 30.5)) {
			$traversal = 30;
		} elsif (($traversal >= 30.5) && ($traversal < 31.8)) {
			$traversal = 31.5;
		} elsif (($traversal >= 31.8) && ($traversal < 32.5)) {
			$traversal = 32;
		} elsif (($traversal >= 32.5) && ($traversal < 40.5)) {
			$traversal = 40;
		} elsif ($traversal >= 40.5) {
			$traversal = 46;
		}
		@result = ($traversal,@ratio);
	}
	return \@result;
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
	setupMetaModes ($resList[0]);
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
# isFbdevBased
#------------------------------------------
BEGIN{ $TYPEINFO{isFbdevBased} = ["function", "boolean"]; }
sub isFbdevBased {
	my $class = shift;
	my $mCard = new SaX::SaXManipulateCard (
		$section{Card}
	);
	if ($mCard -> getCardDriver() eq "fbdev") {
		return 1;
	}
	return 0;
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
	if ($vendor =~ /Unknown/i) {
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
	my $color = $mDesktop->getColorDepth();
	if (! $color) {
		$color = GetFbColor();
	}
	my @list = @{$mDesktop->getResolutions($color)};
	if (! @list) {
		push (@list,"800x600");
	}
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
	my $color = $mDesktop->getColorDepth();
	if (! $color) {
		$color = GetFbColor();
	}
	return $color;
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
# hasValidColorResolutionSetup
#------------------------------------------
BEGIN{ $TYPEINFO{hasValidColorResolutionSetup} = ["function", "boolean","string","string"]; }
sub hasValidColorResolutionSetup {
	my $class = shift;
	my $color = shift;
	my $res   = shift;
	if (! $fbdev) {
		return 1;
	}
	my $mDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	if ($color =~ /\[ (.*) Bit \]/i) {
		$color = $1;
	}
	if ($res =~ /(.*x.*) \(/) {
		$res = $1;
	}
	my $mode = $mDesktop -> getFBKernelMode ($res,$color);
	if ($mode > 0) {
		return 1;
	}
	return 0;
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
	my $file  = "/usr/share/sax/api/data/MonitorResolution";
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
	if ($fbdev) {
		my @fbresult = ();
		my $mDesktop = new SaX::SaXManipulateDesktop (
			$section{Desktop},$section{Card},$section{Path}
		);
		$mDesktop->selectDesktop (0);
		my @fblist = @{$mDesktop->getResolutionsFromFrameBuffer()};
		foreach my $resstring (@result) {
			foreach my $res (@fblist) {
				if ($resstring =~ /$res/) {
					push (@fbresult,$resstring); last;
				}
			}
		}
		return \@fbresult;
	}
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
# readProfile
#------------------------------------------
sub readProfile {
	my $saxDesktop = new SaX::SaXManipulateDesktop (
		$section{Desktop},$section{Card},$section{Path}
	);
	my %result  = ();
	my $profile = $saxDesktop->getDualHeadProfile();
	if ($profile ne "") {
		my $pProfile = new SaX::SaXImportProfile ( $profile );
		$pProfile -> doImport();
		my $mImport = $pProfile -> getImport ( $SaX::SAX_CARD );
		if (defined $mImport) {
			my $saxProfileCard = new SaX::SaXManipulateCard ( $mImport );
			%result = %{$saxProfileCard->getOptions()};
		}
	}
	return %result;
}
#==========================================
# setupMetaModes
#------------------------------------------
sub setupMetaModes {
	my $resolution = $_[0];
	my $mCard = new SaX::SaXManipulateCard (
		$section{Card}
	);
	my %options = %{$mCard->getOptions()};
	if (defined $options{MetaModes}) {
		my @metaList = split (/,/,$options{MetaModes});
		$metaList[0] = $resolution;
		my $value = join (",",@metaList);
		$mCard->removeCardOption ("MetaModes");
		$mCard->addCardOption ("MetaModes",$value);
	}
}   

#==========================================
# return current Keyboard layout
#------------------------------------------
BEGIN{ $TYPEINFO{getXkbLayout} = ["function", "string"]; }
sub getXkbLayout {
	my $class   = shift;
	my $mKeyboard = new SaX::SaXManipulateKeyboard (
		$section{Keyboard}
	);
	my @list = @{$mKeyboard->getXKBLayout()};
	my $result = shift (@list);
	return $result;
}

#==========================================
# set new Keyboard layout
#------------------------------------------
BEGIN{ $TYPEINFO{setXkbLayout} = ["function", "void", "string"]; }
sub setXkbLayout {
	my ($class, $layout)   = @_;
	my $mKeyboard = new SaX::SaXManipulateKeyboard (
		$section{Keyboard}
	);
	$mKeyboard->setXKBLayout ($layout);
}

#==========================================
# set new Keyboard model
#------------------------------------------
BEGIN{ $TYPEINFO{setXkbModel} = ["function", "void", "string"]; }
sub setXkbModel {
	my ($class, $model)   = @_;
	my $mKeyboard = new SaX::SaXManipulateKeyboard (
		$section{Keyboard}
	);
	$mKeyboard->setXKBModel ($model);
}

#==========================================
# set new layout variant for given layout
#------------------------------------------
BEGIN{ $TYPEINFO{setXkbVariant} = ["function", "void", "string", "string"]; }
sub setXkbVariant {
	my ($class, $layout, $variant)   = @_;
	my $mKeyboard = new SaX::SaXManipulateKeyboard (
		$section{Keyboard}
	);
	$mKeyboard->setXKBVariant ($layout, $variant);
}

#==========================================
# set mapping for the special keys
#------------------------------------------
BEGIN{ $TYPEINFO{setXkbMappings} = ["function","void", ["map","string","string"]];}
sub setXkbMappings {
	# ...
	# set mapping for the special keys (Left/Right-Alt Scroll-Lock
	# and Right Ctrl) parameter is map with pairs of type
	# { SaX::XKB_LEFT_ALT => SaX::XKB_MAP_META }
	# ---
	my ($class, $mappings)   = @_;
	my $mKeyboard = new SaX::SaXManipulateKeyboard (
		$section{Keyboard}
	);
	return if (ref ($mappings) ne "HASH" || ! %{$mappings});
	while (my ($type, $mapping) = each %{$mappings}) {
		next if !$mapping;
		$mKeyboard->setXKBMapping ($type, $mapping);
	}
}

#==========================================
# set new list of Xkb options
#------------------------------------------
BEGIN{ $TYPEINFO{setXkbOptions} = ["function","void", ["list","string"]];}
sub setXkbOptions {
	# ...
	# resets the current list of options and adds the new ones
	# parameter is list of options
	# ---
	my ($class, $options)   = @_;
	return if (!defined $options || ref ($options) ne "ARRAY");
	my $mKeyboard = new SaX::SaXManipulateKeyboard (
		$section{Keyboard}
	);
	my @opt = @{$options};
	$mKeyboard->setXKBOption (shift @opt);
	foreach my $option (@opt) {
	    $mKeyboard->addXKBOption ($option);
	}
}

#==========================================
# test code
#------------------------------------------
if (0) {
	loadApplication();

	my $c = hasValidColorResolutionSetup (undef,"24","1024x768");
	printf ("___$c\n");
	exit (0);
	
	my @a = @{getAvailableResolutionNames()};
	print "@a\n";
	exit (0);

	my @list = @{getDisplaySize()};
	print "@list\n";
	@list = (12.2,"5/4");
	setDisplaySize ("class",\@list);
	@list = @{getDisplaySize()};
	print "@list\n";
	exit;

	print "HW_UPDATE=$ENV{HW_UPDATE}\n";
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
