---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

function LibsSocial:RegisterEvents()
	-- Friend list events (bucketed to avoid rapid-fire refreshes)
	self:RegisterBucketEvent({
		'FRIENDLIST_UPDATE',
		'BN_FRIEND_INFO_CHANGED',
		'BN_FRIEND_ACCOUNT_ONLINE',
		'BN_FRIEND_ACCOUNT_OFFLINE',
		'GUILD_ROSTER_UPDATE',
		'GROUP_ROSTER_UPDATE',
	}, 1, 'OnFriendListUpdateBucket')

	-- Zone tracking for same-zone highlighting
	self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'OnZoneChanged')

	-- Blocking events
	self:RegisterEvent('DUEL_REQUESTED', 'OnDuelRequested')
	self:RegisterEvent('PET_BATTLE_PVP_DUEL_REQUESTED', 'OnPetDuelRequested')
	self:RegisterEvent('PARTY_INVITE_REQUEST', 'OnPartyInviteRequest')
	self:RegisterEvent('BN_FRIEND_INVITE_ADDED', 'OnFriendInviteReceived')
	self:RegisterEvent('QUEST_ACCEPT_CONFIRM', 'OnQuestAcceptConfirm')

	-- Auto-accept events
	self:RegisterEvent('CONFIRM_SUMMON', 'OnConfirmSummon')
	self:RegisterEvent('LFG_PROPOSAL_SHOW', 'OnLFGProposalShow')
	self:RegisterEvent('PARTY_INVITE_REQUEST', 'OnPartyInviteForAutoAccept')
	self:RegisterEvent('CHAT_MSG_WHISPER', 'OnWhisper')

	-- Player login
	self:RegisterEvent('PLAYER_LOGIN', 'OnPlayerLogin')
	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'OnPlayerEnteringWorld')
end

function LibsSocial:OnPlayerLogin()
	-- Request friend list update
	C_FriendList.ShowFriends()
	if IsInGuild() then
		C_GuildInfo.GuildRoster()
	end
end

function LibsSocial:OnPlayerEnteringWorld()
	-- Update display after entering world
	if self.UpdateDisplay then
		self:UpdateDisplay()
	end
end

function LibsSocial:OnFriendListUpdateBucket()
	-- Update cached friend data
	if self.Friends and self.Friends.RefreshData then
		self.Friends:RefreshData()
	end

	-- Update display
	if self.UpdateDisplay then
		self:UpdateDisplay()
	end
end

function LibsSocial:OnZoneChanged()
	if self.Friends then
		self.Friends:RefreshPlayerZone()
	end
end

-- Blocking event handlers (delegated to Blocking module)
function LibsSocial:OnDuelRequested(event, name)
	if self.Blocking and self.Blocking.HandleDuel then
		self.Blocking:HandleDuel(name)
	end
end

function LibsSocial:OnPetDuelRequested(event, name)
	if self.Blocking and self.Blocking.HandlePetDuel then
		self.Blocking:HandlePetDuel(name)
	end
end

function LibsSocial:OnPartyInviteRequest(event, name, ...)
	if self.Blocking and self.Blocking.HandlePartyInvite then
		self.Blocking:HandlePartyInvite(name, ...)
	end
end

function LibsSocial:OnFriendInviteReceived(event, ...)
	if self.Blocking and self.Blocking.HandleFriendInvite then
		self.Blocking:HandleFriendInvite(...)
	end
end

function LibsSocial:OnQuestAcceptConfirm(event, name, questTitle)
	if self.Blocking and self.Blocking.HandleSharedQuest then
		self.Blocking:HandleSharedQuest(name, questTitle)
	end
end

-- Auto-accept event handlers (delegated to AutoAccept module)
function LibsSocial:OnConfirmSummon(event)
	if self.AutoAccept and self.AutoAccept.HandleSummon then
		self.AutoAccept:HandleSummon()
	end
end

function LibsSocial:OnLFGProposalShow(event)
	if self.AutoAccept and self.AutoAccept.HandleLFGProposal then
		self.AutoAccept:HandleLFGProposal()
	end
end

function LibsSocial:OnPartyInviteForAutoAccept(event, name, ...)
	if self.AutoAccept and self.AutoAccept.HandlePartyInvite then
		self.AutoAccept:HandlePartyInvite(name, ...)
	end
end

function LibsSocial:OnWhisper(event, message, sender, ...)
	if self.AutoAccept and self.AutoAccept.HandleWhisper then
		self.AutoAccept:HandleWhisper(message, sender, ...)
	end
end
