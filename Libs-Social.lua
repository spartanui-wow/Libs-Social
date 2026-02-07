---@class LibsSocial
local ADDON_NAME, LibsSocial = ...

-- Create the addon using AceAddon
LibsSocial = LibStub('AceAddon-3.0'):NewAddon(ADDON_NAME, 'AceEvent-3.0', 'AceConsole-3.0')
_G.LibsSocial = LibsSocial

LibsSocial.version = '1.0.0'
LibsSocial.addonName = "Lib's Social"

-- Module containers
LibsSocial.Friends = {}
LibsSocial.Blocking = {}
LibsSocial.AutoAccept = {}
LibsSocial.FriendTreatment = {}

function LibsSocial:OnInitialize()
	-- Initialize logger
	if LibAT and LibAT.Logger then
		self.logger = LibAT.Logger.RegisterAddon('LibsSocial')
	end

	-- Database is initialized in Core/Database.lua
	self:InitializeDatabase()

	-- Register slash commands
	self:RegisterChatCommand('social', 'SlashCommand')
	self:RegisterChatCommand('libssocial', 'SlashCommand')
end

function LibsSocial:OnEnable()
	-- Initialize all systems
	self:InitializeFriends()
	self:InitializeBlocking()
	self:InitializeAutoAccept()
	self:InitializeFriendTreatment()
	self:InitializeDataBroker()
	self:InitializeMinimapButton()
	self:InitializeOptions()

	-- Register core events
	self:RegisterEvents()

	self:Log(self.addonName .. ' v' .. self.version .. ' loaded', 'info')
end

function LibsSocial:OnDisable()
	self:UnregisterAllEvents()
end

function LibsSocial:SlashCommand(input)
	input = input and input:trim():lower() or ''

	if input == '' or input == 'config' or input == 'options' then
		self:OpenOptions()
	elseif input == 'block' then
		self.db.profile.blocking.enabled = not self.db.profile.blocking.enabled
		self:Print('Blocking ' .. (self.db.profile.blocking.enabled and 'enabled' or 'disabled'))
	elseif input == 'accept' then
		self.db.profile.autoAccept.enabled = not self.db.profile.autoAccept.enabled
		self:Print('Auto-accept ' .. (self.db.profile.autoAccept.enabled and 'enabled' or 'disabled'))
	else
		self:Print('Commands: /social [config|block|accept]')
	end
end

-- Logging helper
function LibsSocial:Log(message, level)
	level = level or 'info'
	if self.logger and self.logger[level] then
		self.logger[level](message)
	end
end
