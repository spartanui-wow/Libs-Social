---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

---@class LibsSocial.DataBroker : AceModule
local DataBroker = LibsSocial:NewModule('DataBroker')
LibsSocial.DataBroker = DataBroker

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
local GROUP_ICON = '|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t'

local BNET_CLIENT_WOW = BNET_CLIENT_WOW or 'WoW'

function DataBroker:OnEnable()
	self.socialLDB = LDB:NewDataObject("Lib's Social", {
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
				self:CycleDisplayFormat()
			elseif button == 'MiddleButton' then
				if IsInGuild() then
					ToggleGuildFrame()
				else
					LibsSocial:Log('You are not in a guild', 'info')
				end
			end
		end,
		-- OnEnter instead of OnTooltipShow: displays show the GameTooltip again after OnTooltipShow
		-- returns, which left an empty or hint-only game tooltip over this one
		OnEnter = function(frame)
			self:ShowCustomTooltip(frame)
		end,
		GetOptions = function()
			return {
				type = 'group',
				name = 'Social Settings',
				args = {
					format = {
						type = 'select',
						name = 'Display Format',
						desc = 'How to display friend counts',
						order = 1,
						values = {
							combined = 'Combined (Total)',
							friends = 'Friends Only',
							guild = 'Guild Only',
							realid = 'Battle.net Only',
							detailed = 'Detailed (F/B/G)',
						},
						get = function()
							return LibsSocial.db.profile.display.format
						end,
						set = function(_, val)
							LibsSocial.db.profile.display.format = val
							self:UpdateDisplay()
						end,
					},
					colorByStatus = {
						type = 'toggle',
						name = 'Color by Status',
						desc = 'Color the display text based on online/offline status',
						order = 2,
						get = function()
							return LibsSocial.db.profile.display.colorByStatus
						end,
						set = function(_, val)
							LibsSocial.db.profile.display.colorByStatus = val
							self:UpdateDisplay()
						end,
					},
					colorCodedCounts = {
						type = 'toggle',
						name = 'Color-Coded Counts',
						desc = 'Color each category differently in Detailed format',
						order = 3,
						get = function()
							return LibsSocial.db.profile.display.colorCodedCounts
						end,
						set = function(_, val)
							LibsSocial.db.profile.display.colorCodedCounts = val
							self:UpdateDisplay()
						end,
					},
				},
			}
		end,
	})

	LibsSocial.dataObject = self.socialLDB
	self:UpdateDisplay()

	QTip.RegisterCallback(self, 'OnReleaseTooltip', 'OnReleaseTooltip')
end

function DataBroker:OnDisable()
	QTip.UnregisterCallback(self, 'OnReleaseTooltip')
	if self.activeTooltip and QTip:IsAcquiredTooltip(TOOLTIP_KEY) then
		QTip:ReleaseTooltip(self.activeTooltip)
	end
end

---@param _ string Event name
---@param tooltip table The tooltip being released
function DataBroker:OnReleaseTooltip(_, tooltip)
	if tooltip == self.activeTooltip then
		tooltip.IsMouseOver = nil
		self.activeTooltip = nil
	end
end

function DataBroker:UpdateDisplay()
	if not self.socialLDB then
		return
	end

	local Friends = LibsSocial.Friends

	local text = self:GetDisplayText()
	self.socialLDB.text = text

	-- Update icon based on online status
	local totalOnline = Friends:GetTotalOnline()
	if totalOnline > 0 then
		self.socialLDB.icon = 'Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon'
	else
		self.socialLDB.icon = 'Interface\\FriendsFrame\\UI-Toast-FriendOfflineIcon'
	end
end

function DataBroker:GetDisplayText()
	local db = LibsSocial.db.profile.display
	local Friends = LibsSocial.Friends

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

function DataBroker:CycleDisplayFormat()
	local formats = { 'combined', 'friends', 'guild', 'realid', 'detailed' }
	local current = LibsSocial.db.profile.display.format
	local currentIndex = 1

	for i, format in ipairs(formats) do
		if format == current then
			currentIndex = i
			break
		end
	end

	local nextIndex = currentIndex < #formats and currentIndex + 1 or 1
	LibsSocial.db.profile.display.format = formats[nextIndex]

	LibsSocial:Log('Display format: ' .. formats[nextIndex], 'info')
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
local function IsInMyGroup(name)
	if not name or name == '' or not IsInGroup() then
		return false
	end

	-- Try both the raw name and the short version
	local short = LibsSocial:ShortName(name)
	return (UnitInParty(short) or UnitInRaid(short) or UnitInParty(name) or UnitInRaid(name)) and true or false
end

local function GetGroupIndicator(name)
	if IsInMyGroup(name) then
		return GROUP_ICON .. ' '
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
			-- Battle.net rows lead with the BattleTag, so that is what they are sorted by
			valA = (a.battleTag or a.name or a.characterName or ''):lower()
			valB = (b.battleTag or b.name or b.characterName or ''):lower()
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
	-- Span before setting the text: text set on a one-column cell widens the first column to fit it
	local row = tooltip:AddRow()
	local cell = row:GetCell(1)
	cell:SetColSpan(2)
	cell:SetText(text)
	if r then
		cell:SetTextColor(r, g, b)
	end
	return row
end

-- Copies of LibQTip-2.0 with the same version differ in what a cell script receives when no
-- argument was given: some pass (frame, button), others (frame, nil, button), and whichever
-- addon loads first decides. Always passing an argument gives (frame, arg, button) in both.
local function OnPlayerRowMouseDown(frame, playerData, button)
	if button == 'LeftButton' then
		LibsSocial.PlayerMenu:Whisper(playerData)
	elseif button == 'RightButton' then
		LibsSocial.PlayerMenu:Show(playerData, frame)
	end
end

---Set up a player row with right-click context menu and hover highlight
---Scripts must be set on cells (not rows) because cells have higher frame level and intercept mouse events.
---@param row table LibQTip-2.0 row
---@param playerData table Player data for context menu
---@param numCols number Number of columns in the tooltip
local function SetupPlayerRow(row, playerData, numCols)
	for i = 1, numCols do
		row:GetCell(i):SetScript('OnMouseDown', OnPlayerRowMouseDown, playerData)
	end
end

---Collapse or expand a section and rebuild the tooltip (argument order: see OnPlayerRowMouseDown)
local function OnSectionHeaderMouseDown(_, sectionKey)
	local collapsedSections = LibsSocial.db.profile.display.collapsedSections
	collapsedSections[sectionKey] = not collapsedSections[sectionKey]
	if DataBroker.activeAnchor then
		DataBroker:ShowCustomTooltip(DataBroker.activeAnchor, true)
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

	-- Set on cells since they intercept mouse events above rows
	row:GetCell(1):SetScript('OnMouseDown', OnSectionHeaderMouseDown, sectionKey)
	row:GetCell(2):SetScript('OnMouseDown', OnSectionHeaderMouseDown, sectionKey)

	return collapsed
end

---Counts the open player menu as part of the tooltip, so moving onto a menu that sticks out of
---the tooltip does not hide the tooltip (and the menu with it)
---@param tooltip Frame
---@return boolean
local function TooltipIsMouseOver(tooltip, ...)
	if QTip.FrameMetatable.__index.IsMouseOver(tooltip, ...) then
		return true
	end
	local menuManager = Menu and Menu.GetManager and Menu.GetManager()
	if menuManager and menuManager:IsAnyMenuOpen() then
		local openMenu = menuManager:GetOpenMenu()
		if openMenu and openMenu:IsMouseOver() then
			return true
		end
	end
	return false
end

---Show the custom tooltip anchored to a frame
---@param anchor Frame The frame to anchor to
---@param keepScroll? boolean Keep the scroll position of the tooltip being replaced
function DataBroker:ShowCustomTooltip(anchor, keepScroll)
	local scrollValue
	local previous = self.activeTooltip
	if previous and QTip:IsAcquiredTooltip(TOOLTIP_KEY) then
		if keepScroll and previous.Slider and previous.Slider:IsShown() then
			scrollValue = previous.Slider:GetValue()
		end
		QTip:ReleaseTooltip(previous)
	end

	-- Store anchor for rebuilds (collapsible sections)
	self.activeAnchor = anchor

	-- Acquire 2-column tooltip (name left, zone right)
	local tooltip = QTip:AcquireTooltip(TOOLTIP_KEY, 2, 'LEFT', 'RIGHT')
	self.activeTooltip = tooltip

	-- Tooltip frames are pooled and shared with other addons; this is removed again on release
	tooltip.IsMouseOver = TooltipIsMouseOver

	-- Configure max height for scrolling
	tooltip:SetMaxHeight(UIParent:GetHeight() * 0.6)

	-- Build content
	self:BuildTooltipContent(tooltip)

	-- Anchor + auto-hide
	tooltip:SmartAnchorTo(anchor)
	tooltip:SetAutoHideDelay(0.25, anchor)
	tooltip:UpdateLayout()
	tooltip:Show()

	if scrollValue and tooltip.Slider and tooltip.Slider:IsShown() then
		local _, maxValue = tooltip.Slider:GetMinMaxValues()
		tooltip.Slider:SetValue(math.min(scrollValue, maxValue))
	end
end

---Build all tooltip content sections
---@param tooltip table LibQTip-2.0 tooltip
function DataBroker:BuildTooltipContent(tooltip)
	local Friends = LibsSocial.Friends
	local TT = LibsSocial.Tooltip
	local GC = LibsSocial.GameClients
	local db = LibsSocial.db.profile
	local ttDb = db.display.tooltip

	-- Title. Width settings only count when made before the text is set.
	local titleCell = tooltip:AddHeadingRow():GetCell(1)
	titleCell:SetColSpan(2)
	local extraWidth = ttDb.extraWidth or 0
	if extraWidth > 0 then
		titleCell:SetMinWidth(300 + extraWidth)
	end
	titleCell:SetText("Lib's Social")

	-- "Who's Playing What" summary line
	local gameCounts = Friends:GetGameCounts()
	local sortedGames = {}
	for tag, count in pairs(gameCounts) do
		table.insert(sortedGames, { tag = tag, count = count })
	end
	table.sort(sortedGames, function(a, b)
		if a.count ~= b.count then
			return a.count > b.count
		end
		return a.tag < b.tag
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
				for _, info in pairs(Friends.characterFriends) do
					if info.connected then
						table.insert(onlineFriends, info)
					end
				end
				SortPlayers(onlineFriends, ttDb.sortField or 'name', ttDb.sortDirection or 'asc')

				for _, info in ipairs(onlineFriends) do
					local name = info.name
					local groupIcon = GetGroupIndicator(name)
					local coloredName = TT:ColorName(name, info.class)
					local leftParts = { groupIcon .. coloredName }

					if ttDb.showLevels then
						table.insert(leftParts, ' (' .. TT:ColorLevel(info.level or 0) .. ')')
					end

					local status = FormatStatus(info.afk, info.dnd, info.mobile)
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
						name = LibsSocial:ShortName(name),
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
						className = info.class,
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
end

---True for a Battle.net friend in World of Warcraft on the same version of the game as the player
---@param info table Friend data
---@param GC table GameClients
---@return boolean
local function IsInMyGame(info, GC)
	return info.clientProgram == BNET_CLIENT_WOW and GC.IsSameProject(info.wowProjectID)
end

---Player data handed to the row click handlers and the player menu for a Battle.net friend
---@param info table Friend data
---@return table
local function BNetPlayerData(info)
	return {
		accountID = info.accountID,
		accountName = info.accountName,
		gameAccountID = info.gameAccountID,
		characterName = info.characterName,
		clientProgram = info.clientProgram,
		wowProjectID = info.wowProjectID,
		realm = info.realmName,
		class = info.classFile or info.className,
		className = info.className,
		level = info.characterLevel,
		battleTag = info.battleTag,
	}
end

---Build activity-grouped content: classifies all online players into activity buckets
---Buckets: In My Group -> In My Zone -> Available -> Busy/AFK -> Other Games
---@param tooltip table LibQTip-2.0 tooltip
---@param Friends table Friends data
---@param TT table Tooltip helpers
---@param GC table GameClients
---@param ttDb table Tooltip settings
function DataBroker:BuildActivityGroupedContent(tooltip, Friends, TT, GC, ttDb)
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
		-- Skip app-only clients
		if playerInfo.clientProgram and GC.IsAppClient(playerInfo.clientProgram) then
			return
		end

		-- Another game, or another version of WoW: they cannot be in this group or zone
		if playerInfo.source == 'bnet' and not IsInMyGame(playerInfo, GC) then
			table.insert(buckets[5].players, playerInfo)
			return
		end

		if IsInMyGroup(playerInfo.fullName or playerInfo.name) then
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
	for _, info in pairs(Friends.characterFriends) do
		if info.connected then
			ClassifyPlayer({
				name = LibsSocial:ShortName(info.name),
				fullName = info.name,
				level = info.level,
				class = info.class,
				area = info.area,
				isAFK = info.afk,
				isDND = info.dnd,
				mobile = info.mobile,
				source = 'friend',
			})
		end
	end

	-- Classify BNet friends
	for _, info in pairs(Friends.battleNetFriends) do
		if info.isOnline then
			ClassifyPlayer({
				name = info.characterName,
				fullName = info.characterName,
				accountID = info.accountID,
				accountName = info.accountName,
				gameAccountID = info.gameAccountID,
				battleTag = info.battleTag,
				characterName = info.characterName,
				realmName = info.realmName,
				level = info.characterLevel,
				className = info.className,
				classFile = info.classFile,
				areaName = info.areaName,
				clientProgram = info.clientProgram,
				isBnetAFK = info.isBnetAFK,
				isBnetDND = info.isBnetDND,
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
							local charName = TT:ColorName(p.characterName, p.classFile or p.className)
							table.insert(leftParts, '  ' .. charName)
						end
						if p.clientProgram and p.clientProgram ~= BNET_CLIENT_WOW then
							local clientTag = GC.GetClientDisplayName(p.clientProgram)
							table.insert(leftParts, string.format(' |cffaaaaaa[%s]|r', clientTag))
						elseif ttDb.showWowProject and not GC.IsSameProject(p.wowProjectID) then
							table.insert(leftParts, string.format(' |cffcccccc(%s)|r', GC.GetProjectLabel(p.wowProjectID)))
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

					if p.accountID then
						SetupPlayerRow(row, BNetPlayerData({
							accountID = p.accountID,
							accountName = p.accountName,
							gameAccountID = p.gameAccountID,
							characterName = p.characterName,
							clientProgram = p.clientProgram,
							wowProjectID = p.wowProjectID,
							realmName = p.realmName,
							classFile = p.classFile,
							className = p.className,
							characterLevel = p.level,
							battleTag = p.battleTag,
						}), 2)
					else
						SetupPlayerRow(row, {
							name = p.name,
							fullName = p.fullName,
							class = p.classFileName or p.class,
							className = p.class,
							level = p.level,
							rank = p.rank,
						}, 2)
					end
				end
			end
		end
	end
end

---Online Battle.net friends from one of the friend tables, in the configured order
---@param friendTable table<number, table>
---@param ttDb table Tooltip settings
---@param onlineOnly? boolean
---@return table[]
local function SortedBNetFriends(friendTable, ttDb, onlineOnly)
	local list = {}
	for _, info in pairs(friendTable) do
		if not onlineOnly or info.isOnline then
			table.insert(list, info)
		end
	end
	SortPlayers(list, ttDb.sortField or 'name', ttDb.sortDirection or 'asc')
	return list
end

---Build BNet In-Game section
---@param tooltip table LibQTip-2.0 tooltip
---@param Friends table Friends data
---@param TT table Tooltip helpers
---@param GC table GameClients
---@param ttDb table Tooltip settings
function DataBroker:BuildBNetInGameSection(tooltip, Friends, TT, GC, ttDb)
	if Friends.numBattleNetInGame == 0 then
		return
	end

	tooltip:AddSeparator()
	local collapsed = AddSectionHeader(tooltip, 'Battle.net (In Game)', string.format('|cff%s%d|r', COLORS.online, Friends.numBattleNetInGame), 'battleNetInGame', SECTION_COLORS.bnet)

	if not collapsed then
		for _, info in ipairs(SortedBNetFriends(Friends.battleNetInGame, ttDb)) do
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
function DataBroker:BuildBNetAppSection(tooltip, Friends, TT, GC, ttDb)
	if Friends.numBattleNetAppOnly == 0 then
		return
	end

	tooltip:AddSeparator()
	local collapsed = AddSectionHeader(tooltip, 'Battle.net (App)', string.format('|cff%s%d|r', COLORS.offline, Friends.numBattleNetAppOnly), 'battleNetApp', SECTION_COLORS.bnet)

	if not collapsed then
		for _, info in ipairs(SortedBNetFriends(Friends.battleNetAppOnly, ttDb)) do
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
function DataBroker:BuildBNetCombinedSection(tooltip, Friends, TT, GC, ttDb)
	tooltip:AddSeparator()
	local collapsed = AddSectionHeader(
		tooltip,
		'Battle.net',
		string.format('|cff%s%d online|r', Friends.numBattleNetOnline > 0 and COLORS.online or COLORS.offline, Friends.numBattleNetOnline),
		'battleNetInGame',
		SECTION_COLORS.bnet
	)

	if not collapsed then
		for _, info in ipairs(SortedBNetFriends(Friends.battleNetFriends, ttDb, true)) do
			self:AddBNetFriendLine(tooltip, TT, GC, ttDb, info)
		end
	end
end

---Add a single BNet friend line to the tooltip
---@param tooltip table LibQTip-2.0 tooltip
---@param TT table Tooltip helpers
---@param GC table GameClients
---@param ttDb table Tooltip settings
---@param info table Friend data
function DataBroker:AddBNetFriendLine(tooltip, TT, GC, ttDb, info)
	local accountTag = (info.battleTag or info.accountName or 'Unknown'):gsub('#%d+$', '')
	local inMyGame = IsInMyGame(info, GC)

	local groupIcon = inMyGame and GetGroupIndicator(info.characterName) or ''
	local leftParts = { groupIcon .. string.format('|cff%s%s|r', COLORS.realid, accountTag) }

	-- Character info for WoW players
	if info.characterName then
		local charName = TT:ColorName(info.characterName, info.classFile or info.className)
		table.insert(leftParts, '  ' .. charName)

		if ttDb.showLevels and info.characterLevel and info.characterLevel > 0 then
			table.insert(leftParts, ' (' .. TT:ColorLevel(info.characterLevel) .. ')')
		end
	end

	-- Game client tag for non-WoW games
	if ttDb.showGameClient and info.clientProgram and info.clientProgram ~= BNET_CLIENT_WOW and not GC.IsAppClient(info.clientProgram) then
		local clientTag = GC.GetClientDisplayName(info.clientProgram)
		table.insert(leftParts, string.format(' |cffaaaaaa[%s]|r', clientTag))
	end

	-- WoW project label (only if different from player's)
	if ttDb.showWowProject and info.clientProgram == BNET_CLIENT_WOW and not GC.IsSameProject(info.wowProjectID) then
		table.insert(leftParts, string.format(' |cffcccccc(%s)|r', GC.GetProjectLabel(info.wowProjectID)))
	end

	-- Status
	local isAFK = info.isBnetAFK or info.isGameAFK
	local isDND = info.isBnetDND or info.isGameBusy
	local status = FormatStatus(isAFK, isDND, false)
	if status ~= '' then
		table.insert(leftParts, status)
	end

	local leftStr = table.concat(leftParts)

	-- Zone (right side). A zone of the same name in another game version is not the player's zone.
	local rightStr = nil
	local zr, zg, zb = 0.7, 0.7, 0.7
	if ttDb.showZones and info.areaName and info.areaName ~= '' then
		if inMyGame then
			rightStr, zr, zg, zb = FormatZone(info.areaName)
		else
			rightStr = info.areaName
		end
	end

	local row = tooltip:AddRow(leftStr, rightStr)
	if rightStr and rightStr ~= '' then
		row:GetCell(2):SetTextColor(zr, zg, zb)
	end

	SetupPlayerRow(row, BNetPlayerData(info), 2)

	-- Broadcast message
	if ttDb.showBroadcasts and info.customMessage and info.customMessage ~= '' then
		AddFullLine(tooltip, '   |cff00A2E8' .. info.customMessage .. '|r')
	end

	-- Note
	if ttDb.showNotes and info.noteText and info.noteText ~= '' then
		AddFullLine(tooltip, '   |cffaaaaaa' .. info.noteText .. '|r')
	end
end
