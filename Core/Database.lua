---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

---@class LibsSocial.Database : AceModule
local Database = LibsSocial:NewModule('Database')
LibsSocial.Database = Database

local defaults = {
	profile = {
		blocking = {
			enabled = false,
			duels = true,
			petDuels = true,
			partyInvites = false,
			friendRequests = false,
			sharedQuests = false,
		},
		autoAccept = {
			enabled = false,
			partyFromFriends = true,
			syncFromFriends = true,
			queueFromFriends = false,
			inviteKeyword = '',
			inviteKeywordEnabled = false,
		},
		friendTreatment = {
			guildAsFriends = true,
			communityAsFriends = false,
		},
		display = {
			format = 'combined',
			showLabel = true,
			showMobileIndicators = true,
			showStatusIcons = true,
			colorByStatus = true,
			colorCodedCounts = false,
			tooltip = {
				extraWidth = 0,
				sortField = 'name',
				sortDirection = 'asc',
				groupMode = 'default',
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
		minimap = {
			hide = false,
		},
	},
}

function Database:OnInitialize()
	LibsSocial.db = LibStub('AceDB-3.0'):New('LibsSocialDB', defaults, true)

	LibsSocial.db.RegisterCallback(LibsSocial, 'OnProfileChanged', 'OnProfileChanged')
	LibsSocial.db.RegisterCallback(LibsSocial, 'OnProfileCopied', 'OnProfileChanged')
	LibsSocial.db.RegisterCallback(LibsSocial, 'OnProfileReset', 'OnProfileChanged')
end

function LibsSocial:OnProfileChanged()
	if self.UpdateDisplay then
		self:UpdateDisplay()
	end
end
