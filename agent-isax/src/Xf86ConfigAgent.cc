/*
 * XF86ConfigAgent.cc
 *
 * An agent for reading and writing the XF86Config file via isax.
 *
 * Authors:    Thomas Roelz <tom@suse.de>
 * Maintainer: Thomas Roelz (tom@suse.de)
 *
 * This is a new version for Rel.8.1 where SaX is used to write the XF86Config on the whole.
 * Consequently there are some new Requirements.
 * - Do not support Xfree 3 any more. (SaX can't do it). Don't distinguish XFree3 from XFree4.
 * - Do not write rc.sax sections on the whole (only partly update them).
 *   Therefore the functions writing the different rc.sax sections must not write
 *   static data (as was convenient up to now to *create* the sections).
 * - Remove option to have "manual" font paths (rely on SaX entirely).
 * - Remove any functionality that is not related to mouse, keyboard or language (writing).
 *   All other functionality was good only for *creating* the XF86Config file
 *   which is now done by SaX.
 *
 * Now this agent is no longer capable of *creating* a fullsize XF68Config file. Instead
 * of this it can now do a true update of some sections, i.e. pass only that information
 * to isax that has changed in some way (no static section data anymore).
 *
 * $Id$
 */

#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <regex.h>
#include <string>

#include <YCP.h>
#include <ycp/y2log.h>
#include <ycp/Parser.h>

#include "Xf86ConfigAgent.h"



// ****************************************************************************************
// Global variables.
// ****************************************************************************************


// YaST2-tmpdir
//
static string glob_tmpdir = "";

// Logfile for isax output.
//
static string isax_log_path = "";

// The rc.sax file.
//
static string rc_sax_path = "";

// The isax update command (XFree4)
//
static string xfree4_update_command = "";



// ****************************************************************************************
// Utility functions
// ****************************************************************************************



// Get the YaST2 tmp dir. Assign global variables.
//
void Xf86ConfigAgent::init( void )
{

    if ( glob_tmpdir == "" )	// Not yet assigned
    {
	glob_tmpdir = "/tmp";	// default

	if ( mainscragent )
	{
	    YCPPath path = ".target.tmpdir";
	    YCPValue ret = mainscragent->Read( path );

	    if ( ret->isString() )	// success
	    {
		glob_tmpdir = ret->asString()->value();
		y2milestone( "tmpdir assigned <%s>", glob_tmpdir.c_str () );
	    }
	    else y2error("<.target.tmpdir> System agent returned nil. Using /tmp");
	}
	else y2error("Couldn't get mainscragent to determine tmpdir. Using /tmp");

        // Assign logfile for isax output.
	//
	isax_log_path = glob_tmpdir + "/isax.log";

	// Assign the rc.sax file.
	//
	rc_sax_path = glob_tmpdir + "/rc.sax";

	// Assign the isax update command (XFree4)
	// It is always the same.
	//
	xfree4_update_command = "/usr/X11R6/lib/sax/tools/isax -m -f "	// -m means modify
	    + rc_sax_path +
	    + " -c /etc/X11/XF86Config > "
	    + isax_log_path
	    + " 2>&1";
    }

    // no return value
}



// Run a shell command via bash.
//
int Xf86ConfigAgent::shellCommand( const string command )
{
    string runcmd = "/bin/bash -c 'ulimit -s unlimited\n" + command + "'";

    y2milestone( "Command: <%s>", runcmd.c_str() );

    int exitcode = system( runcmd.c_str() );

    if ( WIFEXITED( exitcode ) ) exitcode = WEXITSTATUS( exitcode );

    y2milestone( "Exitcode: <%d>", exitcode );

    return exitcode;
}



// Read a YCP file and deliver the contents as YCP data.
//
YCPValue Xf86ConfigAgent::readYCPFile( const string ycp_file )
{
    int fd = open( ycp_file.c_str(), O_RDONLY );

    if ( fd < 0 )
    {
	string msg = "Can't open isax output file <" + ycp_file + "> for reading.";
	return YCPError( msg );
    }

    Parser parser( fd, ycp_file.c_str() );
    parser.setBuffered();
    YCode *parsed_code = parser.parse ();
    YCPValue contents = YCPNull ();
    if (parsed_code != NULL)
	contents = parsed_code->evaluate (true);


//    YCPParser parser( fd, ycp_file.c_str() );

//    parser.setBuffered(); 	// Read from file. Buffering is always possible here

//    YCPValue contents = parser.parse();

    close( fd );

    return( ! contents.isNull() ? contents : YCPVoid() );
}



// Merge a source map into a target map.
// This is far from being a generic map merger but highly specialized code
// for the XF86Config agent.
//
YCPValue Xf86ConfigAgent::mergeMaps( YCPMap target, YCPMap source )
{
    // All maps in the source.
    //
    for ( YCPMapIterator s_pos = source->begin(); s_pos != source->end(); ++s_pos)
    {
	YCPValue s_key   = s_pos.key();
	YCPValue s_value = s_pos.value();

	if ( ! s_key->isInteger() ) return YCPError( string("Invalid key '")
						     + s_key->toString()
						     + "' (should be integer)" );

	if ( ! s_value->isMap() ) return YCPError( string("Invalid value '")
						   + s_key->toString()
						   + "' (should be map)" );

	bool found = false;

	// All maps in the target.
	//
	for ( YCPMapIterator t_pos = target->begin(); t_pos != target->end(); ++t_pos)
	{
	    YCPValue t_key   = t_pos.key();
	    YCPValue t_value = t_pos.value();

	    if ( ! t_key->isInteger() ) return YCPError( string("Invalid key '")
							 + t_key->toString()
							 + "' (should be integer)" );

	    if ( ! t_value->isMap() ) return YCPError( string("Invalid value '")
						       + s_key->toString()
						       + "' (should be map)" );

	    if ( s_key->compare( t_key ) == YO_EQUAL )	// source incarnation already exists in target
	    {
		found = true;

		// All the content in the source value has to be added to the target
		// value supposing both are maps.
		//
		for ( YCPMapIterator s2_pos = s_value->asMap()->begin();
		      s2_pos != s_value->asMap()->end();
		      ++s2_pos)
		{
		    // Get all the content of the inner source map.
		    //
		    YCPValue s2_key   = s2_pos.key();
		    YCPValue s2_value = s2_pos.value();

		    // Add it to the inner target map.
		    //
		    YCPMap t_value_map = t_value->asMap();
		    t_value_map->add ( s2_key, s2_value );
		    t_value = t_value_map;
// this was wrong with NI
//		    t_value->asMap()->add( s2_key, s2_value );
		}

		// Add this extended inner target map to the target map using the same key.
		//
		target->add( t_key, t_value );
	    }
	}

	if ( ! found )	// source incarnation not yet in target
	{
	    // Add the new incarnation to the target map with the source content.
	    //
	    target->add( s_key, s_value );
	}
    }

    return target;
}



// Get value and comment for a given key from a YCP map (as strings).
//
ValueComment Xf86ConfigAgent::getValueComment( const YCPMap map, const string key )
{
    ValueComment retval = { "", "" };

    for ( YCPMapIterator i = map->begin(); i != map->end (); i++ )
    {
       if ( ! i.key()->isString() )	// key must be a string
       {
	  y2error( "Cannot write invalid key %s, must be a string",
		   i.value()->toString().c_str());
       }
       else if ( ! i.value()->isList() )	// value must be a list
       {
	  y2error( "Invalid value %s. Must be a pair [ string value, string comment ]",
		   i.value()->toString().c_str());
       }
       else	// everything OK
       {
	  string variablename = i.key()->asString()->value();
	  YCPList valuecomment = i.value()->asList();

	  //
	  // if the key matches evaluate the rest
	  //
	  if ( variablename == key )	// gotcha
	  {
	     if ( valuecomment->size() != 2 )
	     {
		y2error ("Invalid value %s. Must be a pair [ string value, string comment ]",
			 i.value()->toString().c_str());

		break;	// something went wrong with the format
	     }

	     string value = "";

	     if ( valuecomment->value(0)->isString() )		// value is string --> use directly
	     {
		value = valuecomment->value(0)->asString()->value();
	     }
	     else if ( valuecomment->value(0)->isList() )	// value is list --> use elements
	     {
		// assemble result string as csl of list elements
		//
		YCPList valueList = valuecomment->value(0)->asList();

		// evaluate list if not empty
		//
		if ( valueList->size() > 0 )
		{
		   int k = 0;

		   // assign first element directly
		   //
		   if ( valueList->value(0)->isString() )	// string
		   {
		      value = valueList->value(0)->asString()->value();
		   }
		   else	// something else
		   {
		      value = valueList->value(0)->toString();
		   }

		   // append remaining entries separated by commas
		   //
		   for ( k = 1; k < valueList->size(); k++ )
		   {
		      if ( valueList->value(k)->isString() )	// string
		      {
			 value = value + "," + valueList->value(k)->asString()->value();
		      }
		      else	// something else
		      {
			 value = value + "," + valueList->value(k)->toString();
		      }
		   }
		}
	     }
	     else	// value is something else --> transform to string
	     {
		value = valuecomment->value(0)->toString();
	     }

	     string comment;
	     if ( valuecomment->value(1)->isString() )
		 comment = valuecomment->value(1)->asString()->value();
	     else
		 comment = valuecomment->value(1)->toString();

	     retval.v = value;
	     retval.c = comment;

	     return retval;
	  }
       }
    }

    return retval;	// return { "", "" } if not found
}



// Write the keyboard section of the rc.sax file (XFree4)
//
void  Xf86ConfigAgent::writeKeyboardSection( const YCPMap& config_map, FILE* file )
{
    // Params should be checked by caller.
    // File is writeable (opened by caller).
    //
    const char *value;

    fprintf( file, "Keyboard {\n" );
    value = getValueComment( config_map, "PROTOCOL" ).v.c_str();
    if( *value != 0 )
	fprintf( file, " 0 Protocol         =    %s\n", value );

    value = getValueComment( config_map, "XKBRULES" ).v.c_str();
    if( *value != 0 )
	fprintf( file, " 0 XkbRules         =    %s\n", value );

    value = getValueComment( config_map, "XKBMODEL" ).v.c_str();
    if( *value != 0 )
	fprintf( file, " 0 XkbModel         =    %s\n", value );

    value = getValueComment( config_map, "XKBLAYOUT" ).v.c_str();
    if( *value != 0 )
	fprintf( file, " 0 XkbLayout        =    %s\n", value );

    value = getValueComment( config_map, "XKBVARIANT" ).v.c_str();
    if( *value != 0 )
	fprintf( file, " 0 XkbVariant       =    %s\n", value );

    value = getValueComment( config_map, "XKBKEYCODES" ).v.c_str();
    if( *value != 0 )
	fprintf( file, " 0 Keycodes         =    %s\n", value );

    value = getValueComment( config_map, "MAPNAME" ).v.c_str();
    if( *value != 0 )
	fprintf( file, " 0 MapName          =    %s\n", value );

    value = getValueComment( config_map, "LEFTALT" ).v.c_str();
    if( *value != 0 )
	fprintf( file, " 0 LeftAlt          =    %s\n", value );

    value = getValueComment( config_map, "RIGHTALT" ).v.c_str();
    if( *value != 0 )
	fprintf( file, " 0 RightAlt         =    %s\n", value );

    value = getValueComment( config_map, "SCROLLOCK" ).v.c_str();
    if( *value != 0 )
	fprintf( file, " 0 ScrollLock       =    %s\n", value );

    value = getValueComment( config_map, "RIGHTCTL" ).v.c_str();
    if( *value != 0 )
	fprintf( file, " 0 RightCtl         =    %s\n", value );

    fprintf( file, " 0 Identifier       =    Keyboard[0]\n" );
    fprintf( file, " 0 Driver           =    keyboard\n" );
    fprintf(file, "}\n" );

    // no return value
}



// Write the mouse section of the rc.sax file (XFree4)
//
void  Xf86ConfigAgent::writeMouseSection( const YCPMap& config_map, FILE* file )
{
    // Params should be checked by caller.
    // File is writeable (opened by caller).
    //
    fprintf( file, "Mouse {\n" );
    fprintf( file, " 1 Identifier       =    Mouse[1]\n" );
    fprintf( file, " 1 Device           =    %s\n", getValueComment( config_map, "MOUSEDEVICE" ).v.c_str() );
    fprintf( file, " 1 Protocol         =    %s\n", getValueComment( config_map, "MOUSEPROT" ).v.c_str() );
    fprintf( file, " 1 Emulate3Buttons  =    %s\n", getValueComment( config_map, "EMU3BTN" ).v.c_str() );
    fprintf( file, " 1 ButtonNumber     =    %s\n", getValueComment( config_map, "MOUSEBUTTONS" ).v.c_str() );
    // set Zaxis mapping in XFree 4 style if apropriate.
    // WARNING: The string originated for XFree 3 is _not_ parsed or converted.
    // This is not necessary because only _one_ wheel is supported and the syntax is fixed.
    if ( getValueComment( config_map, "MOUSEOPT" ).v != "" )
    {
	fprintf( file, " 1 ZAxisMapping     =    4 5\n" );
    }
    fprintf(file, "}\n");

    // no return value
}



// Write the path section of the rc.sax file (XFree4)
//
void  Xf86ConfigAgent::writePathSection( const YCPMap& config_map, FILE* file )
{
    // Params are only dummies here (symmetry reasons)
    // File is writeable (opened by caller).
    //
    fprintf( file, "Path {\n" );

    // Special tag ==> font list is taken from SaX by isax.
    //
    fprintf( file, " 0 FontPath         =    YaST2\n" );
    fprintf( file, "}\n" );

    // no return value
}



// Read the whole XF86Config file (only XFree4).
//
YCPValue Xf86ConfigAgent::ReadAllXFree4( const YCPValue& arg )
{
    YCPMap     retval       = YCPNull();
    YCPValue   locret 	    = YCPVoid();
    YCPMap     section      = YCPNull();
    YCPMap     all_sections = YCPNull();
    YCPInteger zero         = "0";	// Why is zero( 0 ) invalid ???

    // Get the information corresponding to all the sections in the rc.sax file.
    // Start with the Keyboard section.
    //
    locret = ReadKeyboard( arg );

    // Get the sections map only containing the Keyboard section and assign it as
    // a start for the map containing all sections.
    //
    if ( locret->isMap() )	retval = locret->asMap();	// start
    else			return YCPVoid();

    // Read and add the Mouse section.
    //
    locret = ReadMouse( arg );

    if ( locret->isMap() )
    {
	locret = mergeMaps( retval, locret->asMap() );

	if ( locret->isMap() )  retval = locret->asMap();
	else			return YCPVoid();
    }
    else 			return YCPVoid();

    // Read and add the Card section.
    //
    locret = ReadCard( arg );

    if ( locret->isMap() )
    {
	locret = mergeMaps( retval, locret->asMap() );

	if ( locret->isMap() )  retval = locret->asMap();
	else			return YCPVoid();
    }
    else 			return YCPVoid();

    // Read and add the Desktop section.
    //
    locret = ReadDesktop( arg );

    if ( locret->isMap() )
    {
	locret = mergeMaps( retval, locret->asMap() );

	if ( locret->isMap() )  retval = locret->asMap();
	else			return YCPVoid();
    }
    else 			return YCPVoid();

    // Read and add the Path section.
    //
    locret = ReadPath( arg );

    if ( locret->isMap() )
    {
	locret = mergeMaps( retval, locret->asMap() );

	if ( locret->isMap() )  retval = locret->asMap();
	else			return YCPVoid();
    }
    else 			return YCPVoid();

    // Read and add the Layout section.
    //
    locret = ReadLayout( arg );

    if ( locret->isMap() )
    {
	locret = mergeMaps( retval, locret->asMap() );

	if ( locret->isMap() )  retval = locret->asMap();
	else			return YCPVoid();
    }
    else 			return YCPVoid();

    return retval;
}




// Read a section of the XF86Config file (only XFree4).
//
YCPValue Xf86ConfigAgent::ReadXF86Config( const string section, const YCPValue& arg )
{
    YCPValue contents = YCPVoid();

    // Assign output file for isax.
    //
    string isax_output_path = glob_tmpdir + "/isax_output.ycp";

    // Read the requested section.
    //
    string command = "/usr/X11R6/lib/sax/tools/isax -y -l "
	+ section
	+ " > "
	+ isax_output_path
	+ " 2> "
	+ isax_log_path;

    int exitcode = shellCommand( command );

    if ( exitcode == 0 )	// OK
    {
	// Read the file produced by isax.
	//
	contents = readYCPFile( isax_output_path );
    }

    return contents;		// should be a YCP map on success
}



// Read the Keyboard section of the XF86Config file (only XFree4).
//
YCPValue Xf86ConfigAgent::ReadKeyboard( const YCPValue& arg )
{
    return ReadXF86Config( "Keyboard", arg );
}



// Read the Mouse section of the XF86Config file (only XFree4).
//
YCPValue Xf86ConfigAgent::ReadMouse( const YCPValue& arg )
{
    return ReadXF86Config( "Mouse", arg );
}



// Read the Card section of the XF86Config file (only XFree4).
//
YCPValue Xf86ConfigAgent::ReadCard( const YCPValue& arg )
{
    return ReadXF86Config( "Card", arg );
}



// Read the Desktop section of the XF86Config file (only XFree4).
//
YCPValue Xf86ConfigAgent::ReadDesktop( const YCPValue& arg )
{
    return ReadXF86Config( "Desktop", arg );
}



// Read the Path section of the XF86Config file (only XFree4).
//
YCPValue Xf86ConfigAgent::ReadPath( const YCPValue& arg )
{
    return ReadXF86Config( "Path", arg );
}



// Read the Layout section of the XF86Config file (only XFree4).
//
YCPValue Xf86ConfigAgent::ReadLayout( const YCPValue& arg )
{
    return ReadXF86Config( "Layout", arg );
}



// Update the rc.sax keyboard section
//
YCPValue Xf86ConfigAgent::UpdateKeyboard( const YCPMap& config_map, const YCPValue& arg )
{
    y2milestone( "Updating the keyboard section" );

    FILE* file = fopen( rc_sax_path.c_str(), "w" );

    if ( ! file )
    {
	string msg = "Can't open rc.sax file <" + rc_sax_path + "> for writing.";
	return YCPError( msg );
    }

    // Write the keyboard section
    //
    writeKeyboardSection( config_map, file );

    // After having written the contents close the rc.sax file.
    //
    if ( file ) fclose( file );

    // Now call isax for XFree4 to process this file (update the XF86Config file).
    //
    int exitcode = shellCommand( xfree4_update_command );

    return YCPBoolean( exitcode == 0 );
}



// Update the rc.sax mouse section
//
YCPValue Xf86ConfigAgent::UpdateMouse( const YCPMap& config_map, const YCPValue& arg )
{
    y2milestone( "Updating the mouse section" );

    FILE* file = fopen( rc_sax_path.c_str(), "w" );

    if ( ! file )
    {
	string msg = "Can't open rc.sax file <" + rc_sax_path + "> for writing.";
	return YCPError( msg );
    }

    // Write the mouse section
    //
    writeMouseSection( config_map, file );

    // After having written the contents close the rc.sax file.
    //
    if ( file ) fclose( file );

    // Now call isax for XFree4 to process this file (update the XF86Config file).
    //
    int exitcode = shellCommand( xfree4_update_command );

    return YCPBoolean( exitcode == 0 );
}



// Update the rc.sax path section
//
YCPValue Xf86ConfigAgent::UpdatePath( const YCPMap& config_map, const YCPValue& arg )
{
    y2milestone( "Updating the path section" );

    FILE* file = fopen( rc_sax_path.c_str(), "w" );

    if ( ! file )
    {
	string msg = "Can't open rc.sax file <" + rc_sax_path + "> for writing.";
	return YCPError( msg );
    }

    // Write the path section
    //
    writePathSection( config_map, file );

    // After having written the contents close the rc.sax file.
    //
    if ( file ) fclose( file );

    // Now call isax for XFree4 to process this file (update the XF86Config file).
    //
    int exitcode = shellCommand( xfree4_update_command );

    return YCPBoolean( exitcode == 0 );
}




// ****************************************************************************************
// Exported functions
// ****************************************************************************************


Xf86ConfigAgent::Xf86ConfigAgent()
{
}



// The generic SCR Read function.
// This is only possible for XFree 4.
//
YCPValue Xf86ConfigAgent::Read( const YCPPath& path, const YCPValue& arg, const YCPValue& opt )
{
    YCPValue retval = YCPVoid();

    y2milestone( "Path: <%s>", path->toString().c_str());

    // Assign global variable glob_tmpdir if necessary for YaST2 tmpdir access.
    // Can't be done in the constructor for technical reasons.
    //
    init();

    // Some plausi checks...
    //
    if ( ! path->isPath() )
    {
	return YCPError( "Path is not a path" );
    }

    // Check out what should be read.
    //
    if ( path->isRoot() )	// Is "." in the agent, ".xf86config" in the outer world.
    {
	// This means the whole XF86Config file should be read (only XFree 4).
	//
	retval = ReadAllXFree4( arg );
    }
    else	// There is a subpath...
    {
	// This means only a part of the XF86Config file should be read (only XFree 4).
	// This could be done shorter by using subpath directly as parameter for ReadXF86Config()
	// but this way it is symmetric to Write and provides a subpath checking.
	//
	string subpath =  path->component_str( 0 ); 	// subpath after .xf86config

	y2milestone( "subpath: <%s>", subpath.c_str() );

	if ( subpath == "keyboard" )
	{
	    retval = ReadKeyboard( arg );
	}
	else if ( subpath == "mouse" )
	{
	    retval = ReadMouse( arg );
	}
	else if ( subpath == "card" )
	{
	    retval = ReadCard( arg );
	}
	else if ( subpath == "desktop" )
	{
	    retval = ReadDesktop( arg );
	}
	else if ( subpath == "path" )
	{
	    retval = ReadPath( arg );
	}
	else if ( subpath == "layout" )
	{
	    retval = ReadLayout( arg );
	}
	else
	{
	    string msg = "Unknown subpath <" + subpath + ">";
	    return YCPError( msg );
	}
    }

    return retval;
}


// The generic SCR Write function.
//
YCPValue Xf86ConfigAgent::Write( const YCPPath& path, const YCPValue& value, const YCPValue& arg )
{
    YCPValue retval = YCPBoolean( false );

    y2milestone( "Path: <%s>", path->toString().c_str());

    // Assign global variable glob_tmpdir if necessary for YaST2 tmpdir access.
    // Can't be done in the constructor for technical reasons.
    //
    init();

    // Some plausi checks...
    //
    if ( ! path->isPath() )
    {
	return YCPError( "Path is not a path" );
    }

    if ( ! value->isMap() )
    {
	return YCPError( "Value is not a map" );
    }

    YCPMap config_map = value->asMap();

    // Check out what should be written.
    //
    if ( path->isRoot() )	// Is "." in the agent, ".xf86config" in the outer world.
    {
	return YCPError( string("Writing whole XF86Config not allowed here (Done by Sax).") );
    }
    else	// There is a subpath...
    {
	string subpath =  path->component_str( 0 ); 	// subpath after .xf86config

	y2milestone( "subpath: <%s>", subpath.c_str() );

	if ( subpath == "card"
	     || subpath == "desktop"
	     || subpath == "layout" )
	{
	    return YCPError( string("Writing ") + subpath + " is not provided!" );
	}
	else if ( subpath == "keyboard" )
	{
	    retval = UpdateKeyboard( config_map, arg );
	}
	else if ( subpath == "mouse" )
	{
	    retval = UpdateMouse( config_map, arg );
	}
	else if ( subpath == "path" )
	{
	    retval = UpdatePath( config_map, arg );
	}
	else
	{
	    string msg = "Unknown subpath <" + subpath + ">";
	    return YCPError( msg );
	}
    }

    return retval;
}

// The directory function.
// Returns all possible subpaths as YCPList.
//
YCPValue Xf86ConfigAgent::Dir( const YCPPath& path )
{
    y2milestone( "Path: <%s>", path->toString().c_str());

    // The paths for the dir command.
    //
    YCPList paths;

    if ( path->isRoot() )
    {
	// Return all subpaths
	//
	paths->add( YCPPath( ".keyboard" ) );
	paths->add( YCPPath( ".mouse" ) );
	paths->add( YCPPath( ".card" ) );
	paths->add( YCPPath( ".desktop" ) );
	paths->add( YCPPath( ".path" ) );
	paths->add( YCPPath( ".layout" ) );
    }

    // Otherwise return empty list.
    //
    return paths;
}

