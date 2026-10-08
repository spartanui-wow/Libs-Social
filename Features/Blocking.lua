---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

---@class LibsSocial.Blocking : AceModule
local Blocking = LibsSocial:NewModule('Blocking')
LibsSocial.Blocking = Blocking

---@param name string
function Blocking:HandleDuel(name)
	local db = LibsSocial.db.profile.blocking

	if not db.enabled or not db.duels then
		return
	end

	-- A name we cannot read cannot be checked against the friend list, so leave the request alone
	if not LibsSocial.IsReadable(name) then
		return
	end

	if LibsSocial.Friends:IsTreatedAsFriend(name) then
		LibsSocial:Log('Duel from friend ' .. name .. ' - not blocking', 'debug')
		return
	end

	CancelDuel()
	StaticPopup_Hide('DUEL_REQUESTED')

	LibsSocial:Log('Blocked duel from ' .. name, 'info')
end

---@param name string
function Blocking:HandlePetDuel(name)
	local db = LibsSocial.db.profile.blocking

	if not db.enabled or not db.petDuels then
		return
	end

	if not LibsSocial.IsReadable(name) then
		return
	end

	if LibsSocial.Friends:IsTreatedAsFriend(name) then
		LibsSocial:Log('Pet duel from friend ' .. name .. ' - not blocking', 'debug')
		return
	end

	C_PetBattles.CancelPVPDuel()
	StaticPopup_Hide('PET_BATTLE_PVP_DUEL_REQUESTED')

	LibsSocial:Log('Blocked pet duel from ' .. name, 'info')
end

---@param name string
function Blocking:HandlePartyInvite(name, ...)
	local db = LibsSocial.db.profile.blocking

	if not db.enabled or not db.partyInvites then
		return
	end

	if not LibsSocial.IsReadable(name) then
		return
	end

	if LibsSocial.Friends:IsTreatedAsFriend(name) then
		LibsSocial:Log('Party invite from friend ' .. name .. ' - not blocking', 'debug')
		return
	end

	DeclineGroup()
	StaticPopup_Hide('PARTY_INVITE')
	StaticPopup_Hide('PARTY_INVITE_XREALM')

	LibsSocial:Log('Blocked party invite from ' .. name, 'info')
end

function Blocking:HandleFriendInvite(...)
	local db = LibsSocial.db.profile.blocking

	if not db.enabled or not db.friendRequests then
		return
	end

	local numInvites = BNGetNumFriendInvites()
	if numInvites > 0 then
		for i = 1, numInvites do
			local inviteID, accountName = BNGetFriendInviteInfo(i)
			if inviteID then
				BNDeclineFriendInvite(inviteID)
				LibsSocial:Log('Blocked friend request from ' .. (accountName or 'unknown'), 'info')
			end
		end
	end
end

---@param name string
---@param questTitle string
function Blocking:HandleSharedQuest(name, questTitle)
	local db = LibsSocial.db.profile.blocking

	if not db.enabled or not db.sharedQuests then
		return
	end

	if not LibsSocial.IsReadable(name) then
		return
	end

	if LibsSocial.Friends:IsTreatedAsFriend(name) then
		LibsSocial:Log('Shared quest from friend ' .. name .. ' - not blocking', 'debug')
		return
	end

	DeclineQuest()
	StaticPopup_Hide('QUEST_ACCEPT')

	LibsSocial:Log('Blocked shared quest "' .. tostring(questTitle) .. '" from ' .. name, 'info')
end
