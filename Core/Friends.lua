---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

---@class LibsSocial.Friends : AceModule
local Friends = LibsSocial:NewModule('Friends')
LibsSocial.Friends = Friends

function Friends:OnInitialize()
	self.characterFriends = {}
	self.battleNetFriends = {}
	self.battleNetInGame = {}
	self.battleNetAppOnly = {}
	self.guildMembers = {}
	self.communityMembers = {}

	self.numCharacterFriends = 0
	self.numCharacterOnline = 0
	self.numBattleNetFriends = 0
	self.numBattleNetOnline = 0
	self.numBattleNetInGame = 0
	self.numBattleNetAppOnly = 0
	self.numGuildMembers = 0
	self.numGuildOnline = 0

	self.playerZone = ''
end

function Friends:OnEnable()
	self:RefreshData()
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
			local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(i)
			local bestGameInfo = accountInfo.gameAccountInfo
			local bestIsApp = GameClients.IsAppClient(bestGameInfo and bestGameInfo.clientProgram)

			if numGameAccounts > 1 then
				for j = 1, numGameAccounts do
					local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)
					if gameAccountInfo then
						local isApp = GameClients.IsAppClient(gameAccountInfo.clientProgram)
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

			if characterName then
				local fullName = realmName and (characterName .. '-' .. realmName) or characterName
				self.battleNetFriends[fullName] = friendData
			end

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

---@param name string
---@return boolean
function Friends:IsCharacterFriend(name)
	if not name then
		return false
	end
	local shortName = Ambiguate(name, 'none')
	return self.characterFriends[shortName] ~= nil or self.characterFriends[name] ~= nil
end

---@param name string
---@return boolean
function Friends:IsBattleNetFriend(name)
	if not name then
		return false
	end
	local shortName = Ambiguate(name, 'none')
	return self.battleNetFriends[shortName] ~= nil or self.battleNetFriends[name] ~= nil
end

---@param name string
---@return boolean
function Friends:IsGuildMember(name)
	if not name then
		return false
	end
	local shortName = Ambiguate(name, 'none')
	return self.guildMembers[shortName] ~= nil or self.guildMembers[name] ~= nil
end

---@param name string
---@return boolean
function Friends:IsFriend(name)
	return self:IsCharacterFriend(name) or self:IsBattleNetFriend(name)
end

---@param name string
---@return boolean
function Friends:IsTreatedAsFriend(name)
	if self:IsFriend(name) then
		return true
	end

	local db = LibsSocial.db.profile.friendTreatment

	if db.guildAsFriends and self:IsGuildMember(name) then
		return true
	end

	return false
end

---@return number
function Friends:GetTotalOnline()
	return self.numCharacterOnline + self.numBattleNetOnline + self.numGuildOnline
end

---@return number
function Friends:GetTotalCount()
	return self.numCharacterFriends + self.numBattleNetFriends + self.numGuildMembers
end

---@return table<string, number>
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
