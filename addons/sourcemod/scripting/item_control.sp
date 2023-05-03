#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>


public Plugin myinfo =
{
	name = "ItemControl",
	author = "TouchMe",
	description = "",
	version = "build_0001",
	url = "https://github.com/TouchMe-Inc/l4d2_item_control"
};


enum ItemClass {
	ItemClass_None = 0,
	ItemClass_FirstAidKit,
	ItemClass_Defibrillator,
	ItemClass_Pills,
	ItemClass_Adrenaline,
	ItemClass_PipeBomb,
	ItemClass_Molotov,
	ItemClass_Vomitjar
}

enum struct Coord {
	float x;
	float y;
	float z;
}

enum struct Item {
	Coord coord;
	ItemClass class;
}


Handle g_hItems = INVALID_HANDLE;


public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public void OnMapStart()
{

	char sMapName[64];
	GetCurrentMap(sMapName, sizeof(sMapName));

	char sSpawnCoordPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sSpawnCoordPath, PLATFORM_MAX_PATH, "data/item_control/%s.cfg", sMapName);

	Handle hSpawnCoords = CreateArray(sizeof(Coord));

	if (!FileExists(sSpawnCoordPath))
	{
		FindSpawnCoord(hSpawnCoords);
		SaveSpawnCoord(sSpawnCoordPath, hSpawnCoords);
	} 

	else {
		LoadSpawnCoord(sSpawnCoordPath, hSpawnCoords);
	}

	g_hItems = CreateArray(sizeof(Item));

	/*
	Determine the number of items from the config or cvar, 
	and then form a list of them to arrange in the first and second rounds 
	*/
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// Spawn item on Coords

	return Plugin_Continue;
}


void FindSpawnCoord(Handle &hSpawnCoords)
{
	Coord tSpawnCoord;
	char sClassName[32];
	float fOrigin[3];

	for(int i = 0; i <= GetEntityCount(); i++)
	{
		if (!IsValidEntity(i)) {
			continue;
		}

		GetEdictClassname(i, sClassName, sizeof(sClassName));

		if (IsItemControlClass(sClassName)) {
			continue;
		}

		GetEntPropVector(i, Prop_Send, "m_vecOrigin", fOrigin);

		tSpawnCoord.x = fOrigin[0];
		tSpawnCoord.y = fOrigin[1];
		tSpawnCoord.z = fOrigin[2];

		PushArrayArray(hSpawnCoords, tSpawnCoord);
	}
}

void SaveSpawnCoord(const char[] sFilePath, Handle &hSpawnCoords)
{
	File hFile = OpenFile(sFilePath, "wt");
	if (!hFile) {
		SetFailState("Could not open file!");
	}

	Coord tSpawnCoord;
	for(int iIndex = 0; iIndex <= GetArraySize(hSpawnCoords); iIndex++)
	{
		GetArrayArray(hSpawnCoords, iIndex, tSpawnCoord);

		hFile.WriteLine("%f %f %f", tSpawnCoord.x, tSpawnCoord.y, tSpawnCoord.z);
	}

	hFile.Close();
}

void LoadSpawnCoord(const char[] sFilePath, Handle &hSpawnCoords)
{
	File hFile = OpenFile(sFilePath, "rt");
	if (!hFile) {
		SetFailState("Could not open file!");
	}

	while (!hFile.EndOfFile())
	{
		char sCurLine[255];

		if (!hFile.ReadLine(sCurLine, sizeof(sCurLine))) {
			break;
		}

		int iLineLength = strlen(sCurLine);

		for (int iChar = 0; iChar < iLineLength; iChar++)
		{
			if (sCurLine[iChar] == '/' && iChar != iLineLength - 1 && sCurLine[iChar + 1] == '/')
			{
				sCurLine[iChar] = '\0';
				break;
			}
		}
		
		TrimString(sCurLine);
		
		if ((sCurLine[0] == '/' && sCurLine[1] == '/') || (sCurLine[0] == '\0')) {
			continue;
		}

		int iPos;
		char sBreakLine[64];
		Coord tSpawnCoord;

		// Find Coord.x
		iPos = BreakString(sCurLine, sBreakLine, sizeof(sBreakLine));
		tSpawnCoord.x = StringToFloat(sBreakLine); 

		// Find Coord.y
		iPos += BreakString(sCurLine[iPos], sBreakLine, sizeof(sBreakLine));
		tSpawnCoord.y = StringToFloat(sBreakLine);

		// Find Coord.z
		BreakString(sCurLine[iPos], sBreakLine, sizeof(sBreakLine));
		tSpawnCoord.z = StringToFloat(sBreakLine);

		PushArrayArray(hSpawnCoords, tSpawnCoord);
	}

	hFile.Close();
}

bool IsItemControlClass(const char[] sClassName)
{
	return	(sClassName[7] == 'f' && sClassName[8] == 'i') || // weapon_first_aid_kit_spawn
			(sClassName[7] == 'd' && sClassName[8] == 'e') || // weapon_defibrillator_spawn
			(sClassName[7] == 'p' && sClassName[8] == 'a') || // weapon_pain_pills_spawn
			(sClassName[7] == 'a' && sClassName[8] == 'd') || // weapon_adrenaline_spawn
			(sClassName[7] == 'p' && sClassName[8] == 'i' && sClassName[9] == 'p') || // weapon_pipe_bomb_spawn (throw weapon_[pi]stol)
			(sClassName[7] == 'm' && sClassName[8] == 'o') || // weapon_molotov_spawn
			(sClassName[7] == 'v' && sClassName[8] == 'o'); // weapon_vomitjar_spawn
}