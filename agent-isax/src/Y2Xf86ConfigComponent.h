// -*- c++ -*-

#ifndef Y2AnyAgentComponent_h
#define Y2AnyAgentComponent_h

#include "Y2.h"

class SCRInterpreter;
class Xf86ConfigAgent;

class Y2Xf86ConfigComponent : public Y2Component
{
    SCRInterpreter *interpreter;
    Xf86ConfigAgent *agent;

public:

    /**
     * Create a new Y2AnyAgentComponent
     */
    Y2Xf86ConfigComponent();

    /**
     * Cleans up
     */
    ~Y2Xf86ConfigComponent();

    /**
     * Returns true: The scr is a server component
     */
    bool isServer() const;

    /**
     * Returns "ag_anyagent": This is the name of the anyagent component
     */
    string name() const;

    /**
     * Evalutas a command to the scr
     */
    YCPValue evaluate(const YCPValue& command);

    /**
     * Returns the SCRAgent of the Y2Component, which of course is a
     * Xf86ConfigAgent.
     */
    SCRAgent* getSCRAgent ();

};

#endif
