---@class LibsSocial : AceAddon, AceEvent-3.0, AceConsole-3.0, AceBucket-3.0
local ADDON_NAME, LibsSocial = ...
LibsSocial = LibStub('AceAddon-3.0'):NewAddon(ADDON_NAME, 'AceEvent-3.0', 'AceConsole-3.0', 'AceBucket-3.0')
_G.LibsSocial = LibsSocial

LibsSocial:SetDefaultModuleLibraries('AceEvent-3.0', 'AceTimer-3.0')

LibsSocial.version = '1.0.0'
LibsSocial.addonName = "Lib's Social"

-- WoW Forever runs the modern interface with Classic rules, and WOW_PROJECT_ID is not always its own id there
local FOREVER_PROJECT_ID = WOW_PROJECT_CAMELOT or 18
local interfaceVersion = select(4, GetBuildInfo()) or 0
LibsSocial.IsForever = WOW_PROJECT_ID == FOREVER_PROJECT_ID or (interfaceVersion >= 16000 and interfaceVersion < 20000)
LibsSocial.ProjectID = LibsSocial.IsForever and FOREVER_PROJECT_ID or WOW_PROJECT_ID

---False for a secret value that addon code may not read
---@param value any
---@return boolean
function LibsSocial.IsReadable(value)
	if value == nil then
		return false
	end
	return not canaccessvalue or canaccessvalue(value)
end

---True where characters have a first and last name and no realm (WoW Forever). Names there look
---like "First Last", and "First-Last" means the same character.
---@return boolean
function LibsSocial:UsesSurnames()
	if RegionalUniqueNamesEnabled and RegionalUniqueNamesEnabled() then
		return true
	end
	return self.IsForever
end

local playerRealm

---@return string
local function PlayerRealm()
	if not playerRealm or playerRealm == '' then
		playerRealm = GetNormalizedRealmName and GetNormalizedRealmName() or nil
		if not playerRealm or playerRealm == '' then
			playerRealm = (GetRealmName() or ''):gsub('[%s%-]', '')
		end
	end
	return playerRealm
end

---One comparable key for any spelling of a character name: "Name-Realm" on realm clients,
---"First Last" where names have a surname.
---@param name string?
---@param realm string? Realm to use when the name has none
---@return string|nil key
function LibsSocial:NameKey(name, realm)
	if not self.IsReadable(name) or type(name) ~= 'string' or name == '' then
		return nil
	end

	if self:UsesSurnames() then
		local key = strtrim((name:gsub('%-', ' '):gsub('%s+', ' ')))
		return key ~= '' and key or nil
	end

	local base, nameRealm = name:match('^([^%-]+)%-(.+)$')
	if base then
		name, realm = base, nameRealm
	elseif not self.IsReadable(realm) or type(realm) ~= 'string' then
		realm = nil
	end

	name = name:gsub('%s', '')
	realm = realm and realm:gsub('[%s%-]', '') or ''
	if realm == '' then
		realm = PlayerRealm()
	end
	if realm == '' then
		return name
	end
	return name .. '-' .. realm
end

---The name to show for a character: without the realm on realm clients, the full name otherwise
---@param name string
---@return string
function LibsSocial:ShortName(name)
	if self:UsesSurnames() then
		return strtrim((name:gsub('%-', ' ')))
	end
	return Ambiguate(name, 'none')
end

---Comparable name key for a unit (see NameKey)
---@param unit string
---@return string|nil
function LibsSocial:UnitNameKey(unit)
	local name, realmOrSurname = UnitName(unit)
	if not self.IsReadable(name) then
		return nil
	end
	if not self.IsReadable(realmOrSurname) or realmOrSurname == '' then
		realmOrSurname = nil
	end
	if self:UsesSurnames() then
		if realmOrSurname and not name:find(realmOrSurname, 1, true) then
			name = name .. ' ' .. realmOrSurname
		end
		return self:NameKey(name)
	end
	return self:NameKey(name, realmOrSurname)
end

function LibsSocial:OnInitialize()
	if LibAT and LibAT.Logger then
		self.logger = LibAT.Logger.RegisterAddon('LibsSocial')
	end

	-- Before the Database module creates the saved variables, so Setup can spot a new install
	self:RegisterSetup()

	self:RegisterChatCommand('social', 'SlashCommand')
	self:RegisterChatCommand('libssocial', 'SlashCommand')
end

function LibsSocial:OnEnable()
	-- Modules auto-enable via Ace3 lifecycle

	-- Register with Addon Compartment (10.x+ dropdown)
	if AddonCompartmentFrame and AddonCompartmentFrame.RegisterAddon then
		AddonCompartmentFrame:RegisterAddon({
			text = "Lib's Social",
			icon = 'Interface/FriendsFrame/UI-Toast-FriendOnlineIcon',
			registerForAnyClick = true,
			notCheckable = true,
			func = function(_, _, _, _, mouseButton)
				if mouseButton == 'LeftButton' then
					ToggleFriendsFrame()
				else
					self:OpenOptions()
				end
			end,
			funcOnEnter = function()
				GameTooltip:SetOwner(AddonCompartmentFrame, 'ANCHOR_CURSOR_RIGHT')
				GameTooltip:AddLine("|cffffffffLib's|r |cffe21f1fSocial|r", 1, 1, 1)
				GameTooltip:AddLine(' ')
				GameTooltip:AddLine('|cffeda55fLeft-Click|r to toggle friends panel.', 1, 1, 1)
				GameTooltip:AddLine('|cffeda55fRight-Click|r to open options.', 1, 1, 1)
				GameTooltip:Show()
			end,
		})
	end

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

function LibsSocial:Log(message, level)
	level = level or 'info'
	if self.logger and self.logger[level] then
		self.logger[level](message)
	end
end

function LibsSocial:UpdateDisplay()
	if self.DataBroker then
		self.DataBroker:UpdateDisplay()
	end
end

function LibsSocial:OpenOptions()
	if self.Options then
		self.Options:OpenOptions()
	end
end
