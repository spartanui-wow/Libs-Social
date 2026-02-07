---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

local FriendTreatment = {}
LibsSocial.FriendTreatment = FriendTreatment

function LibsSocial:InitializeFriendTreatment()
	-- Nothing special needed for initialization
	-- The actual friend treatment logic is in Friends:IsTreatedAsFriend()
end

---Check if guild members should be treated as friends
---@return boolean
function FriendTreatment:IsGuildAsFriends()
	return LibsSocial.db.profile.friendTreatment.guildAsFriends
end

---Check if community members should be treated as friends
---@return boolean
function FriendTreatment:IsCommunityAsFriends()
	return LibsSocial.db.profile.friendTreatment.communityAsFriends
end

---Toggle guild as friends setting
---@param value boolean
function FriendTreatment:SetGuildAsFriends(value)
	LibsSocial.db.profile.friendTreatment.guildAsFriends = value
end

---Toggle community as friends setting
---@param value boolean
function FriendTreatment:SetCommunityAsFriends(value)
	LibsSocial.db.profile.friendTreatment.communityAsFriends = value
end
