---@class LibsSocial
local LibsSocial = LibStub('AceAddon-3.0'):GetAddon('Libs-Social')

local LibDBIcon = LibStub('LibDBIcon-1.0')

function LibsSocial:InitializeMinimapButton()
	if not self.dataObject then
		return
	end

	-- Register the minimap button
	LibDBIcon:Register("Lib's Social", self.dataObject, self.db.profile.minimap)

	-- Apply initial visibility
	if self.db.profile.minimap.hide then
		LibDBIcon:Hide("Lib's Social")
	else
		LibDBIcon:Show("Lib's Social")
	end
end

function LibsSocial:ToggleMinimapButton()
	local hide = not self.db.profile.minimap.hide
	self.db.profile.minimap.hide = hide

	if hide then
		LibDBIcon:Hide("Lib's Social")
	else
		LibDBIcon:Show("Lib's Social")
	end
end
