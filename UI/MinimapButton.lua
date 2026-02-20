---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

---@class LibsSocial.MinimapButton : AceModule
local MinimapButton = LibsSocial:NewModule('MinimapButton')
LibsSocial.MinimapButton = MinimapButton

local LibDBIcon = LibStub('LibDBIcon-1.0')

function MinimapButton:OnEnable()
	if not LibsSocial.dataObject then
		return
	end

	-- Smart default: hide minimap icon when Libs-DataBar is present (it shows LDB data already)
	if not LibsSocial.db.profile.minimapDefaultApplied then
		LibsSocial.db.profile.minimapDefaultApplied = true
		if C_AddOns.IsAddOnLoaded('Libs-DataBar') then
			LibsSocial.db.profile.minimap.hide = true
		end
	end

	-- Register the minimap button
	LibDBIcon:Register("Lib's Social", LibsSocial.dataObject, LibsSocial.db.profile.minimap)

	-- Apply initial visibility
	if LibsSocial.db.profile.minimap.hide then
		LibDBIcon:Hide("Lib's Social")
	else
		LibDBIcon:Show("Lib's Social")
	end
end

function MinimapButton:ToggleMinimapButton()
	local hide = not LibsSocial.db.profile.minimap.hide
	LibsSocial.db.profile.minimap.hide = hide

	if hide then
		LibDBIcon:Hide("Lib's Social")
	else
		LibDBIcon:Show("Lib's Social")
	end
end
