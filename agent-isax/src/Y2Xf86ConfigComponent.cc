

#include "Y2Xf86ConfigComponent.h"
#include <scr/SCRInterpreter.h>
#include "Xf86ConfigAgent.h"


Y2Xf86ConfigComponent::Y2Xf86ConfigComponent()
    : interpreter(0),
      agent(0)
{
}


Y2Xf86ConfigComponent::~Y2Xf86ConfigComponent()
{
    if (interpreter) {
        delete interpreter;
        delete agent;
    }
}


bool
Y2Xf86ConfigComponent::isServer() const
{
    return true;
}


string
Y2Xf86ConfigComponent::name() const
{
    return "ag_xf86config";
}


YCPValue
Y2Xf86ConfigComponent::evaluate(const YCPValue& value)
{
    if (!interpreter)
	getSCRAgent ();
    return interpreter->evaluate(value);
}


SCRAgent*
Y2Xf86ConfigComponent::getSCRAgent ()
{
    if (!interpreter)
    {
	agent = new Xf86ConfigAgent ();
	interpreter = new SCRInterpreter (agent);
    }
    return agent;
}
