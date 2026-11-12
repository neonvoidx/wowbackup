local ADDON, ns = ...

local one

local HISTORY_LINES = ns.MAX_HISTORY -- the window can hold as many lines as the largest allowed history

local function UpdateCount(H)
    H.win.count:SetText(("%d remembered"):format(ns.GetHistoryCount(H.W)))
end

-- True if the entry's character name or item name contains the search term.
local function IsMatch(H, e)
    local who = Ambiguate(e.name, "short"):lower()
    if who:find(H.search, 1, true) or e.name:lower():find(H.search, 1, true) then
        return true
    end
    local item = e.link:match("%[(.-)%]")
    return item and item:lower():find(H.search, 1, true) and true or false
end

local function UpdateSearchStatus(H)
    if H.search == "" then
        H.win.status:SetText("")
    elseif #H.matches == 0 then
        H.win.status:SetText("|cffff5555no match|r")
    else
        H.win.status:SetText(("%d / %d"):format(H.matchPos, #H.matches))
    end
end

local function Redraw(H)
    if H.win and H.win:IsShown() then
        local isMatch = H.search ~= "" and function(e)
            return IsMatch(H, e)
        end or nil
        H.matches, H.drawn, H.sep = ns.RenderTo(H.W, H.win.messages, ns.db.hist, HISTORY_LINES, isMatch, H.matchPos)
        if H.matchPos > #H.matches then
            H.matchPos = #H.matches
        end
        UpdateCount(H)
        UpdateSearchStatus(H)
    end
end

-- Core calls this whenever the history of a window or the display settings change.
function ns.OnHistoryChanged(W)
    if one and one.W == W then
        Redraw(one)
    end
end

-- A new loot event: add just that line instead of redrawing thousands.
function ns.OnNewEntry(entry)
    local H, W = one, one and one.W
    if H and H.win and H.win:IsShown() then
        if H.search ~= "" then
            return Redraw(H) -- keep the highlights and the match count right
        end
        if ns.ShouldShow(entry, ns.db.hist) then
            H.sep = H.sep or {}
            local lines = ns.Separators(ns.db.hist, H.sep, entry)
            if lines then
                for _, text in ipairs(lines) do
                    H.win.messages:AddMessage(ns.MARK_OFF .. text)
                end
            end
            H.win.messages:AddMessage(ns.MARK_OFF .. ns.FormatEntry(entry, ns.db.hist, W))
        end
        UpdateCount(H)
    end
end

-- Scroll so that line number `index` (1 = oldest drawn) sits in the middle of the view.
local function ScrollToLine(H, index)
    local msgs = H.win.messages
    local _, size = msgs:GetFont()
    local visibleLines = math.max(1, math.floor(msgs:GetHeight() / (size + 3)))
    local offset = H.drawn - index - math.floor(visibleLines / 2)
    msgs:SetScrollOffset(math.max(0, math.min(offset, msgs:GetMaxScrollRange())))
end

-- Find: a new term highlights every match and jumps to the newest; pressing Find
-- again (or Enter) steps to the next older match and wraps around.
local function DoSearch(H)
    local term = strtrim(H.win.searchBox:GetText()):lower()
    H.win.searchBox:ClearFocus()
    if term ~= H.search then
        H.search = term
        H.matchPos = 0
        Redraw(H) -- finds the matches
        if #H.matches > 0 then
            H.matchPos = #H.matches
            Redraw(H) -- draws the current one green
        end
    elseif #H.matches > 0 then
        H.matchPos = H.matchPos - 1
        if H.matchPos < 1 then
            H.matchPos = #H.matches
        end
        Redraw(H)
    end
    UpdateSearchStatus(H)
    if H.matchPos > 0 and H.matches[H.matchPos] then
        ScrollToLine(H, H.matches[H.matchPos])
    end
end

StaticPopupDialogs["FROGSKISCHATLOOT_RESET_HISTORY"] = {
    text = "Delete all remembered loot history?\n\nThis cannot be undone.",
    button1 = YES,
    button2 = NO,
    OnAccept = function(_, W)
        ns.ClearHistory(W)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

local function Build(W)
    local H = {
        W = W,
        search = "",
        matches = {},
        drawn = 0,
        matchPos = 0
    }
    one = H
    local frameName = "FrogskisChatLootHistory" .. W.id

    local win = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    H.win = win
    local saved = ns.db.histSize
    win:SetSize(saved and saved.w or 575, saved and saved.h or 529)
    win:SetResizable(true)
    if win.SetResizeBounds then
        win:SetResizeBounds(360, 180, 1200, 1000)
    else
        win:SetMinResize(360, 180)
    end
    win:SetPoint("CENTER", 24 * (W.id - 1), -24 * (W.id - 1)) -- a little off the middle, as it always was
    win:SetFrameStrata("DIALOG")
    win:SetFrameLevel(60) -- always above the options window, which uses 20
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    ns.ApplyWindowStyle(win)
    tinsert(UISpecialFrames, frameName)

    local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -10)
    win.title = title

    win.count = win:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    win.count:SetPoint("LEFT", title, "RIGHT", 8, 0)

    local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    close:SetSize(22, 22)
    close:SetPoint("TOPRIGHT", -4, -4)

    local gear = ns.AddGearButton(win, function(self)
        ns.ToggleQuickFilters(self, ns.db.hist, function()
            Redraw(H)
        end, false, H.W)
    end)
    gear:ClearAllPoints()
    gear:SetPoint("RIGHT", close, "LEFT", -4, 0)

    local reset = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    reset:SetSize(54, 20)
    reset:SetPoint("RIGHT", gear, "LEFT", -6, 0)
    reset:SetText("Reset")
    reset:SetScript("OnClick", function()
        StaticPopup_Show("FROGSKISCHATLOOT_RESET_HISTORY", nil, nil, H.W)
    end)

    -- Search row: character or item name, then Find.
    local box = CreateFrame("EditBox", nil, win, "InputBoxTemplate")
    box:SetPoint("TOPLEFT", 18, -32)
    box:SetSize(200, 20)
    box:SetAutoFocus(false)
    box:SetMaxLetters(40)
    box:SetScript("OnEnterPressed", function()
        DoSearch(H)
    end)
    box:SetScript("OnEscapePressed", box.ClearFocus)
    win.searchBox = box

    local find = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    find:SetSize(54, 22)
    find:SetPoint("LEFT", box, "RIGHT", 6, 0)
    find:SetText("Find")
    find:SetScript("OnClick", function()
        DoSearch(H)
    end)

    win.status = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    win.status:SetPoint("LEFT", find, "RIGHT", 8, 0)

    find:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Search by character or item name")
        GameTooltip:AddLine("Matches are marked with >>. Press Find again for the next older match.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    find:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local msgs = CreateFrame("ScrollingMessageFrame", nil, win)
    msgs:SetPoint("TOPLEFT", 10, -74)
    msgs:SetPoint("BOTTOMRIGHT", -26, 22)

    -- Blizzard's own scroll bar, wired to the message frame.
    local bar = CreateFrame("EventFrame", nil, win, "MinimalScrollBar")
    bar:SetPoint("TOPRIGHT", win, "TOPRIGHT", -8, -78)
    bar:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -8, 28)

    -- Grip in the bottom right corner to resize the window.
    local grip = CreateFrame("Button", nil, win)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -4, 4)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function()
        win:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", function()
        win:StopMovingOrSizing()
        ns.db.histSize = {
            w = math.floor(win:GetWidth() + 0.5),
            h = math.floor(win:GetHeight() + 0.5)
        }
    end)
    local font, size, flags = W.frame:GetFont() -- the chat window's own font
    msgs:SetFont(font, size, flags)
    msgs:SetJustifyH("LEFT")
    msgs:SetMaxLines(HISTORY_LINES)
    msgs:SetFading(false)
    msgs:SetHyperlinksEnabled(true)
    msgs:EnableMouseWheel(true)
    msgs:SetScript("OnMouseWheel", function(self, delta)
        local step = IsShiftKeyDown() and 10 or 3
        for _ = 1, step do
            if delta > 0 then
                self:ScrollUp()
            else
                self:ScrollDown()
            end
        end
    end)
    msgs:SetScript("OnHyperlinkClick", function(self, link, text, button)
        SetItemRef(link, text, button, self)
    end)
    ns.SetupTooltips(msgs)
    ScrollUtil.InitScrollingMessageFrameWithScrollBar(msgs, bar, true) -- true: we handle the wheel
    win.messages = msgs

    local hold = "history" -- the chat stays at full opacity while this window is open
    win:SetScript("OnShow", function()
        ns.SetChatHold(hold, true)
        win.title:SetText("Loot history")
        local shownFont, shownSize, shownFlags = H.W.frame:GetFont() -- the font of the chat window it is shown for
        if shownFont then
            msgs:SetFont(shownFont, shownSize, shownFlags)
        end
        Redraw(H)
    end)
    win:Hide() -- frames start shown; hide so the first toggle opens it and OnShow fires
    win:SetScript("OnHide", function()
        ns.SetChatHold(hold, false)
    end) -- set after the Hide above
end

-- The loot window the history window is shown for when nothing else says: the one named "Loot", else the first.
local function HomeWindow(list)
    for _, W in ipairs(list) do
        if (GetChatWindowInfo(W.id)) == "Loot" then
            return W
        end
    end
    return list[1]
end

-- The gear's "History..." of a loot window: the one history window opens (or closes), for that loot window.
function ns.ToggleHistory(W)
    if not one then
        Build(W)
    end
    if one.win:IsShown() then
        one.win:Hide()
    else
        one.W = W
        one.win:Show()
    end
end

-- The options window's button and /fcl history: the one history window of all the loot windows.
function ns.ToggleAllHistory()
    local list = ns.ActiveWindows()
    if #list == 0 then
        return ns.Print("No loot window found. Tick Loot in a chat tab's settings.")
    end
    if not one then
        Build(HomeWindow(list))
    end
    if one.win:IsShown() then
        one.win:Hide()
    else
        if not one.W.active then
            one.W = HomeWindow(list)
        end
        one.win:Show()
    end
end

-- Loot was unticked in a chat window: the history window goes on for another loot window, and closes when there is none.
function ns.CloseHistory(W)
    if not (one and one.W == W) then
        return
    end
    local other = HomeWindow(ns.ActiveWindows()) -- W is not active any more
    if other then
        one.W = other
        if one.win:IsShown() then
            Redraw(one)
        end
    else
        one.win:Hide()
    end
end
