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
#use Data::Dumper;
#use Time::localtime;
#use SaX;
#use FBSet;
#use Env;

textdomain("x11");

our %TYPEINFO;

use strict;
use Errno qw(ENOENT);

#
# keeping compatible API but just return dummy data
#


#==========================================
# isInitialized
#------------------------------------------
BEGIN{ $TYPEINFO{isInitialized} = ["function","boolean"]; }
sub isInitialized {
	return 1;
}

#==========================================
# loadApplication
#------------------------------------------
BEGIN{ $TYPEINFO{loadApplication} = ["function","void"]; }
sub loadApplication {

# LOADING OF SaX disabled
return;

}
#==========================================
# getKernelFrameBufferMode
#------------------------------------------
BEGIN{ $TYPEINFO{getKernelFrameBufferMode} = ["function", "integer"]; }
sub getKernelFrameBufferMode {

return 0;

}
#==========================================
# setKernelFrameBufferMode
#------------------------------------------
BEGIN{ $TYPEINFO{setKernelFrameBufferMode} = ["function","boolean","integer"]; }
sub setKernelFrameBufferMode {

return 1;

}
#==========================================
# writeConfiguration
#------------------------------------------
BEGIN{ $TYPEINFO{writeConfiguration} = ["function","boolean"]; }
sub writeConfiguration {

return 1;

}
#==========================================
# setPreferredMode
# set the selected resolution and color depth the user selected (bnc#402581)
#------------------------------------------
BEGIN{ $TYPEINFO{setPreferredMode} = ["function", "boolean", "string", "string"]; }
sub setPreferredMode {

return 1;

}
#==========================================
# testConfiguration
#------------------------------------------
BEGIN{ $TYPEINFO{testConfiguration} = ["function","boolean"]; }
sub testConfiguration {

return 1;

}
#==========================================
# isExternalVGANoteBook
#------------------------------------------
BEGIN{ $TYPEINFO{isExternalVGANoteBook} = ["function","boolean"]; }
sub isExternalVGANoteBook {

return 1;

}
#==========================================
# isNoteBookHardware
#------------------------------------------
BEGIN{ $TYPEINFO{isNoteBookHardware} = ["function","boolean"]; }
sub isNoteBookHardware {

return 1;

}
#==========================================
# isExternalVGAactive
#------------------------------------------
BEGIN{ $TYPEINFO{isExternalVGAactive} = ["function","boolean"]; }
sub isExternalVGAactive {

return 1;

}
#==========================================
# activateExternalVGA
#------------------------------------------
BEGIN{ $TYPEINFO{activateExternalVGA} = ["function", "void"]; }
sub activateExternalVGA {

return;

}
#==========================================
# deactivateExternalVGA
#------------------------------------------
BEGIN{ $TYPEINFO{deactivateExternalVGA} = ["function", "void"]; }
sub deactivateExternalVGA {

return;

}
#==========================================
# setDisplaySize
#------------------------------------------
BEGIN{ $TYPEINFO{setDisplaySize} = ["function","void",["list","string"]]; }
sub setDisplaySize {

return;

}
#==========================================
# getDisplaySize
#------------------------------------------
BEGIN{ $TYPEINFO{getDisplaySize} = ["function", ["list","string"]]; }
sub getDisplaySize {

my @res = ();
return \@res;

}
#==========================================
# setResolution
#------------------------------------------
BEGIN{ $TYPEINFO{setResolution} = ["function", "void", "string"]; }
sub setResolution {

return;

}
#==========================================
# setDefaultColorDepth
#------------------------------------------
BEGIN{ $TYPEINFO{setDefaultColorDepth} = ["function", "void","string"]; }
sub setDefaultColorDepth {

return;

}
#==========================================
# activate3D
#------------------------------------------
BEGIN{ $TYPEINFO{activate3D} = ["function", "void"]; }
sub activate3D {

return;

}
#==========================================
# deactivate3D
#------------------------------------------
BEGIN{ $TYPEINFO{deactivate3D} = ["function", "void"]; }
sub deactivate3D {

return;

}
#==========================================
# hasOpenGLFeatures
#------------------------------------------
BEGIN{ $TYPEINFO{hasOpenGLFeatures} = ["function", "boolean"]; }
sub hasOpenGLFeatures {

return 0;

}
#==========================================
# has3DCapabilities
#------------------------------------------
BEGIN{ $TYPEINFO{has3DCapabilities} = ["function", "boolean"]; }
sub has3DCapabilities {

return 0;

}
#==========================================
# isFbdevBased
#------------------------------------------
BEGIN{ $TYPEINFO{isFbdevBased} = ["function", "boolean"]; }
sub isFbdevBased {

return 0;

}
#==========================================
# getCardName
#------------------------------------------
BEGIN{ $TYPEINFO{getCardName} = ["function", "string"]; }
sub getCardName {

return "SAX AND YAST2-X11 ARE DISABLED";

}
#==========================================
# getMonitorName
#------------------------------------------
BEGIN{ $TYPEINFO{getMonitorName} = ["function", "string"]; }
sub getMonitorName {

return "SAX AND YAST2-X11 ARE DISABLED";

}
#==========================================
# getMonitorVendor
#------------------------------------------
BEGIN{ $TYPEINFO{getMonitorVendor} = ["function", "string"]; }
sub getMonitorVendor {

return "SAX AND YAST2-X11 ARE DISABLED";

}
#==========================================
# getMonitorModel
#------------------------------------------
BEGIN{ $TYPEINFO{getMonitorModel} = ["function", "string"]; }
sub getMonitorModel {

return "SAX AND YAST2-X11 ARE DISABLED";

}
#==========================================
# getActiveResolution
#------------------------------------------
BEGIN{ $TYPEINFO{getActiveResolution} = ["function", "string"]; }
sub getActiveResolution {

return "SAX AND YAST2-X11 ARE DISABLED";

}
#==========================================
# getActiveResolutionString
#------------------------------------------
BEGIN{ $TYPEINFO{getActiveResolutionString} = ["function", "string"]; }
sub getActiveResolutionString {

return "SAX AND YAST2-X11 ARE DISABLED";

}
#==========================================
# getActiveColorDepth
#------------------------------------------
BEGIN{ $TYPEINFO{getActiveColorDepth} = ["function", "string"]; }
sub getActiveColorDepth {

return "SAX AND YAST2-X11 ARE DISABLED";

}
#==========================================
# getHsyncMin
#------------------------------------------
BEGIN{ $TYPEINFO{getHsyncMin} = ["function", "string"]; }
sub getHsyncMin {

return "SAX AND YAST2-X11 ARE DISABLED";

}
#==========================================
# getHsyncMax
#------------------------------------------
BEGIN{ $TYPEINFO{getHsyncMax} = ["function", "string"]; }
sub getHsyncMax {

return "SAX AND YAST2-X11 ARE DISABLED";

}
#==========================================
# getVsyncMin
#------------------------------------------
BEGIN{ $TYPEINFO{getVsyncMin} = ["function", "string"]; }
sub getVsyncMin {

return "SAX AND YAST2-X11 ARE DISABLED";

}
#==========================================
# getVsyncMax
#------------------------------------------
BEGIN{ $TYPEINFO{getVsyncMax} = ["function", "string"]; }
sub getVsyncMax {

return "SAX AND YAST2-X11 ARE DISABLED";

}
#==========================================
# setHsyncRange
#------------------------------------------
BEGIN{ $TYPEINFO{setHsyncRange} = ["function", "void","integer","integer"]; }
sub setHsyncRange {

return;

}
#==========================================
# setVsyncRange
#------------------------------------------
BEGIN{ $TYPEINFO{setVsyncRange} = ["function", "void","integer","integer"]; }
sub setVsyncRange {

return;

}
#==========================================
# getMonitorCDB
#------------------------------------------
BEGIN{ $TYPEINFO{getMonitorCDB} = ["function",["map","string",["list","string"]]]; }
sub getMonitorCDB {

my %res = ();
return \%res;

}
#==========================================
# setMonitorCDB
#------------------------------------------
BEGIN{ $TYPEINFO{setMonitorCDB} = ["function","void",["list","string"]]; }
sub setMonitorCDB {

return; 

}
#==========================================
# hasValidColorResolutionSetup
#------------------------------------------
BEGIN{ $TYPEINFO{hasValidColorResolutionSetup} = ["function", "boolean","string","string"]; }
sub hasValidColorResolutionSetup {

return 1;

}
#==========================================
# getAvailableResolutions
#------------------------------------------
BEGIN{ $TYPEINFO{getAvailableResolutions} = ["function",["map","string","string"]]; }
sub getAvailableResolutions {

my %res = ();
return \%res;

}
#==========================================
# getAvailableResolutionNames
#------------------------------------------
BEGIN{ $TYPEINFO{getAvailableResolutionNames} = ["function",["list","string"]]; }
sub getAvailableResolutionNames {

my @res;
return \@res;

}

#==========================================
# return current Keyboard layout
#------------------------------------------
BEGIN{ $TYPEINFO{getXkbLayout} = ["function", "string"]; }
sub getXkbLayout {

return "SAX AND YAST2-X11 ARE DISABLED";

}

#==========================================
# set new Keyboard layout
#------------------------------------------
BEGIN{ $TYPEINFO{setXkbLayout} = ["function", "void", "string"]; }
sub setXkbLayout {

return;

}

#==========================================
# set new Keyboard model
#------------------------------------------
BEGIN{ $TYPEINFO{setXkbModel} = ["function", "void", "string"]; }
sub setXkbModel {

return;

}

#==========================================
# set new layout variant for given layout
#------------------------------------------
BEGIN{ $TYPEINFO{setXkbVariant} = ["function", "void", "string", "string"]; }
sub setXkbVariant {

return;

}

#==========================================
# set mapping for the special keys
#------------------------------------------
BEGIN{ $TYPEINFO{setXkbMappings} = ["function","void", ["map","string","string"]];}
sub setXkbMappings {

return;

}

#==========================================
# set new list of Xkb options
#------------------------------------------
BEGIN{ $TYPEINFO{setXkbOptions} = ["function","void", ["list","string"]];}
sub setXkbOptions {

return;

}

#==========================================
# getTabletCDB
#------------------------------------------
BEGIN{ $TYPEINFO{getTabletCDB} = ["function",["map","string",["list","string"]]]; }
sub getTabletCDB {

my %res = ();
return \%res;

}
#==========================================
# getTabletVendor
#------------------------------------------
BEGIN{ $TYPEINFO{getTabletVendor} = ["function", "string"]; }
sub getTabletVendor {

return "SAX AND YAST2-X11 ARE DISABLED";

}
#==========================================
# getTabletModel
#------------------------------------------
BEGIN{ $TYPEINFO{getTabletModel} = ["function", "string"]; }
sub getTabletModel {

return "SAX AND YAST2-X11 ARE DISABLED";

}
#==========================================
# getTabletID
#------------------------------------------
BEGIN{ $TYPEINFO{getTabletID} = ["function", "integer"]; }
sub getTabletID {

return 0;

}
#==========================================
# setTablet
#------------------------------------------
BEGIN{ $TYPEINFO{setTablet} = ["function","void",["list","string"]]; }
sub setTablet {

return;

}

1;
