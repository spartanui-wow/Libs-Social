---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

local LDB = LibStub('LibDataBroker-1.1')
local QTip = LibStub('LibQTip-2.0')

-- Tooltip key for LibQTip-2.0
local TOOLTIP_KEY = 'LibsSocialTooltip'

-- Color constants
local COLORS = {
	realid = '00A2E8',
	friends = 'FFFFFF',
	guild = '00FF00',
	mobile = 'CCCCCC',
	separator = 'FFD200',
	offline = '808080',
	online = '40FF40',
	sameZone = '00FF00',
}

-- Section header color tables
local SECTION_COLORS = {
	bnet = { r = 0, g = 0.64, b = 0.91 },
	friends = { r = 1, g = 1, b = 1 },
	guild = { r = 0, g = 1, b = 0 },
}

-- Status icon textures
local STATUS_ICON_AFK = '|TInterface\\FriendsFrame\\StatusIcon-Away:0|t'
local STATUS_ICON_DND = '|TInterface\\FriendsFrame\\StatusIcon-DnD:0|t'

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
			-- Hijack: hide the GameTooltip and show our custom tooltip instead
			local owner = tooltip:GetOwner()
			tooltip:Hide()
			local anchor = owner or tooltip
			LibsSocial:ShowCustomTooltip(anchor)
		end,
	})

	self.dataObject = socialLDB
	self:UpdateDisplay()
end

function LibsSocial:UpdateDisplay()
	if not socialLDB then
		return
	end

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
		if db.colorCodedCounts then
			if Friends.numBattleNetFriends > 0 then
				table.insert(parts, string.format('|cff%sB:%d/%d|r', COLORS.realid, Friends.numBattleNetOnline, Friends.numBattleNetFriends))
			end
			if Friends.numCharacterFriends > 0 then
				table.insert(parts, string.format('|cff%sF:%d/%d|r', COLORS.friends, Friends.numCharacterOnline, Friends.numCharacterFriends))
			end
			if IsInGuild() then
				table.insert(parts, string.format('|cff%sG:%d/%d|r', COLORS.guild, Friends.numGuildOnline, Friends.numGuildMembers))
			end
		else
			if Friends.numBattleNetFriends > 0 then
				table.insert(parts, string.format('B:%d/%d', Friends.numBattleNetOnline, Friends.numBattleNetFriends))
			end
			if Friends.numCharacterFriends > 0 then
				table.insert(parts, string.format('F:%d/%d', Friends.numCharacterOnline, Friends.numCharacterFriends))
			end
			if IsInGuild() then
				table.insert(parts, string.format('G:%d/%d', Friends.numGuildOnline, Friends.numGuildMembers))
			end
		end
		text = table.concat(parts, ' | ')
	else -- 'combined' default
		local totalOnline = Friends:GetTotalOnline()
		local totalFriends = Friends:GetTotalCount()
		text = string.format('Friends: %d/%d', totalOnline, totalFriends)
	end

	-- Apply color coding (skip if colorCodedCounts already applied colors)
	if db.colorByStatus and not (format == 'detailed' and db.colorCodedCounts) then
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

---Format a status string for a player (icon or text based on settings)
---@param afk boolean Is AFK
---@param dnd boolean Is DND/Busy
---@param mobile boolean? Is on mobile
---@return string status Formatted status string
local function FormatStatus(afk, dnd, mobile)
	local db = LibsSocial.db.profile.display.tooltip

	local status = ''
	if mobile then
		status = ' |cffcccccc(Mobile)|r'
	end

	if afk then
		if db.useStatusIcons then
			status = ' ' .. STATUS_ICON_AFK .. status
		else
			status = ' |cffffff00<AFK>|r' .. status
		end
	elseif dnd then
		if db.useStatusIcons then
			status = ' ' .. STATUS_ICON_DND .. status
		else
			status = ' |cffff0000<DND>|r' .. status
		end
	end

	return status
end

---Format zone text with same-zone highlighting
---@param zone string? Zone name
---@return string zoneText Formatted zone text
---@return number r Red
---@return number g Green
---@return number b Blue
local function FormatZone(zone)
	if not zone or zone == '' then
		return '', 0.7, 0.7, 0.7
	end

	local db = LibsSocial.db.profile.display.tooltip
	local playerZone = LibsSocial.Friends.playerZone

	if db.highlightSameZone and playerZone ~= '' and zone == playerZone then
		return zone, 0, 1, 0
	end

	return zone, 0.7, 0.7, 0.7
end

---Get a group indicator prefix if the player is in the current group/raid
---@param name string Character name (may include realm)
---@return string indicator Green checkmark prefix or empty string
local function GetGroupIndicator(name)
	if not name or name == '' then
		return ''
	end

	-- Try both the raw name and the ambiguated version
	local short = Ambiguate(name, 'none')
	if UnitInParty(short) or UnitInRaid(short) or UnitInParty(name) or UnitInRaid(name) then
		return '|cff00ff00\226\156\147|r ' -- Green checkmark ✓
	end

	return ''
end

---Sort a list of player tables by the configured sort field and direction
---@param players table[] Array of player data tables
---@param sortField string Field name: 'name', 'level', 'class', 'zone', 'rank'
---@param sortDirection string 'asc' or 'desc'
local function SortPlayers(players, sortField, sortDirection)
	local ascending = sortDirection ~= 'desc'

	table.sort(players, function(a, b)
		local valA, valB

		if sortField == 'level' then
			valA = a.level or a.characterLevel or 0
			valB = b.level or b.characterLevel or 0
		elseif sortField == 'class' then
			valA = a.class or a.classFileName or a.className or ''
			valB = b.class or b.classFileName or b.className or ''
		elseif sortField == 'zone' then
			valA = a.area or a.zone or a.areaName or ''
			valB = b.area or b.zone or b.areaName or ''
		elseif sortField == 'rank' then
			valA = a.rankIndex or 99
			valB = b.rankIndex or 99
		else -- 'name' default
			valA = (a.name or a.characterName or ''):lower()
			valB = (b.name or b.characterName or ''):lower()
		end

		if ascending then
			return valA < valB
		else
			return valA > valB
		end
	end)
end

---Add a full-width line (spanning both columns) to the tooltip
---@param tooltip table LibQTip-2.0 tooltip
---@param text string Line text
---@param r number? Red
---@param g number? Green
---@param b number? Blue
local function AddFullLine(tooltip, text, r, g, b)
	local row = tooltip:AddRow(text)
	local cell = row:GetCell(1)
	cell:SetColSpan(2)
	if r then
		cell:SetTextColor(r, g, b)
	end
	return row
end

---Set up a player row with right-click context menu and hover highlight
---Scripts must be set on cells (not rows) because cells have higher frame level and intercept mouse events.
---@param row table LibQTip-2.0 row
---@param playerData table Player data for context menu
---@param numCols number Number of columns in the tooltip
local function SetupPlayerRow(row, playerData, numCols)
	-- LibQTip-2.0's Cell:SetScript injects a nil Parameter arg before the real script args.
	-- So OnMouseDown receives (frame, nil, button) instead of (frame, button).
	-- We use select(2, ...) to skip the injected arg and get the real button.
	local handler = function(frame, ...)
		local button = select(2, ...)
		if button == 'LeftButton' then
			-- Click-to-whisper
			if playerData.accountID then
				ChatFrame_SendSmartTell(playerData.accountName)
			elseif playerData.name then
				ChatFrame_SendTell(playerData.fullName or playerData.name)
			end
		elseif button == 'RightButton' then
			if LibsSocial.PlayerMenu then
				LibsSocial.PlayerMenu:Show(playerData, frame)
			end
		end
	end

	-- Set script on each cell so clicks are captured regardless of which column is clicked
	-- Use OnMouseDown so the menu opens on press (OnMouseUp fires after release + includes extra args)
	for i = 1, numCols do
		local cell = row:GetCell(i)
		if cell then
			cell:SetScript('OnMouseDown', handler)
		else
			LibsSocial:Log('SetupPlayerRow: cell ' .. i .. ' is nil for row', 'warning')
		end
	end
end

---Add a collapsible section header row
---@param tooltip table LibQTip-2.0 tooltip
---@param text string Header text
---@param countText string Right-side count text
---@param sectionKey string Key into collapsedSections
---@param color table? {r,g,b} color
---@return boolean collapsed Whether section is collapsed
local function AddSectionHeader(tooltip, text, countText, sectionKey, color)
	local collapsed = LibsSocial.db.profile.display.collapsedSections[sectionKey] or false
	local arrow = collapsed and '+' or '-'

	local headerText
	if color then
		headerText = string.format('|cffffffff%s|r |cff%02x%02x%02x%s|r', arrow, color.r * 255, color.g * 255, color.b * 255, text)
	else
		headerText = string.format('|cffffffff%s|r %s', arrow, text)
	end

	local row = tooltip:AddRow(headerText, countText)
	row:SetColor(0.15, 0.15, 0.15, 0.5)

	-- Click to toggle collapse — set on cells since they intercept mouse events above rows
	local toggleHandler = function()
		LibsSocial.db.profile.display.collapsedSections[sectionKey] = not collapsed
		-- Rebuild the tooltip
		if LibsSocial.activeAnchor then
			LibsSocial:ShowCustomTooltip(LibsSocial.activeAnchor)
		end
	end

	row:GetCell(1):SetScript('OnMouseDown', toggleHandler)
	row:GetCell(2):SetScript('OnMouseDown', toggleHandler)

	return collapsed
end

---Show the custom tooltip anchored to a frame
---@param anchor Frame The frame to anchor to
function LibsSocial:ShowCustomTooltip(anchor)
	-- Release any existing tooltip
	if QTip:IsAcquiredTooltip(TOOLTIP_KEY) then
		QTip:ReleaseTooltip(self.activeTooltip)
	end

	-- Store anchor for rebuilds (collapsible sections)
	self.activeAnchor = anchor

	-- Acquire 2-column tooltip (name left, zone right)
	local tooltip = QTip:AcquireTooltip(TOOLTIP_KEY, 2, 'LEFT', 'RIGHT')
	self.activeTooltip = tooltip

	-- Configure max height for scrolling
	tooltip:SetMaxHeight(UIParent:GetHeight() * 0.6)

	-- Build content
	self:BuildTooltipContent(tooltip)

	-- Anchor + auto-hide
	tooltip:SmartAnchorTo(anchor)
	tooltip:SetAutoHideDelay(0.25, anchor)
	tooltip:UpdateLayout()
	tooltip:Show()
end

---Build all tooltip content sections
---@param tooltip table LibQTip-2.0 tooltip
function LibsSocial:BuildTooltipContent(tooltip)
	local Friends = self.Friends
	local TT = self.Tooltip
	local GC = self.GameClients
	local db = self.db.profile
	local ttDb = db.display.tooltip

	-- Title
	local titleRow = tooltip:AddHeadingRow("Lib's Social")
	titleRow:GetCell(1):SetColSpan(2)

	-- "Who's Playing What" summary line
	local gameCounts = Friends:GetGameCounts()
	local sortedGames = {}
	for tag, count in pairs(gameCounts) do
		table.insert(sortedGames, { tag = tag, count = count })
	end
	table.sort(sortedGames, function(a, b)
		return a.count > b.count
	end)
	if #sortedGames > 0 then
		local parts = {}
		for _, entry in ipairs(sortedGames) do
			table.insert(parts, entry.tag .. ': ' .. entry.count)
		end
		AddFullLine(tooltip, table.concat(parts, '  |  '), 0.6, 0.6, 0.6)
	end

	if ttDb.groupMode == 'activity' then
		-- Activity-based grouping: organize all players by what they're doing
		self:BuildActivityGroupedContent(tooltip, Friends, TT, GC, ttDb)
	else
		-- Default grouping: BNet / Friends / Guild sections

		-- Battle.net Friends
		if Friends.numBattleNetFriends > 0 then
			if ttDb.separateBNetSections then
				self:BuildBNetInGameSection(tooltip, Friends, TT, GC, ttDb)
				self:BuildBNetAppSection(tooltip, Friends, TT, GC, ttDb)
			else
				self:BuildBNetCombinedSection(tooltip, Friends, TT, GC, ttDb)
			end
		end

		-- Character Friends Section
		if Friends.numCharacterFriends > 0 then
			tooltip:AddSeparator()
			local collapsed = AddSectionHeader(
				tooltip,
				'Friends',
				string.format('|cff%s%d online|r', Friends.numCharacterOnline > 0 and COLORS.online or COLORS.offline, Friends.numCharacterOnline),
				'characterFriends',
				SECTION_COLORS.friends
			)

			if not collapsed then
				-- Collect online friends into sortable array
				local onlineFriends = {}
				for name, info in pairs(Friends.characterFriends) do
					if info.connected then
						info._sortName = name
						table.insert(onlineFriends, info)
					end
				end
				SortPlayers(onlineFriends, ttDb.sortField or 'name', ttDb.sortDirection or 'asc')

				for _, info in ipairs(onlineFriends) do
					local name = info._sortName
					local groupIcon = GetGroupIndicator(name)
					local coloredName = TT:ColorName(name, info.class)
					local leftParts = { groupIcon .. coloredName }

					if ttDb.showLevels then
						table.insert(leftParts, ' (' .. TT:ColorLevel(info.level or 0) .. ')')
					end

					local status = FormatStatus(false, false, info.mobile)
					if status ~= '' then
						table.insert(leftParts, status)
					end

					local leftStr = table.concat(leftParts)
					local zone, zr, zg, zb = FormatZone(info.area)
					local rightStr = ttDb.showZones and zone or nil

					local row = tooltip:AddRow(leftStr, rightStr)
					if rightStr and rightStr ~= '' then
						row:GetCell(2):SetTextColor(zr, zg, zb)
					end

					SetupPlayerRow(row, {
						name = name,
						fullName = name,
						class = info.class,
						level = info.level,
					}, 2)

					-- Notes
					if ttDb.showNotes and info.notes and info.notes ~= '' then
						AddFullLine(tooltip, '   |cffaaaaaa' .. info.notes .. '|r')
					end
				end
			end
		end

		-- Guild Section
		if IsInGuild() then
			local guildName = GetGuildInfo('player')

			tooltip:AddSeparator()
			local collapsed = AddSectionHeader(
				tooltip,
				'Guild: ' .. (guildName or ''),
				string.format('|cff%s%d online|r', Friends.numGuildOnline > 0 and COLORS.online or COLORS.offline, Friends.numGuildOnline),
				'guild',
				SECTION_COLORS.guild
			)

			if not collapsed then
				-- Collect online guild members and sort
				local onlineGuild = {}
				for _, info in pairs(Friends.guildMembers) do
					if info.online then
						table.insert(onlineGuild, info)
					end
				end
				SortPlayers(onlineGuild, ttDb.sortField or 'name', ttDb.sortDirection or 'asc')

				for _, info in ipairs(onlineGuild) do
					local groupIcon = GetGroupIndicator(info.fullName or info.name)
					local coloredName = TT:ColorName(info.name, info.classFileName)
					local leftParts = { groupIcon .. coloredName }

					if ttDb.showLevels then
						table.insert(leftParts, ' (' .. TT:ColorLevel(info.level or 0) .. ')')
					end

					if ttDb.showRank and info.rank then
						table.insert(leftParts, ' |cffaaaaaa' .. info.rank .. '|r')
					end

					local status = FormatStatus(info.status == 1, info.status == 2, info.mobile)
					if status ~= '' then
						table.insert(leftParts, status)
					end

					local leftStr = table.concat(leftParts)
					local zone, zr, zg, zb = FormatZone(info.zone)
					local rightStr = ttDb.showZones and zone or nil

					local row = tooltip:AddRow(leftStr, rightStr)
					if rightStr and rightStr ~= '' then
						row:GetCell(2):SetTextColor(zr, zg, zb)
					end

					SetupPlayerRow(row, {
						name = info.name,
						fullName = info.fullName,
						class = info.classFileName or info.class,
						level = info.level,
						rank = info.rank,
					}, 2)

					-- Notes
					if ttDb.showNotes and info.note and info.note ~= '' then
						AddFullLine(tooltip, '   |cffaaaaaa' .. info.note .. '|r')
					end
					if ttDb.showOfficerNotes and info.officernote and info.officernote ~= '' then
						AddFullLine(tooltip, '   |cffff8800[O] ' .. info.officernote .. '|r')
					end
				end
			end
		end
	end -- end of default groupMode else block

	-- Status info
	tooltip:AddSeparator()
	local blockStatus = db.blocking.enabled and '|cff00ff00On|r' or '|cffff0000Off|r'
	local acceptStatus = db.autoAccept.enabled and '|cff00ff00On|r' or '|cffff0000Off|r'
	AddFullLine(tooltip, string.format('Block: %s | Auto-accept: %s', blockStatus, acceptStatus), 0.6, 0.6, 0.6)

	-- Click hints
	tooltip:AddSeparator()
	AddFullLine(tooltip, '|cffffff00Left Click:|r Friends  |cffffff00Right:|r Cycle Format  |cffffff00Middle:|r Guild', 0.5, 0.5, 0.5)
	AddFullLine(tooltip, '|cffffff00Shift+Left:|r Options  |cffffff00Left-click player:|r Whisper  |cffffff00Right-click player:|r Menu', 0.5, 0.5, 0.5)

	-- Apply extra width if configured
	local extraWidth = db.display.tooltip.extraWidth or 0
	if extraWidth > 0 then
		-- Set min width on title cell to force tooltip wider
		titleRow:GetCell(1):SetMinWidth(300 + extraWidth)
	end
end

---Build activity-grouped content: classifies all online players into activity buckets
---Buckets: In My Group → In My Zone → Available → Busy/AFK → Other Games
---@param tooltip table LibQTip-2.0 tooltip
---@param Friends table Friends data
---@param TT table Tooltip helpers
---@param GC table GameClients
---@param ttDb table Tooltip settings
function LibsSocial:BuildActivityGroupedContent(tooltip, Friends, TT, GC, ttDb)
	-- Classification buckets
	local buckets = {
		{ key = 'inGroup', name = 'In My Group', color = { r = 0, g = 1, b = 0 }, players = {} },
		{ key = 'inZone', name = 'In My Zone', color = { r = 0, g = 0.8, b = 1 }, players = {} },
		{ key = 'available', name = 'Available', color = { r = 1, g = 1, b = 1 }, players = {} },
		{ key = 'busy', name = 'Busy / AFK', color = { r = 1, g = 0.5, b = 0 }, players = {} },
		{ key = 'otherGames', name = 'Other Games', color = { r = 0.6, g = 0.6, b = 0.6 }, players = {} },
	}

	local playerZone = Friends.playerZone

	---Classify a single player into a bucket
	---@param playerInfo table Normalized player info
	local function ClassifyPlayer(playerInfo)
		-- Non-WoW BNet friend (not app)
		if playerInfo.clientProgram and playerInfo.clientProgram ~= 'WoW' and not GC.IsAppClient(playerInfo.clientProgram) then
			table.insert(buckets[5].players, playerInfo)
			return
		end

		-- Skip app-only clients
		if playerInfo.clientProgram and GC.IsAppClient(playerInfo.clientProgram) then
			return
		end

		-- Check if in player's group
		local checkName = playerInfo.fullName or playerInfo.name or ''
		local shortName = checkName ~= '' and Ambiguate(checkName, 'none') or ''
		if shortName ~= '' and (UnitInParty(shortName) or UnitInRaid(shortName)) then
			table.insert(buckets[1].players, playerInfo)
			return
		end

		-- Check same zone
		local zone = playerInfo.area or playerInfo.zone or playerInfo.areaName or ''
		if playerZone ~= '' and zone == playerZone then
			table.insert(buckets[2].players, playerInfo)
			return
		end

		-- Check AFK/DND
		if
			playerInfo.isAFK
			or playerInfo.isDND
			or playerInfo.isBnetAFK
			or playerInfo.isBnetDND
			or playerInfo.isGameAFK
			or playerInfo.isGameBusy
			or playerInfo.status == 1
			or playerInfo.status == 2
		then
			table.insert(buckets[4].players, playerInfo)
			return
		end

		-- Available
		table.insert(buckets[3].players, playerInfo)
	end

	-- Classify character friends
	for name, info in pairs(Friends.characterFriends) do
		if info.connected then
			ClassifyPlayer({
				name = name,
				fullName = name,
				level = info.level,
				class = info.class,
				area = info.area,
				isAFK = false,
				isDND = false,
				mobile = info.mobile,
				source = 'friend',
			})
		end
	end

	-- Classify BNet friends (deduplicated by accountID)
	local seenAccounts = {}
	for _, info in pairs(Friends.battleNetFriends) do
		if info.isOnline and info.accountID and not seenAccounts[info.accountID] then
			seenAccounts[info.accountID] = true
			ClassifyPlayer({
				name = info.characterName,
				fullName = info.characterName,
				accountID = info.accountID,
				accountName = info.accountName or info.battleTag,
				battleTag = info.battleTag,
				characterName = info.characterName,
				realmName = info.realmName,
				level = info.characterLevel,
				className = info.className,
				areaName = info.areaName,
				clientProgram = info.clientProgram,
				isBnetAFK = info.isBnetAFK,
				isBnetDND = info.isDND,
				isGameAFK = info.isGameAFK,
				isGameBusy = info.isGameBusy,
				wowProjectID = info.wowProjectID,
				source = 'bnet',
			})
		end
	end

	-- Classify guild members
	for _, info in pairs(Friends.guildMembers) do
		if info.online then
			ClassifyPlayer({
				name = info.name,
				fullName = info.fullName,
				level = info.level,
				class = info.class,
				classFileName = info.classFileName,
				zone = info.zone,
				rank = info.rank,
				rankIndex = info.rankIndex,
				status = info.status,
				mobile = info.mobile,
				source = 'guild',
			})
		end
	end

	-- Render each non-empty bucket
	for _, bucket in ipairs(buckets) do
		if #bucket.players > 0 then
			SortPlayers(bucket.players, ttDb.sortField or 'name', ttDb.sortDirection or 'asc')

			tooltip:AddSeparator()
			local collapsed = AddSectionHeader(tooltip, bucket.name, string.format('|cff%s%d|r', COLORS.online, #bucket.players), 'activity_' .. bucket.key, bucket.color)

			if not collapsed then
				for _, p in ipairs(bucket.players) do
					-- Build name display
					local leftParts = {}

					if p.accountID then
						-- BNet friend: show account tag + character name
						local accountTag = (p.battleTag or p.accountName or 'Unknown'):gsub('#%d+$', '')
						table.insert(leftParts, string.format('|cff%s%s|r', COLORS.realid, accountTag))
						if p.characterName then
							local charName = TT:ColorName(p.characterName, p.className)
							table.insert(leftParts, '  ' .. charName)
						end
						if p.clientProgram and p.clientProgram ~= 'WoW' and not GC.IsAppClient(p.clientProgram) then
							local clientTag = GC.GetClientDisplayName(p.clientProgram)
							table.insert(leftParts, string.format(' |cffaaaaaa[%s]|r', clientTag))
						end
					else
						-- Character friend or guild member
						local displayClass = p.classFileName or p.class
						local coloredName = TT:ColorName(p.name or '?', displayClass)
						table.insert(leftParts, coloredName)
					end

					if ttDb.showLevels then
						local level = p.level or 0
						if level > 0 then
							table.insert(leftParts, ' (' .. TT:ColorLevel(level) .. ')')
						end
					end

					local leftStr = table.concat(leftParts)

					-- Zone (right side)
					local zone = p.area or p.zone or p.areaName or ''
					local rightStr = nil
					local zr, zg, zb = 0.7, 0.7, 0.7
					if ttDb.showZones and zone ~= '' then
						rightStr, zr, zg, zb = FormatZone(zone)
					end

					local row = tooltip:AddRow(leftStr, rightStr)
					if rightStr and rightStr ~= '' then
						row:GetCell(2):SetTextColor(zr, zg, zb)
					end

					-- Setup player row interactions
					SetupPlayerRow(row, {
						accountID = p.accountID,
						accountName = p.accountName,
						characterName = p.characterName,
						name = p.name,
						fullName = p.fullName,
						realm = p.realmName,
						class = p.classFileName or p.className or p.class,
						level = p.level,
						rank = p.rank,
						battleTag = p.battleTag,
					}, 2)
				end
			end
		end
	end
end

---Build BNet In-Game section
---@param tooltip table LibQTip-2.0 tooltip
---@param Friends table Friends data
---@param TT table Tooltip helpers
---@param GC table GameClients
---@param ttDb table Tooltip settings
function LibsSocial:BuildBNetInGameSection(tooltip, Friends, TT, GC, ttDb)
	if Friends.numBattleNetInGame == 0 then
		return
	end

	tooltip:AddSeparator()
	local collapsed = AddSectionHeader(tooltip, 'Battle.net (In Game)', string.format('|cff%s%d|r', COLORS.online, Friends.numBattleNetInGame), 'battleNetInGame', SECTION_COLORS.bnet)

	if not collapsed then
		for _, info in pairs(Friends.battleNetInGame) do
			self:AddBNetFriendLine(tooltip, TT, GC, ttDb, info)
		end
	end
end

---Build BNet App/Launcher section
---@param tooltip table LibQTip-2.0 tooltip
---@param Friends table Friends data
---@param TT table Tooltip helpers
---@param GC table GameClients
---@param ttDb table Tooltip settings
function LibsSocial:BuildBNetAppSection(tooltip, Friends, TT, GC, ttDb)
	if Friends.numBattleNetAppOnly == 0 then
		return
	end

	tooltip:AddSeparator()
	local collapsed = AddSectionHeader(tooltip, 'Battle.net (App)', string.format('|cff%s%d|r', COLORS.offline, Friends.numBattleNetAppOnly), 'battleNetApp', SECTION_COLORS.bnet)

	if not collapsed then
		for _, info in pairs(Friends.battleNetAppOnly) do
			self:AddBNetFriendLine(tooltip, TT, GC, ttDb, info)
		end
	end
end

---Build combined BNet section (when separateBNetSections is off)
---@param tooltip table LibQTip-2.0 tooltip
---@param Friends table Friends data
---@param TT table Tooltip helpers
---@param GC table GameClients
---@param ttDb table Tooltip settings
function LibsSocial:BuildBNetCombinedSection(tooltip, Friends, TT, GC, ttDb)
	tooltip:AddSeparator()
	local collapsed = AddSectionHeader(
		tooltip,
		'Battle.net',
		string.format('|cff%s%d online|r', Friends.numBattleNetOnline > 0 and COLORS.online or COLORS.offline, Friends.numBattleNetOnline),
		'battleNetInGame',
		SECTION_COLORS.bnet
	)

	if not collapsed then
		-- Deduplicate: only process by accountID
		local seen = {}
		for _, info in pairs(Friends.battleNetFriends) do
			if info.isOnline and info.accountID and not seen[info.accountID] then
				seen[info.accountID] = true
				self:AddBNetFriendLine(tooltip, TT, GC, ttDb, info)
			end
		end
	end
end

---Add a single BNet friend line to the tooltip
---@param tooltip table LibQTip-2.0 tooltip
---@param TT table Tooltip helpers
---@param GC table GameClients
---@param ttDb table Tooltip settings
---@param info table Friend data
function LibsSocial:AddBNetFriendLine(tooltip, TT, GC, ttDb, info)
	local accountTag = info.battleTag or info.accountName or 'Unknown'
	accountTag = accountTag:gsub('#%d+$', '')

	local groupIcon = info.characterName and GetGroupIndicator(info.characterName) or ''
	local leftParts = { groupIcon .. string.format('|cff%s%s|r', COLORS.realid, accountTag) }

	-- Character info for WoW players
	if info.characterName then
		local charName = TT:ColorName(info.characterName, info.className)
		table.insert(leftParts, '  ' .. charName)

		if ttDb.showLevels and info.characterLevel and info.characterLevel > 0 then
			table.insert(leftParts, ' (' .. TT:ColorLevel(info.characterLevel) .. ')')
		end
	end

	-- Game client tag for non-WoW games
	if ttDb.showGameClient and info.clientProgram and info.clientProgram ~= 'WoW' and not GC.IsAppClient(info.clientProgram) then
		local clientTag = GC.GetClientDisplayName(info.clientProgram)
		table.insert(leftParts, string.format(' |cffaaaaaa[%s]|r', clientTag))
	end

	-- WoW project label (only if different from player's)
	if ttDb.showWowProject and info.clientProgram == 'WoW' and info.wowProjectID then
		local myProject = WOW_PROJECT_ID
		if info.wowProjectID ~= myProject then
			local label = GC.GetProjectLabel(info.wowProjectID)
			table.insert(leftParts, string.format(' |cffcccccc(%s)|r', label))
		end
	end

	-- Status
	local isAFK = info.isBnetAFK or info.isGameAFK
	local isDND = info.isBnetDND or info.isGameBusy
	local status = FormatStatus(isAFK, isDND, false)
	if status ~= '' then
		table.insert(leftParts, status)
	end

	local leftStr = table.concat(leftParts)

	-- Zone (right side)
	local rightStr = nil
	local zr, zg, zb = 0.7, 0.7, 0.7
	if ttDb.showZones and info.areaName and info.areaName ~= '' then
		rightStr, zr, zg, zb = FormatZone(info.areaName)
	end

	local row = tooltip:AddRow(leftStr, rightStr)
	if rightStr and rightStr ~= '' then
		row:GetCell(2):SetTextColor(zr, zg, zb)
	end

	SetupPlayerRow(row, {
		accountID = info.accountID,
		accountName = info.accountName or info.battleTag,
		characterName = info.characterName,
		realm = info.realmName,
		class = info.className,
		level = info.characterLevel,
		battleTag = info.battleTag,
	}, 2)

	-- Broadcast message
	if ttDb.showBroadcasts and info.customMessage and info.customMessage ~= '' then
		AddFullLine(tooltip, '   |cff00A2E8' .. info.customMessage .. '|r')
	end

	-- Note
	if ttDb.showNotes and info.noteText and info.noteText ~= '' then
		AddFullLine(tooltip, '   |cffaaaaaa' .. info.noteText .. '|r')
	end
end
