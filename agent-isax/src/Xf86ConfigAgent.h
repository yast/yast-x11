// -*- c++ -*-

#ifndef Xf86ConfigAgent_h
#define Xf86ConfigAgent_h


#include <scr/SCRAgent.h>
#include <Y2.h>

/**
 * @short SCR Agent for access to rc.sax
 */

// Simplify access to the map passed to the agent
//
typedef struct
{
    string v;	// value
    string c;	// comment
} ValueComment;

class Xf86ConfigAgent : public SCRAgent 
{
public:
    Xf86ConfigAgent();

    /**
     * Reads data. Destroy the result after use.
     * @param path Specifies what part of the subtree should
     * be read. The path is specified _relatively_ to Root()!
     */
    YCPValue Read(const YCPPath& path, const YCPValue& arg = YCPNull());

    /**
     * Writes data. Destroy the result after use.
     */
    YCPValue Write(const YCPPath& path, const YCPValue& value, const YCPValue& arg = YCPNull());

    /**
     * Get a list of all subtrees.
     */
    YCPValue Dir(const YCPPath& path);
    
private:
    // Utilities
    void init( void );
    int shellCommand( const string command );
    YCPValue readYCPFile( const string ycp_file );
    YCPValue mergeMaps( YCPMap target, YCPMap source );
    ValueComment getValueComment( const YCPMap config_map, const string key);

    void writeKeyboardSection( const YCPMap& config_map, FILE* file );
    void writeMouseSection( const YCPMap& config_map, FILE* file );
    void writePathSection( const YCPMap& config_map, FILE* file );

    // Read whole XF86Config file (only XFree 4)
    YCPValue ReadAllXFree4( const YCPValue& arg = YCPNull() );

    // Read parts of the XF86Config file (only XFree 4)
    YCPValue ReadXF86Config( const string section, const YCPValue& arg = YCPNull() );
    YCPValue ReadKeyboard( const YCPValue& arg = YCPNull() );
    YCPValue ReadMouse( const YCPValue& arg = YCPNull() );
    YCPValue ReadCard( const YCPValue& arg = YCPNull() );
    YCPValue ReadDesktop( const YCPValue& arg = YCPNull() );
    YCPValue ReadPath( const YCPValue& arg = YCPNull() );
    YCPValue ReadLayout( const YCPValue& arg = YCPNull() );

    // Write parts of the XF86Config file (only XFree 4)
    YCPValue UpdateKeyboard( const YCPMap& config_map, const YCPValue& arg = YCPNull() );
    YCPValue UpdateMouse( const YCPMap& config_map, const YCPValue& arg = YCPNull() );
    YCPValue UpdatePath( const YCPMap& config_map, const YCPValue& arg = YCPNull() );
};


#endif // Xf86ConfigAgent_h
