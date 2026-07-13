-- Overachiever2: History
-- Browser-style back/forward navigation for the Achievement UI.

local addonName, ns = ...

local Utils = Overachiever2.Utils
local L = ns.L

-- Re-entrancy guard: true while programmatic back/forward navigation is in progress
local navigating = false

-- UI elements (created when Blizzard_AchievementUI loads)
local holder, backBtn, fwdBtn, posText, mouseOverlay

-- Default keybinds of back/forward for history
local defaultBack = "BUTTON4"
local defaultForward = "BUTTON5"

-- ============================================================================
-- Data Model
-- ============================================================================

local function IsEnabled()
    return Overachiever2_Settings and Overachiever2_Settings.EnableHistory
end

local function GetHistory()
    Overachiever2_CharSettings = Overachiever2_CharSettings or {}
    if not Overachiever2_CharSettings.History then
        Overachiever2_CharSettings.History = {
            entries = {},
            cursor = 0,
        }
    end
    return Overachiever2_CharSettings.History
end

local function GetMaxSize()
    return (Overachiever2_Settings and Overachiever2_Settings.HistoryMaxSize) or 10
end

-- Forward declaration
local UpdateButtons

local function TrimToMaxSize(history)
    local maxSize = GetMaxSize()
    while #history.entries > maxSize do
        table.remove(history.entries, 1)
        history.cursor = history.cursor - 1
        if history.cursor < 1 then
            history.cursor = math.min(1, #history.entries)
        end
    end
end

local function Push(achID)
    if not IsEnabled() then return end
    if navigating then return end
    if ns.IsSessionRestoring and ns.IsSessionRestoring() then return end
    if not achID or achID == 0 then return end

    local history = GetHistory()

    -- Deduplication: consecutive duplicate is a no-op
    if history.cursor > 0 and history.entries[history.cursor] == achID then
        return
    end

    -- Branching: discard everything after cursor
    if history.cursor < #history.entries then
        for i = #history.entries, history.cursor + 1, -1 do
            table.remove(history.entries, i)
        end
    end

    -- Append new entry
    table.insert(history.entries, achID)
    history.cursor = #history.entries

    -- Trim to max size
    TrimToMaxSize(history)

    if UpdateButtons then UpdateButtons() end
end

local function CanGoBack()
    local history = GetHistory()
    return history.cursor > 1
end

local function CanGoForward()
    local history = GetHistory()
    return history.cursor < #history.entries
end

local function NavigateTo()
    local history = GetHistory()
    if history.cursor < 1 or history.cursor > #history.entries then return end

    local achID = history.entries[history.cursor]

    -- Validate the achievement
    if not C_AchievementInfo.IsValidAchievement(achID) then
        -- Remove invalid entry and adjust cursor
        table.remove(history.entries, history.cursor)
        if history.cursor > #history.entries then
            history.cursor = #history.entries
        end
        if UpdateButtons then UpdateButtons() end
        return
    end

    navigating = true
    AchievementFrame_SelectAchievement(achID)
    navigating = false

    if UpdateButtons then UpdateButtons() end
end

local function GoBack(steps)
    if not IsEnabled() then return end
    steps = steps or 1
    local history = GetHistory()
    local newCursor = history.cursor - steps
    if newCursor < 1 then newCursor = 1 end
    if newCursor == history.cursor then return end
    history.cursor = newCursor
    NavigateTo()
end

local function GoForward(steps)
    if not IsEnabled() then return end
    steps = steps or 1
    local history = GetHistory()
    local newCursor = history.cursor + steps
    if newCursor > #history.entries then newCursor = #history.entries end
    if newCursor == history.cursor then return end
    history.cursor = newCursor
    NavigateTo()
end

local function GoToIndex(index)
    if not IsEnabled() then return end
    local history = GetHistory()
    if index < 1 or index > #history.entries then return end
    if index == history.cursor then return end
    history.cursor = index
    NavigateTo()
end

local function GetBackList()
    local history = GetHistory()
    local list = {}
    for i = history.cursor - 1, 1, -1 do
        table.insert(list, { index = i, achID = history.entries[i] })
    end
    return list
end

local function GetForwardList()
    local history = GetHistory()
    local list = {}
    for i = history.cursor + 1, #history.entries do
        table.insert(list, { index = i, achID = history.entries[i] })
    end
    return list
end

local function GetPositionText()
    local history = GetHistory()
    if history.cursor == 0 or #history.entries == 0 then return "" end
    return string.format("%d /%d", history.cursor, #history.entries)
end

-- ============================================================================
-- Exposed functions for slash commands (via ns) and keybinds (via global table)
-- ============================================================================

function ns.HistoryClear()
    local history = GetHistory()
    wipe(history.entries)
    history.cursor = 0
    if UpdateButtons then UpdateButtons() end
end

function ns.HistoryPrintStatus()
    local history = GetHistory()
    if #history.entries == 0 then
        Utils.Print(L["HISTORY_EMPTY"])
    else
        Utils.Print(string.format(L["HISTORY_STATUS"], #history.entries, history.cursor))
    end
end

function Overachiever2.HistoryGoBack()
    if AchievementFrame and AchievementFrame:IsShown() then
        GoBack(1)
    end
end

function Overachiever2.HistoryGoForward()
    if AchievementFrame and AchievementFrame:IsShown() then
        GoForward(1)
    end
end

-- Callbacks from Options.lua
function ns.HistoryOnSettingChanged()
    if UpdateButtons then UpdateButtons() end
end

function ns.HistoryOnMaxSizeChanged()
    local history = GetHistory()
    TrimToMaxSize(history)
    if UpdateButtons then UpdateButtons() end
end

-- ============================================================================
-- UI: Buttons, Position Text, Dropdown
-- ============================================================================

local function ShowHistoryDropdown(anchorFrame, direction)
    local list = (direction == "back") and GetBackList() or GetForwardList()
    if #list == 0 then return end

    MenuUtil.CreateContextMenu(anchorFrame, function(ownerRegion, rootDescription)
        for _, entry in ipairs(list) do
            local _, name, _, _, _, _, _, _, _, icon = ns.GetAchievementInfo(entry.achID)
            if name then
                local text = name
                if icon then
                    text = "|T" .. icon .. ":14:14|t " .. name
                end
                rootDescription:CreateButton(text, function()
                    GoToIndex(entry.index)
                end)
            end
        end
    end)
end

local function CreateUI()
    -- Holder frame anchored to the right of the point border box
    holder = CreateFrame("Frame", "OA2HistoryHolder", AchievementFrame)
    holder:SetSize(64, 32)
    holder:SetPoint("LEFT", AchievementFrame.Header.PointBorder, "RIGHT", -5, 0)

    -- Back button
    backBtn = CreateFrame("Button", "OA2HistoryBackButton", holder)
    backBtn:SetSize(32, 32)
    backBtn:SetPoint("LEFT", holder, "LEFT", 0, 0)

    backBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    backBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    backBtn:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
    backBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    backBtn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            ShowHistoryDropdown(self, "back")
        else
            GoBack(1)
        end
    end)
    backBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    backBtn:SetScript("OnEnter", function(self)
        Utils.ShowTip(self, "ANCHOR_BOTTOM", L["OPT_HISTORY_BACK_KEY_TITLE"], L["HISTORY_TIP_RIGHTCLICK"])
    end)
    backBtn:SetScript("OnLeave", Utils.HideTip)

    -- Forward button
    fwdBtn = CreateFrame("Button", "OA2HistoryForwardButton", holder)
    fwdBtn:SetSize(32, 32)
    fwdBtn:SetPoint("LEFT", holder, "RIGHT", -32, 0)

    fwdBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    fwdBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    fwdBtn:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
    fwdBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    fwdBtn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            ShowHistoryDropdown(self, "forward")
        else
            GoForward(1)
        end
    end)
    fwdBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    fwdBtn:SetScript("OnEnter", function(self)
        Utils.ShowTip(self, "ANCHOR_BOTTOM", L["OPT_HISTORY_FORWARD_KEY_TITLE"], L["HISTORY_TIP_RIGHTCLICK"])
    end)
    fwdBtn:SetScript("OnLeave", Utils.HideTip)

    -- Help icon (sized to match the position indicator font)
    local helpIcon = CreateFrame("Frame", nil, holder)
    local fontObj = GameFontNormalSmall
    local _, fontSize = fontObj:GetFont()
    local iconSize = fontSize + 12
    helpIcon:SetSize(iconSize, iconSize)
    helpIcon:SetPoint("BOTTOMLEFT", backBtn, "TOPLEFT", 0, -6)

    local helpTexture = helpIcon:CreateTexture(nil, "ARTWORK")
    helpTexture:SetAllPoints()
    helpTexture:SetTexture("Interface\\common\\help-i")

    helpIcon:SetScript("OnEnter", function(self)
        local backKey = GetBindingKey("OA2_KB_HISTORY_BACK") or defaultBack
        local fwdKey = GetBindingKey("OA2_KB_HISTORY_FORWARD") or defaultForward
        local backText = backKey and GetBindingText(backKey) or "—"
        local fwdText = fwdKey and GetBindingText(fwdKey) or "—"
        Utils.ShowTip(self, "ANCHOR_LEFT", L["HISTORY_HELP_TITLE"],
            string.format(L["HISTORY_HELP_DESC"], Utils.WhiteText(backText), Utils.WhiteText(fwdText)))
    end)
    helpIcon:SetScript("OnLeave", Utils.HideTip)

    -- Position indicator (centered between the two buttons)
    posText = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    posText:SetPoint("BOTTOMRIGHT", fwdBtn, "TOPRIGHT", -5, 0)
    -- posText:SetPoint("LEFT", helpIcon, "RIGHT", -3, 0)
    posText:SetText("")

    -- Transparent overlay to capture mouse-button keybinds inside the achievement
    -- frame. Already created at addon-load time with SetPassThroughButtons applied
    -- (combat-restricted). It stays a child of UIParent to avoid re-parenting
    -- pitfalls (SetParent doesn't recalc frame level/strata like CreateFrame does);
    -- we just anchor its geometry to AchievementFrame here. Visibility is synced
    -- via OnShow/OnHide hooks in InstallHooks().
    mouseOverlay:ClearAllPoints()
    mouseOverlay:SetPoint("TOPLEFT", AchievementFrame, "TOPLEFT", 0, 0)
    mouseOverlay:SetPoint("BOTTOMRIGHT", AchievementFrame, "BOTTOMRIGHT", 0, 0)
end

UpdateButtons = function()
    if not holder then return end
    backBtn:SetEnabled(CanGoBack())
    fwdBtn:SetEnabled(CanGoForward())
    posText:SetText(GetPositionText())
    holder:SetShown(IsEnabled())
end

-- ============================================================================
-- Override Bindings (Achievement-window-only)
-- ============================================================================

-- Convert a binding key name like "BUTTON4" or "SHIFT-BUTTON5" to the
-- RegisterForClicks token(s) needed, e.g. "Button4Up".  Returns nil for
-- non-mouse-button keys (keyboard keybinds handled via Bindings.xml).
local function BindingKeyToClickToken(bindingKey)
    local num = bindingKey and bindingKey:match("BUTTON(%d+)$")
    if num then return "Button" .. num .. "Up" end
end

local function RefreshOverlayClicks()
    if not mouseOverlay then return end
    local clicks = {}
    local seen = {}
    local function add(token)
        if token and not seen[token] then
            seen[token] = true
            clicks[#clicks + 1] = token
        end
    end
    -- Always include the defaults
    add("Button4Up")
    add("Button5Up")
    -- Include whatever the user configured (may be same or different mouse buttons)
    add(BindingKeyToClickToken(GetBindingKey("OA2_KB_HISTORY_BACK")))
    add(BindingKeyToClickToken(GetBindingKey("OA2_KB_HISTORY_FORWARD")))
    mouseOverlay:RegisterForClicks(unpack(clicks))
end

-- SetOverrideBindingClick / ClearOverrideBindings are combat-protected. The
-- achievement frame can open mid-combat via the TOGGLEACHIEVEMENT keybind, so
-- we defer binding install/remove until PLAYER_REGEN_ENABLED when needed and
-- reconcile against the current AchievementFrame shown state.
local bindingCombatFrame
local needsBindingReconcile = false

local function ApplyOverrideBindings()
    if not holder then return end
    if AchievementFrame and AchievementFrame:IsShown() and IsEnabled() then
        local backKey = GetBindingKey("OA2_KB_HISTORY_BACK") or defaultBack
        local fwdKey = GetBindingKey("OA2_KB_HISTORY_FORWARD") or defaultForward
        SetOverrideBindingClick(holder, true, backKey, backBtn:GetName())
        SetOverrideBindingClick(holder, true, fwdKey, fwdBtn:GetName())
        RefreshOverlayClicks()
    else
        ClearOverrideBindings(holder)
    end
end

local function RequestOverrideBindingReconcile()
    if InCombatLockdown() then
        needsBindingReconcile = true
        if not bindingCombatFrame then
            bindingCombatFrame = CreateFrame("Frame")
            bindingCombatFrame:SetScript("OnEvent", function(self)
                if not InCombatLockdown() and needsBindingReconcile then
                    needsBindingReconcile = false
                    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                    ApplyOverrideBindings()
                end
            end)
        end
        bindingCombatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    ApplyOverrideBindings()
end

local function InstallOverrideBindings()
    if not IsEnabled() or not holder then return end
    RequestOverrideBindingReconcile()
end

local function RemoveOverrideBindings()
    if not holder then return end
    RequestOverrideBindingReconcile()
end

-- ============================================================================
-- Hooks & Initialization
-- ============================================================================

local function InstallHooks()
    -- Record achievement visits from row clicks
    hooksecurefunc(AchievementTemplateMixin, "OnClick", function(self)
        if not navigating then
            local achID = AchievementFrameAchievements_GetSelectedAchievementId()
            if achID then Push(achID) end
        end
    end)

    -- Record achievement visits from programmatic navigation (search, links, meta-criteria, etc.)
    hooksecurefunc("AchievementFrame_SelectAchievement", function(id)
        if not navigating then
            Push(id)
        end
    end)

    -- Override bindings + overlay visibility on show/hide. The overlay is a
    -- child of UIParent (not AchievementFrame), so visibility does not track
    -- automatically — we sync it here.
    AchievementFrame:HookScript("OnShow", function()
        if mouseOverlay then mouseOverlay:Show() end
        InstallOverrideBindings()
        UpdateButtons()
    end)
    AchievementFrame:HookScript("OnHide", function()
        if mouseOverlay then mouseOverlay:Hide() end
        RemoveOverrideBindings()
    end)
end

local function Initialize()
    CreateUI()
    RefreshOverlayClicks()
    InstallHooks()
    UpdateButtons()
end

-- ============================================================================
-- PLAYER_LOGOUT: wipe history if persistence is disabled
-- ============================================================================

local logoutFrame = CreateFrame("Frame")
logoutFrame:RegisterEvent("PLAYER_LOGOUT")
logoutFrame:SetScript("OnEvent", function()
    if Overachiever2_Settings and not Overachiever2_Settings.HistoryPersist then
        local history = GetHistory()
        wipe(history.entries)
        history.cursor = 0
    end
end)

-- ============================================================================
-- Eager overlay creation: SetPassThroughButtons is combat-restricted, so we
-- create it at addon-load time (always out of combat except after /reload
-- during combat). Parented to UIParent (not AchievementFrame) to avoid the
-- frame-level/strata issues that SetParent causes; geometry and visibility
-- are synced against AchievementFrame in CreateUI / the OnShow|OnHide hooks.
-- ============================================================================

mouseOverlay = CreateFrame("Button", nil, UIParent)
mouseOverlay:SetFrameStrata("DIALOG")
mouseOverlay:SetMouseMotionEnabled(false) -- let tooltips work through the overlay
mouseOverlay:Hide()
mouseOverlay:SetScript("OnClick", function(self, button)
    local mods = ""
    if IsAltKeyDown() then mods = mods .. "ALT-" end
    if IsControlKeyDown() then mods = mods .. "CTRL-" end
    if IsShiftKeyDown() then mods = mods .. "SHIFT-" end
    local fullKey = mods .. button:upper()

    local backKey = GetBindingKey("OA2_KB_HISTORY_BACK") or defaultBack
    local fwdKey = GetBindingKey("OA2_KB_HISTORY_FORWARD") or defaultForward
    if fullKey == backKey then
        GoBack(1)
    elseif fullKey == fwdKey then
        GoForward(1)
    end
end)

if not InCombatLockdown() then
    mouseOverlay:SetPassThroughButtons("LeftButton", "RightButton", "MiddleButton")
else
    -- Only reachable via /reload during combat. Retry when combat ends.
    local regenFrame = CreateFrame("Frame")
    regenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    regenFrame:SetScript("OnEvent", function(self)
        if mouseOverlay and not InCombatLockdown() then
            mouseOverlay:SetPassThroughButtons("LeftButton", "RightButton", "MiddleButton")
            self:UnregisterAllEvents()
        end
    end)
end

-- ============================================================================
-- Wait for Blizzard_AchievementUI to load
-- ============================================================================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, loadedName)
    if loadedName == "Blizzard_AchievementUI" then
        Initialize()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- If already loaded
if AchievementFrame then
    Initialize()
    initFrame:UnregisterEvent("ADDON_LOADED")
end
