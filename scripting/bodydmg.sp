#include <sourcemod>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

enum player
{
	head,
	upperchest,
	lowerchest,
	leftarm,
	rightarm,
	leftleg,
	rightleg,
	hits
}

int g_Damage[MAXPLAYERS+1][MAXPLAYERS+1][player];
ConVar g_cvar_xcord, g_cvar_ycord, g_cvar_red, g_cvar_green, g_cvar_blue, g_cvar_holdtime;
float x, y, holdtime;
int red, blue, green;

Handle g_Cookie_DisplayMessage;
bool g_bClientMessagePreference[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name			= 	"Body HitGroup Damage",
	author			= 	"Cruze",
	description		= 	"Represents an illustrated player to show damage given at which body part by enemy to player when player dies.",
	version			= 	"1.1",
	url				= 	"http://steamcommunity.com/profiles/76561198132924835"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_hitplace", Command_BodyDmg, "Enable / Disable the displaying of body damage plugin at player death");
	HookEvent("player_hurt", PlayerHurt);
	HookEvent("player_death", PlayerDeath);
	HookEvent("round_start", Round);
	HookEvent("round_end", Round);
	g_cvar_xcord = CreateConVar("sm_bodydmg_xcord", "0.20");
	g_cvar_ycord = CreateConVar("sm_bodydmg_ycord", "0.25");
	g_cvar_red = CreateConVar("sm_bodydmg_redhud", "0");
	g_cvar_green = CreateConVar("sm_bodydmg_greenhud", "255");
	g_cvar_blue = CreateConVar("sm_bodydmg_bluehud", "0");
	g_cvar_holdtime = CreateConVar("sm_bodydmg_holdtime", "5.0");
	HookConVarChange(g_cvar_xcord, OnConVarValuesChanged);
	HookConVarChange(g_cvar_ycord, OnConVarValuesChanged);
	HookConVarChange(g_cvar_red, OnConVarValuesChanged);
	HookConVarChange(g_cvar_green, OnConVarValuesChanged);
	HookConVarChange(g_cvar_blue, OnConVarValuesChanged);
	AutoExecConfig(true, "plugin.bodydmg");
	LoadTranslations("bodydmg.phrases");
	
	g_Cookie_DisplayMessage = RegClientCookie("Display Body Damage Message", "Whether player wants to see body hud or not.", CookieAccess_Private);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!AreClientCookiesCached(i))
		{
			continue;
		}
		OnClientCookiesCached(i);
	}
}

public int OnConVarValuesChanged(Handle convar, const char[] oldval, const char[] newval)
{
	if(StrEqual(oldval, newval, false))
		return;
	if(convar == g_cvar_xcord)
	{
		x = StringToFloat(newval);
	}
	else if(convar == g_cvar_ycord)
	{
		y = StringToFloat(newval);
	}
	else if(convar == g_cvar_red)
	{
		red = StringToInt(newval);
	}
	else if(convar == g_cvar_green)
	{
		green = StringToInt(newval);
	}
	else if(convar == g_cvar_blue)
	{
		blue = StringToInt(newval);
	}
	else if(convar == g_cvar_holdtime)
	{
		holdtime = StringToFloat(newval);
	}
}

public void OnMapStart()
{
	x = g_cvar_xcord.FloatValue;
	y = g_cvar_ycord.FloatValue;
	red = g_cvar_red.IntValue;
	green = g_cvar_green.IntValue;
	blue = g_cvar_blue.IntValue;
	holdtime = g_cvar_holdtime.FloatValue;
}

public void OnClientPutInServer(int client)
{
	OnClientCookiesCached(client);
}

public void OnClientCookiesCached(int client)
{
    char sValue[8];
    GetClientCookie(client, g_Cookie_DisplayMessage, sValue, sizeof(sValue));
    
    if(sValue[0] == '\0')
	{
		g_bClientMessagePreference[client] = true;
	}
	else
	{
		g_bClientMessagePreference[client] = !!StringToInt(sValue);
	}
}

public Action Command_BodyDmg(int client, int args)
{
	if(g_bClientMessagePreference[client])
	{
		//PrintToChat(client, "[SM] Disabled the displaying of body damage.");
		PrintToChat(client, "%t", "DisabledBodyDMG");
		g_bClientMessagePreference[client] = false;
		SetClientCookie(client, g_Cookie_DisplayMessage, "0");
	}
	else
	{
		//PrintToChat(client, "[SM] Enabled the displaying of body damage.");
		PrintToChat(client, "%t", "EnabledBodyDMG");
		g_bClientMessagePreference[client] = true;
		SetClientCookie(client, g_Cookie_DisplayMessage, "1");
	}
	return Plugin_Handled;
}

public Action Round(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		for(int j = 1; j <= MaxClients; j++)
		{
			ResetArray(i, j);
			ResetArray(j, i);
		}
	}
}

public Action PlayerHurt(Event ev, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(ev.GetInt("userid"));
	int attacker = GetClientOfUserId(ev.GetInt("attacker"));
	
	if(client < 1 || client > MaxClients || attacker < 1 || attacker > MaxClients  || attacker == client)
	{
		return Plugin_Continue;
	}
	
	int hitgroup = ev.GetInt("hitgroup");
	switch(hitgroup)
	{
		case 1: g_Damage[attacker][client][head] += 1;
		case 2: g_Damage[attacker][client][upperchest] += 1;
		case 3: g_Damage[attacker][client][lowerchest] += 1;
		case 4: g_Damage[attacker][client][leftarm] += 1;
		case 5: g_Damage[attacker][client][rightarm] += 1;
		case 6: g_Damage[attacker][client][leftleg] += 1;
		case 7: g_Damage[attacker][client][rightleg] += 1;
	}
	g_Damage[attacker][client][hits] += 1;
	return Plugin_Continue;
}

public Action PlayerDeath(Event ev, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(ev.GetInt("userid"));
	int attacker = GetClientOfUserId(ev.GetInt("attacker"));
	
	if(victim < 1 || victim > MaxClients || attacker < 1 || attacker > MaxClients || attacker == victim)
	{
		return Plugin_Continue;
	}
	
	if(g_bClientMessagePreference[victim])
	{
		SetHudTextParams(x, y, holdtime, red, green, blue, 255, 1, 1.0, 0.0, 0.0);
		ShowHudText(victim, -1, "       (%d)\n--%d--[%d]--%d--\n       [%d]\n       %d %d\n    _/   \\_\n  %N's Body\n  Total hits: %d", g_Damage[victim][attacker][head], g_Damage[victim][attacker][upperchest], g_Damage[victim][attacker][lowerchest], g_Damage[victim][attacker][leftarm], g_Damage[victim][attacker][rightarm], g_Damage[victim][attacker][leftleg], g_Damage[victim][attacker][rightleg], attacker, g_Damage[victim][attacker][hits]);
	}
	
	ResetArray(victim, attacker);
	ResetArray(attacker, victim);
	return Plugin_Continue;
}

void ResetArray(int player1, int player2)
{
	g_Damage[player1][player2][head] = 0;
	g_Damage[player1][player2][upperchest] = 0;
	g_Damage[player1][player2][lowerchest] = 0;
	g_Damage[player1][player2][leftarm] = 0;
	g_Damage[player1][player2][rightarm] = 0;
	g_Damage[player1][player2][leftleg] = 0;
	g_Damage[player1][player2][rightleg] = 0;
	g_Damage[player1][player2][hits] = 0;
}