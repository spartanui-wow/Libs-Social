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

---Show context menu for a character friend
---@param name string Character name (possibly with realm)
---@param anchor Frame Frame to anchor menu to
function PlayerMenu:ShowForCharacter(name, anchor)
	if InCombatLockdown() then
		return
	end
	if not name then
		return
	end

	MenuUtil.CreateContextMenu(anchor, function(ownerRegion, rootDescription)
		rootDescription:CreateTitle(name)

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

---Show context menu for a Battle.net friend
---@param accountName string? Account display name
---@param accountID number BNet account ID
---@param characterName string? In-game character name
---@param anchor Frame Frame to anchor menu to
function PlayerMenu:ShowForBNet(accountName, accountID, characterName, anchor)
	if InCombatLockdown() then
		return
	end
	if not accountID then
		return
	end

	local displayName = accountName or 'Unknown'

	MenuUtil.CreateContextMenu(anchor, function(ownerRegion, rootDescription)
		rootDescription:CreateTitle(displayName)

		rootDescription:CreateButton('Whisper', function()
			ChatFrame_SendSmartTell(displayName)
		end)

		if characterName and characterName ~= '' then
			rootDescription:CreateButton('Invite to Party', function()
				BNInviteFriend(accountID)
			end)
		end

		local accountInfo = C_BattleNet.GetAccountInfoByID(accountID)
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
end
