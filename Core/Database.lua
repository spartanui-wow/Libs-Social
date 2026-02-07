---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

local defaults = {
	profile = {
		-- Blocking settings
		blocking = {
			enabled = true,
			duels = true,
			petDuels = true,
			partyInvites = false,
			friendRequests = false,
			sharedQuests = false,
		},
		-- Auto-accept settings
		autoAccept = {
			enabled = true,
			partyFromFriends = true,
			syncFromFriends = true,
			queueFromFriends = false,
			inviteKeyword = '',
			inviteKeywordEnabled = false,
		},
		-- Friend treatment settings
		friendTreatment = {
			guildAsFriends = true,
			communityAsFriends = false,
		},
		-- Display settings
		display = {
			format = 'combined', -- 'combined', 'friends', 'guild', 'realid', 'detailed'
			showLabel = true,
			showMobileIndicators = true,
			showStatusIcons = true,
			colorByStatus = true,
		},
		-- Minimap button
		minimap = {
			hide = false,
		},
	},
}

function LibsSocial:InitializeDatabase()
	self.db = LibStub('AceDB-3.0'):New('LibsSocialDB', defaults, true)

	-- Register profile callbacks
	self.db.RegisterCallback(self, 'OnProfileChanged', 'OnProfileChanged')
	self.db.RegisterCallback(self, 'OnProfileCopied', 'OnProfileChanged')
	self.db.RegisterCallback(self, 'OnProfileReset', 'OnProfileChanged')
end

function LibsSocial:OnProfileChanged()
	-- Refresh systems when profile changes
	if self.UpdateDisplay then
		self:UpdateDisplay()
	end
end
