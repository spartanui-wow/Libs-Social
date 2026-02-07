---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

local AutoAccept = {}
LibsSocial.AutoAccept = AutoAccept

function LibsSocial:InitializeAutoAccept()
	-- Nothing special needed for initialization
end

---Handle party invite for auto-accept
---@param name string Inviter name
function AutoAccept:HandlePartyInvite(name, ...)
	local db = LibsSocial.db.profile.autoAccept

	if not db.enabled or not db.partyFromFriends then
		return
	end

	-- Check if player is treated as friend
	if not LibsSocial.Friends:IsTreatedAsFriend(name) then
		return
	end

	-- Don't auto-accept if we're already in a group
	if IsInGroup() then
		return
	end

	-- Don't auto-accept if we're in a dungeon finder queue
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

	-- Accept the invite
	AcceptGroup()
	StaticPopup_Hide('PARTY_INVITE')
	StaticPopup_Hide('PARTY_INVITE_XREALM')

	LibsSocial:Log('Auto-accepted party invite from friend ' .. name, 'info')
end

---Handle party sync request (not a real event, would need to hook)
function AutoAccept:HandlePartySync()
	local db = LibsSocial.db.profile.autoAccept

	if not db.enabled or not db.syncFromFriends then
		return
	end

	-- Party sync auto-accept would go here
	-- This requires hooking the Party Sync UI
end

---Handle LFG proposal (for queue from friends)
function AutoAccept:HandleLFGProposal()
	local db = LibsSocial.db.profile.autoAccept

	if not db.enabled or not db.queueFromFriends then
		return
	end

	-- Check if party leader is a friend
	local leaderName = UnitName('party1')
	if not leaderName then
		return
	end

	if not LibsSocial.Friends:IsTreatedAsFriend(leaderName) then
		return
	end

	-- Note: Can't auto-accept LFG without role selection
	-- This would need more complex handling
	LibsSocial:Log('LFG proposal from friend ' .. leaderName .. ' - manual acceptance needed', 'debug')
end

---Handle whisper for keyword invite
---@param message string Whisper message
---@param sender string Sender name
function AutoAccept:HandleWhisper(message, sender, ...)
	local db = LibsSocial.db.profile.autoAccept

	if not db.enabled or not db.inviteKeywordEnabled then
		return
	end

	local keyword = db.inviteKeyword
	if not keyword or keyword == '' then
		return
	end

	-- Check if message contains keyword (case insensitive)
	if not message:lower():find(keyword:lower(), 1, true) then
		return
	end

	-- Check if we can invite
	if not (UnitIsGroupLeader('player') or UnitIsGroupAssistant('player') or not IsInGroup()) then
		return
	end

	-- Check if sender is online (can't invite offline Battle.net friends)
	local shortName = Ambiguate(sender, 'none')

	-- Invite the player
	InviteUnit(shortName)

	LibsSocial:Log('Invited ' .. shortName .. ' (whispered keyword)', 'info')
end

---Handle summon confirmation
function AutoAccept:HandleSummon()
	-- Note: Summons are handled in Convenience module, not here
	-- This is a placeholder if we want to add friend-based summon logic
end
