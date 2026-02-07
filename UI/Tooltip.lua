---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

-- Enhanced tooltip functionality
-- The main tooltip is built in DataBroker.lua
-- This file provides additional tooltip utilities

local Tooltip = {}
LibsSocial.Tooltip = Tooltip

-- Tooltip helper functions

---Format a player name with class color
---@param name string Player name
---@param class string? Class name for coloring
---@return string Colored name
function Tooltip:ColorName(name, class)
	if not name then
		return 'Unknown'
	end

	if class then
		local color = RAID_CLASS_COLORS[class:upper()]
		if color then
			return string.format('|cff%02x%02x%02x%s|r', color.r * 255, color.g * 255, color.b * 255, name)
		end
	end

	return name
end

---Format a status string
---@param online boolean Is online
---@param mobile boolean Is on mobile
---@param afk boolean Is AFK
---@param dnd boolean Is DND
---@return string Status string
function Tooltip:GetStatusString(online, mobile, afk, dnd)
	if not online then
		return '|cff808080Offline|r'
	end

	local status = '|cff00ff00Online|r'

	if mobile then
		status = status .. ' |cffcccccc(Mobile)|r'
	end

	if afk then
		status = status .. ' |cffffff00<AFK>|r'
	elseif dnd then
		status = status .. ' |cffff0000<DND>|r'
	end

	return status
end

---Format level with difficulty color
---@param level number Player level
---@return string Colored level string
function Tooltip:ColorLevel(level)
	if not level or level <= 0 then
		return '??'
	end

	local color = GetQuestDifficultyColor(level)
	return string.format('|cff%02x%02x%02x%d|r', color.r * 255, color.g * 255, color.b * 255, level)
end
