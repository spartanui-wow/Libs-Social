---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

---@class LibsSocial.Events : AceModule, AceEvent-3.0, AceBucket-3.0
local Events = LibsSocial:NewModule('Events', 'AceEvent-3.0', 'AceBucket-3.0')
LibsSocial.Events = Events

function Events:OnEnable()
	-- Friend list events (bucketed to avoid rapid-fire refreshes)
	self:RegisterBucketEvent({
		'FRIENDLIST_UPDATE',
		'BN_FRIEND_INFO_CHANGED',
		'BN_FRIEND_ACCOUNT_ONLINE',
		'BN_FRIEND_ACCOUNT_OFFLINE',
		'GUILD_ROSTER_UPDATE',
		'GROUP_ROSTER_UPDATE',
	}, 1, 'OnFriendListUpdateBucket')

	-- Zone tracking
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
	self:RegisterEvent('CHAT_MSG_WHISPER', 'OnWhisper')

	-- Player login
	self:RegisterEvent('PLAYER_LOGIN', 'OnPlayerLogin')
	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'OnPlayerEnteringWorld')
end

function Events:OnDisable()
	self:UnregisterAllEvents()
	self:UnregisterAllBuckets()
end

function Events:OnPlayerLogin()
	C_FriendList.ShowFriends()
	if IsInGuild() then
		C_GuildInfo.GuildRoster()
	end
end

function Events:OnPlayerEnteringWorld()
	if LibsSocial.UpdateDisplay then
		LibsSocial:UpdateDisplay()
	end
end

function Events:OnFriendListUpdateBucket()
	if LibsSocial.Friends then
		LibsSocial.Friends:RefreshData()
	end

	if LibsSocial.UpdateDisplay then
		LibsSocial:UpdateDisplay()
	end
end

function Events:OnZoneChanged()
	if LibsSocial.Friends then
		LibsSocial.Friends:RefreshPlayerZone()
	end
end

function Events:OnDuelRequested(event, name)
	if LibsSocial.Blocking then
		LibsSocial.Blocking:HandleDuel(name)
	end
end

function Events:OnPetDuelRequested(event, name)
	if LibsSocial.Blocking then
		LibsSocial.Blocking:HandlePetDuel(name)
	end
end

function Events:OnPartyInviteRequest(event, name, ...)
	if LibsSocial.Blocking then
		LibsSocial.Blocking:HandlePartyInvite(name, ...)
	end
	if LibsSocial.AutoAccept then
		LibsSocial.AutoAccept:HandlePartyInvite(name, ...)
	end
end

function Events:OnFriendInviteReceived(event, ...)
	if LibsSocial.Blocking then
		LibsSocial.Blocking:HandleFriendInvite(...)
	end
end

function Events:OnQuestAcceptConfirm(event, name, questTitle)
	if LibsSocial.Blocking then
		LibsSocial.Blocking:HandleSharedQuest(name, questTitle)
	end
end

function Events:OnConfirmSummon()
	if LibsSocial.AutoAccept then
		LibsSocial.AutoAccept:HandleSummon()
	end
end

function Events:OnLFGProposalShow()
	if LibsSocial.AutoAccept then
		LibsSocial.AutoAccept:HandleLFGProposal()
	end
end

function Events:OnWhisper(event, message, sender, ...)
	if LibsSocial.AutoAccept then
		LibsSocial.AutoAccept:HandleWhisper(message, sender, ...)
	end
end
