---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

---@class LibsSocial.AutoAccept : AceModule
local AutoAccept = LibsSocial:NewModule('AutoAccept')
LibsSocial.AutoAccept = AutoAccept

---@param name string
function AutoAccept:HandlePartyInvite(name, ...)
	local db = LibsSocial.db.profile.autoAccept

	if not db.enabled or not db.partyFromFriends then
		return
	end

	if not LibsSocial.Friends:IsTreatedAsFriend(name) then
		return
	end

	if IsInGroup() then
		return
	end

	local isQueued = false
	for i = 1, 4 do
		local hasData = GetLFGQueueStats(i)
		if hasData then
			isQueued = true
			break
		end
	end

	if isQueued then
		LibsSocial:Log('In queue, not auto-accepting party from ' .. name, 'debug')
		return
	end

	AcceptGroup()
	StaticPopup_Hide('PARTY_INVITE')
	StaticPopup_Hide('PARTY_INVITE_XREALM')

	LibsSocial:Log('Auto-accepted party invite from friend ' .. name, 'info')
end

function AutoAccept:HandlePartySync()
	local db = LibsSocial.db.profile.autoAccept

	if not db.enabled or not db.syncFromFriends then
		return
	end
end

function AutoAccept:HandleLFGProposal()
	local db = LibsSocial.db.profile.autoAccept

	if not db.enabled or not db.queueFromFriends then
		return
	end

	local leaderName = UnitName('party1')
	if not leaderName then
		return
	end

	if not LibsSocial.Friends:IsTreatedAsFriend(leaderName) then
		return
	end

	LibsSocial:Log('LFG proposal from friend ' .. leaderName .. ' - manual acceptance needed', 'debug')
end

---@param message string
---@param sender string
function AutoAccept:HandleWhisper(message, sender, ...)
	local db = LibsSocial.db.profile.autoAccept

	if not db.enabled or not db.inviteKeywordEnabled then
		return
	end

	local keyword = db.inviteKeyword
	if not keyword or keyword == '' then
		return
	end

	if not message:lower():find(keyword:lower(), 1, true) then
		return
	end

	if not (UnitIsGroupLeader('player') or UnitIsGroupAssistant('player') or not IsInGroup()) then
		return
	end

	local shortName = Ambiguate(sender, 'none')

	InviteUnit(shortName)

	LibsSocial:Log('Invited ' .. shortName .. ' (whispered keyword)', 'info')
end

function AutoAccept:HandleSummon()
	-- Placeholder for friend-based summon logic
end
