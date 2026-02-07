---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

local LDB = LibStub('LibDataBroker-1.1')

-- Color constants
local COLORS = {
	realid = '00A2E8',
	friends = 'FFFFFF',
	guild = '00FF00',
	mobile = 'CCCCCC',
	separator = 'FFD200',
	offline = '808080',
	online = '40FF40',
}

-- Mobile icons
local MOBILE_HERE_ICON = '|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat:0:0:0:0:16:16:0:16:0:16:73:177:73|t'
local MOBILE_BUSY_ICON = '|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat-BusyMobile:0:0:0:0:16:16:0:16:0:16|t'
local MOBILE_AWAY_ICON = '|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat-AwayMobile:0:0:0:0:16:16:0:16:0:16|t'

-- Create the LibDataBroker object
local socialLDB

function LibsSocial:InitializeDataBroker()
	socialLDB = LDB:NewDataObject("Lib's Social", {
		type = 'data source',
		text = 'Loading...',
		icon = 'Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon',
		label = 'Social',
		OnClick = function(frame, button)
			if button == 'LeftButton' then
				if IsShiftKeyDown() then
					LibsSocial:OpenOptions()
				else
					ToggleFriendsFrame()
				end
			elseif button == 'RightButton' then
				LibsSocial:CycleDisplayFormat()
			elseif button == 'MiddleButton' then
				if IsInGuild() then
					ToggleGuildFrame()
				else
					LibsSocial:Log('You are not in a guild', 'info')
				end
			end
		end,
		OnTooltipShow = function(tooltip)
			LibsSocial:BuildTooltip(tooltip)
		end,
	})

	self.dataObject = socialLDB
	self:UpdateDisplay()
end

function LibsSocial:UpdateDisplay()
	if not socialLDB then
		return
	end

	local db = self.db.profile.display
	local Friends = self.Friends

	local text = self:GetDisplayText()
	socialLDB.text = text

	-- Update icon based on online status
	local totalOnline = Friends:GetTotalOnline()
	if totalOnline > 0 then
		socialLDB.icon = 'Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon'
	else
		socialLDB.icon = 'Interface\\FriendsFrame\\UI-Toast-FriendOfflineIcon'
	end
end

function LibsSocial:GetDisplayText()
	local db = self.db.profile.display
	local Friends = self.Friends

	local text = ''
	local format = db.format

	if format == 'friends' then
		text = string.format('Friends: %d/%d', Friends.numCharacterOnline, Friends.numCharacterFriends)
	elseif format == 'guild' then
		if IsInGuild() then
			text = string.format('Guild: %d/%d', Friends.numGuildOnline, Friends.numGuildMembers)
		else
			text = 'Guild: None'
		end
	elseif format == 'realid' then
		text = string.format('Battle.net: %d/%d', Friends.numBattleNetOnline, Friends.numBattleNetFriends)
	elseif format == 'detailed' then
		local parts = {}
		if Friends.numCharacterFriends > 0 then
			table.insert(parts, string.format('F:%d/%d', Friends.numCharacterOnline, Friends.numCharacterFriends))
		end
		if Friends.numBattleNetFriends > 0 then
			table.insert(parts, string.format('B:%d/%d', Friends.numBattleNetOnline, Friends.numBattleNetFriends))
		end
		if IsInGuild() then
			table.insert(parts, string.format('G:%d/%d', Friends.numGuildOnline, Friends.numGuildMembers))
		end
		text = table.concat(parts, ' | ')
	else -- 'combined' default
		local totalOnline = Friends:GetTotalOnline()
		local totalFriends = Friends:GetTotalCount()
		text = string.format('Friends: %d/%d', totalOnline, totalFriends)
	end

	-- Apply color coding
	if db.colorByStatus then
		local totalOnline = Friends:GetTotalOnline()
		if totalOnline > 0 then
			text = '|cFF' .. COLORS.online .. text .. '|r'
		else
			text = '|cFF' .. COLORS.offline .. text .. '|r'
		end
	end

	return text
end

function LibsSocial:CycleDisplayFormat()
	local formats = { 'combined', 'friends', 'guild', 'realid', 'detailed' }
	local current = self.db.profile.display.format
	local currentIndex = 1

	for i, format in ipairs(formats) do
		if format == current then
			currentIndex = i
			break
		end
	end

	local nextIndex = currentIndex < #formats and currentIndex + 1 or 1
	self.db.profile.display.format = formats[nextIndex]

	self:Log('Display format: ' .. formats[nextIndex], 'info')
	self:UpdateDisplay()
end

function LibsSocial:BuildTooltip(tooltip)
	local Friends = self.Friends
	local TT = self.Tooltip
	local db = self.db.profile

	tooltip:SetText("Lib's Social")

	-- Battle.net Friends Section
	if Friends.numBattleNetFriends > 0 then
		tooltip:AddLine(' ')
		tooltip:AddDoubleLine(
			string.format('|cff%sBattle.net|r', COLORS.realid),
			string.format('|cff%s%d online|r', Friends.numBattleNetOnline > 0 and COLORS.online or COLORS.offline, Friends.numBattleNetOnline)
		)

		-- Sort online BNet friends into a list
		local onlineBNet = {}
		for _, info in pairs(Friends.battleNetFriends) do
			-- Skip duplicate entries (indexed by both accountID and character name)
			if info.isOnline and info.accountID and not onlineBNet[info.accountID] then
				onlineBNet[info.accountID] = info
			end
		end

		for _, info in pairs(onlineBNet) do
			local accountTag = info.battleTag or info.accountName or 'Unknown'
			-- Remove the #number from battletags for cleaner display
			accountTag = accountTag:gsub('#%d+$', '')

			local charInfo = ''
			if info.characterName then
				local charName = TT:ColorName(info.characterName, info.className)
				local realm = info.realmName and ('-' .. info.realmName) or ''
				charInfo = string.format('  %s%s', charName, realm)
			end

			local zone = info.areaName or ''
			local status = ''
			if info.isBnetAFK or info.isGameAFK then
				status = ' |cffffff00<AFK>|r'
			elseif info.isBnetDND or info.isGameBusy then
				status = ' |cffff0000<DND>|r'
			end

			if info.characterName then
				tooltip:AddDoubleLine(
					string.format('|cff%s%s|r%s%s', COLORS.realid, accountTag, charInfo, status),
					zone,
					nil, nil, nil,
					0.7, 0.7, 0.7
				)
			else
				tooltip:AddLine(string.format('|cff%s%s|r%s', COLORS.realid, accountTag, status))
			end
		end
	end

	-- Character Friends Section
	if Friends.numCharacterFriends > 0 then
		tooltip:AddLine(' ')
		tooltip:AddDoubleLine(
			string.format('|cff%sFriends|r', COLORS.friends),
			string.format('|cff%s%d online|r', Friends.numCharacterOnline > 0 and COLORS.online or COLORS.offline, Friends.numCharacterOnline)
		)

		for name, info in pairs(Friends.characterFriends) do
			if info.connected then
				local coloredName = TT:ColorName(name, info.class)
				local levelStr = TT:ColorLevel(info.level or 0)
				local zone = info.area or ''
				local status = ''
				if info.mobile then
					status = ' |cffcccccc(Mobile)|r'
				end

				tooltip:AddDoubleLine(
					string.format('%s (%s %s)%s', coloredName, levelStr, info.class or '??', status),
					zone,
					nil, nil, nil,
					0.7, 0.7, 0.7
				)
			end
		end
	end

	-- Guild Section
	if IsInGuild() then
		local guildName = GetGuildInfo('player')
		tooltip:AddLine(' ')
		tooltip:AddDoubleLine(
			string.format('|cff%sGuild: %s|r', COLORS.guild, guildName or ''),
			string.format('|cff%s%d online|r', Friends.numGuildOnline > 0 and COLORS.online or COLORS.offline, Friends.numGuildOnline)
		)

		-- Sort guild members by rank index (lower = higher rank)
		local onlineGuild = {}
		for _, info in pairs(Friends.guildMembers) do
			if info.online then
				table.insert(onlineGuild, info)
			end
		end
		table.sort(onlineGuild, function(a, b)
			return (a.rankIndex or 99) < (b.rankIndex or 99)
		end)

		for _, info in ipairs(onlineGuild) do
			local coloredName = TT:ColorName(info.name, info.classFileName)
			local zone = info.zone or ''
			local rank = info.rank or ''
			local status = ''
			if info.mobile then
				status = ' |cffcccccc(Mobile)|r'
			end

			tooltip:AddDoubleLine(
				string.format('%s (%s)%s', coloredName, rank, status),
				zone,
				nil, nil, nil,
				0.7, 0.7, 0.7
			)
		end
	end

	-- Status info
	tooltip:AddLine(' ')
	local blockStatus = db.blocking.enabled and '|cff00ff00Enabled|r' or '|cffff0000Disabled|r'
	local acceptStatus = db.autoAccept.enabled and '|cff00ff00Enabled|r' or '|cffff0000Disabled|r'
	tooltip:AddLine(string.format('Blocking: %s | Auto-accept: %s', blockStatus, acceptStatus))

	-- Click hints
	tooltip:AddLine(' ')
	tooltip:AddLine('|cffffff00Left Click:|r Friends | |cffffff00Right:|r Cycle Format')
	tooltip:AddLine('|cffffff00Shift+Left:|r Options | |cffffff00Middle:|r Guild')

	tooltip:Show()
end
