/**
 * Provides some basic manipulation of ConVars.
 */
#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required

#define PLUGIN_VERSION "0.1.0"
public Plugin myinfo = {
	name = "ConVar Configuration",
	author = "nosoop",
	description = "Convenient ConVar manipulation.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop"
}

#define CONFIG_PATH "configs/convars.cfg"

#define MAX_CONVAR_NAME_LENGTH 64
#define MAX_CONVAR_VALUE_LENGTH 256
#define CONVAR_BOUNDS_DISABLED_VALUE "none"

StringMap g_LockedConVars;

public void OnPluginStart() {
	g_LockedConVars = new StringMap();
}

public void OnAllPluginsLoaded() {
	ProcessConVarConfig();
}

void ProcessConVarConfig() {
	char configPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configPath, sizeof(configPath), CONFIG_PATH);
	
	KeyValues config = new KeyValues("ConVars");
	
	if (FileExists(configPath) && config.ImportFromFile(configPath)) {
		if (!config.GotoFirstSubKey()) {
			return;
		}
		
		char convarName[MAX_CONVAR_NAME_LENGTH];
		do {
			config.GetSectionName(convarName, sizeof(convarName));
			
			ConVar hCvar = FindConVar(convarName);
			
			if (hCvar) {
				char value[MAX_CONVAR_VALUE_LENGTH];
				
				config.GetString("minimum", value, sizeof(value));
				Config_SetConVarBounds(hCvar, ConVarBound_Lower, value);
				
				config.GetString("maximum", value, sizeof(value));
				Config_SetConVarBounds(hCvar, ConVarBound_Upper, value);
				
				config.GetString("flags/hidden", value, sizeof(value));
				if (strlen(value)) {
					Config_SetConVarFlagState(hCvar, FCVAR_HIDDEN, value);
				}
				
				config.GetString("flags/developmentonly", value, sizeof(value));
				if (strlen(value)) {
					Config_SetConVarFlagState(hCvar, FCVAR_DEVELOPMENTONLY, value);
				}
				
				config.GetString("flags/cheat", value, sizeof(value));
				if (strlen(value)) {
					Config_SetConVarFlagState(hCvar, FCVAR_CHEAT, value);
				}
				
				config.GetString("flags/notify", value, sizeof(value));
				if (strlen(value)) {
					Config_SetConVarFlagState(hCvar, FCVAR_NOTIFY, value);
				}
				
				config.GetString("locked", value, sizeof(value));
				if (strlen(value)) {
					Config_LockConVar(hCvar, value);
				}
			}
		} while (config.GotoNextKey());
	} else {
		LogError("Config KeyValues file does not exist or file is malformed.  "
				... "Are you sure it's installed at " ... CONFIG_PATH ... "?");
	}
	delete config;
}

void Config_SetConVarBounds(ConVar convar, ConVarBounds type, const char[] value) {
	if (strlen(value)) {
		if (StrEqual(value, CONVAR_BOUNDS_DISABLED_VALUE)) {
			convar.SetBounds(type, false);
		} else {
			convar.SetBounds(type, true, StringToFloat(value));
		}
	}
}

void Config_LockConVar(ConVar convar, const char[] value) {
	char convarName[MAX_CONVAR_NAME_LENGTH];
	convar.GetName(convarName, sizeof(convarName));
	
	convar.SetString(value);
	g_LockedConVars.SetString(convarName, value);
	
	convar.AddChangeHook(OnConVarChanged);
}

void Config_UnlockConVar(ConVar convar) {
	char convarName[MAX_CONVAR_NAME_LENGTH];
	convar.GetName(convarName, sizeof(convarName));
	
	g_LockedConVars.Remove(convarName);
	
	convar.RemoveChangeHook(OnConVarChanged);
}

void Config_SetConVarFlagState(ConVar convar, int flag, const char[] value) {
	bool bEnable = StringToInt(value) != 0;
	if (bEnable) {
		convar.Flags |= flag;
	} else {
		convar.Flags &= ~flag;
	}
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	char convarName[MAX_CONVAR_NAME_LENGTH];
	convar.GetName(convarName, sizeof(convarName));
	
	char lockedValue[MAX_CONVAR_VALUE_LENGTH];
	if (g_LockedConVars.GetString(convarName, lockedValue, sizeof(lockedValue))
			&& !StrEqual(newValue, lockedValue)) {
		convar.SetString(oldValue);
		LogError("ConVar %s is locked to value %s", convarName, lockedValue);
	}
}
