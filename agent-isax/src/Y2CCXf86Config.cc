#include <scr/Y2AgentComponent.h>
#include <scr/Y2CCAgentComponent.h>

#include "Xf86ConfigAgent.h"


typedef Y2AgentComp <Xf86ConfigAgent> Y2Xf86ConfigAgentComp;

Y2CCAgentComp <Y2Xf86ConfigAgentComp> g_y2ccag_xf86config ("ag_xf86config");

/*
#include "Y2CCXf86Config.h"
#include "Y2Xf86ConfigComponent.h"


Y2CCXf86Config::Y2CCXf86Config()
    : Y2ComponentCreator(Y2ComponentBroker::BUILTIN)
{
}


bool
Y2CCXf86Config::isServerCreator() const
{
    return true;
}


Y2Component *
Y2CCXf86Config::create(const char *name) const
{
    if (!strcmp(name, "ag_xf86config")) return new Y2Xf86ConfigComponent();
    else return 0;
}


Y2CCXf86Config g_y2ccag_xf86config;*/
