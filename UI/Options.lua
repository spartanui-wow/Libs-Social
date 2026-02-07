---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

local AceConfig = LibStub('AceConfig-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')

function LibsSocial:InitializeOptions()
	local options = {
		name = "Lib's Social",
		type = 'group',
		childGroups = 'tab',
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				args = {
					displayHeader = {
						name = 'Display Settings',
						type = 'header',
						order = 1,
					},
					format = {
						name = 'Display Format',
						desc = 'How to display friend counts',
						type = 'select',
						order = 2,
						values = {
							combined = 'Combined (Total)',
							friends = 'Friends Only',
							guild = 'Guild Only',
							realid = 'Battle.net Only',
							detailed = 'Detailed (F/B/G)',
						},
						get = function()
							return self.db.profile.display.format
						end,
						set = function(_, value)
							self.db.profile.display.format = value
							self:UpdateDisplay()
						end,
					},
					colorByStatus = {
						name = 'Color by Status',
						desc = 'Color the display text based on online/offline status',
						type = 'toggle',
						order = 3,
						get = function()
							return self.db.profile.display.colorByStatus
						end,
						set = function(_, value)
							self.db.profile.display.colorByStatus = value
							self:UpdateDisplay()
						end,
					},
					showMobileIndicators = {
						name = 'Show Mobile Indicators',
						desc = 'Show icons for friends on mobile devices',
						type = 'toggle',
						order = 4,
						get = function()
							return self.db.profile.display.showMobileIndicators
						end,
						set = function(_, value)
							self.db.profile.display.showMobileIndicators = value
						end,
					},
				},
			},
			blocking = {
				name = 'Blocking',
				type = 'group',
				order = 2,
				args = {
					enabled = {
						name = 'Enable Blocking',
						desc = 'Master toggle for all blocking features',
						type = 'toggle',
						order = 1,
						width = 'full',
						get = function()
							return self.db.profile.blocking.enabled
						end,
						set = function(_, value)
							self.db.profile.blocking.enabled = value
						end,
					},
					blockHeader = {
						name = 'Block Types',
						type = 'header',
						order = 2,
					},
					duels = {
						name = 'Block Duels',
						desc = 'Automatically decline duel requests (except from friends)',
						type = 'toggle',
						order = 3,
						disabled = function()
							return not self.db.profile.blocking.enabled
						end,
						get = function()
							return self.db.profile.blocking.duels
						end,
						set = function(_, value)
							self.db.profile.blocking.duels = value
						end,
					},
					petDuels = {
						name = 'Block Pet Battle Duels',
						desc = 'Automatically decline pet battle duel requests (except from friends)',
						type = 'toggle',
						order = 4,
						disabled = function()
							return not self.db.profile.blocking.enabled
						end,
						get = function()
							return self.db.profile.blocking.petDuels
						end,
						set = function(_, value)
							self.db.profile.blocking.petDuels = value
						end,
					},
					partyInvites = {
						name = 'Block Party Invites',
						desc = 'Automatically decline party invites (except from friends)',
						type = 'toggle',
						order = 5,
						disabled = function()
							return not self.db.profile.blocking.enabled
						end,
						get = function()
							return self.db.profile.blocking.partyInvites
						end,
						set = function(_, value)
							self.db.profile.blocking.partyInvites = value
						end,
					},
					friendRequests = {
						name = 'Block Friend Requests',
						desc = 'Automatically decline BattleTag/Real ID friend requests',
						type = 'toggle',
						order = 6,
						disabled = function()
							return not self.db.profile.blocking.enabled
						end,
						get = function()
							return self.db.profile.blocking.friendRequests
						end,
						set = function(_, value)
							self.db.profile.blocking.friendRequests = value
						end,
					},
					sharedQuests = {
						name = 'Block Shared Quests',
						desc = 'Automatically decline shared quests (except from friends)',
						type = 'toggle',
						order = 7,
						disabled = function()
							return not self.db.profile.blocking.enabled
						end,
						get = function()
							return self.db.profile.blocking.sharedQuests
						end,
						set = function(_, value)
							self.db.profile.blocking.sharedQuests = value
						end,
					},
				},
			},
			autoAccept = {
				name = 'Auto-Accept',
				type = 'group',
				order = 3,
				args = {
					enabled = {
						name = 'Enable Auto-Accept',
						desc = 'Master toggle for all auto-accept features',
						type = 'toggle',
						order = 1,
						width = 'full',
						get = function()
							return self.db.profile.autoAccept.enabled
						end,
						set = function(_, value)
							self.db.profile.autoAccept.enabled = value
						end,
					},
					acceptHeader = {
						name = 'Auto-Accept Types',
						type = 'header',
						order = 2,
					},
					partyFromFriends = {
						name = 'Party Invites from Friends',
						desc = 'Automatically accept party invites from friends',
						type = 'toggle',
						order = 3,
						disabled = function()
							return not self.db.profile.autoAccept.enabled
						end,
						get = function()
							return self.db.profile.autoAccept.partyFromFriends
						end,
						set = function(_, value)
							self.db.profile.autoAccept.partyFromFriends = value
						end,
					},
					syncFromFriends = {
						name = 'Party Sync from Friends',
						desc = 'Automatically accept party sync requests from friends',
						type = 'toggle',
						order = 4,
						disabled = function()
							return not self.db.profile.autoAccept.enabled
						end,
						get = function()
							return self.db.profile.autoAccept.syncFromFriends
						end,
						set = function(_, value)
							self.db.profile.autoAccept.syncFromFriends = value
						end,
					},
					inviteHeader = {
						name = 'Whisper Invite',
						type = 'header',
						order = 10,
					},
					inviteKeywordEnabled = {
						name = 'Enable Whisper Invite',
						desc = 'Invite players who whisper a specific keyword',
						type = 'toggle',
						order = 11,
						disabled = function()
							return not self.db.profile.autoAccept.enabled
						end,
						get = function()
							return self.db.profile.autoAccept.inviteKeywordEnabled
						end,
						set = function(_, value)
							self.db.profile.autoAccept.inviteKeywordEnabled = value
						end,
					},
					inviteKeyword = {
						name = 'Invite Keyword',
						desc = 'Players whispering this keyword will be invited to your group',
						type = 'input',
						order = 12,
						disabled = function()
							return not self.db.profile.autoAccept.enabled or not self.db.profile.autoAccept.inviteKeywordEnabled
						end,
						get = function()
							return self.db.profile.autoAccept.inviteKeyword
						end,
						set = function(_, value)
							self.db.profile.autoAccept.inviteKeyword = value
						end,
					},
				},
			},
			friendTreatment = {
				name = 'Friend Treatment',
				type = 'group',
				order = 4,
				args = {
					desc = {
						name = 'These settings determine who is treated as a "friend" for blocking and auto-accept purposes.',
						type = 'description',
						order = 1,
					},
					guildAsFriends = {
						name = 'Treat Guild Members as Friends',
						desc = 'Guild members will bypass blocking and trigger auto-accept',
						type = 'toggle',
						order = 2,
						width = 'full',
						get = function()
							return self.db.profile.friendTreatment.guildAsFriends
						end,
						set = function(_, value)
							self.db.profile.friendTreatment.guildAsFriends = value
						end,
					},
					communityAsFriends = {
						name = 'Treat Community Members as Friends',
						desc = 'Community members will bypass blocking and trigger auto-accept',
						type = 'toggle',
						order = 3,
						width = 'full',
						get = function()
							return self.db.profile.friendTreatment.communityAsFriends
						end,
						set = function(_, value)
							self.db.profile.friendTreatment.communityAsFriends = value
						end,
					},
				},
			},
			minimap = {
				name = 'Minimap',
				type = 'group',
				order = 5,
				args = {
					hide = {
						name = 'Hide Minimap Button',
						desc = 'Hide the minimap button',
						type = 'toggle',
						order = 1,
						get = function()
							return self.db.profile.minimap.hide
						end,
						set = function(_, value)
							self.db.profile.minimap.hide = value
							if value then
								LibStub('LibDBIcon-1.0'):Hide("Lib's Social")
							else
								LibStub('LibDBIcon-1.0'):Show("Lib's Social")
							end
						end,
					},
				},
			},
		},
	}

	-- Add profile options
	options.args.profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(self.db)
	options.args.profiles.order = 100

	AceConfig:RegisterOptionsTable('LibsSocial', options)
	self.optionsFrame = AceConfigDialog:AddToBlizOptions('LibsSocial', "Lib's Social")
end

function LibsSocial:OpenOptions()
	-- Try to use Settings API first (Retail)
	if Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(self.optionsFrame.name)
	else
		-- Fallback for Classic
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrame) -- Call twice to ensure it opens
	end
end
