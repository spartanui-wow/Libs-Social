---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

local Blocking = {}
LibsSocial.Blocking = Blocking

function LibsSocial:InitializeBlocking()
	-- Nothing special needed for initialization
end

---Handle incoming duel request
---@param name string Challenger name
function Blocking:HandleDuel(name)
	local db = LibsSocial.db.profile.blocking

	if not db.enabled or not db.duels then
		return
	end

	-- Check if player is treated as friend
	if LibsSocial.Friends:IsTreatedAsFriend(name) then
		LibsSocial:Log('Duel from friend ' .. name .. ' - not blocking', 'debug')
		return
	end

	-- Cancel the duel
	CancelDuel()
	StaticPopup_Hide('DUEL_REQUESTED')

	LibsSocial:Log('Blocked duel from ' .. name, 'info')
end

---Handle incoming pet battle duel request
---@param name string Challenger name
function Blocking:HandlePetDuel(name)
	local db = LibsSocial.db.profile.blocking

	if not db.enabled or not db.petDuels then
		return
	end

	-- Check if player is treated as friend
	if LibsSocial.Friends:IsTreatedAsFriend(name) then
		LibsSocial:Log('Pet duel from friend ' .. name .. ' - not blocking', 'debug')
		return
	end

	-- Cancel the pet duel
	C_PetBattles.CancelPVPDuel()
	StaticPopup_Hide('PET_BATTLE_PVP_DUEL_REQUESTED')

	LibsSocial:Log('Blocked pet duel from ' .. name, 'info')
end

---Handle incoming party invite
---@param name string Inviter name
function Blocking:HandlePartyInvite(name, ...)
	local db = LibsSocial.db.profile.blocking

	if not db.enabled or not db.partyInvites then
		return
	end

	-- Check if player is treated as friend
	if LibsSocial.Friends:IsTreatedAsFriend(name) then
		LibsSocial:Log('Party invite from friend ' .. name .. ' - not blocking', 'debug')
		return
	end

	-- Decline the invite
	DeclineGroup()
	StaticPopup_Hide('PARTY_INVITE')
	StaticPopup_Hide('PARTY_INVITE_XREALM')

	LibsSocial:Log('Blocked party invite from ' .. name, 'info')
end

---Handle incoming friend request
---@param ... any BattleNet friend invite info
function Blocking:HandleFriendInvite(...)
	local db = LibsSocial.db.profile.blocking

	if not db.enabled or not db.friendRequests then
		return
	end

	-- Get pending invites and decline them
	local numInvites = BNGetNumFriendInvites()
	if numInvites > 0 then
		for i = 1, numInvites do
			local inviteID, accountName, isBattleTag = BNGetFriendInviteInfo(i)
			if inviteID then
				BNDeclineFriendInvite(inviteID)
				LibsSocial:Log('Blocked friend request from ' .. (accountName or 'unknown'), 'info')
			end
		end
	end
end

---Handle shared quest
---@param name string Player who shared the quest
---@param questTitle string Quest title
function Blocking:HandleSharedQuest(name, questTitle)
	local db = LibsSocial.db.profile.blocking

	if not db.enabled or not db.sharedQuests then
		return
	end

	-- Check if player is treated as friend
	if LibsSocial.Friends:IsTreatedAsFriend(name) then
		LibsSocial:Log('Shared quest from friend ' .. name .. ' - not blocking', 'debug')
		return
	end

	-- Decline the quest
	DeclineQuest()
	StaticPopup_Hide('QUEST_ACCEPT')

	LibsSocial:Log('Blocked shared quest "' .. questTitle .. '" from ' .. name, 'info')
end
