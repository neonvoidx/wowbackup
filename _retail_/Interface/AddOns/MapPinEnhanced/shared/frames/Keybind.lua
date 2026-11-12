---@class MapPinEnhanced
local MapPinEnhanced = select(2, ...)
local L = MapPinEnhanced.L

---@type MapPinEnhancedKeybindTemplate?
local listeningButton

---@class MapPinEnhancedKeybindTemplate : MapPinEnhancedButtonTemplate
---@field bindingAction string?
---@field available boolean?
---@field pendingKey string?
---@field refreshBinding fun()?
---@field cancelOnMouseDown fun()?
MapPinEnhancedKeybindMixin = {}

function MapPinEnhancedKeybindMixin:OnLoad()
    MapPinEnhancedButtonMixin.OnLoad(self)
    self:RegisterForClicks("AnyUp")
    self:EnableKeyboard(false)
    self:EnableMouseWheel(false)
    self:SetMotionScriptsWhileDisabled(true)
    self:Disable()
end

---@param action string
function MapPinEnhancedKeybindMixin:Setup(action)
    assert(type(action) == "string" and action ~= "", "Keybind:Setup requires a binding action")
    self:Reset()
    self.bindingAction = action
    self.available = true
    if self:IsShown() then self:OnShow() end
end

function MapPinEnhancedKeybindMixin:StopListening()
    if listeningButton == self then listeningButton = nil end
    self.pendingKey = nil
    self:EnableKeyboard(false)
    self:EnableMouseWheel(false)
end

function MapPinEnhancedKeybindMixin:RefreshBinding()
    local enabled = self.bindingAction ~= nil and self.available ~= false and not InCombatLockdown()
    if not enabled then self:StopListening() end
    self:SetEnabled(enabled)
    local key = self.bindingAction and GetBindingKey(self.bindingAction)
    self:SetLabel(listeningButton == self and L["Press a key..."] or (key and GetBindingText(key) or L["Not bound"]))
    self:SetTooltip(InCombatLockdown() and L["Keybinds cannot be changed during combat."] or
        L["Click to set a keybind. Right-click to clear. Escape cancels."])
    if GameTooltip:GetOwner() == self then self:OnTooltipEnter() end
end

---@param available boolean
function MapPinEnhancedKeybindMixin:SetAvailable(available)
    self.available = available
    self:RefreshBinding()
end

---@param key string?
function MapPinEnhancedKeybindMixin:ApplyBinding(key)
    if not self.bindingAction or self.available == false or InCombatLockdown() then return end
    local oldKeys = { GetBindingKey(self.bindingAction) }
    -- Preserve the old shortcut if Blizzard rejects the new key.
    if key and not SetBinding(key, self.bindingAction) then
        self.pendingKey = nil
        self:SetLabel(L["Invalid keybind"])
        return
    end
    for _, oldKey in ipairs(oldKeys) do
        if oldKey ~= key then SetBinding(oldKey) end
    end
    SaveBindings(GetCurrentBindingSet())
    self:StopListening()
    self:RefreshBinding()
end

---@param key string
function MapPinEnhancedKeybindMixin:OnKeyDown(key)
    if listeningButton ~= self then return end
    if key == "ESCAPE" then
        self:StopListening()
        self:RefreshBinding()
        return
    end
    key = GetConvertedKeyOrButton(key)
    if IsKeyPressIgnoredForBinding(key) then return end
    key = CreateKeyChordStringUsingMetaKeyState(key)
    local action = GetBindingAction(key)
    if action ~= "" and action ~= self.bindingAction and self.pendingKey ~= key then
        self.pendingKey = key
        self:SetLabel(L["Press again to replace"])
        self:SetTooltip(string.format(L["%s is bound to %s. Press it again to replace that binding."],
            GetBindingText(key), GetBindingName(action)))
        self:OnTooltipEnter()
        return
    end
    self:ApplyBinding(key)
end

---@param button mouseButton
function MapPinEnhancedKeybindMixin:OnClick(button)
    if not self:IsEnabled() then return end
    if button == "RightButton" then
        self:ApplyBinding(nil)
    elseif button == "LeftButton" then
        if listeningButton == self then
            self:StopListening()
        else
            if listeningButton then
                local previous = listeningButton
                previous:StopListening()
                previous:RefreshBinding()
            end
            local focus = GetCurrentKeyBoardFocus()
            if focus then focus:ClearFocus() end
            listeningButton = self
            self:EnableKeyboard(true)
            self:SetPropagateKeyboardInput(false)
            self:EnableMouseWheel(true)
        end
        self:RefreshBinding()
    else
        self:OnKeyDown(button)
    end
end

---@param delta number
function MapPinEnhancedKeybindMixin:OnMouseWheel(delta)
    self:OnKeyDown(delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN")
end

function MapPinEnhancedKeybindMixin:OnShow()
    if self.bindingAction and not self.refreshBinding then
        self.refreshBinding = function() self:RefreshBinding() end
        self.cancelOnMouseDown = function()
            if listeningButton == self and not self:IsMouseOver() then
                self:StopListening()
                self:RefreshBinding()
            end
        end
        MapPinEnhanced:RegisterEvent("UPDATE_BINDINGS", self.refreshBinding)
        MapPinEnhanced:RegisterEvent("PLAYER_REGEN_DISABLED", self.refreshBinding)
        MapPinEnhanced:RegisterEvent("PLAYER_REGEN_ENABLED", self.refreshBinding)
        MapPinEnhanced:RegisterEvent("GLOBAL_MOUSE_DOWN", self.cancelOnMouseDown)
    end
    self:RefreshBinding()
end

function MapPinEnhancedKeybindMixin:OnHide()
    self:StopListening()
    if self.refreshBinding then
        MapPinEnhanced:UnregisterEventForFunction("UPDATE_BINDINGS", self.refreshBinding)
        MapPinEnhanced:UnregisterEventForFunction("PLAYER_REGEN_DISABLED", self.refreshBinding)
        MapPinEnhanced:UnregisterEventForFunction("PLAYER_REGEN_ENABLED", self.refreshBinding)
        self.refreshBinding = nil
    end
    if self.cancelOnMouseDown then
        MapPinEnhanced:UnregisterEventForFunction("GLOBAL_MOUSE_DOWN", self.cancelOnMouseDown)
        self.cancelOnMouseDown = nil
    end
    self:OnTooltipLeave()
end

function MapPinEnhancedKeybindMixin:Reset()
    self:OnHide()
    self.bindingAction = nil
    self.available = nil
    self:RefreshBinding()
    self:SetTooltip(nil)
end
