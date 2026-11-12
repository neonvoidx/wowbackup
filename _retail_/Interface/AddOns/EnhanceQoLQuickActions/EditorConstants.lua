local DraggedItemMixin = {}
_G.EQOLQuickCastEditorDraggedItemMixin = DraggedItemMixin

function DraggedItemMixin:SetToCursor(texture, atlas, action)
	_G.EnhanceQoL.QuickCast:SetActionIcon(self.Icon, self, texture, atlas, action)
	self:Show()
end

function DraggedItemMixin:OnUpdate()
	local topLevel = _G.GetAppropriateTopLevelParent and _G.GetAppropriateTopLevelParent() or _G.UIParent
	local x, y
	if _G.GetScaledCursorPositionForFrame then
		x, y = _G.GetScaledCursorPositionForFrame(topLevel)
	else
		x, y = _G.GetCursorPosition()
		local scale = topLevel:GetEffectiveScale()
		x, y = x / scale, y / scale
	end
	self:ClearAllPoints()
	self:SetPoint("TOPLEFT", topLevel, "BOTTOMLEFT", x + 8, y - 8)
end

local ReorderMarkerMixin = {}
_G.EQOLQuickCastEditorReorderMarkerMixin = ReorderMarkerMixin

function ReorderMarkerMixin:SetHorizontal()
	self.Texture:SetAtlas("cdm-horizontal", true)
end

function ReorderMarkerMixin:SetVertical()
	self.Texture:SetAtlas("CDM-vertical", true)
end
