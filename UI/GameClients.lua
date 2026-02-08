---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

local GameClients = {}
LibsSocial.GameClients = GameClients

-- BNet game client program mappings
-- Key is the clientProgram string from C_BattleNet.GetFriendGameAccountInfo
GameClients.CLIENT_LIST = {
	WoW = { tag = 'WoW', name = 'World of Warcraft' },
	WTCG = { tag = 'HS', name = 'Hearthstone' },
	Hero = { tag = 'HotS', name = 'Heroes of the Storm' },
	Pro = { tag = 'OW', name = 'Overwatch' },
	OSI = { tag = 'D2', name = 'Diablo 2: Resurrected' },
	D3 = { tag = 'D3', name = 'Diablo 3' },
	Fen = { tag = 'D4', name = 'Diablo 4' },
	ANBS = { tag = 'DI', name = 'Diablo Immortal' },
	S1 = { tag = 'SC', name = 'Starcraft' },
	S2 = { tag = 'SC2', name = 'Starcraft 2' },
	W3 = { tag = 'WC3', name = 'Warcraft 3: Reforged' },
	RTRO = { tag = 'AC', name = 'Arcade Collection' },
	WLBY = { tag = 'CB4', name = 'Crash Bandicoot 4' },
	VIPR = { tag = 'BO4', name = 'COD: Black Ops 4' },
	ODIN = { tag = 'WZ', name = 'COD: Warzone' },
	AUKS = { tag = 'WZ2', name = 'COD: Warzone 2' },
	LAZR = { tag = 'MW2', name = 'COD: Modern Warfare 2' },
	ZEUS = { tag = 'CW', name = 'COD: Cold War' },
	FORE = { tag = 'VG', name = 'COD: Vanguard' },
	GRY = { tag = 'AR', name = 'Warcraft Arclight Rumble' },
	App = { tag = 'App', name = 'Battle.net' },
	BSAp = { tag = 'Mobile', name = 'Mobile' },
}

-- Quick lookup for app/launcher clients (not in a game)
GameClients.APP_CLIENTS = {
	App = true,
	BSAp = true,
	CLNT = true,
	[''] = true,
}

-- WoW project ID to display name
GameClients.WOW_PROJECT_NAMES = {
	[1] = 'Retail', -- WOW_PROJECT_MAINLINE
	[2] = 'Classic Era', -- WOW_PROJECT_CLASSIC
	[5] = 'TBC Classic', -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC
	[11] = 'Wrath Classic', -- WOW_PROJECT_WRATH_CLASSIC
	[14] = 'Cata Classic', -- WOW_PROJECT_CATACLYSM_CLASSIC
	[19] = 'Mists Classic', -- WOW_PROJECT_MISTS_CLASSIC
}

---Get the display name for a BNet game client
---@param clientProgram string? The clientProgram from game account info
---@return string displayName The short tag or full name
function GameClients.GetClientDisplayName(clientProgram)
	if not clientProgram or clientProgram == '' then
		return ''
	end
	local info = GameClients.CLIENT_LIST[clientProgram]
	if info then
		return info.tag
	end
	return clientProgram
end

---Get the full game name for a BNet game client
---@param clientProgram string? The clientProgram from game account info
---@return string gameName The full game name
function GameClients.GetClientFullName(clientProgram)
	if not clientProgram or clientProgram == '' then
		return 'Unknown'
	end
	local info = GameClients.CLIENT_LIST[clientProgram]
	if info then
		return info.name
	end
	return clientProgram
end

---Check if a client program represents an app/launcher (not in a game)
---@param clientProgram string? The clientProgram from game account info
---@return boolean isApp True if client is the app/launcher/mobile
function GameClients.IsAppClient(clientProgram)
	if not clientProgram then
		return true
	end
	return GameClients.APP_CLIENTS[clientProgram] or false
end

---Get the WoW project display label
---@param wowProjectID number? The wowProjectID from game account info
---@return string label The project label (e.g., 'Retail', 'Classic Era')
function GameClients.GetProjectLabel(wowProjectID)
	if not wowProjectID then
		return ''
	end
	return GameClients.WOW_PROJECT_NAMES[wowProjectID] or ('Project ' .. wowProjectID)
end
