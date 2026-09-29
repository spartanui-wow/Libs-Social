---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

local ICON_NAME = "Lib's Social"

---Show or hide the minimap button right away
---@param show boolean
local function SetMinimapShown(show)
	LibsSocial.db.profile.minimap.hide = not show
	local LibDBIcon = LibStub('LibDBIcon-1.0', true)
	if LibDBIcon then
		if show then
			LibDBIcon:Show(ICON_NAME)
		else
			LibDBIcon:Hide(ICON_NAME)
		end
	end
end

---Register the first-run setup with Libs-AddonTools. Must run before the database is created, so
---a new install can be told apart from a player who used the addon before.
function LibsSocial:RegisterSetup()
	if not LibAT or not LibAT.Setup then
		return
	end

	local reg = LibAT.Setup:Register('libs-social', {
		name = "Lib's Social",
		icon = 'Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon',
		summary = 'See your friends and guild at a glance, and stop unwanted duels and invites.',
		priority = 80,
		isExistingUser = function()
			return type(LibsSocialDB) == 'table' and next(LibsSocialDB) ~= nil
		end,
		optionsCommand = '/social',
	})
	if not reg then
		return
	end

	-- A data bar already shows this addon, so the minimap button is not needed there
	local wantMinimap = not (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded('Libs-DataBar'))

	reg:AddStep({
		id = 'helpers',
		kind = 'toggles',
		name = 'Helpers',
		title = 'What should Social do for you?',
		text = 'Friends and guild members are never turned away. You can change these later.',
		items = {
			{
				key = 'blockDuels',
				title = 'Turn down duels from strangers',
				caption = 'Duel and pet battle requests from people you do not know are declined for you.',
				recommended = false,
			},
			{
				key = 'acceptInvites',
				title = 'Join groups from friends',
				caption = 'Group invites from your friends and guild are accepted for you.',
				recommended = false,
			},
			{
				key = 'minimap',
				title = 'Minimap button',
				caption = 'A button by the minimap that shows who is online.',
				recommended = wantMinimap,
			},
		},
		get = function(key)
			local profile = LibsSocial.db.profile
			if key == 'blockDuels' then
				return profile.blocking.enabled and true or false
			elseif key == 'acceptInvites' then
				return profile.autoAccept.enabled and true or false
			elseif key == 'minimap' then
				return not profile.minimap.hide
			end
			return false
		end,
		set = function(key, value)
			local profile = LibsSocial.db.profile
			if key == 'blockDuels' then
				profile.blocking.enabled = value
			elseif key == 'acceptInvites' then
				profile.autoAccept.enabled = value
			elseif key == 'minimap' then
				SetMinimapShown(value)
			end
			LibsSocial:Log('Setup set ' .. tostring(key) .. ' to ' .. tostring(value), 'debug')
		end,
	})
end
