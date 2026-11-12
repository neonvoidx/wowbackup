-- ManaRise - Report.lua
-- /mr report: a window with the status text, ready to copy into a bug report.
-- The text is collected by running the status and scan commands with chat
-- output redirected (ns.capture). If the window can't be built on this client,
-- the same lines go to chat.

local _, ns = ...
local L = ns.L

local R = {}
ns.Report = R

local function Plain(s)
    s = string.gsub(s, "|c%x%x%x%x%x%x%x%x", "")
    return (string.gsub(s, "|r", ""))
end

function R:Collect()
    local lines = {}
    local build, _, _, toc = "?", nil, nil, nil
    if GetBuildInfo then build, _, _, toc = GetBuildInfo() end
    lines[#lines + 1] = string.format("ManaRise %s | client %s (toc %s) | locale %s/%s",
        tostring(ns.version), tostring(build), tostring(toc), tostring(GetLocale and GetLocale()), tostring(ns.locale))
    if UnitClass then lines[#lines + 1] = "class: " .. tostring(select(2, UnitClass("player"))) end
    ns.capture = {}
    local ok, err = pcall(function()
        SlashCmdList.MANARISE("status")
        if ns.apiOK then SlashCmdList.MANARISE("scan") end
    end)
    local got = ns.capture
    ns.capture = nil
    for i = 1, #got do lines[#lines + 1] = Plain(got[i]) end
    if not ok then
        lines[#lines + 1] = "error: " .. tostring(err)
        ns:LogError("report", err)
    end
    if ns.apiOK and ns.ActionBars then
        local total, squares, gamepad = ns.ActionBars:ButtonStats()
        lines[#lines + 1] = string.format("buttons: %d tracked, %d with a ManaRise square icon mask, %d Gamepad buttons skipped",
            total, squares, gamepad)
    end
    if #ns.errors == 0 then
        lines[#lines + 1] = "recent errors: none"
    else
        lines[#lines + 1] = "recent errors:"
        for _, e in ipairs(ns.errors) do
            lines[#lines + 1] = string.format("  %s%s: %s", e.where, e.count > 1 and (" x" .. e.count) or "", e.msg)
        end
    end
    if ns.missingKeys then
        local keys = {}
        for k in pairs(ns.missingKeys) do keys[#keys + 1] = tostring(k) end
        lines[#lines + 1] = "missing texts: " .. table.concat(keys, ", ")
    end
    return lines
end

local function Build()
    local f = CreateFrame("Frame", "ManaRiseReportFrame", UIParent, "BackdropTemplate")
    f:SetSize(560, 360)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -10)
    title:SetText(L.REPORT_TITLE)

    local scroll = CreateFrame("ScrollFrame", "ManaRiseReportScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -34)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -32, 40)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetWidth(500)
    edit:SetScript("OnEscapePressed", function() f:Hide() end)
    scroll:SetScrollChild(edit)
    f.edit = edit

    local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    close:SetSize(100, 22)
    close:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
    close:SetText(L.REPORT_CLOSE)
    close:SetScript("OnClick", function() f:Hide() end)
    return f
end

function R:Show()
    local lines = self:Collect()
    if not self.frame then
        if ns:InCombat() then
            ns:Print(L.REPORT_AFTER_COMBAT)
            return
        end
        local ok, frame = pcall(Build)
        if not ok then
            ns:Print(L.REPORT_FALLBACK, tostring(frame))
            for i = 1, #lines do ns:Print("%s", lines[i]) end
            return
        end
        self.frame = frame
    end
    self.text = table.concat(lines, "\n")
    self.frame.edit:SetText(self.text)
    self.frame:Show()
    self.frame.edit:SetFocus()
    self.frame.edit:HighlightText()
end
