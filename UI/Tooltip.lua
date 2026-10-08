---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

-- Enhanced tooltip functionality
-- The main tooltip is built in DataBroker.lua
-- This file provides additional tooltip utilities

local Tooltip = {}
LibsSocial.Tooltip = Tooltip

local classFileByLocalName

---Friend list and Battle.net data give the class in the player's language ("Todesritter"),
---while RAID_CLASS_COLORS is keyed by the English file name ("DEATHKNIGHT")
---@param class string
---@return string|nil classFile
local function GetClassFile(class)
	if RAID_CLASS_COLORS[class] then
		return class
	end

	if not classFileByLocalName then
		local map = {}
		for _, list in ipairs({ LOCALIZED_CLASS_NAMES_MALE, LOCALIZED_CLASS_NAMES_FEMALE }) do
			if type(list) == 'table' then
				for classFile, localName in pairs(list) do
					map[localName] = classFile
				end
			end
		end
		if next(map) then
			classFileByLocalName = map
		end
	end

	local classFile = classFileByLocalName and classFileByLocalName[class]
	if classFile then
		return classFile
	end

	return (class:upper():gsub('%s', ''))
end

---Class color for a class file name or a class name in the player's language
---@param class string?
---@return table|nil color
function Tooltip:GetClassColor(class)
	if type(class) ~= 'string' or class == '' then
		return nil
	end
	local classFile = GetClassFile(class)
	return classFile and RAID_CLASS_COLORS[classFile] or nil
end

---Format a player name with class color
---@param name string Player name
---@param class string? Class file name or class name in the player's language
---@return string Colored name
function Tooltip:ColorName(name, class)
	if not name then
		return 'Unknown'
	end

	local color = self:GetClassColor(class)
	if color then
		return string.format('|cff%02x%02x%02x%s|r', color.r * 255, color.g * 255, color.b * 255, name)
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

---Get a status icon texture string
---@param afk boolean Is AFK
---@param dnd boolean Is DND
---@return string icon Inline texture string or empty
function Tooltip:GetStatusIcon(afk, dnd)
	if afk then
		return '|TInterface\\FriendsFrame\\StatusIcon-Away:0|t'
	elseif dnd then
		return '|TInterface\\FriendsFrame\\StatusIcon-DnD:0|t'
	end
	return ''
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
