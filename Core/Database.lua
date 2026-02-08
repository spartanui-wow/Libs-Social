---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

local defaults = {
	profile = {
		-- Blocking settings
		blocking = {
			enabled = false,
			duels = true,
			petDuels = true,
			partyInvites = false,
			friendRequests = false,
			sharedQuests = false,
		},
		-- Auto-accept settings
		autoAccept = {
			enabled = false,
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
			colorCodedCounts = false, -- Color each category in detailed format
			tooltip = {
				extraWidth = 0, -- 0-200 additional pixel width
				sortField = 'name', -- 'name', 'level', 'class', 'zone', 'rank'
				sortDirection = 'asc', -- 'asc', 'desc'
				groupMode = 'default', -- 'default', 'activity'
				showLevels = true,
				showNotes = true,
				showOfficerNotes = false,
				showZones = true,
				showRank = true,
				showBroadcasts = true,
				showGameClient = true,
				showWowProject = true,
				highlightSameZone = true,
				useStatusIcons = true,
				separateBNetSections = true,
			},
			collapsedSections = {
				battleNetInGame = false,
				battleNetApp = false,
				characterFriends = false,
				guild = false,
				activity_inGroup = false,
				activity_inZone = false,
				activity_available = false,
				activity_busy = false,
				activity_otherGames = false,
			},
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
