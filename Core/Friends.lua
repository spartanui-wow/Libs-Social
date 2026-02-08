---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

local Friends = {}
LibsSocial.Friends = Friends

-- Cached data
Friends.characterFriends = {}
Friends.battleNetFriends = {}
Friends.battleNetInGame = {}
Friends.battleNetAppOnly = {}
Friends.guildMembers = {}
Friends.communityMembers = {}

-- Counts
Friends.numCharacterFriends = 0
Friends.numCharacterOnline = 0
Friends.numBattleNetFriends = 0
Friends.numBattleNetOnline = 0
Friends.numBattleNetInGame = 0
Friends.numBattleNetAppOnly = 0
Friends.numGuildMembers = 0
Friends.numGuildOnline = 0

-- Player zone for same-zone highlighting
Friends.playerZone = ''

function LibsSocial:InitializeFriends()
	Friends:RefreshData()
end

function Friends:RefreshData()
	self:RefreshCharacterFriends()
	self:RefreshBattleNetFriends()
	self:RefreshGuildMembers()
	self:RefreshPlayerZone()
end

function Friends:RefreshPlayerZone()
	self.playerZone = GetRealZoneText() or ''
end

function Friends:RefreshCharacterFriends()
	wipe(self.characterFriends)

	self.numCharacterFriends = C_FriendList.GetNumFriends() or 0
	self.numCharacterOnline = C_FriendList.GetNumOnlineFriends() or 0

	for i = 1, self.numCharacterFriends do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info then
			self.characterFriends[info.name] = {
				name = info.name,
				level = info.level,
				class = info.className,
				area = info.area,
				connected = info.connected,
				mobile = info.mobile,
				notes = info.notes,
			}
		end
	end
end

function Friends:RefreshBattleNetFriends()
	wipe(self.battleNetFriends)
	wipe(self.battleNetInGame)
	wipe(self.battleNetAppOnly)

	local GameClients = LibsSocial.GameClients
	local numFriends, numOnline = BNGetNumFriends()
	self.numBattleNetFriends = numFriends or 0
	self.numBattleNetOnline = numOnline or 0
	self.numBattleNetInGame = 0
	self.numBattleNetAppOnly = 0

	for i = 1, self.numBattleNetFriends do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo then
			-- Find the best game account among multiple game accounts
			-- Prefer: in-game with hasFocus > in-game > app with hasFocus > app
			local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(i)
			local bestGameInfo = accountInfo.gameAccountInfo
			local bestIsApp = GameClients.IsAppClient(bestGameInfo and bestGameInfo.clientProgram)

			if numGameAccounts > 1 then
				for j = 1, numGameAccounts do
					local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)
					if gameAccountInfo then
						local isApp = GameClients.IsAppClient(gameAccountInfo.clientProgram)
						-- Prefer game clients over app, and hasFocus within same tier
						if (bestIsApp and not isApp) or (bestIsApp == isApp and gameAccountInfo.hasFocus) then
							bestGameInfo = gameAccountInfo
							bestIsApp = isApp
						end
					end
				end
			end

			local characterName = bestGameInfo and bestGameInfo.characterName
			local realmName = bestGameInfo and bestGameInfo.realmName
			local clientProgram = bestGameInfo and bestGameInfo.clientProgram

			local friendData = {
				accountID = accountInfo.bnetAccountID,
				accountName = accountInfo.accountName,
				battleTag = accountInfo.battleTag,
				isOnline = accountInfo.isOnline,
				isBnetAFK = accountInfo.isAFK,
				isBnetDND = accountInfo.isDND,
				characterName = characterName,
				realmName = realmName,
				characterLevel = bestGameInfo and bestGameInfo.characterLevel,
				className = bestGameInfo and bestGameInfo.className,
				areaName = bestGameInfo and bestGameInfo.areaName,
				isGameBusy = bestGameInfo and bestGameInfo.isGameBusy,
				isGameAFK = bestGameInfo and bestGameInfo.isGameAFK,
				wowProjectID = bestGameInfo and bestGameInfo.wowProjectID,
				clientProgram = clientProgram,
				noteText = accountInfo.note,
				customMessage = accountInfo.customMessage,
				customMessageTime = accountInfo.customMessageTime,
			}

			self.battleNetFriends[accountInfo.bnetAccountID] = friendData

			-- Also index by character name if available
			if characterName then
				local fullName = realmName and (characterName .. '-' .. realmName) or characterName
				self.battleNetFriends[fullName] = friendData
			end

			-- Classify into in-game vs app-only for separated display
			if accountInfo.isOnline then
				if GameClients.IsAppClient(clientProgram) then
					self.battleNetAppOnly[accountInfo.bnetAccountID] = friendData
					self.numBattleNetAppOnly = self.numBattleNetAppOnly + 1
				else
					self.battleNetInGame[accountInfo.bnetAccountID] = friendData
					self.numBattleNetInGame = self.numBattleNetInGame + 1
				end
			end
		end
	end
end

function Friends:RefreshGuildMembers()
	wipe(self.guildMembers)

	if not IsInGuild() then
		self.numGuildMembers = 0
		self.numGuildOnline = 0
		return
	end

	self.numGuildMembers = GetNumGuildMembers() or 0
	self.numGuildOnline = 0

	for i = 1, self.numGuildMembers do
		local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile = GetGuildRosterInfo(i)
		if name then
			local shortName = Ambiguate(name, 'none')
			self.guildMembers[shortName] = {
				fullName = name,
				name = shortName,
				rank = rank,
				rankIndex = rankIndex,
				level = level,
				class = class,
				classFileName = classFileName,
				zone = zone,
				note = note,
				officernote = officernote,
				online = online,
				status = status,
				mobile = isMobile,
			}

			if online then
				self.numGuildOnline = self.numGuildOnline + 1
			end
		end
	end
end

---Check if a player is a character friend
---@param name string Player name
---@return boolean
function Friends:IsCharacterFriend(name)
	if not name then
		return false
	end
	local shortName = Ambiguate(name, 'none')
	return self.characterFriends[shortName] ~= nil or self.characterFriends[name] ~= nil
end

---Check if a player is a Battle.net friend
---@param name string Player name or Battle.net account ID
---@return boolean
function Friends:IsBattleNetFriend(name)
	if not name then
		return false
	end
	local shortName = Ambiguate(name, 'none')
	return self.battleNetFriends[shortName] ~= nil or self.battleNetFriends[name] ~= nil
end

---Check if a player is a guild member
---@param name string Player name
---@return boolean
function Friends:IsGuildMember(name)
	if not name then
		return false
	end
	local shortName = Ambiguate(name, 'none')
	return self.guildMembers[shortName] ~= nil or self.guildMembers[name] ~= nil
end

---Check if a player is any type of friend
---@param name string Player name
---@return boolean
function Friends:IsFriend(name)
	return self:IsCharacterFriend(name) or self:IsBattleNetFriend(name)
end

---Check if a player should be treated as a friend (including guild/community)
---@param name string Player name
---@return boolean
function Friends:IsTreatedAsFriend(name)
	-- Check if actual friend
	if self:IsFriend(name) then
		return true
	end

	local db = LibsSocial.db.profile.friendTreatment

	-- Check guild treatment
	if db.guildAsFriends and self:IsGuildMember(name) then
		return true
	end

	-- Check community treatment (not implemented yet)
	-- if db.communityAsFriends and self:IsCommunityMember(name) then
	--     return true
	-- end

	return false
end

---Get total online count
---@return number
function Friends:GetTotalOnline()
	return self.numCharacterOnline + self.numBattleNetOnline + self.numGuildOnline
end

---Get total friend count
---@return number
function Friends:GetTotalCount()
	return self.numCharacterFriends + self.numBattleNetFriends + self.numGuildMembers
end

---Get game client counts for online BNet friends (deduplicated by accountID)
---@return table<string, number> counts Keyed by display tag (e.g., "WoW", "D4", "OW"), values are counts
function Friends:GetGameCounts()
	local GC = LibsSocial.GameClients
	local counts = {}
	local seen = {}

	for _, info in pairs(self.battleNetFriends) do
		if info.isOnline and info.accountID and not seen[info.accountID] then
			seen[info.accountID] = true
			local client = info.clientProgram
			if client and client ~= '' then
				local tag = GC.GetClientDisplayName(client)
				counts[tag] = (counts[tag] or 0) + 1
			end
		end
	end

	return counts
end
