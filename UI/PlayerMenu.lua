---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

local PlayerMenu = {}
LibsSocial.PlayerMenu = PlayerMenu

-- Temporary EditBox for copy-to-clipboard functionality
local copyBox

---Create the temporary copy editbox (one-time)
local function GetCopyBox()
	if not copyBox then
		copyBox = CreateFrame('EditBox', 'LibsSocialCopyBox', UIParent, 'InputBoxTemplate')
		copyBox:SetSize(200, 30)
		copyBox:SetPoint('CENTER')
		copyBox:SetFrameStrata('DIALOG')
		copyBox:SetAutoFocus(true)
		copyBox:SetScript('OnEscapePressed', function(self)
			self:ClearFocus()
			self:Hide()
		end)
		copyBox:SetScript('OnEnterPressed', function(self)
			self:ClearFocus()
			self:Hide()
		end)
		copyBox:SetScript('OnEditFocusLost', function(self)
			self:Hide()
		end)
		copyBox:Hide()
	end
	return copyBox
end

---Show a copy box with text pre-selected
---@param text string Text to copy
local function ShowCopyBox(text)
	local box = GetCopyBox()
	box:SetText(text)
	box:Show()
	box:HighlightText()
	box:SetFocus()
end

---Add player info lines to a menu description
---@param rootDescription table Menu root description
---@param playerData table Player data
local function AddPlayerInfoLines(rootDescription, playerData)
	-- Realm
	local realm = playerData.realm
	if (not realm or realm == '') and playerData.fullName and playerData.fullName:find('-') then
		realm = playerData.fullName:match('-(.+)$')
	end
	if realm and realm ~= '' then
		rootDescription:CreateTitle('Realm: ' .. realm)
	end

	-- Class
	if playerData.class and playerData.class ~= '' then
		local className = playerData.class
		local color = RAID_CLASS_COLORS[className:upper()]
		if color then
			rootDescription:CreateTitle('Class: ' .. string.format('|cff%02x%02x%02x%s|r', color.r * 255, color.g * 255, color.b * 255, className))
		else
			rootDescription:CreateTitle('Class: ' .. className)
		end
	end

	-- Level
	if playerData.level and playerData.level > 0 then
		rootDescription:CreateTitle('Level: ' .. tostring(playerData.level))
	end

	-- Rank (guild)
	if playerData.rank and playerData.rank ~= '' then
		rootDescription:CreateTitle('Rank: ' .. playerData.rank)
	end

	-- BattleTag
	if playerData.battleTag and playerData.battleTag ~= '' then
		rootDescription:CreateTitle('BattleTag: ' .. playerData.battleTag)
	end
end

---Show context menu for a player (character friend, BNet friend, or guild member)
---@param playerData table Player data from tooltip row
---@param anchor Frame Frame to anchor menu to
function PlayerMenu:Show(playerData, anchor)
	if InCombatLockdown() then
		return
	end

	if playerData.accountID then
		-- BNet friend
		local displayName = playerData.accountName or 'Unknown'
		local characterName = playerData.characterName

		MenuUtil.CreateContextMenu(anchor, function(ownerRegion, rootDescription)
			rootDescription:CreateTitle(displayName)

			-- Player info
			AddPlayerInfoLines(rootDescription, playerData)
			rootDescription:CreateDivider()

			-- Actions
			rootDescription:CreateButton('Whisper', function()
				ChatFrame_SendSmartTell(displayName)
			end)

			if characterName and characterName ~= '' then
				rootDescription:CreateButton('Invite to Party', function()
					BNInviteFriend(playerData.accountID)
				end)
			end

			local accountInfo = C_BattleNet.GetAccountInfoByID(playerData.accountID)
			local battleTag = accountInfo and accountInfo.battleTag
			if battleTag then
				rootDescription:CreateButton('Copy BattleTag', function()
					ShowCopyBox(battleTag)
				end)
			end

			if characterName and characterName ~= '' then
				rootDescription:CreateButton('Copy Character Name', function()
					ShowCopyBox(characterName)
				end)
			end
		end)
	else
		-- Character friend or guild member
		local name = playerData.fullName or playerData.name
		if not name then
			return
		end

		MenuUtil.CreateContextMenu(anchor, function(ownerRegion, rootDescription)
			rootDescription:CreateTitle(name)

			-- Player info
			AddPlayerInfoLines(rootDescription, playerData)
			rootDescription:CreateDivider()

			-- Actions
			rootDescription:CreateButton('Whisper', function()
				ChatFrame_SendTell(name)
			end)

			rootDescription:CreateButton('Invite to Party', function()
				InviteUnit(name)
			end)

			if IsInRaid() or (IsInGroup() and (UnitIsGroupLeader('player') or UnitIsGroupAssistant('player'))) then
				rootDescription:CreateButton('Invite to Raid', function()
					InviteUnit(name)
				end)
			end

			rootDescription:CreateButton('Copy Name', function()
				ShowCopyBox(name)
			end)
		end)
	end
end
