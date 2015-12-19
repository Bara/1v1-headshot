#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <multicolors>
#include "include/multi1v1.inc"
#include "multi1v1/generic.sp"
#include "multi1v1/version.sp"

#pragma semicolon 1
#pragma newdecls required

bool g_HeadShot[MAXPLAYERS+1];
Handle g_hHeadShotCookie = INVALID_HANDLE;

bool g_EnableHeadShot[MAXPLAYERS+1];

public Plugin myinfo = {
    name = "CS:GO Multi1v1: headshot addon",
    author = "splewis & Bara",
    description = "Adds an option for headshot only",
    version = PLUGIN_VERSION,
    url = "http://git.tf/Bara"
};

public void OnPluginStart() {
    LoadTranslations("multi1v1.phrases");
    g_hHeadShotCookie = RegClientCookie("multi1v1_headshot", "Multi-1v1 that allow only headshot in rounds", CookieAccess_Protected);
    
    // Lateload support
    for(int client = 1; client <= MaxClients; client++)
	{
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(IsClientInGame(victim) && IsClientInGame(attacker))
	{
		if (victim >= 0 && attacker >= 0 && g_EnableHeadShot[victim] && g_EnableHeadShot[attacker])
		{
			if(damagetype & CS_DMG_HEADSHOT)
			{
				return Plugin_Continue;
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void OnClientConnected(int client) {
    g_HeadShot[client] = false;
}

public void Multi1v1_OnGunsMenuCreated(int client, Menu menu) {
    char enabledString[32];
    GetEnabledString(enabledString, sizeof(enabledString), g_HeadShot[client], client);
    AddMenuOption(menu, "headshot", "Headshot Only: %s", enabledString);
}

public void Multi1v1_GunsMenuCallback(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        char buffer[128];
        menu.GetItem(param2, buffer, sizeof(buffer));
        if (StrEqual(buffer, "headshot")) {
            g_HeadShot[client] = !g_HeadShot[client];
            SetCookieBool(client, g_hHeadShotCookie, g_HeadShot[client]);
            Multi1v1_GiveWeaponsMenu(client, GetMenuSelectionPosition());
        }
    }
}

public void Multi1v1_AfterPlayerSetup(int client) {
    if (!IsActivePlayer(client)) {
        return;
    }

    int arena = Multi1v1_GetArenaNumber(client);
    int p1 = Multi1v1_GetArenaPlayer1(arena);
    int p2 = Multi1v1_GetArenaPlayer2(arena);
    
    // Random round chance is 1:2
    if (g_HeadShot[p1] && g_HeadShot[p2] && !g_EnableHeadShot[p1] && !g_EnableHeadShot[p2] && GetRandomInt(0, 1) == 1)
    {
    	g_EnableHeadShot[p1] = true;
    	g_EnableHeadShot[p2] = true;
    	
    	CPrintToChat(p1, "{darkred}This is a headshot only round!");
    	CPrintToChat(p2, "{darkred}This is a headshot only round!");
    }
}

public void OnClientCookiesCached(int client) {
    if (IsFakeClient(client))
        return;
    g_HeadShot[client] = GetCookieBool(client, g_hHeadShotCookie);
}

// Reset stuff
public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			g_EnableHeadShot[client] = false;
		}
	}
}
