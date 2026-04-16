----------------------------------------------------------------------
-- MidnightCheatSheet – UI.lua
-- 5 tabs: Stats | Consumes & Enchants | Wishlist | Gearing | Talents
-- Wishlist supports multiple named lists per spec.
----------------------------------------------------------------------
local _, MCS = ...

local pairs, ipairs, format, type, tostring, tonumber = pairs, ipairs, format, type, tostring, tonumber
local wipe, strtrim, select = wipe, strtrim, select
local table_insert, table_sort = table.insert, table.sort
local math_rad, math_deg, math_cos, math_sin, math_max, math_abs = math.rad, math.deg, math.cos, math.sin, math.max, math.abs
local math_atan2 = math.atan2
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local IsAltKeyDown, IsShiftKeyDown = IsAltKeyDown, IsShiftKeyDown
local GetCursorPosition = GetCursorPosition
local GetCombatRating, GetCombatRatingBonus = GetCombatRating, GetCombatRatingBonus
local GetItemQualityColor = GetItemQualityColor
local HandleModifiedItemClick = HandleModifiedItemClick
local C_Item = C_Item
local C_CurrencyInfo = C_CurrencyInfo
local C_Timer = C_Timer
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local Minimap = Minimap
local UIParent = UIParent
local GetTime = GetTime

local W, H = 480, 560
local PAD, ICON = 8, 22
local recycleFrame = CreateFrame("Frame"); recycleFrame:Hide()
local COL = {
    gold={1,.82,0}, white={1,1,1}, grey={.55,.55,.55},
    green={.2,1,.2}, red={1,.3,.3}, bg={.05,.05,.1,.92},
    Haste={.2,1,.6}, Crit={1,.4,.4}, Mastery={.9,.6,1}, Vers={.5,.8,1},
}

----------------------------------------------------------------------
-- Wishlist picker popup (dropdown when alt-clicking an item)
-- Shows ALL specs for this class, each with their wishlists.
-- Multi-select: stays open, toggles items in-place.
----------------------------------------------------------------------
local pickerFrame

local function CreatePicker()
    if pickerFrame then return pickerFrame end
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize(220, 40); f:SetFrameStrata("TOOLTIP"); f:SetFrameLevel(100)
    f:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=12,
        insets={left=3,right=3,top=3,bottom=3} })
    f:SetBackdropColor(.06,.06,.12,.97); f:SetBackdropBorderColor(0,.6,1,.9)
    f:EnableMouse(true); f:Hide()
    f._anchor = nil
    f._openTime = 0
    f:SetScript("OnShow", function(self)
        self._closeTimer = 0
        self._openTime = GetTime()
    end)
    -- Auto-close: generous grace period, also keep open if mouse is on anchor
    f:SetScript("OnUpdate", function(self, elapsed)
        if GetTime() - self._openTime < 1.5 then
            self._closeTimer = 0
            return
        end
        local overPicker = self:IsMouseOver()
        local overAnchor = self._anchor and self._anchor.IsMouseOver and self._anchor:IsMouseOver()
        if overPicker or overAnchor then
            self._closeTimer = 0
        else
            self._closeTimer = self._closeTimer + elapsed
            if self._closeTimer > 1.2 then self:Hide() end
        end
    end)
    f.elements = {}
    pickerFrame = f
    return f
end

local function ShowPicker(itemID, source, anchor)
    local f = CreatePicker()
    -- Clear old elements
    for _, el in ipairs(f.elements) do
        el:Hide()
        el:SetParent(recycleFrame)
    end
    wipe(f.elements)

    f._itemID = itemID
    f._source = source

    local cls = MCS:GetPlayerClass()
    local specs = cls and MCS.ALL_SPECS[cls]
    if not specs then return end

    local y = 6
    local maxW = 210

    -- Title: item name
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetFont(STANDARD_TEXT_FONT, 10, "")
    title:SetPoint("TOPLEFT", 8, -y)
    title:SetTextColor(0, .8, 1)
    title:SetText("Add/Remove from wishlists:")
    table_insert(f.elements, title)
    y = y + 15

    -- Build list for each spec
    for _, specName in ipairs(specs) do
        local specKey = MCS:MakeSpecKey(cls, specName)
        local isActiveSpec = (specName == MCS.currentSpec)
        local listNames = MCS:GetListNames(specKey)

        -- Spec header
        local specHdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        specHdr:SetFont(STANDARD_TEXT_FONT, 10, "")
        specHdr:SetPoint("TOPLEFT", 8, -y)
        local r, g, b = MCS:ClassColor(cls)
        if isActiveSpec then
            specHdr:SetTextColor(r, g, b)
            specHdr:SetText(specName .. "  |cff666666(active)|r")
        else
            specHdr:SetTextColor(r * .65, g * .65, b * .65)
            specHdr:SetText(specName)
        end
        table_insert(f.elements, specHdr)
        y = y + 14

        -- One button per list under this spec
        -- Show preset lists first (read-only indicator), then user lists (toggleable)
        for _, ln in ipairs(listNames) do
            local isPreset = MCS:IsPresetList(specKey, ln)
            local onList = MCS:IsOnWishlist(itemID, specKey, ln)
            local btn = CreateFrame("Button", nil, f)
            btn:SetSize(maxW - 16, 18); btn:SetPoint("TOPLEFT", 16, -y)
            local hl = btn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, .08)
            local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            txt:SetFont(STANDARD_TEXT_FONT, 11, ""); txt:SetPoint("LEFT", 4, 0)

            -- Store references for in-place update
            btn._specKey = specKey
            btn._listName = ln
            btn._txt = txt
            btn._isPreset = isPreset

            local function UpdateBtnText(b)
                if b._isPreset then
                    -- Preset: show read-only status
                    local isOn = MCS:IsOnWishlist(itemID, b._specKey, b._listName)
                    if isOn then
                        b._txt:SetText("|cff6688cc\226\156\147  [BiS] " .. b._listName .. "|r")
                    else
                        b._txt:SetText("|cff445577   [BiS] " .. b._listName .. "|r")
                    end
                else
                    -- User list: toggleable
                    local isOn = MCS:IsOnWishlist(itemID, b._specKey, b._listName)
                    if isOn then
                        b._txt:SetText("|cffff6666\226\156\147  " .. b._listName .. "|r  |cff888888(on list)|r")
                    else
                        b._txt:SetText("|cff00ff00+  " .. b._listName .. "|r")
                    end
                end
            end
            UpdateBtnText(btn)

            if isPreset then
                -- Preset lists are not clickable in picker (read-only)
                btn:SetScript("OnEnter", function(b)
                    GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
                    GameTooltip:AddLine("|cff6688cc[BiS]|r " .. ln, 1,1,1)
                    GameTooltip:AddLine("Addon-provided list (read-only)", .6,.6,.6)
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            else
                -- User lists are toggleable
                btn:SetScript("OnClick", function(b)
                    local added = MCS:ToggleWishlistItem(itemID, b._specKey, b._listName, source)
                    if added == nil then return end  -- blocked (preset)
                    local link = MCS:GetItemLink(itemID) or tostring(itemID)
                    local msg = added and "|cff00ff00+|r" or "|cffff4444-|r"
                    print(format("|cff00ccff[MCS]|r %s %s (%s / %s)", msg, link, MCS:FormatSpecKey(b._specKey), b._listName))
                    UpdateBtnText(b)
                    if MCS.frame and MCS.frame:IsShown() then MCS:UpdateUI() end
                    f._closeTimer = 0
                    f._openTime = GetTime()
                end)
            end

            table_insert(f.elements, btn)
            y = y + 18
        end

        y = y + 4  -- gap between specs
    end

    -- Close button at bottom
    y = y + 2
    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(maxW - 16, 16); closeBtn:SetPoint("TOPLEFT", 8, -y)
    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeTxt:SetFont(STANDARD_TEXT_FONT, 9, ""); closeTxt:SetAllPoints()
    closeTxt:SetTextColor(.5, .5, .5); closeTxt:SetText("Click to close")
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    local clHL = closeBtn:CreateTexture(nil, "HIGHLIGHT")
    clHL:SetAllPoints(); clHL:SetColorTexture(1, 1, 1, .05)
    table_insert(f.elements, closeBtn)
    y = y + 18

    local pickerH = y + 4
    f:SetSize(maxW, pickerH)
    f:ClearAllPoints()
    f._anchor = anchor

    local posX, posY
    if anchor and anchor.GetRight then
        local aR = anchor:GetRight()
        local aT = anchor:GetTop()
        local s = anchor:GetEffectiveScale()
        posX = aR
        posY = aT
    else
        local cx, cy = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        posX = cx / s + 8
        posY = cy / s + 8
    end

    -- Clamp to screen: ensure picker stays fully visible
    local uiW, uiH = UIParent:GetWidth(), UIParent:GetHeight()
    -- Right edge
    if posX + maxW > uiW then posX = uiW - maxW - 4 end
    -- Left edge
    if posX < 0 then posX = 4 end
    -- Bottom edge (posY is the TOP of the picker, so bottom = posY - pickerH)
    if posY - pickerH < 0 then posY = pickerH + 4 end
    -- Top edge
    if posY > uiH then posY = uiH - 4 end

    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", posX, posY)
    f:Show()
end

----------------------------------------------------------------------
-- Tooltip hook: show wishlist membership on ALL item tooltips
----------------------------------------------------------------------
local function OnTooltipSetItem(tooltip, data)
    if not MCS.db then return end
    -- Modern tooltip system passes data directly; extract itemID from it
    local itemID
    if data and data.id then
        itemID = data.id
    elseif tooltip.GetItem then
        -- Fallback: try GetItem if available on this tooltip type
        local ok, _, link = pcall(tooltip.GetItem, tooltip)
        if ok and link then
            itemID = tonumber(link:match("item:(%d+)"))
        end
    end
    if not itemID then return end
    local lines = MCS:GetWishlistTooltipText(itemID)
    if not lines then return end
    tooltip:AddLine(" ")
    tooltip:AddLine("|cffFFD100* MCS Wishlist:|r")
    for _, line in ipairs(lines) do
        tooltip:AddLine("   " .. line)
    end
    tooltip:Show()
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)

----------------------------------------------------------------------
-- Chat link hook: Alt-click item links in chat → wishlist picker
----------------------------------------------------------------------
hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
    if not IsAltKeyDown() then return end
    local itemID = tonumber(link:match("item:(%d+)"))
    if not itemID then return end
    -- Build source from chat
    local source = "Chat link"
    ShowPicker(itemID, source, nil)  -- nil anchor = position at cursor
end)

----------------------------------------------------------------------
-- Button pool
----------------------------------------------------------------------
local pool = {}
local function Acquire(parent)
    for _, b in ipairs(pool) do
        if not b._on then b:SetParent(parent); b:ClearAllPoints(); b:Show(); b._on=true; return b end
    end
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(W-40, ICON+4); b:EnableMouse(true); b:RegisterForClicks("AnyUp")
    b.icon = b:CreateTexture(nil,"ARTWORK"); b.icon:SetSize(ICON,ICON); b.icon:SetPoint("LEFT",2,0)
    b.text = b:CreateFontString(nil,"OVERLAY","GameFontNormal")
    b.text:SetFont(STANDARD_TEXT_FONT,11,""); b.text:SetPoint("LEFT",b.icon,"RIGHT",6,0)
    b.text:SetPoint("RIGHT",-22,0); b.text:SetJustifyH("LEFT")
    b.star = b:CreateFontString(nil,"OVERLAY"); b.star:SetFont(STANDARD_TEXT_FONT,14,"")
    b.star:SetPoint("RIGHT",-2,0); b.star:SetTextColor(1,.82,0)
    local hl = b:CreateTexture(nil,"HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1,1,1,.06)
    b:SetScript("OnEnter", function(s)
        if s._itemID then
            GameTooltip:SetOwner(s,"ANCHOR_RIGHT")
            GameTooltip:SetItemByID(s._itemID)
            -- Wishlist info is appended automatically via the tooltip hook
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    b:SetScript("OnClick", function(s, btn)
        if not s._itemID then return end
        if IsShiftKeyDown() and btn=="LeftButton" then
            local link = MCS:GetItemLink(s._itemID)
            if link then
                HandleModifiedItemClick(link)
            end
        elseif IsAltKeyDown() and btn=="LeftButton" then
            ShowPicker(s._itemID, s._src, s)
        end
    end)
    b._on = true; table_insert(pool, b); return b
end

local function ReleaseAll()
    for _, b in ipairs(pool) do b:Hide(); b._on=false; b._itemID=nil; b._src=nil; b.star:SetText("") end
end

local function SetupBtn(btn, itemID, suffix, y, parent, specKey, listName)
    btn:SetParent(parent); btn:SetPoint("TOPLEFT",4,-y); btn._itemID=itemID; btn._src=suffix
    local nm,_,q,_,_,_,_,_,_,tx = C_Item.GetItemInfo(itemID)
    if nm and tx then
        local r,g,b = GetItemQualityColor(q or 1)
        local l = format("|cff%02x%02x%02x%s|r",r*255,g*255,b*255,nm)
        if suffix then l = l.."  |cff888888"..suffix.."|r" end
        btn.text:SetText(l); btn.icon:SetTexture(tx)
    else
        btn.text:SetText("|cff666666item:"..itemID.." (loading)|r"); btn.icon:SetTexture(134400)
        MCS:CacheItem(itemID, function()
            if btn._on and btn._itemID==itemID then
                local n2,_,q2,_,_,_,_,_,_,t2 = C_Item.GetItemInfo(itemID)
                if n2 and t2 then
                    local r2,g2,b2 = GetItemQualityColor(q2 or 1)
                    local l2 = format("|cff%02x%02x%02x%s|r",r2*255,g2*255,b2*255,n2)
                    if suffix then l2=l2.."  |cff888888"..suffix.."|r" end
                    btn.text:SetText(l2); btn.icon:SetTexture(t2)
                end
            end
        end)
    end
    local hits = MCS:FindItemOnLists(itemID)
    btn.star:SetText(#hits > 0 and "*" or "")
end

local function SetupSpellBtn(btn, spellID, name, suffix, y, parent)
    btn:SetParent(parent); btn:SetPoint("TOPLEFT",4,-y); btn._itemID=nil; btn._src=suffix
    local info = C_Spell.GetSpellInfo(spellID)
    local icon = info and info.iconID or 134400
    local l = "|cffa335ee"..name.."|r"
    if suffix then l = l.."  |cff888888"..suffix.."|r" end
    btn.text:SetText(l); btn.icon:SetTexture(icon)
    btn.star:SetText("")
end

----------------------------------------------------------------------
-- Text helpers
----------------------------------------------------------------------
local txts = {}
local function Txt(p, y, text, r, g, b, sz, ind)
    sz=sz or 12; ind=ind or 0
    local fs = p:CreateFontString(nil,"OVERLAY","GameFontNormal")
    fs:SetFont(STANDARD_TEXT_FONT,sz,""); fs:SetPoint("TOPLEFT",PAD+ind,-y)
    fs:SetPoint("RIGHT",-PAD,0); fs:SetJustifyH("LEFT"); fs:SetWordWrap(true)
    fs:SetTextColor(r or 1,g or 1,b or 1); fs:SetText(text)
    table_insert(txts, fs); return y + fs:GetStringHeight() + 2
end
local function Hdr(p, y, text)
    y = y + 6; y = Txt(p,y,text,unpack(COL.gold),13)
    local ln = p:CreateTexture(nil,"ARTWORK"); ln:SetColorTexture(.4,.35,.1,.6); ln:SetHeight(1)
    ln:SetPoint("TOPLEFT",PAD,-y); ln:SetPoint("RIGHT",-PAD,0)
    table_insert(txts, ln); return y + 3
end
local function ClearTxt()
    for _,o in ipairs(txts) do
        o:Hide()
        o:SetParent(recycleFrame)
    end
    wipe(txts)
end
local function ClearC(c)
    local children = {c:GetChildren()}
    for i = 1, #children do children[i]:Hide(); children[i]:SetParent(recycleFrame) end
    local regions = {c:GetRegions()}
    for i = 1, #regions do regions[i]:Hide(); regions[i]:SetParent(recycleFrame) end
end

----------------------------------------------------------------------
-- Small button helper (for nav/action buttons)
----------------------------------------------------------------------
local function SmallBtn(parent, w, text, anchor, offX, offY)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(w, 20)
    if type(anchor) == "table" then
        b:SetPoint("LEFT", anchor, "RIGHT", offX or 4, offY or 0)
    else
        b:SetPoint("TOPLEFT", offX or 0, offY or 0)
    end
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize=8, insets={left=2,right=2,top=2,bottom=2}})
    b:SetBackdropColor(.15,.15,.25,1); b:SetBackdropBorderColor(.4,.4,.6,.8)
    local t = b:CreateFontString(nil,"OVERLAY","GameFontNormal")
    t:SetFont(STANDARD_TEXT_FONT,10,""); t:SetPoint("CENTER"); t:SetText(text)
    b._label = t
    table_insert(txts, b)
    return b
end

----------------------------------------------------------------------
-- Init
----------------------------------------------------------------------
function MCS:InitUI()
    if self.frame then return end
    local f = CreateFrame("Frame","MCSFrame",UIParent,"BackdropTemplate")
    local savedW = MCS.db and MCS.db.windowWidth or W
    local savedH = MCS.db and MCS.db.windowHeight or H
    f:SetSize(savedW, savedH); f:SetPoint("CENTER"); f:SetMovable(true); f:EnableMouse(true)
    f:SetResizable(true); f:SetResizeBounds(380, 300, 800, 900)
    f:SetClampedToScreen(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",f.StartMoving); f:SetScript("OnDragStop",f.StopMovingOrSizing)
    f:SetFrameStrata("HIGH")
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=14,
        insets={left=3,right=3,top=3,bottom=3}})
    f:SetBackdropColor(unpack(COL.bg)); f:SetBackdropBorderColor(.3,.3,.4,.9)
    self.frame = f

    -- Title
    local tb = f:CreateTexture(nil,"ARTWORK"); tb:SetColorTexture(.1,.08,.18,.95); tb:SetHeight(28)
    tb:SetPoint("TOPLEFT",4,-4); tb:SetPoint("TOPRIGHT",-4,-4)
    local ti = f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    ti:SetPoint("LEFT",tb,"LEFT",10,0); ti:SetText("|cff00ccffMidnight Cheat Sheet|r")
    local tiSub = f:CreateFontString(nil,"OVERLAY","GameFontNormal")
    tiSub:SetPoint("LEFT",ti,"RIGHT",2,0); tiSub:SetFont(STANDARD_TEXT_FONT,10,"")
    tiSub:SetTextColor(.55,.55,.55); tiSub:SetText("- by Ch\195\187d-Ravencrest")
    local curLabel = f:CreateFontString(nil,"OVERLAY","GameFontNormal")
    curLabel:SetFont(STANDARD_TEXT_FONT,9,""); curLabel:SetTextColor(.7,.7,.7)
    curLabel:SetText("Current:")
    self.specLabel = f:CreateFontString(nil,"OVERLAY","GameFontNormal")
    self.specLabel:SetPoint("RIGHT",tb,"RIGHT",-36,0); self.specLabel:SetJustifyH("RIGHT")
    self.specLabel:SetFont(STANDARD_TEXT_FONT,10,"")
    curLabel:SetPoint("RIGHT", self.specLabel, "LEFT", -3, 0)
    -- Class selector button (left of spec label)
    local specBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    specBtn:SetHeight(18)
    specBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",
        edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    specBtn:SetBackdropColor(.12,.1,.2,.9); specBtn:SetBackdropBorderColor(.35,.35,.55,.8)
    self.specBtnLabel = specBtn:CreateFontString(nil,"OVERLAY","GameFontNormal")
    self.specBtnLabel:SetFont(STANDARD_TEXT_FONT,9,"")
    self.specBtnLabel:SetPoint("LEFT",4,0); self.specBtnLabel:SetPoint("RIGHT",-4,0)
    self.specBtnLabel:SetJustifyH("CENTER")
    specBtn:SetScript("OnEnter", function(b)
        b:SetBackdropColor(.2,.18,.3,1); b:SetBackdropBorderColor(.5,.5,.7,.9)
    end)
    specBtn:SetScript("OnLeave", function(b)
        b:SetBackdropColor(.12,.1,.2,.9); b:SetBackdropBorderColor(.35,.35,.55,.8)
    end)
    specBtn:SetScript("OnClick", function(b)
        MCS:ShowClassDropdown(b)
    end)
    self.specBtn = specBtn
    local csLabel = f:CreateFontString(nil,"OVERLAY","GameFontNormal")
    csLabel:SetFont(STANDARD_TEXT_FONT,9,""); csLabel:SetTextColor(.7,.7,.7)
    csLabel:SetText("Class:")
    csLabel:SetPoint("RIGHT", specBtn, "LEFT", -3, 0)
    specBtn:SetPoint("RIGHT", curLabel, "LEFT", -10, 0)
    local cb = CreateFrame("Button",nil,f,"UIPanelCloseButton")
    cb:SetPoint("TOPRIGHT",-2,-2); cb:SetScript("OnClick",function() MCS:Hide() end)

    -- 4 Tabs
    local tabY = -34
    local TAB_NAMES = { "Stats", "Consumes & Enchants", "Wishlist", "Gearing", "Talents" }
    self.tabs={}; self.tabFrames={}
    for i, tn in ipairs(TAB_NAMES) do
        local tw = (W-8) / #TAB_NAMES
        local tab = CreateFrame("Button",nil,f,"BackdropTemplate")
        tab:SetSize(tw,22); tab:SetPoint("TOPLEFT",4+(i-1)*tw,tabY)
        tab:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",
            edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,
            insets={left=2,right=2,top=2,bottom=2}})
        tab.txt = tab:CreateFontString(nil,"OVERLAY","GameFontNormal")
        tab.txt:SetFont(STANDARD_TEXT_FONT,10,""); tab.txt:SetPoint("CENTER"); tab.txt:SetText(tn)
        tab:SetScript("OnClick",function() MCS:SelectTab(i) end)
        self.tabs[i] = tab
        local sf = CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT",6,tabY-26); sf:SetPoint("BOTTOMRIGHT",-28,8)
        local c = CreateFrame("Frame",nil,sf); c:SetWidth(W-50); c:SetHeight(1)
        sf:SetScrollChild(c); sf:Hide()
        self.tabFrames[i] = { scroll=sf, content=c }
    end

    -- Resize grip (bottom-right corner, above scrollbar)
    local grip = CreateFrame("Button", nil, f)
    grip:SetFrameLevel(f:GetFrameLevel() + 20)
    grip:SetSize(16, 16); grip:SetPoint("BOTTOMRIGHT", -4, 4)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
        if MCS.db then
            MCS.db.windowWidth = math.floor(f:GetWidth() + 0.5)
            MCS.db.windowHeight = math.floor(f:GetHeight() + 0.5)
        end
        MCS:OnResize()
    end)

    f:SetScript("OnSizeChanged", function(fr, w, h)
        -- Update content widths and tab widths on resize
        local tw = (w - 8) / #TAB_NAMES
        for i, tab in ipairs(MCS.tabs) do
            tab:SetSize(tw, 22)
            tab:SetPoint("TOPLEFT", 4 + (i-1)*tw, tabY)
        end
        for i = 1, #TAB_NAMES do
            local tf = MCS.tabFrames[i]
            if tf then tf.content:SetWidth(w - 50) end
        end
    end)

    -- Scale buttons (bottom-right, left of resize grip)
    local function MakeScaleBtn(label, xOff, delta)
        local sb = CreateFrame("Button", nil, f, "BackdropTemplate")
        sb:SetSize(18, 18); sb:SetPoint("BOTTOMRIGHT", xOff, 4)
        sb:SetFrameLevel(f:GetFrameLevel() + 20)
        sb:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",
            edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
        sb:SetBackdropColor(.15,.12,.25,.9); sb:SetBackdropBorderColor(.4,.4,.6,.8)
        local sbt = sb:CreateFontString(nil,"OVERLAY","GameFontNormal")
        sbt:SetFont(STANDARD_TEXT_FONT,11,""); sbt:SetPoint("CENTER",0,1); sbt:SetText(label)
        sb:SetScript("OnEnter", function(b)
            b:SetBackdropColor(.25,.2,.35,1); b:SetBackdropBorderColor(.6,.6,.8,.9)
        end)
        sb:SetScript("OnLeave", function(b)
            b:SetBackdropColor(.15,.12,.25,.9); b:SetBackdropBorderColor(.4,.4,.6,.8)
        end)
        sb:SetScript("OnClick", function()
            local oldS = MCS.db.uiScale or 1
            local s = oldS + delta
            s = math.max(0.7, math.min(1.5, math.floor(s * 20 + 0.5) / 20))
            if s == oldS then return end
            -- Pin bottom-right corner in place so the button stays under cursor
            local right = f:GetRight() * oldS
            local bottom = f:GetBottom() * oldS
            MCS.db.uiScale = s
            f:SetScale(s)
            f:ClearAllPoints()
            f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", right / s, bottom / s)
        end)
        return sb
    end
    MakeScaleBtn("+", -22, 0.05)
    MakeScaleBtn("\226\136\146", -40, -0.05)  -- minus sign (−)

    -- Apply saved scale
    if MCS.db and MCS.db.uiScale then f:SetScale(MCS.db.uiScale) end

    self:CreateMinimapButton()
    f:Hide(); self:SelectTab(1)
end

function MCS:OnResize()
    if not self.frame or not self.frame:IsShown() then return end
    ReleaseAll(); ClearTxt()
    self:SelectTab(self.activeTab or 1)
end

function MCS:SelectTab(idx)
    self.activeTab = idx
    for i, t in ipairs(self.tabs) do
        local on = (i==idx)
        t:SetBackdropColor(on and .15 or .08, on and .15 or .08, on and .25 or .14, on and 1 or .85)
        t.txt:SetTextColor(on and 1 or .5, on and .82 or .5, on and 0 or .5)
        self.tabFrames[i].scroll[on and "Show" or "Hide"](self.tabFrames[i].scroll)
    end
    if idx==1 then self:BuildStatsTab()
    elseif idx==2 then self:BuildGearTab()
    elseif idx==3 then self:BuildWishlistTab()
    elseif idx==4 then self:BuildGearingTab()
    elseif idx==5 then self:BuildTalentsTab() end
end

function MCS:Show()  if self.frame then self.frame:Show(); self:UpdateUI() end end
function MCS:Hide()  if self.frame then self.frame:Hide() end end
function MCS:Toggle() if self.frame and self.frame:IsShown() then self:Hide() else self:Show() end end

function MCS:UpdateUI()
    if not self.frame or not self.frame:IsShown() then return end
    local cls, spec = self.currentClass, self.currentSpec
    if cls and spec then
        local r,g,b = self:ClassColor(cls)
        self.specLabel:SetText(format("|cff%02x%02x%02x%s %s|r", r*255,g*255,b*255, spec, UnitClass("player") or ""))
    end
    -- Update class selector button
    local viewCls = MCS.viewingClass or self.currentClass
    if viewCls then
        local pretty = ({
            DEATHKNIGHT="Death Knight", DEMONHUNTER="Demon Hunter",
        })[viewCls] or (viewCls:sub(1,1) .. viewCls:sub(2):lower())
        local r,g,b = self:ClassColor(viewCls)
        self.specBtnLabel:SetText(format("|cff%02x%02x%02x%s|r", r*255,g*255,b*255, pretty))
        self.specBtn:SetWidth(self.specBtnLabel:GetStringWidth() + 10)
    end
    ReleaseAll(); ClearTxt()
    self:SelectTab(self.activeTab or 1)
end

----------------------------------------------------------------------
-- Class selector dropdown (for Wishlist tab cross-class browsing)
----------------------------------------------------------------------
local classDropdown

function MCS:ShowClassDropdown(anchor)
    if classDropdown and classDropdown:IsShown() then classDropdown:Hide(); return end
    if not classDropdown then
        classDropdown = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        classDropdown:SetFrameStrata("TOOLTIP"); classDropdown:SetFrameLevel(120)
        classDropdown:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",
            edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,
            insets={left=3,right=3,top=3,bottom=3}})
        classDropdown:SetBackdropColor(.05,.05,.1,.95)
        classDropdown:SetBackdropBorderColor(.3,.3,.5,.8)
        classDropdown:SetScript("OnShow", function(dd)
            dd:SetScript("OnUpdate", function(d)
                if not d:IsMouseOver() and not anchor:IsMouseOver() then
                    d.elapsed = (d.elapsed or 0) + .03
                    if d.elapsed > .5 then d:Hide() end
                else d.elapsed = 0 end
            end)
        end)
        classDropdown:SetScript("OnHide", function(dd)
            dd:SetScript("OnUpdate", nil)
        end)
    end
    -- Clear old buttons
    for _, child in ipairs({classDropdown:GetChildren()}) do child:Hide(); child:SetParent(recycleFrame) end

    local SORTED_CLASSES = {}
    for cls in pairs(self.ALL_SPECS) do table_insert(SORTED_CLASSES, cls) end
    table_sort(SORTED_CLASSES)

    local bh, pad = 18, 3
    local maxW = 100
    local btns = {}
    for i, cls in ipairs(SORTED_CLASSES) do
        local b = CreateFrame("Button", nil, classDropdown, "BackdropTemplate")
        b:SetHeight(bh)
        b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"})
        b:SetBackdropColor(0,0,0,0)
        local r, g, bb = self:ClassColor(cls)
        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetFont(STANDARD_TEXT_FONT, 10, "")
        fs:SetAllPoints(); fs:SetJustifyH("LEFT")
        local displayName = cls:sub(1,1) .. cls:sub(2):lower():gsub("knight","knight"):gsub("hunter","hunter"):gsub("demon","demon")
        -- Pretty class names
        local pretty = ({
            DEATHKNIGHT="Death Knight", DEMONHUNTER="Demon Hunter",
        })[cls] or (cls:sub(1,1) .. cls:sub(2):lower())
        fs:SetText(format("  |cff%02x%02x%02x%s|r", r*255, g*255, bb*255, pretty))
        local tw = fs:GetStringWidth() + 12
        if tw > maxW then maxW = tw end
        b:SetScript("OnEnter", function(btn) btn:SetBackdropColor(.2,.2,.3,.8) end)
        b:SetScript("OnLeave", function(btn) btn:SetBackdropColor(0,0,0,0) end)
        b:SetScript("OnClick", function()
            MCS.viewingClass = cls
            MCS.viewingSpecKey = nil
            MCS.activeListName = nil
            MCS.statsTabSpec = nil
            MCS.gearTabSpec = nil
            classDropdown:Hide()
            MCS:UpdateUI()
        end)
        btns[i] = b
    end
    local totalH = #btns * (bh + pad) + pad * 2
    classDropdown:SetSize(maxW + 10, totalH)
    classDropdown:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -2)
    for i, b in ipairs(btns) do
        b:SetPoint("TOPLEFT", pad, -(pad + (i-1) * (bh + pad)))
        b:SetPoint("RIGHT", -pad, 0)
        b:Show()
    end
    classDropdown:Show()
end

----------------------------------------------------------------------
-- TAB 1: Stats (priority + weights + live stats + DR brackets)
----------------------------------------------------------------------

-- Combat rating IDs (CR_ constants)
local STAT_CR = {
    Crit    = CR_CRIT_MELEE    or 9,
    Haste   = CR_HASTE_MELEE   or 18,
    Mastery = CR_MASTERY        or 26,
    Vers    = CR_VERSATILITY_DAMAGE_DONE or 29,
}

-- Diminishing Returns brackets (from rating %, not total %)
-- Source: Blizzard systems since 9.0.1, confirmed unchanged in 12.0.1
-- Applies to: Crit, Haste, Mastery (in mastery points), Versatility
-- Penalty is applied only to the portion of rating within that bracket.
local DR_BRACKETS = {
    { threshold = 0,  penalty = 0,   label = "0-30%",    color = {.3,1,.5} },    -- Full value
    { threshold = 30, penalty = 10,  label = "30-39%",   color = {.7,1,.3} },    -- 10% penalty
    { threshold = 39, penalty = 20,  label = "39-47%",   color = {1,.9,.2} },    -- 20% penalty
    { threshold = 47, penalty = 30,  label = "47-54%",   color = {1,.6,.2} },    -- 30% penalty
    { threshold = 54, penalty = 40,  label = "54-66%",   color = {1,.3,.2} },    -- 40% penalty
    { threshold = 66, penalty = 50,  label = "66-126%",  color = {.8,.2,.2} },   -- 50% penalty
}
local DR_HARD_CAP = 126  -- Can't exceed from rating

-- Read current secondary stat from equipped gear
-- Returns: rating (number), percentage (number)
local function GetLiveStat(statName)
    local crID = STAT_CR[statName]
    if not crID then return 0, 0 end
    local rating = GetCombatRating(crID) or 0
    local pct = GetCombatRatingBonus(crID) or 0
    return rating, pct
end

-- Determine which DR bracket a stat is in
local function GetDRBracket(pct)
    local bracket = DR_BRACKETS[1]
    for i = #DR_BRACKETS, 1, -1 do
        if pct >= DR_BRACKETS[i].threshold then
            bracket = DR_BRACKETS[i]
            break
        end
    end
    return bracket
end

function MCS:BuildStatsTab()
    local c = self.tabFrames[1].content; ClearC(c)
    local y = PAD

    -- Determine which specs this class has
    local cls = MCS.viewingClass or self.currentClass
    local specs = cls and self.ALL_SPECS[cls]
    if not specs or #specs == 0 then
        y = Txt(c, y, "No class detected.", 1, .3, .3)
        c:SetHeight(y + PAD); return
    end

    -- Default to current spec if no override is set, or reset if class changed
    if not self.statsTabSpec or not self:MakeSpecKey(cls, self.statsTabSpec) then
        self.statsTabSpec = (cls == self.currentClass) and self.currentSpec or specs[1]
    end

    -- Spec selector row
    local labelFs = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelFs:SetFont(STANDARD_TEXT_FONT, 10, ""); labelFs:SetPoint("TOPLEFT", 8, -y)
    labelFs:SetTextColor(.6, .6, .6); labelFs:SetText("Spec:")
    table_insert(txts, labelFs)

    local btnX = 42
    for _, specName in ipairs(specs) do
        local isActive = (specName == self.statsTabSpec)
        local specKey = self:MakeSpecKey(cls, specName)
        local hasData = self.SpecDB[specKey] and true or false

        local btn = CreateFrame("Button", nil, c, "BackdropTemplate")
        local iconID = self:GetSpecIcon(specName, cls)
        local iconW = iconID and 18 or 0
        btn:SetSize(specName:len() * 6.5 + 16 + iconW, 20)
        btn:SetPoint("TOPLEFT", btnX, -y + 2)
        btn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
        if isActive then
            btn:SetBackdropColor(.2, .2, .4, 1)
            btn:SetBackdropBorderColor(.4, .6, 1, .8)
        else
            btn:SetBackdropColor(.1, .1, .15, .8)
            btn:SetBackdropBorderColor(.25, .25, .3, .6)
        end

        if iconID then
            local ico = btn:CreateTexture(nil, "ARTWORK")
            ico:SetSize(16, 16); ico:SetPoint("LEFT", 3, 0)
            ico:SetTexture(iconID); ico:SetTexCoord(.08, .92, .08, .92)
            if not isActive then ico:SetDesaturated(true); ico:SetAlpha(.6) end
        end

        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetFont(STANDARD_TEXT_FONT, 10, "")
        if iconID then
            fs:SetPoint("LEFT", 3 + 18, 0); fs:SetPoint("RIGHT", -3, 0)
        else
            fs:SetAllPoints()
        end
        fs:SetJustifyH("CENTER")
        if isActive then
            local r, g, b = self:ClassColor(cls)
            fs:SetTextColor(r, g, b)
        elseif hasData then
            fs:SetTextColor(.65, .65, .65)
        else
            fs:SetTextColor(.35, .35, .35)
        end
        fs:SetText(specName)

        btn:SetScript("OnClick", function()
            self.statsTabSpec = specName
            self.gearTabSpec = specName
            MCS.viewingSpecKey = self:MakeSpecKey(cls, specName)
            MCS.activeListName = nil
            self:BuildStatsTab()
        end)
        btn:SetScript("OnEnter", function(b)
            if not isActive then
                b:SetBackdropColor(.15, .15, .25, 1)
                b:SetBackdropBorderColor(.35, .45, .7, .8)
            end
        end)
        btn:SetScript("OnLeave", function(b)
            if not isActive then
                b:SetBackdropColor(.1, .1, .15, .8)
                b:SetBackdropBorderColor(.25, .25, .3, .6)
            end
        end)

        table_insert(txts, btn)
        btnX = btnX + btn:GetWidth() + 4
    end

    y = y + 24

    -- Show indicator if viewing a non-active spec or different class
    if cls ~= self.currentClass or self.statsTabSpec ~= self.currentSpec then
        local hint = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hint:SetFont(STANDARD_TEXT_FONT, 9, ""); hint:SetPoint("TOPLEFT", 8, -y)
        hint:SetTextColor(.9, .7, .2)
        local pretty = ({DEATHKNIGHT="Death Knight",DEMONHUNTER="Demon Hunter"})[cls]
            or (cls:sub(1,1) .. cls:sub(2):lower())
        hint:SetText("Viewing " .. self.statsTabSpec .. " " .. pretty)
        table_insert(txts, hint)
        y = y + 14
    end

    -- Use the selected spec's data
    local specKey = self:MakeSpecKey(cls, self.statsTabSpec)
    local data = self.SpecDB[specKey]
    if not data then
        y = Txt(c, y, "No data for " .. (self.statsTabSpec or "?") .. ".", 1, .3, .3)
        c:SetHeight(y + PAD); return
    end

    -- Column X positions
    local COL_RANK   = 10
    local COL_STAT   = 30
    local COL_YOU    = 110
    local COL_DR     = 280
    local ROW_H      = 16

    local function MakeLabel(parent, x, yOff, text, r, g, b, sz)
        local fs2 = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs2:SetFont(STANDARD_TEXT_FONT, sz or 10, "")
        fs2:SetPoint("TOPLEFT", x, -yOff)
        fs2:SetTextColor(r or .5, g or .5, b or .5)
        fs2:SetText(text)
        table_insert(txts, fs2)
        return fs2
    end

    -- Section 1: Hero tree stat priorities
    -- Collect hero tree names in sorted order for consistent display
    local htNames = {}
    for htName in pairs(data.stats) do
        table_insert(htNames, htName)
    end
    table_sort(htNames)

    for _, htName in ipairs(htNames) do
        local htStats = data.stats[htName]
        if not htStats then break end

        -- Hero tree section header
        y = Hdr(c, y, htName)
        y = y + 2

        -- Column headers
        MakeLabel(c, COL_RANK, y, "#",        .5,.5,.5, 9)
        MakeLabel(c, COL_STAT, y, "Stat",     .5,.5,.5, 9)
        MakeLabel(c, COL_YOU,  y, "You have",  .5,.5,.5, 9)
        MakeLabel(c, COL_DR,   y, "DR",       .5,.5,.5, 9)
        y = y + 14

        -- Separator line
        local sep = c:CreateTexture(nil,"ARTWORK"); sep:SetColorTexture(.3,.3,.4,.4); sep:SetHeight(1)
        sep:SetPoint("TOPLEFT", PAD, -y); sep:SetPoint("RIGHT", -PAD, 0)
        table_insert(txts, sep)
        y = y + 3

        for i, stat in ipairs(htStats) do
            local sc = COL[stat] or COL.white

            -- Rank (#1 gold, rest grey)
            local rankCol = (i==1) and {1,.82,0} or {.55,.55,.55}
            MakeLabel(c, COL_RANK, y, "#"..i, rankCol[1], rankCol[2], rankCol[3], 12)

            -- Stat name (colored)
            MakeLabel(c, COL_STAT, y, stat, sc[1], sc[2], sc[3], 12)

            -- Live stats
            local rating, pct = GetLiveStat(stat)
            if rating > 0 then
                MakeLabel(c, COL_YOU, y, format("%.1f%%  (%s)", pct, self:FormatNumber(rating)), 1, 1, 1, 11)
                -- DR bracket indicator
                local bracket = GetDRBracket(pct)
                local bc = bracket.color
                local drText = bracket.penalty > 0
                    and format("-%d%%", bracket.penalty)
                    or "OK"
                MakeLabel(c, COL_DR, y, drText, bc[1], bc[2], bc[3], 11)
            else
                MakeLabel(c, COL_YOU, y, "--", .3,.3,.3, 11)
            end

            y = y + ROW_H
        end

        y = y + 4
    end

    -- Section 2: DR reference chart
    y = y + 2
    y = Hdr(c, y, "Diminishing Returns Brackets")
    y = Txt(c, y, "Penalty applies only to rating within each bracket.", .5,.5,.5, 9, 4)
    y = y + 2
    local REF_COL1 = 16   -- bracket / stat name
    local REF_COL2 = 100  -- penalty / rating
    local REF_COL3 = 210  -- your stat (thresholds only)
    for _, br in ipairs(DR_BRACKETS) do
        local bc = br.color
        MakeLabel(c, REF_COL1, y, br.label, bc[1], bc[2], bc[3], 10)
        if br.penalty == 0 then
            MakeLabel(c, REF_COL2, y, "Full value", .3, 1, .5, 10)
        else
            MakeLabel(c, REF_COL2, y, format("%d%% penalty", br.penalty), bc[1], bc[2], bc[3], 10)
        end
        y = y + 13
    end
    MakeLabel(c, REF_COL1, y, format("Hard cap: %d%%", DR_HARD_CAP), .5, .5, .5, 10)
    y = y + 13

    -- Section 3: Universal first DR thresholds (Midnight S1)
    y = y + 4
    y = Hdr(c, y, "First DR Threshold (Midnight S1)")
    y = Txt(c, y, "Rating needed to reach 30% (where first DR penalty kicks in).", .5,.5,.5, 9, 4)
    y = y + 2
    local thresholds = {
        { stat="Crit",    rating=365 },
        { stat="Haste",   rating=348 },
        { stat="Mastery", rating=365 },
        { stat="Vers",    rating=428 },
    }
    for _, t in ipairs(thresholds) do
        local sc = COL[t.stat] or COL.white
        MakeLabel(c, REF_COL1, y, t.stat, sc[1], sc[2], sc[3], 10)
        MakeLabel(c, REF_COL2, y, format("%s rating", self:FormatNumber(t.rating)), .8, .8, .8, 10)
        local rating, pct = GetLiveStat(t.stat)
        if rating > 0 then
            local met = (pct >= 30)
            local cr, cg, cb = 1, .3, .3
            if met then cr, cg, cb = .3, 1, .3 end
            MakeLabel(c, REF_COL3, y, format("you: %.1f%%", pct), cr, cg, cb, 10)
        end
        y = y + 13
    end

    c:SetHeight(y + PAD)
end

----------------------------------------------------------------------
-- TAB 2: Consumables & Enchants (with spec/build selector)
----------------------------------------------------------------------
function MCS:BuildGearTab()
    local c = self.tabFrames[2].content; ClearC(c)
    local y = PAD

    -- Determine which specs this class has
    local cls = MCS.viewingClass or self.currentClass
    local specs = cls and self.ALL_SPECS[cls]
    if not specs or #specs == 0 then
        y = Txt(c, y, "No class detected.", 1, .3, .3)
        c:SetHeight(y + PAD); return
    end

    -- Default to current spec if no override is set, or reset if class changed
    if not self.gearTabSpec or not self:MakeSpecKey(cls, self.gearTabSpec) then
        self.gearTabSpec = (cls == self.currentClass) and self.currentSpec or specs[1]
    end

    -- Spec selector row
    local labelFs = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelFs:SetFont(STANDARD_TEXT_FONT, 10, ""); labelFs:SetPoint("TOPLEFT", 8, -y)
    labelFs:SetTextColor(.6, .6, .6); labelFs:SetText("Spec:")
    table_insert(txts, labelFs)

    local btnX = 42
    for _, specName in ipairs(specs) do
        local isActive = (specName == self.gearTabSpec)
        local specKey = self:MakeSpecKey(cls, specName)
        local hasData = self.SpecDB[specKey] and true or false

        local btn = CreateFrame("Button", nil, c, "BackdropTemplate")
        local iconID = self:GetSpecIcon(specName, cls)
        local iconW = iconID and 18 or 0
        btn:SetSize(specName:len() * 6.5 + 16 + iconW, 20)
        btn:SetPoint("TOPLEFT", btnX, -y + 2)
        btn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
        if isActive then
            btn:SetBackdropColor(.2, .2, .4, 1)
            btn:SetBackdropBorderColor(.4, .6, 1, .8)
        else
            btn:SetBackdropColor(.1, .1, .15, .8)
            btn:SetBackdropBorderColor(.25, .25, .3, .6)
        end

        -- Spec icon
        if iconID then
            local ico = btn:CreateTexture(nil, "ARTWORK")
            ico:SetSize(16, 16)
            ico:SetPoint("LEFT", 3, 0)
            ico:SetTexture(iconID)
            ico:SetTexCoord(.08, .92, .08, .92)
            if not isActive then ico:SetDesaturated(true); ico:SetAlpha(.6) end
        end

        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetFont(STANDARD_TEXT_FONT, 10, "")
        if iconID then
            fs:SetPoint("LEFT", 3 + 18, 0)
            fs:SetPoint("RIGHT", -3, 0)
        else
            fs:SetAllPoints()
        end
        fs:SetJustifyH("CENTER")
        if isActive then
            local r, g, b = self:ClassColor(cls)
            fs:SetTextColor(r, g, b)
        elseif hasData then
            fs:SetTextColor(.65, .65, .65)
        else
            fs:SetTextColor(.35, .35, .35)
        end
        fs:SetText(specName)

        btn:SetScript("OnClick", function()
            self.gearTabSpec = specName
            self.statsTabSpec = specName
            MCS.viewingSpecKey = self:MakeSpecKey(cls, specName)
            MCS.activeListName = nil
            self:BuildGearTab()
        end)
        btn:SetScript("OnEnter", function(b)
            if not isActive then
                b:SetBackdropColor(.15, .15, .25, 1)
                b:SetBackdropBorderColor(.35, .45, .7, .8)
            end
        end)
        btn:SetScript("OnLeave", function(b)
            if not isActive then
                b:SetBackdropColor(.1, .1, .15, .8)
                b:SetBackdropBorderColor(.25, .25, .3, .6)
            end
        end)

        table_insert(txts, btn)
        btnX = btnX + btn:GetWidth() + 4
    end

    y = y + 24

    -- Show indicator if viewing a non-active spec or different class
    if cls ~= self.currentClass or self.gearTabSpec ~= self.currentSpec then
        local hint = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hint:SetFont(STANDARD_TEXT_FONT, 9, ""); hint:SetPoint("TOPLEFT", 8, -y)
        hint:SetTextColor(.9, .7, .2)
        local pretty = ({DEATHKNIGHT="Death Knight",DEMONHUNTER="Demon Hunter"})[cls]
            or (cls:sub(1,1) .. cls:sub(2):lower())
        hint:SetText("Viewing " .. self.gearTabSpec .. " " .. pretty)
        table_insert(txts, hint)
        y = y + 14
    end

    -- Use the selected spec's data
    local specKey = self:MakeSpecKey(cls, self.gearTabSpec)
    local data = self.SpecDB[specKey]
    if not data then
        y = Txt(c, y, "No data for " .. (self.gearTabSpec or "?") .. ".", 1, .3, .3)
        c:SetHeight(y + PAD); return
    end

    -- ENCHANTS
    y = Hdr(c, y, "Enchants")
    local enc = data.enchants or {}
    if enc.runeforge then
        for _, rf in ipairs(enc.runeforge) do
            local e = MCS.EnchantByKey[rf.key]
            if e and e.spellID then
                local btn = Acquire(c)
                SetupSpellBtn(btn, e.spellID, e.name, rf.label, y, c)
                y = y + ICON + 5
            end
        end
    elseif enc.wep then
        for i, key in ipairs(enc.wep) do
            local e = MCS.EnchantByKey[key]
            if e then
                local btn = Acquire(c)
                SetupBtn(btn, e.id, i==1 and "Weapon MH" or "Weapon OH", y, c)
                y = y + ICON + 5
            end
        end
    end
    for _, slot in ipairs({"chest","helm","shoulder","boots","legs"}) do
        local key = enc[slot]
        if key then
            local e = MCS.EnchantByKey[key]
            if e then
                local btn = Acquire(c)
                SetupBtn(btn, e.id, slot:sub(1,1):upper()..slot:sub(2), y, c)
                y = y + ICON + 5
            end
        end
    end
    if data.rings then
        for i, key in ipairs(data.rings) do
            local e = MCS.EnchantByKey[key]
            if e then
                local btn = Acquire(c)
                SetupBtn(btn, e.id, "Ring "..i, y, c)
                y = y + ICON + 5
            end
        end
    end

    -- GEMS
    y = Hdr(c, y, "Gems")
    if data.gems then
        if data.gems.epic and MCS.GemByKey[data.gems.epic] then
            local g = MCS.GemByKey[data.gems.epic]
            local btn = Acquire(c); SetupBtn(btn, g.id, "Epic (1 socket)", y, c); y=y+ICON+5
        end
        if data.gems.rare then
            local rares = type(data.gems.rare) == "table" and data.gems.rare or {data.gems.rare}
            for i, key in ipairs(rares) do
                local g = MCS.GemByKey[key]
                if g then
                    local label = i == 1 and "Rare (all others)" or "Rare (alt)"
                    local btn = Acquire(c); SetupBtn(btn, g.id, label, y, c); y=y+ICON+5
                end
            end
        end
    end

    -- CONSUMABLES
    y = Hdr(c, y, "Consumables")
    local cats = {"Flask","Food","Potion","Healing","Rune","Oil","Weapon","Mana"}
    local cons = data.consum or {}
    for _, cat in ipairs(cats) do
        local key = cons[cat]
        if key and MCS.ConsumByKey[key] then
            local item = MCS.ConsumByKey[key]
            local btn = Acquire(c); SetupBtn(btn, item.id, cat, y, c); y=y+ICON+5
        end
    end

    c:SetHeight(y + PAD)
end

----------------------------------------------------------------------
-- TAB 3: Wishlist (multi-spec, multi-list)
----------------------------------------------------------------------
function MCS:BuildWishlistTab()
    local c = self.tabFrames[3].content; ClearC(c)
    local y = PAD

    local viewCls = MCS.viewingClass or self.currentClass
    if not MCS.viewingSpecKey then
        -- Default to current spec if viewing own class, otherwise first spec
        local specs = self.ALL_SPECS[viewCls] or {}
        local defaultSpec = (viewCls == self.currentClass) and self.currentSpec or specs[1]
        if defaultSpec then
            MCS.viewingSpecKey = self:MakeSpecKey(viewCls, defaultSpec)
        else
            MCS.viewingSpecKey = self:SpecKey()
        end
    end
    -- Default to "Overall BiS" if available, otherwise first list
    if not MCS.activeListName then
        local allNames = MCS:GetListNames(MCS.viewingSpecKey)
        MCS.activeListName = nil
        for _, n in ipairs(allNames) do
            if n == "Overall BiS" then MCS.activeListName = n; break end
        end
        if not MCS.activeListName then MCS.activeListName = allNames[1] end
    end
    local specKey  = MCS.viewingSpecKey
    local listName = MCS.activeListName

    -- Tooltip settings row (top of tab)
    local otherOn = self.db.tooltipOtherClasses
    local otherCb = CreateFrame("CheckButton", nil, c, "UICheckButtonTemplate")
    otherCb:SetSize(22, 22); otherCb:SetPoint("TOPLEFT", PAD, -y)
    otherCb:SetChecked(otherOn)
    otherCb:SetScript("OnClick", function(cb)
        MCS.db.tooltipOtherClasses = cb:GetChecked() and true or false
    end)
    local otherLbl = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    otherLbl:SetFont(STANDARD_TEXT_FONT, 10, "")
    otherLbl:SetPoint("LEFT", otherCb, "RIGHT", 0, 0)
    otherLbl:SetText("Show other classes on tooltip")
    otherLbl:SetTextColor(.7, .7, .7)
    table_insert(txts, otherCb); table_insert(txts, otherLbl)
    y = y + 22

    -- ROW 1: Spec selector — clickable buttons for each spec
    local cls = MCS.viewingClass or self.currentClass
    local isOtherClass = (cls ~= self.currentClass)
    local classLabel = isOtherClass
        and format(" |cff888888(viewing %s)|r", ({
            DEATHKNIGHT="Death Knight", DEMONHUNTER="Demon Hunter",
        })[cls] or (cls:sub(1,1) .. cls:sub(2):lower()))
        or ""
    y = Hdr(c, y, "Spec" .. classLabel)
    local mySpecs = self.ALL_SPECS[cls] or {}

    local specBtnX = 8
    for _, spec in ipairs(mySpecs) do
        local k = self:MakeSpecKey(cls, spec)
        local cnt = self:TotalWishlistCount(k)
        local isActive = (k == specKey)
        local iconID = self:GetSpecIcon(spec, cls)

        local btn = CreateFrame("Button", nil, c, "BackdropTemplate")
        local label = format("%s (%d)", spec, cnt)
        local iconW = iconID and 18 or 0
        btn:SetSize(label:len() * 6 + 16 + iconW, 22)
        btn:SetPoint("TOPLEFT", specBtnX, -y)
        btn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})

        if isActive then
            btn:SetBackdropColor(.2, .2, .4, 1)
            btn:SetBackdropBorderColor(.4, .6, 1, .8)
        else
            btn:SetBackdropColor(.1, .1, .15, .8)
            btn:SetBackdropBorderColor(.25, .25, .3, .6)
        end

        -- Spec icon
        if iconID then
            local ico = btn:CreateTexture(nil, "ARTWORK")
            ico:SetSize(16, 16)
            ico:SetPoint("LEFT", 3, 0)
            ico:SetTexture(iconID)
            ico:SetTexCoord(.08, .92, .08, .92)  -- trim default border
            if not isActive then ico:SetDesaturated(true); ico:SetAlpha(.6) end
        end

        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetFont(STANDARD_TEXT_FONT, 10, "")
        if iconID then
            fs:SetPoint("LEFT", 3 + 18, 0)
            fs:SetPoint("RIGHT", -3, 0)
        else
            fs:SetAllPoints()
        end
        fs:SetJustifyH("CENTER")
        if isActive then
            local r, g, b = self:ClassColor(cls)
            fs:SetTextColor(r, g, b)
        else
            fs:SetTextColor(.55, .55, .55)
        end
        fs:SetText(label)

        btn:SetScript("OnClick", function()
            MCS.viewingSpecKey = k
            MCS.activeListName = nil  -- will auto-pick first available
            self.statsTabSpec = spec
            self.gearTabSpec = spec
            MCS:BuildWishlistTab()
        end)
        btn:SetScript("OnEnter", function(b)
            if not isActive then
                b:SetBackdropColor(.15, .15, .25, 1)
                b:SetBackdropBorderColor(.35, .45, .7, .8)
            end
        end)
        btn:SetScript("OnLeave", function(b)
            if not isActive then
                b:SetBackdropColor(.1, .1, .15, .8)
                b:SetBackdropBorderColor(.25, .25, .3, .6)
            end
        end)

        table_insert(txts, btn)
        specBtnX = specBtnX + btn:GetWidth() + 4
    end
    y = y + 24

    -- ROW 2: List selector (tabs within the spec)
    -- User lists: green border | Preset (addon) lists: blue border
    y = Hdr(c, y, "List")
    local listNames = self:GetListNames(specKey)
    local listBtns = {}
    local prevAnchor = nil
    for _, ln in ipairs(listNames) do
        local cnt = self:WishlistCount(specKey, ln)
        local isActive = (ln == listName)
        local isPreset = self:IsPresetList(specKey, ln)
        local tag = isPreset and "|cff6688cc[BiS] |r" or ""
        local label
        if isActive then
            label = format("%s|cffFFD100%s (%d)|r", tag, ln, cnt)
        elseif isPreset then
            label = format("%s|cff7799bb%s (%d)|r", tag, ln, cnt)
        else
            label = format("|cff88aa88%s (%d)|r", ln, cnt)
        end
        local bw = isPreset and 120 or 80
        local b
        if prevAnchor then
            b = SmallBtn(c, bw, label, prevAnchor, 2, 0)
        else
            b = SmallBtn(c, bw, label, nil, 4, -y)
        end
        if isActive then
            if isPreset then
                -- Active preset: blue
                b:SetBackdropColor(.1, .12, .25, 1)
                b:SetBackdropBorderColor(.3, .5, .85, .9)
            else
                -- Active user: green
                b:SetBackdropColor(.1, .18, .1, 1)
                b:SetBackdropBorderColor(.3, .7, .3, .9)
            end
        elseif isPreset then
            -- Inactive preset: dim blue
            b:SetBackdropColor(.08, .08, .14, .8)
            b:SetBackdropBorderColor(.2, .3, .5, .5)
        else
            -- Inactive user: dim green
            b:SetBackdropColor(.08, .1, .08, .8)
            b:SetBackdropBorderColor(.2, .35, .2, .5)
        end
        b:SetScript("OnClick", function()
            MCS.activeListName = ln; MCS:BuildWishlistTab()
        end)
        prevAnchor = b
        table_insert(listBtns, b)
    end
    y = y + 26

    -- New list button + input (only for user lists)
    local newBtn = SmallBtn(c, 60, "|cff00ff00+ New|r", nil, 4, -y)
    local newInput = CreateFrame("EditBox", nil, c, "BackdropTemplate")
    newInput:SetSize(120, 20); newInput:SetPoint("LEFT", newBtn, "RIGHT", 4, 0)
    newInput:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8,
        insets={left=2,right=2,top=2,bottom=2}})
    newInput:SetBackdropColor(.1,.1,.15,1); newInput:SetBackdropBorderColor(.4,.4,.6,.6)
    newInput:SetFont(STANDARD_TEXT_FONT, 10, ""); newInput:SetTextColor(1,1,1)
    newInput:SetAutoFocus(false); newInput:SetMaxLetters(30)
    newInput:SetTextInsets(4,4,0,0)
    table_insert(txts, newInput)

    -- Delete list button (disabled for preset/BiS lists)
    local isPresetActive = listName and self:IsPresetList(specKey, listName)
    local delBtn = SmallBtn(c, 60, "|cffff4444Delete|r", newInput, 4, 0)
    if isPresetActive or not listName then delBtn:SetAlpha(0.3); delBtn:Disable() end

    -- Duplicate button: copies current list into a new user list (works on any list)
    local dupBtn = SmallBtn(c, 70, "|cff88ccffDuplicate|r", delBtn, 4, 0)
    if not listName then dupBtn:SetAlpha(0.3); dupBtn:Disable() end

    newBtn:SetScript("OnClick", function()
        local name = strtrim(newInput:GetText())
        if name == "" then newInput:SetFocus(); return end
        self:CreateList(specKey, name)
        MCS.activeListName = name
        newInput:SetText(""); newInput:ClearFocus()
        MCS:BuildWishlistTab()
    end)
    newInput:SetScript("OnEnterPressed", function(eb)
        local name = strtrim(eb:GetText())
        if name ~= "" then
            MCS:CreateList(specKey, name)
            MCS.activeListName = name
        end
        eb:SetText(""); eb:ClearFocus()
        MCS:BuildWishlistTab()
    end)
    newInput:SetScript("OnEscapePressed", function(eb) eb:SetText(""); eb:ClearFocus() end)

    delBtn:SetScript("OnClick", function()
        if isPresetActive or not listName then return end
        MCS:DeleteList(specKey, listName)
        MCS.activeListName = nil  -- will auto-pick first available
        print("|cff00ccff[MCS]|r Deleted list: " .. listName)
        MCS:BuildWishlistTab()
    end)

    dupBtn:SetScript("OnClick", function()
        if not listName then return end
        local destName = strtrim(newInput:GetText())
        if destName == "" then
            -- Auto-generate name: "Overall BiS (copy)", or increment if taken
            destName = listName .. " (copy)"
            local n = 2
            local existing = MCS:GetListNames(specKey)
            local taken = {}
            for _, nm in ipairs(existing) do taken[nm] = true end
            while taken[destName] do
                destName = listName .. " (copy " .. n .. ")"
                n = n + 1
            end
        end
        if MCS:DuplicateList(specKey, listName, destName) then
            MCS.activeListName = destName
            newInput:SetText(""); newInput:ClearFocus()
            print("|cff00ccff[MCS]|r Duplicated |cffFFD100" .. listName .. "|r -> |cff88cc88" .. destName .. "|r")
            MCS:BuildWishlistTab()
        else
            print("|cff00ccff[MCS]|r Could not duplicate: a list named |cffFFD100" .. destName .. "|r already exists.")
        end
    end)
    dupBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("|cff88ccffDuplicate List|r")
        GameTooltip:AddLine("Copy all items to a new editable list.", 1, 1, 1, true)
        GameTooltip:AddLine("Type a name in the text box first, or", .7, .7, .7, true)
        GameTooltip:AddLine("leave it blank for an auto-generated name.", .7, .7, .7, true)
        GameTooltip:Show()
    end)
    dupBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    y = y + 28

    -- ROW 3: Items
    if not listName then
        y = Hdr(c, y, self:FormatSpecKey(specKey))
        y = Txt(c, y, "No lists yet. Create one above, or Alt-click items to add them.", .5,.5,.5, 11)
        y = y + 6
        y = Txt(c, y, "|cff88cc88Green|r = your lists  |  |cff6688cc[BiS] Blue|r = addon-provided (read-only)", .5,.5,.5, 9)
        y = y + 2
        y = Txt(c, y, "Alt-click items anywhere (chat, DJ, addon) to add to your lists.", .5,.5,.5, 9)
        c:SetHeight(y + PAD); return
    end

    local isViewingPreset = self:IsPresetList(specKey, listName)
    local hdrTag = isViewingPreset and " |cff6688cc[BiS - read-only]|r" or ""
    y = Hdr(c, y, self:FormatSpecKey(specKey) .. " / |cffFFD100" .. listName .. "|r" .. hdrTag)

    -- Tooltip visibility checkboxes
    local tipOn = self:IsTooltipListEnabled(specKey, listName)
    local tipCb = CreateFrame("CheckButton", nil, c, "UICheckButtonTemplate")
    tipCb:SetSize(22, 22); tipCb:SetPoint("TOPLEFT", PAD, -y)
    tipCb:SetChecked(tipOn)
    tipCb:SetScript("OnClick", function(cb)
        MCS:ToggleTooltipList(specKey, listName)
    end)
    local tipLbl = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tipLbl:SetFont(STANDARD_TEXT_FONT, 10, "")
    tipLbl:SetPoint("LEFT", tipCb, "RIGHT", 0, 0)
    tipLbl:SetText("Show on tooltip")
    tipLbl:SetTextColor(.7, .7, .7)
    table_insert(txts, tipCb); table_insert(txts, tipLbl)

    y = y + 22

    local wl = self:GetWishlist(specKey, listName)
    if #wl == 0 then
        if isViewingPreset then
            y = Txt(c, y, "This BiS list is empty (no data scraped yet for this spec).", .5,.5,.5, 11)
        else
            y = Txt(c, y, "Empty — Alt-click items in Consumes & Enchants tab, DJ, or chat.", .5,.5,.5, 11)
        end
    else
        for _, entry in ipairs(wl) do
            local btn = Acquire(c)
            SetupBtn(btn, entry.itemID, entry.source, y, c, specKey, listName)

            -- If viewing a user list, annotate items also on a preset list
            if not isViewingPreset then
                local onPreset, presetName = self:IsOnPresetList(entry.itemID, specKey)
                if onPreset then
                    local bisNote = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    bisNote:SetFont(STANDARD_TEXT_FONT, 8, "")
                    bisNote:SetPoint("RIGHT", btn, "RIGHT", -24, 0)
                    bisNote:SetTextColor(.4, .53, .8)
                    bisNote:SetText("[BiS]")
                end
            end

            -- If viewing a preset list, grey out the alt-click (can't modify)
            if isViewingPreset then
                btn:SetScript("OnClick", function(s, mbtn)
                    if not s._itemID then return end
                    if IsShiftKeyDown() and mbtn=="LeftButton" then
                        local link = MCS:GetItemLink(s._itemID)
                        if link then
                            HandleModifiedItemClick(link)
                        end
                    elseif IsAltKeyDown() and mbtn=="LeftButton" then
                        -- Open picker so they can add to USER lists
                        ShowPicker(s._itemID, s._src, s)
                    end
                end)
            end

            y = y + ICON + 5
        end
    end

    -- Clear all button at bottom (only for user lists)
    if #wl > 0 and not isViewingPreset then
        y = y + 4
        local clr = SmallBtn(c, 100, "|cffff6666Clear All ("..#wl..")|r", nil, 4, -y)
        clr:SetBackdropColor(.3,.1,.1,1); clr:SetBackdropBorderColor(.6,.2,.2,.8)
        clr:SetScript("OnClick", function()
            wipe(wl)
            print("|cff00ccff[MCS]|r Cleared: " .. MCS:FormatSpecKey(specKey) .. " / " .. listName)
            MCS:BuildWishlistTab()
        end)
        y = y + 26
    end

    y = y + 6
    y = Txt(c, y, "|cff88cc88Green|r = your lists  |  |cff6688cc[BiS] Blue|r = addon-provided (read-only)", .5,.5,.5, 9)
    y = y + 2
    y = Txt(c, y, "Alt-click items anywhere (chat, DJ, addon) to add to your lists.", .5,.5,.5, 9)
    y = y + 2
    y = Txt(c, y, "Shift-click = chat link  |  Hover = tooltip", .5,.5,.5, 9)

    c:SetHeight(y + PAD)
end

----------------------------------------------------------------------
-- TAB 4: Gearing (loot tables, crest tracks, vault rewards)
----------------------------------------------------------------------

-- Crest tier colors matching the infographic
-- Myth is light orange (not red) per user request
local TIER_COL = {
    Adv  = {.3, .9, .3},     -- green
    Vet  = {.3, .6, 1},      -- blue
    Champ= {.7, .3, 1},      -- purple
    Hero = {1, .6, .2},       -- orange
    Myth = {1, .75, .3},      -- light orange (was red)
    Hdr  = {1, .82, 0},       -- gold headers
    Dim  = {.45,.45,.45},      -- dimmed
    white= {1,1,1},
}

-- Dawncrest currency IDs - looked up at runtime by name since IDs may vary
-- Known IDs: Adventurer=3383, Champion=3343
local CREST_CURRENCY = {}
local CREST_NAMES = {
    Adv   = "Adventurer Dawncrest",
    Vet   = "Veteran Dawncrest",
    Champ = "Champion Dawncrest",
    Hero  = "Hero Dawncrest",
    Myth  = "Myth Dawncrest",
}

-- Resolve currency IDs at runtime by scanning known ranges
local function ResolveCrestIDs()
    if CREST_CURRENCY._resolved then return end
    CREST_CURRENCY._resolved = true
    if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return end
    -- Scan a wide range of currency IDs to find matches by name
    for id = 3300, 3450 do
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
        if ok and info and info.name then
            for key, name in pairs(CREST_NAMES) do
                if info.name == name then
                    CREST_CURRENCY[key] = id
                end
            end
        end
    end
end

-- Map ilvl to tier color
local function IlvlTierColor(ilvl)
    if ilvl >= 276 then return TIER_COL.Myth
    elseif ilvl >= 263 then return TIER_COL.Hero
    elseif ilvl >= 250 then return TIER_COL.Champ
    elseif ilvl >= 237 then return TIER_COL.Vet
    else return TIER_COL.Adv end
end

-- Map crest reward text to tier
local function CrestTierColor(text)
    if text:find("Myth") then return TIER_COL.Myth
    elseif text:find("Hero") then return TIER_COL.Hero
    elseif text:find("Champ") then return TIER_COL.Champ
    elseif text:find("Vet") then return TIER_COL.Vet
    else return TIER_COL.Adv end
end

function MCS:BuildGearingTab()
    ResolveCrestIDs()
    local c = self.tabFrames[4].content; ClearC(c)
    local y = PAD

    -- Helper: draw a colored cell at absolute position
    local function Cell(parent, x, yOff, w, text, rgb, sz, align)
        local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetFont(STANDARD_TEXT_FONT, sz or 10, "")
        fs:SetPoint("TOPLEFT", x, -yOff)
        fs:SetWidth(w or 50)
        fs:SetJustifyH(align or "CENTER")
        fs:SetTextColor(rgb[1], rgb[2], rgb[3])
        fs:SetText(text)
        table_insert(txts, fs)
        return fs
    end

    -- Helper: horizontal separator
    local function HLine(parent, yOff)
        local ln = parent:CreateTexture(nil,"ARTWORK")
        ln:SetColorTexture(.3,.3,.4,.5); ln:SetHeight(1)
        ln:SetPoint("TOPLEFT", 4, -yOff); ln:SetPoint("RIGHT", -4, 0)
        table_insert(txts, ln)
    end

    -- Helper: create a crest currency link button (icon + hover tooltip)
    local function CrestBtn(parent, x, yOff, tierKey, sz)
        sz = sz or 14
        local currID = CREST_CURRENCY[tierKey]
        local displayName = CREST_NAMES[tierKey] or (tierKey .. " Dawncrest")
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(sz + 120, sz)
        btn:SetPoint("TOPLEFT", x, -yOff)
        -- Icon
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(sz, sz); icon:SetPoint("LEFT")
        local info = currID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currID)
        if info and info.iconFileID then
            icon:SetTexture(info.iconFileID)
        else
            icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
        end
        -- Label with actual currency name
        local tc = TIER_COL[tierKey] or TIER_COL.Dim
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 10, ""); lbl:SetPoint("LEFT", icon, "RIGHT", 3, 0)
        lbl:SetTextColor(tc[1], tc[2], tc[3])
        lbl:SetText(info and info.name or displayName)
        -- Tooltip on hover
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if currID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyLink then
                local link = C_CurrencyInfo.GetCurrencyLink(currID)
                if link then
                    GameTooltip:SetHyperlink(link)
                    GameTooltip:Show()
                    return
                end
            end
            -- Fallback tooltip
            GameTooltip:AddLine(displayName, tc[1], tc[2], tc[3])
            if info then
                GameTooltip:AddLine(info.description or "", 1,1,1, true)
                GameTooltip:AddLine(format("Owned: %d / %d", info.quantity or 0, info.maxQuantity or 0), .8,.8,.8)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        -- Click: paste currency link to chat
        btn:SetScript("OnClick", function()
            if currID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyLink then
                local link = C_CurrencyInfo.GetCurrencyLink(currID)
                if link then
                    HandleModifiedItemClick(link)
                end
            end
        end)
        table_insert(txts, btn)
        return btn
    end

    -- Helper: hoverable crest text in table (shows tooltip on hover)
    local function CrestCell(parent, x, yOff, w, text, tierKey, sz)
        local tc = TIER_COL[tierKey] or TIER_COL.Dim
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(w, 13); btn:SetPoint("TOPLEFT", x, -yOff)
        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetFont(STANDARD_TEXT_FONT, sz or 9, "")
        fs:SetAllPoints(); fs:SetJustifyH("CENTER")
        fs:SetTextColor(tc[1], tc[2], tc[3]); fs:SetText(text)
        local currID = CREST_CURRENCY[tierKey]
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if currID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyLink then
                local link = C_CurrencyInfo.GetCurrencyLink(currID)
                if link then GameTooltip:SetHyperlink(link); GameTooltip:Show(); return end
            end
            local displayName = CREST_NAMES[tierKey] or text
            GameTooltip:AddLine(displayName, tc[1], tc[2], tc[3]); GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        table_insert(txts, btn)
    end

    local RH = 13  -- row height

    ----------------------------------------------------------------
    -- TABLE 1: Upgrade Tracks (matches wiki layout with separate track columns)
    ----------------------------------------------------------------
    y = Hdr(c, y, "Midnight Season 1 Item Level Tracks")
    y = y + 2

    -- Column layout: Crest type | iLvl | Adv | Vet | Champ | Hero | Myth | Crests | Amt
    local T1X = {type=4, ilvl=60, adv=92, vet=155, champ=218, hero=281, myth=344, crests=395, amt=445}
    Cell(c, T1X.type,  y, 52, "Crest type",TIER_COL.Hdr, 8, "LEFT")
    Cell(c, T1X.ilvl,  y, 28, "iLvl",     TIER_COL.Hdr, 8)
    Cell(c, T1X.adv,   y, 58, "Adv",       TIER_COL.Adv, 8)
    Cell(c, T1X.vet,   y, 58, "Vet",       TIER_COL.Vet, 8)
    Cell(c, T1X.champ, y, 58, "Champ",     TIER_COL.Champ, 8)
    Cell(c, T1X.hero,  y, 58, "Hero",      TIER_COL.Hero, 8)
    Cell(c, T1X.myth,  y, 58, "Myth",      TIER_COL.Myth, 8)
    Cell(c, T1X.crests,y, 48, "Crests",    TIER_COL.Hdr, 8)
    Cell(c, T1X.amt,   y, 28, "Amt",       TIER_COL.Hdr, 8)
    y = y + 12; HLine(c, y); y = y + 3

    -- Each row: { ilvl, crestType(tierKey), adv, vet, champ, hero, myth, crestLabel(tierKey for cost), cost }
    -- adv/vet/champ/hero/myth: nil or "Rank N" string
    local tracks = {
        {220, "Adv",   "Adv 1",  nil,     nil,     nil,    nil,    nil,    nil},
        {224, "Adv",   "Adv 2",  nil,     nil,     nil,    nil,    "Adv",  20},
        {227, "Adv",   "Adv 3",  nil,     nil,     nil,    nil,    "Adv",  20},
        {230, "Adv",   "Adv 4",  nil,     nil,     nil,    nil,    "Adv",  20},
        {233, "Adv",   "Adv 5",  "Vet 1", nil,     nil,    nil,    "Adv",  20},
        {237, "Vet",   "Adv 6",  "Vet 2", nil,     nil,    nil,    "Adv/Vet",20},
        {240, "Vet",   nil,      "Vet 3", nil,     nil,    nil,    "Vet",  20},
        {243, "Vet",   nil,      "Vet 4", nil,     nil,    nil,    "Vet",  20},
        {246, "Vet",   nil,      "Vet 5", "Chp 1", nil,    nil,    "Vet",  20},
        {250, "Champ", nil,      "Vet 6", "Chp 2", nil,    nil,    "Vet/Champ",20},
        {253, "Champ", nil,      nil,     "Chp 3", nil,    nil,    "Champ",20},
        {256, "Champ", nil,      nil,     "Chp 4", nil,    nil,    "Champ",20},
        {259, "Champ", nil,      nil,     "Chp 5", "Hero 1",nil,   "Champ",20},
        {263, "Hero",  nil,      nil,     "Chp 6", "Hero 2",nil,   "Champ/Hero",20},
        {266, "Hero",  nil,      nil,     nil,     "Hero 3",nil,   "Hero", 20},
        {269, "Hero",  nil,      nil,     nil,     "Hero 4",nil,   "Hero", 20},
        {272, "Hero",  nil,      nil,     nil,     "Hero 5","Myth 1","Hero",20},
        {276, "Myth",  nil,      nil,     nil,     "Hero 6","Myth 2","Hero/Myth",20},
        {279, "Myth",  nil,      nil,     nil,     nil,    "Myth 3","Myth", 20},
        {282, "Myth",  nil,      nil,     nil,     nil,    "Myth 4","Myth", 20},
        {285, "Myth",  nil,      nil,     nil,     nil,    "Myth 5","Myth", 20},
        {289, "Myth",  nil,      nil,     nil,     nil,    "Myth 6","Myth", 20},
    }

    for _, r in ipairs(tracks) do
        local ilvl, cType = r[1], r[2]
        local tc = TIER_COL[cType] or TIER_COL.Dim

        -- Crest type label — matches the wiki grouping
        local typeName
        if ilvl <= 230 then typeName = "Adventurer"
        elseif ilvl <= 243 then typeName = "Veteran"
        elseif ilvl <= 256 then typeName = "Vet/Champ"
        elseif ilvl <= 269 then typeName = "Champ/Hero"
        elseif ilvl <= 276 then typeName = "Hero/Myth"
        else typeName = "Myth" end
        Cell(c, T1X.type, y, 52, typeName, tc, 8, "LEFT")

        -- iLvl colored by the row's crest type
        Cell(c, T1X.ilvl, y, 28, tostring(ilvl), tc, 9)

        -- Track columns: each colored by its own track tier
        if r[3] then Cell(c, T1X.adv,   y, 58, r[3], TIER_COL.Adv, 8) end
        if r[4] then Cell(c, T1X.vet,   y, 58, r[4], TIER_COL.Vet, 8) end
        if r[5] then Cell(c, T1X.champ, y, 58, r[5], TIER_COL.Champ, 8) end
        if r[6] then Cell(c, T1X.hero,  y, 58, r[6], TIER_COL.Hero, 8) end
        if r[7] then Cell(c, T1X.myth,  y, 58, r[7], TIER_COL.Myth, 8) end

        -- Crests column (hoverable) — determine tier color
        if r[8] then
            -- If two tiers ("Adv/Vet"), pick the higher one for hover
            local crestTier = r[8]
            if crestTier:find("/") then
                crestTier = crestTier:match("/(%S+)$") or crestTier
            end
            -- Map short names
            if crestTier=="Adv" then crestTier="Adv"
            elseif crestTier=="Vet" then crestTier="Vet"
            elseif crestTier=="Champ" then crestTier="Champ"
            elseif crestTier=="Hero" then crestTier="Hero"
            elseif crestTier=="Myth" then crestTier="Myth" end

            -- Display the label, colored by the primary crest
            local cLabel = r[8]:gsub("Adv","Adv"):gsub("Champ","Chmp")
            CrestCell(c, T1X.crests, y, 48, cLabel, crestTier, 8)
        end

        -- Amount
        if r[9] then Cell(c, T1X.amt, y, 28, tostring(r[9]), tc, 8) end

        y = y + RH
    end

    ----------------------------------------------------------------
    -- TABLE 2: M+ Dungeon Loot & Vault
    -- Color ilvls by the ROW's tier, not by ilvl value
    ----------------------------------------------------------------
    y = y + 6
    y = Hdr(c, y, "Mythic+ Dungeon Rewards")
    y = y + 2

    local cols2 = { {x=6,w=48,t="Key"}, {x=58,w=40,t="Loot"}, {x=102,w=40,t="Vault"}, {x=150,w=110,t="Crest Reward"} }
    for _, col in ipairs(cols2) do Cell(c, col.x, y, col.w, col.t, TIER_COL.Hdr, 9) end
    y = y + 12; HLine(c, y); y = y + 3

    -- {key, lootIlvl, vaultIlvl, crestRewardLabel, lootTier, vaultTier, crestTier}
    -- Colors: tiers from the reference infographic
    -- Loot ilvl tiers: 230=Adv, 246=Vet, 250=Vet, 253=Champ, 256=Champ, 259=Champ, 263=Champ, 266=Hero
    -- Vault ilvl tiers: 243=Vet, 256=Champ, 259=Champ, 263=Champ, 266=Hero, 269=Hero, 272=Hero
    local mplus = {
        {"Heroic", 230, 243, "Champ",      "Adv",   "Vet",   "Champ"},
        {"Mythic", 246, 256, "Champ",      "Champ", "Champ", "Champ"},
        {"M2",     250, 256, "Hero",       "Champ", "Hero",  "Hero"},
        {"M3",     250, 259, "Hero",       "Champ", "Hero",  "Hero"},
        {"M4",     253, 259, "Hero",       "Champ", "Hero",  "Hero"},
        {"M5",     256, 263, "Hero",       "Champ", "Hero",  "Hero"},
        {"M6",     259, 263, "Hero",       "Hero",  "Hero",  "Hero"},
        {"M7",     259, 266, "Hero",       "Hero",  "Hero",  "Hero"},
        {"M8",     263, 269, "Hero",       "Hero",  "Hero",  "Hero"},
        {"M9",     263, 269, "Myth",       "Hero",  "Hero",  "Myth"},
        {"M10",    266, 272, "Myth",       "Hero",  "Myth",  "Myth"},
        {"M11",    266, 272, "Myth",       "Hero",  "Myth",  "Myth"},
        {"M12",    266, 272, "Myth",       "Hero",  "Myth",  "Myth"},
    }
    for _, r in ipairs(mplus) do
        Cell(c, 6,  y, 48, r[1], TIER_COL[r[7]] or TIER_COL.Dim, 10, "LEFT")
        Cell(c, 58, y, 40, tostring(r[2]), TIER_COL[r[5]], 10)
        Cell(c, 102,y, 40, tostring(r[3]), TIER_COL[r[6]], 10)
        if r[4] then CrestCell(c, 150, y, 110, r[4], r[7], 9) end
        y = y + RH
    end

    ----------------------------------------------------------------
    -- TABLE 3: Raid Loot
    -- Each difficulty row colored by its tier
    ----------------------------------------------------------------
    y = y + 6
    y = Hdr(c, y, "Raid Item Levels")
    y = y + 2

    local cols3 = { {x=6,w=58,t="Difficulty"}, {x=68,w=40,t="Early"}, {x=112,w=40,t="Mid"}, {x=156,w=40,t="Late"}, {x=200,w=40,t="End"} }
    for _, col in ipairs(cols3) do Cell(c, col.x, y, col.w, col.t, TIER_COL.Hdr, 9) end
    y = y + 12; HLine(c, y); y = y + 3

    -- {difficulty, early, mid, late, end, earlyTier, midTier, lateTier, endTier}
    -- Colors specified per cell to match reference exactly
    local raids = {
        {"LFR",     233, 237, 240, 243, "Vet",   "Vet",   "Vet",   "Champ"},
        {"Normal",  246, 250, 253, 256, "Champ", "Champ", "Champ", "Hero"},
        {"Heroic",  259, 263, 266, 269, "Hero",  "Hero",  "Hero",  "Myth"},
        {"Mythic",  272, 276, 279, 282, "Myth",  "Myth",  "Myth",  "Myth"},
    }
    for _, r in ipairs(raids) do
        Cell(c, 6,  y, 58, r[1], TIER_COL[r[6]], 10, "LEFT")
        Cell(c, 68, y, 40, tostring(r[2]), TIER_COL[r[6]], 10)
        Cell(c, 112,y, 40, tostring(r[3]), TIER_COL[r[7]], 10)
        Cell(c, 156,y, 40, tostring(r[4]), TIER_COL[r[8]], 10)
        Cell(c, 200,y, 40, tostring(r[5]), TIER_COL[r[9]], 10)
        y = y + RH
    end

    ----------------------------------------------------------------
    -- TABLE 4: Crafted Item Levels
    -- Columns are track-specific: color by that column's tier
    ----------------------------------------------------------------
    y = y + 6
    y = Hdr(c, y, "Crafted Item Levels")
    y = y + 2

    local craftHdrs = {
        {x=6,w=40,t="Adv",k="Adv"}, {x=55,w=40,t="Vet",k="Vet"}, {x=105,w=40,t="Champ",k="Champ"},
        {x=155,w=40,t="Hero",k="Hero"}, {x=205,w=40,t="Myth",k="Myth"},
    }
    for _, col in ipairs(craftHdrs) do Cell(c, col.x, y, col.w, col.t, TIER_COL[col.k], 9) end
    y = y + 12; HLine(c, y); y = y + 3

    local crafted = {
        {220, 233, 246, 259, 272},
        {224, 237, 250, 263, 276},
        {227, 240, 253, 266, 279},
        {230, 243, 256, 269, 282},
        {233, 246, 259, 272, 285},
    }
    for _, r in ipairs(crafted) do
        Cell(c, 6,  y, 40, tostring(r[1]), TIER_COL.Adv, 10)
        Cell(c, 55, y, 40, tostring(r[2]), TIER_COL.Vet, 10)
        Cell(c, 105,y, 40, tostring(r[3]), TIER_COL.Champ, 10)
        Cell(c, 155,y, 40, tostring(r[4]), TIER_COL.Hero, 10)
        Cell(c, 205,y, 40, tostring(r[5]), TIER_COL.Myth, 10)
        y = y + RH
    end

    ----------------------------------------------------------------
    -- TABLE 5: Bountiful Delve Loot
    -- Color by the row's tier key
    ----------------------------------------------------------------
    y = y + 6
    y = Hdr(c, y, "Bountiful Delve Rewards")
    y = y + 2

    local cols5 = { {x=6,w=30,t="Tier"}, {x=42,w=40,t="Loot"}, {x=88,w=40,t="Map"}, {x=134,w=40,t="Vault"} }
    for _, col in ipairs(cols5) do Cell(c, col.x, y, col.w, col.t, TIER_COL.Hdr, 9) end
    y = y + 12; HLine(c, y); y = y + 3

    -- Delve data: tier, loot, map, vault, tierKey, blocked?, lootTier, mapTier, vaultTier
    local delves = {
        {"1",  220, nil, 233,  "Adv"},
        {"2",  224, nil, 237,  "Adv"},
        {"3",  227, nil, 240,  "Adv"},
        {"4",  230, 237, 243,  "Vet"},
        {"5",  233, 243, 246,  "Vet"},
        {"6",  237, 250, 253,  "Champ"},
        {"7",  250, 256, 256,  "Champ"},
        {"8",  250, 259, 259,  "Champ", false, "Champ", "Hero", "Hero"},
        {"9",  nil, nil, nil,  "Hero",  true},   -- blocked
        {"10", nil, nil, nil,  "Hero",  true},   -- blocked
        {"11", nil, nil, nil,  "Hero",  true},   -- blocked
    }
    for _, r in ipairs(delves) do
        local tc = TIER_COL[r[5]] or TIER_COL.Dim
        local blocked = r[6]

        Cell(c, 6, y, 30, r[1], tc, 10)

        if blocked then
            Cell(c, 42, y, 40, "\226\128\148", TIER_COL.Dim, 10)
            Cell(c, 88, y, 40, "\226\128\148", TIER_COL.Dim, 10)
            Cell(c, 134,y, 40, "\226\128\148", TIER_COL.Dim, 10)
        else
            local lc = r[7] and TIER_COL[r[7]] or tc
            local mc = r[8] and TIER_COL[r[8]] or tc
            local vc = r[9] and TIER_COL[r[9]] or tc
            Cell(c, 42, y, 40, r[2] and tostring(r[2]) or "n/a", r[2] and lc or TIER_COL.Dim, 10)
            Cell(c, 88, y, 40, r[3] and tostring(r[3]) or "n/a", r[3] and mc or TIER_COL.Dim, 10)
            Cell(c, 134,y, 40, r[4] and tostring(r[4]) or "n/a", r[4] and vc or TIER_COL.Dim, 10)
        end
        y = y + RH
    end

    ----------------------------------------------------------------
    -- Crest legend at bottom — icons + hoverable currency tooltips
    ----------------------------------------------------------------
    y = y + 8
    y = Hdr(c, y, "Dawncrest Currencies")
    y = y + 2

    local crestOrder = {
        {"Adv",   "ilvl 224-237"},
        {"Vet",   "ilvl 237-250"},
        {"Champ", "ilvl 250-263"},
        {"Hero",  "ilvl 263-276"},
        {"Myth",  "ilvl 276-289"},
    }
    for _, cr in ipairs(crestOrder) do
        CrestBtn(c, 10, y, cr[1], 16)
        -- Range label — offset further right to avoid overlap with crest name
        local tc = TIER_COL[cr[1]]
        Cell(c, 200, y+1, 100, cr[2], tc, 9, "LEFT")
        y = y + 18
    end

    y = y + 4
    y = Txt(c, y, "100 crests per type per week. 20 crests per upgrade rank.", .5,.5,.5, 9)
    y = y + 2
    y = Txt(c, y, "3:1 trade-up after earning track achievement. 10:1 trade-down.", .5,.5,.5, 9)

    c:SetHeight(y + PAD)
end

----------------------------------------------------------------------
-- Tab 5: Talents (export strings for M+, Raid ST, Raid Cleave)
----------------------------------------------------------------------
local pendingTalentCopy = ""
StaticPopupDialogs["MCS_COPY_TALENT"] = {
    text = "Copy this talent build string (Ctrl+C):",
    button1 = "Done",
    hasEditBox = true,
    editBoxWidth = 350,
    OnShow = function(self)
        self.EditBox:SetText(pendingTalentCopy)
        self.EditBox:HighlightText()
        self.EditBox:SetFocus()
    end,
    EditBoxOnEscapePressed = function(self)
        StaticPopup_Hide("MCS_COPY_TALENT")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function MCS:BuildTalentsTab()
    local c = self.tabFrames[5].content; ClearC(c)
    local y = PAD

    -- Determine which specs this class has
    local cls = MCS.viewingClass or self.currentClass
    local specs = cls and self.ALL_SPECS[cls]
    if not specs or #specs == 0 then
        y = Txt(c, y, "No class detected.", 1, .3, .3)
        c:SetHeight(y + PAD); return
    end

    -- Default to current spec if no override is set, or reset if class changed
    if not self.talentTabSpec or not self:MakeSpecKey(cls, self.talentTabSpec) then
        self.talentTabSpec = (cls == self.currentClass) and self.currentSpec or specs[1]
    end

    -- Spec selector row
    local labelFs = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelFs:SetFont(STANDARD_TEXT_FONT, 10, ""); labelFs:SetPoint("TOPLEFT", 8, -y)
    labelFs:SetTextColor(.6, .6, .6); labelFs:SetText("Spec:")
    table_insert(txts, labelFs)

    local btnX = 42
    for _, specName in ipairs(specs) do
        local isActive = (specName == self.talentTabSpec)
        local specKey = self:MakeSpecKey(cls, specName)
        local hasData = self.TalentDB[specKey] and true or false

        local btn = CreateFrame("Button", nil, c, "BackdropTemplate")
        local iconID = self:GetSpecIcon(specName, cls)
        local iconW = iconID and 18 or 0
        btn:SetSize(specName:len() * 6.5 + 16 + iconW, 20)
        btn:SetPoint("TOPLEFT", btnX, -y + 2)
        btn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
        if isActive then
            btn:SetBackdropColor(.2, .2, .4, 1)
            btn:SetBackdropBorderColor(.4, .6, 1, .8)
        else
            btn:SetBackdropColor(.1, .1, .15, .8)
            btn:SetBackdropBorderColor(.25, .25, .3, .6)
        end

        -- Spec icon
        if iconID then
            local ico = btn:CreateTexture(nil, "ARTWORK")
            ico:SetSize(16, 16)
            ico:SetPoint("LEFT", 3, 0)
            ico:SetTexture(iconID)
            ico:SetTexCoord(.08, .92, .08, .92)
            if not isActive then ico:SetDesaturated(true); ico:SetAlpha(.6) end
        end

        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetFont(STANDARD_TEXT_FONT, 10, "")
        if iconID then
            fs:SetPoint("LEFT", 3 + 18, 0)
            fs:SetPoint("RIGHT", -3, 0)
        else
            fs:SetAllPoints()
        end
        fs:SetJustifyH("CENTER")
        if isActive then
            local r, g, b = self:ClassColor(cls)
            fs:SetTextColor(r, g, b)
        elseif hasData then
            fs:SetTextColor(.65, .65, .65)
        else
            fs:SetTextColor(.35, .35, .35)
        end
        fs:SetText(specName)

        btn:SetScript("OnClick", function()
            self.talentTabSpec = specName
            self.statsTabSpec = specName
            self.gearTabSpec = specName
            MCS.viewingSpecKey = self:MakeSpecKey(cls, specName)
            MCS.activeListName = nil
            self:BuildTalentsTab()
        end)
        btn:SetScript("OnEnter", function(b)
            if not isActive then
                b:SetBackdropColor(.15, .15, .25, 1)
                b:SetBackdropBorderColor(.35, .45, .7, .8)
            end
        end)
        btn:SetScript("OnLeave", function(b)
            if not isActive then
                b:SetBackdropColor(.1, .1, .15, .8)
                b:SetBackdropBorderColor(.25, .25, .3, .6)
            end
        end)

        table_insert(txts, btn)
        btnX = btnX + btn:GetWidth() + 4
    end

    y = y + 24

    -- Talent content
    local specKey = self:MakeSpecKey(cls, self.talentTabSpec)
    local data = self.TalentDB[specKey]

    if not data then
        y = Txt(c, y, "No talent data available for this spec.", .5, .5, .5)
        c:SetHeight(y + PAD); return
    end

    local sections = { "M+", "Raid ST", "Raid Cleave" }
    for _, section in ipairs(sections) do
        y = Hdr(c, y, section)
        local exportStr = data[section]
        if not exportStr or exportStr == "" then
            y = Txt(c, y, "No build available.", .5, .5, .5)
        else
            -- Copy button
            local copyBtn = CreateFrame("Button", nil, c, "BackdropTemplate")
            copyBtn:SetSize(60, 20)
            copyBtn:SetPoint("TOPLEFT", 8, -y)
            copyBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
            copyBtn:SetBackdropColor(.15, .25, .15, .9)
            copyBtn:SetBackdropBorderColor(.3, .6, .3, .8)

            local copyFs = copyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            copyFs:SetFont(STANDARD_TEXT_FONT, 10, "")
            copyFs:SetAllPoints()
            copyFs:SetJustifyH("CENTER")
            copyFs:SetTextColor(.4, 1, .4)
            copyFs:SetText("Copy")

            copyBtn:SetScript("OnClick", function()
                pendingTalentCopy = exportStr
                StaticPopup_Show("MCS_COPY_TALENT")
            end)
            copyBtn:SetScript("OnEnter", function(b)
                b:SetBackdropColor(.2, .35, .2, 1)
                b:SetBackdropBorderColor(.4, .8, .4, .9)
            end)
            copyBtn:SetScript("OnLeave", function(b)
                b:SetBackdropColor(.15, .25, .15, .9)
                b:SetBackdropBorderColor(.3, .6, .3, .8)
            end)

            table_insert(txts, copyBtn)
            y = y + 24
        end
        y = y + 4
    end

    c:SetHeight(y + PAD)
end

----------------------------------------------------------------------
-- Minimap
----------------------------------------------------------------------
function MCS:CreateMinimapButton()
    -- Try LibDBIcon (compatible with EnhanceQoL button bin and similar addons)
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)

    if LDB and LDBIcon then
        local dataObj = LDB:NewDataObject("MidnightCheatSheet", {
            type = "launcher",
            icon = "Interface\\Icons\\INV_Scroll_11",
            OnClick = function(_, button)
                if button == "LeftButton" then MCS:Toggle() end
            end,
            OnTooltipShow = function(tip)
                tip:AddLine("|cff00ccffMidnight CheatSheet|r")
                tip:AddLine("|cffccccccClick|r toggle  |cffccccccDrag|r to move")
                tip:AddLine("|cffcccccc/mcs|r commands")
            end,
        })
        -- Use MCSdb.minimapIcon for LibDBIcon settings (position, hide state, etc.)
        if not MCS.db then MCS.db = {} end
        if not MCS.db.minimapIcon then MCS.db.minimapIcon = {} end
        LDBIcon:Register("MidnightCheatSheet", dataObj, MCS.db.minimapIcon)
        self.minimapBtn = LDBIcon:GetMinimapButton("MidnightCheatSheet")
        return
    end

    -- Fallback: manual minimap button (no LibDBIcon available)
    local btn = CreateFrame("Button",nil,Minimap)
    btn:SetSize(32,32); btn:SetFrameStrata("MEDIUM"); btn:SetFrameLevel(8)
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local ov = btn:CreateTexture(nil,"OVERLAY"); ov:SetSize(54,54)
    ov:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); ov:SetPoint("TOPLEFT")
    local ic = btn:CreateTexture(nil,"BACKGROUND"); ic:SetSize(20,20)
    ic:SetTexture("Interface\\Icons\\INV_Scroll_11"); ic:SetPoint("CENTER",0,1)
    btn:SetMovable(true); btn:RegisterForDrag("LeftButton"); btn:RegisterForClicks("AnyUp")

    local function IsMinimapSquare()
        if type(GetMinimapShape) == "function" then
            local ok, shape = pcall(GetMinimapShape)
            if ok and shape and shape ~= "ROUND" then return true end
        end
        if Minimap.GetMaskTexture then
            local ok, mask = pcall(Minimap.GetMaskTexture, Minimap)
            if ok and mask and type(mask) == "string" and mask:lower():find("square") then return true end
        end
        return false
    end

    local function PositionButton(angle)
        local isSquare = IsMinimapSquare()
        local rad = math_rad(angle)
        local mW, mH = Minimap:GetWidth() / 2, Minimap:GetHeight() / 2
        local x, y
        if isSquare then
            local rawX = math_cos(rad)
            local rawY = math_sin(rad)
            local scale = math_max(math_abs(rawX), math_abs(rawY))
            x = (rawX / scale) * mW
            y = (rawY / scale) * mH
        else
            local R = mW + 2
            x = math_cos(rad) * R
            y = math_sin(rad) * R
        end
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    local function AngleFromCursor()
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local sc = Minimap:GetEffectiveScale()
        cx, cy = cx / sc, cy / sc
        return math_deg(math_atan2(cy - my, cx - mx))
    end

    local db = MCS.db or {}
    local savedAngle = db.minimapAngle or 220
    PositionButton(savedAngle)

    local dragging = false
    btn:SetScript("OnDragStart", function(s)
        dragging = true
        s:SetScript("OnUpdate", function()
            local angle = AngleFromCursor()
            PositionButton(angle)
            if MCS.db then MCS.db.minimapAngle = angle end
        end)
    end)
    btn:SetScript("OnDragStop", function(s)
        dragging = false
        s:SetScript("OnUpdate", nil)
        local angle = AngleFromCursor()
        if MCS.db then MCS.db.minimapAngle = angle end
    end)
    btn:SetScript("OnClick", function(_, b)
        if b == "LeftButton" and not dragging then MCS:Toggle() end
    end)
    btn:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff00ccffMidnight CheatSheet|r")
        GameTooltip:AddLine("|cffccccccClick|r toggle  |cffccccccDrag|r to move")
        GameTooltip:AddLine("|cffcccccc/mcs|r commands")
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.minimapBtn = btn
end

tinsert(UISpecialFrames, "MCSFrame")

--- Public API for other files (e.g. DungeonJournalHook)
function MCS:ShowWishlistPicker(itemID, source, anchor)
    ShowPicker(itemID, source, anchor)
end
