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
	-- Characters have a last name instead of a realm on some clients, so "First-Last" holds no realm
	if not LibsSocial:UsesSurnames() then
		local realm = playerData.realm
		if (not realm or realm == '') and playerData.fullName and playerData.fullName:find('-', 1, true) then
			realm = playerData.fullName:match('-(.+)$')
		end
		if realm and realm ~= '' then
			rootDescription:CreateTitle('Realm: ' .. realm)
		end
	end

	-- Class
	local className = playerData.className or playerData.class
	if className and className ~= '' then
		local color = LibsSocial.Tooltip:GetClassColor(playerData.class or className)
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

local BNET_CLIENT_WOW = BNET_CLIENT_WOW or 'WoW'

---True when the player can whisper or invite this Battle.net friend's character in this game
---@param playerData table
---@return boolean
local function IsReachableCharacter(playerData)
	return playerData.characterName ~= nil
		and playerData.characterName ~= ''
		and playerData.clientProgram == BNET_CLIENT_WOW
		and LibsSocial.GameClients.IsSameProject(playerData.wowProjectID)
end

---Open a whisper to a player (Battle.net whisper for Battle.net friends)
---@param playerData table Player data from a tooltip row
function PlayerMenu:Whisper(playerData)
	local util = ChatFrameUtil
	if playerData.accountID then
		local target = playerData.accountName
		if not target or target == '' then
			return
		end
		if util and util.SendBNetTell then
			util.SendBNetTell(target)
		elseif ChatFrame_SendBNetTell then
			ChatFrame_SendBNetTell(target)
		end
		return
	end

	local name = playerData.fullName or playerData.name
	if not name or name == '' then
		return
	end
	if util and util.SendTell then
		util.SendTell(name)
	elseif ChatFrame_SendTell then
		ChatFrame_SendTell(name)
	end
end

---Invite a player to the group
---@param playerData table Player data from a tooltip row
function PlayerMenu:Invite(playerData)
	if playerData.accountID then
		local gameAccountID = playerData.gameAccountID
		if not gameAccountID then
			return
		end
		if C_BattleNet and C_BattleNet.InviteFriend then
			C_BattleNet.InviteFriend(gameAccountID)
		elseif BNInviteFriend then
			BNInviteFriend(gameAccountID)
		end
		return
	end

	local name = playerData.fullName or playerData.name
	if not name or name == '' then
		return
	end
	local InviteUnit = C_PartyInfo and C_PartyInfo.InviteUnit or InviteUnit
	if InviteUnit then
		InviteUnit(name)
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
		local displayName = playerData.accountName or playerData.battleTag or 'Unknown'
		local characterName = playerData.characterName

		MenuUtil.CreateContextMenu(anchor, function(ownerRegion, rootDescription)
			rootDescription:CreateTitle(displayName)

			-- Player info
			AddPlayerInfoLines(rootDescription, playerData)
			rootDescription:CreateDivider()

			-- Actions
			rootDescription:CreateButton('Whisper', function()
				PlayerMenu:Whisper(playerData)
			end)

			if IsReachableCharacter(playerData) and playerData.gameAccountID then
				rootDescription:CreateButton('Invite to Party', function()
					PlayerMenu:Invite(playerData)
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
			rootDescription:CreateTitle(playerData.name or name)

			-- Player info
			AddPlayerInfoLines(rootDescription, playerData)
			rootDescription:CreateDivider()

			-- Actions
			rootDescription:CreateButton('Whisper', function()
				PlayerMenu:Whisper(playerData)
			end)

			rootDescription:CreateButton('Invite to Party', function()
				PlayerMenu:Invite(playerData)
			end)

			if IsInRaid() or (IsInGroup() and (UnitIsGroupLeader('player') or UnitIsGroupAssistant('player'))) then
				rootDescription:CreateButton('Invite to Raid', function()
					PlayerMenu:Invite(playerData)
				end)
			end

			rootDescription:CreateButton('Copy Name', function()
				ShowCopyBox(name)
			end)
		end)
	end
end
