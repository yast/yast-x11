// -*- c++ -*-

#ifndef Y2CCXf86Config_h
#define Y2CCXf86Config_h

#include "Y2.h"

class Y2CCXf86Config : public Y2ComponentCreator
{
 public:
    /**
     * Creates a new Y2CCXf86Config object.
     */
    Y2CCXf86Config();
    
    /**
     * Returns true: The Xf86Config agent is a server component.
     */
    bool isServerCreator() const;
    
    /**
     * Creates a new @ref Y2SCRComponent, if name is "ag_xf86config".
     */
    Y2Component *create(const char *name) const;
};

#endif
