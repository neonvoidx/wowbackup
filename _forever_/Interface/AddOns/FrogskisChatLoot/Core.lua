local ADDON, ns = ...

local MIN_HISTORY, MAX_HISTORY = 100, 5000 -- allowed range of the "max entries" setting
ns.MIN_HISTORY, ns.MAX_HISTORY = MIN_HISTORY, MAX_HISTORY

local issecretvalue = issecretvalue or function()
    return false
end

local function AllQualities()
    return {
        [0] = true,
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true
    }
end

local DEFAULTS = {
    -- Qualities that are shown: 0 grey, 1 white, 2 green, 3 blue, 4 epic, 5 legendary and up
    qualities = {
        [0] = false,
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true
    },
    showSelf = true,
    showOthers = true,
    minItemLevel = 0, -- applies to weapons and armor only
    -- [classID] = true: the item types that are hidden (consumables, bags, gems, crafting reagents ...); none
    hideClass = {},
    blacklist = "", -- item names / IDs, separated by commas or new lines
    whitelist = "", -- always shown, overrides every filter
    timestamp = false,
    classColor = true,
    showItemLevel = false,
    showQuantity = true,
    separator = ">", -- text between the name and the item
    leftMargin = 3, -- extra space in front of every line, in pixels
    alignColumn = true, -- pad names so every item starts at the same x
    shortenNames = true, -- cut long player names ("Cyberchungus" -> "Cyber...") so the column of arrows sits further left
    nameEllipsis = false, -- a cut name ends with "..." ("verylo..."); off: it ends with three more letters ("verylongn")
    nameMaxWidth = 62, -- how wide a name may be, in the window's own units (the "->" column can be dragged to change it)
    shortenItems = true, -- "One chat line per loot entry": a long item name is cut ("[Sanctified Knight's Pho...]") so no line takes two rows
    showReceived = true, -- also show items handed over: trades, mail, quest rewards, vendors
    showMoney = true, -- show the money lines ("Your share of the loot is 4 Copper.")
    moneyLines = true, -- a money line is laid out like a loot line: "Frogski -> 3g 22s 84c"
    moneyIcons = true, -- the g, s and c are the little gold, silver and copper pictures
    moneyIconSize = 7, -- how big those pictures are, in pixels
    moneyIconDrop = 3, -- how many pixels lower than the middle of the text line they stand
    showRolls = true, -- show the roll lines (need, greed, pass, won)
    showDrops = true, -- show what a boss drops for a roll: the "<boss> drops:" line and the items
    showAllDrops = true, -- the boss drops line shows every item of the kill, not only the ones that can be rolled on
    dropTree = true, -- lines from the "<boss> drops:" line down to the names of the items it dropped
    showCrafts = true, -- show the crafting lines ("Name creates: [Item]", "You create: [Item]")
    chatLines = 1000, -- loot history lines put back in a chat window after a reload (0 - 1000)
    dateSeparator = true, -- a grey date line between two loot lines of different days ("Monday 10-Oct-2026")
    instanceSeparator = true, -- a grey line with the instance name in front of loot picked up inside an instance
    separatorIndent = 0, -- spaces in front of the date and place lines
    dateIcon = "calendar", -- a little picture next to the date: none, calendar, clock, note, scroll
    dateIconSide = "left",
    dateIconScale = 0.8, -- how big the pictures are compared to their normal size: 0.5 to 1.5
    placeIcon = "map", -- a little picture next to the name of an instance: none, map, skull ...
    placeIconSide = "left",
    placeIconScale = 0.8,
    townIcon = "inn", -- a little picture next to the name of a town (a city, an inn, the housing neighbourhood): none, house, inn ...
    townIconSide = "left",
    townIconScale = 0.8,
    worldIcon = "crosshair_directions_48", -- a little picture next to the name of a place in the open world (not a town, not an instance)
    worldIconSide = "left",
    worldIconScale = 0.8,
    dateColor = "ffffa3", -- the font color of each of those lines, as hex: date, instance, town, open world, elite boss, rare boss
    placeColor = "20bb00",
    townColor = "88ff84",
    worldColor = "89acce",
    eliteBossIcon = "nameplates-icon-elite-gold", -- the "<boss> drops:" line of an elite boss, a world boss and any boss not known to be a rare: its picture, side, size and text color
    eliteBossIconSide = "left",
    eliteBossIconScale = 1,
    eliteBossColor = "ff0023",
    rareBossIcon = "nameplates-icon-elite-silver", -- the same for a rare
    rareBossIconSide = "left",
    rareBossIconScale = 1,
    rareBossColor = "bdfffa",
    zoneSeparator = true, -- a grey line with the zone name whenever the loot comes from another place
    showSoulbound = true, -- show items that bind when picked up (off: they are hidden)
    showWarbound = true, -- show warbound (account bound) items
    showBoE = true, -- show items that bind when equipped
    boeSound = false, -- play a sound when an item that binds when equipped drops
    boeSoundId = 31578, -- which sound (a sound kit number from BOE_SOUNDS)
    -- Quick filters of the history windows (separate from the Loot windows').
    -- Its filters are its own; the chat windows' are above.
    hist = {
        qualities = AllQualities(), -- every quality is shown
        showSelf = true,
        showOthers = true,
        minItemLevel = 0,
        hideClass = {}, -- no item type is hidden
        blacklist = "",
        whitelist = "",
        showReceived = true,
        showCrafts = true,
        dateSeparator = true, -- a grey date line between two lines of different days
        instanceSeparator = true, -- a grey line with the instance name in front of loot from an instance
        zoneSeparator = true, -- a grey line with the zone name whenever the loot comes from another place
        showSoulbound = true, -- all three binding kinds are shown
        showWarbound = true,
        showBoE = true,
        timestamp = false,
        dates = false
    },
    customIcons = {
        date = {},
        place = {},
        town = {},
        world = {},
        eliteboss = {},
        rareboss = {}
    }, -- texture atlas names added by hand to the picture lists, for each kind of line
    townZones = {}, -- ["Zone name"] = "town" | "home": places learned as towns, for loot recorded before it was known
    maxHistory = 5000, -- entries remembered per character and window (shown in its history window)
    histories = {}, -- before 1.5: ["Name-Realm"] = { entries } (moved into winHist)
    winHist = {}, -- ["Name-Realm"].shared = { entries }: one history for all the loot windows (before: a list for each chat window id)
    winRolls = {}, -- ["Name-Realm"].shared = { { text, time, boss } }: the roll lines, put back after a reload (one list, the same way)
    gearPos = {} -- [chat window id] = { x, y }: where the gear sits in that window
}

-- Profiles. Everything the options window sets about how loot lines are filtered and shown belongs to
-- a profile; the History window's own filters, the size limit of the history and the saved history
-- itself are the same whatever the profile.
local GLOBAL_KEYS = {
    hist = true,
    maxHistory = true,
    histories = true,
    winHist = true,
    winRolls = true,
    gearPos = true,
    townZones = true,
    customIcons = true
}
-- Two settings belong to the character: how many lines are put back in the chat window after a reload and how
-- many entries the history remembers. They are the same whatever profile is in use.
local CHAR_KEYS = {
    chatLines = true,
    maxHistory = true
}
local ISPROFILE, SETTING_DEFAULTS = {}, {}
for k, v in pairs(DEFAULTS) do
    if not GLOBAL_KEYS[k] and not CHAR_KEYS[k] then
        ISPROFILE[k] = true
        SETTING_DEFAULTS[k] = v
    end
end

-- Item classes that make sense to filter (classID -> label).
ns.ITEM_CLASSES = {{0, "Consumables"}, {1, "Containers (bags)"}, {2, "Weapons"}, {3, "Gems"}, {4, "Armor"},
                   {7, "Crafting reagents"}, -- the trade goods class, plus any item flagged as a crafting reagent
{9, "Recipes"}, {12, "Quest items"}, {15, "Miscellaneous"}, {17, "Battle pets"}, {19, "Profession items"},
                   {20, "Housing / neighborhood"}, -- event items such as Home-Grown Wax
{"currency", "Currency (crests etc.)"} -- not an item class: currency gains
}

local COLOR_TO_QUALITY = {
    ["9d9d9d"] = 0,
    ["ffffff"] = 1,
    ["1eff00"] = 2,
    ["0070dd"] = 3,
    ["a335ee"] = 4,
    ["ff8000"] = 5,
    ["e6cc80"] = 6,
    ["00ccff"] = 7
}
local QUALITY_TO_COLOR = {}
for hex, q in pairs(COLOR_TO_QUALITY) do
    QUALITY_TO_COLOR[q] = hex
end

local WEAPON, ARMOR = 2, 4
-- Item binding (the bindType the game reports): 1 = picked up, 2 = equipped, 7/8/9 = warbound
local BIND_PICKUP, BIND_EQUIP = 1, 2
local WARBOUND = {
    [7] = true,
    [8] = true,
    [9] = true
}
local CRAFTING_REAGENTS = 7 -- the trade goods item class

local root -- the saved variables table: profiles, characters, history ...
local profile, profileName -- the settings of the profile in use
local char -- this character's profile choice and automation (root.chars[charKey])
local charKey -- "Name-Realm"

-- `db` is what the rest of the addon reads and writes. A setting that belongs to a profile goes to
-- (comes from) the profile in use; anything else goes to (comes from) the saved variables
-- themselves. Switching profile is therefore just pointing `profile` somewhere else.
local db = setmetatable({}, {
    __index = function(_, k)
        if not root then
            return nil
        end
        if CHAR_KEYS[k] then
            return char and char[k]
        end
        if ISPROFILE[k] then
            return profile[k]
        end
        return root[k]
    end,
    __newindex = function(_, k, v)
        if CHAR_KEYS[k] then
            if char then
                char[k] = v
            end
        elseif ISPROFILE[k] then
            profile[k] = v
        else
            root[k] = v
        end
    end
})
local windows = {} -- [chat window id] = loot window object (see Activate)
local blackSet, whiteSet = {}, {}
local histBlackSet, histWhiteSet = {}, {} -- the history windows' own always-hide / always-show lists

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Frogski's Chat Loot Filter|r: " .. msg)
end
ns.Print = Print

local function InLockdown()
    return C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() or false
end

---------------------------------------------------------------------------
-- Keeping the chat at full opacity while our own windows are open
---------------------------------------------------------------------------

-- A chat fading addon (AutoHideUI...) fades the chat frames the mouse is not over, by
-- asking each one IsMouseOver(). While one of our windows or menus is open (a "hold"),
-- the chat frames and their tabs answer "yes". The answer comes from a wrapper that looks
-- at the holds, so ending a hold is just clearing it: no override is ever put back over
-- someone else's. The wrapper calls the widget's own method, not whatever another addon
-- may have set on the frame.
local holds = {} -- [reason] = true

local function WrapIsMouseOver(obj)
    if not obj or obj.fclMouseWrapped then
        return
    end
    local meta = getmetatable(obj)
    local method = meta and type(meta.__index) == "table" and meta.__index.IsMouseOver
    if type(method) ~= "function" then
        return
    end
    obj.fclMouseWrapped = true
    obj.IsMouseOver = function(self, ...)
        if next(holds) then
            return true
        end
        return method(self, ...)
    end
end

function ns.SetChatHold(reason, on)
    if not on then
        holds[reason] = nil
        return
    end
    holds[reason] = true
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        WrapIsMouseOver(_G["ChatFrame" .. i])
        WrapIsMouseOver(_G["ChatFrame" .. i .. "Tab"])
    end
end

---------------------------------------------------------------------------
-- Database
---------------------------------------------------------------------------

local function CopyDefaults(src, dst)
    for k, v in pairs(src) do
        if dst[k] == nil then
            if type(v) == "table" then
                dst[k] = {}
                CopyDefaults(v, dst[k])
            else
                dst[k] = v
            end
        end
    end
end

local function ParseList(text, set)
    wipe(set)
    for entry in tostring(text or ""):gmatch("[^,\n]+") do
        entry = strtrim(entry):lower()
        if entry ~= "" then
            set[entry] = true
        end
    end
end

function ns.RebuildLists()
    ParseList(db.blacklist, blackSet)
    ParseList(db.whitelist, whiteSet)
    ParseList(db.hist.blacklist, histBlackSet)
    ParseList(db.hist.whitelist, histWhiteSet)
end

---------------------------------------------------------------------------
-- Shared widgets
---------------------------------------------------------------------------

-- Item tooltips on mouseover for a message frame.
function ns.SetupTooltips(frame)
    if frame.fclHooked then
        return
    end
    frame.fclHooked = true
    frame:HookScript("OnHyperlinkEnter", function(self, link)
        if link and (link:find("^item:") or link:find("^spell:") or link:find("^enchant:") or link:find("^currency:")) then
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
        end
    end)
    frame:HookScript("OnHyperlinkLeave", function()
        GameTooltip:Hide()
    end)
end

-- Dark panel with a thin gold-brown rounded border, like Blizzard's dropdown menus.
function ns.ApplyWindowStyle(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4
        }
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    frame:SetBackdropBorderColor(0.62, 0.5, 0.28, 1)
end

-- Small gear: opens the quick filter menu. Fades with `fadeRegion` if given.
function ns.AddGearButton(frame, onClick, fadeRegion)
    local btn = CreateFrame("Button", nil, frame)
    btn:SetSize(18, 18)
    btn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    btn:SetFrameLevel(frame:GetFrameLevel() + 10)
    btn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    btn:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton")
    btn:GetHighlightTexture():SetAlpha(0.5)
    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Loot filters")
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Follow the window's own opacity (including the fade in/out on mouseover).
    if fadeRegion then
        btn:SetScript("OnUpdate", function(self)
            self:SetAlpha(self:IsMouseOver() and 1 or fadeRegion:GetAlpha())
        end)
    end
    return btn
end

---------------------------------------------------------------------------
-- Filtering
---------------------------------------------------------------------------

-- Items whose data the client has not loaded yet (right after login, for instance): their
-- quality is asked for once, and every loot window is drawn again when the answer arrives.
local outstanding = {} -- [itemID] = true: asked for, not answered yet
local requested = {} -- [itemID] = true: asked for once this session (never asked twice)

local function NeedItemInfo(link)
    local id = tonumber(link:match("|Hitem:(%d+)"))
    if id and not requested[id] and C_Item.RequestLoadItemDataByID then
        requested[id] = true
        outstanding[id] = true
        C_Item.RequestLoadItemDataByID(id)
    end
end

-- `e` (the entry the link belongs to) is optional: when given, the quality is remembered in it
-- (and so in the saved history) the first time it is known.
local function QualityFromLink(link, e)
    if e and e.quality then
        return e.quality
    end
    local hex = link:match("|c%x%x(%x%x%x%x%x%x)")
    if hex and COLOR_TO_QUALITY[hex:lower()] then
        local q = COLOR_TO_QUALITY[hex:lower()]
        if e then
            e.quality = q
        end
        return q
    end
    -- No (known) color in the link: ask the client instead.
    if link:find("|Hcurrency:", 1, true) then
        local info = C_CurrencyInfo.GetCurrencyInfoFromLink(link)
        if info and info.quality then
            return info.quality
        end
    end
    local quality = select(3, C_Item.GetItemInfo(link))
    if quality then
        if e then
            e.quality = quality
        end
        return quality
    end
    NeedItemInfo(link) -- not loaded yet: shown as common until it is
    return 1
end

-- Re-wrap the link in its quality color so the line always matches the item.
local function ColorizeLink(link, e)
    local bare = link:gsub("^|c%x%x%x%x%x%x%x%x", ""):gsub("|r$", "")
    local hex = QUALITY_TO_COLOR[QualityFromLink(link, e)]
    return hex and ("|cff" .. hex .. bare .. "|r") or link
end

local function Matches(set, name, itemID)
    if next(set) == nil then
        return false
    end
    if itemID and set[tostring(itemID)] then
        return true
    end
    local lname = name and name:lower()
    return lname and set[lname] or false
end

-- How an item binds: "soulbound", "warbound", "boe" or "none"; nil while it cannot be told yet.
-- Use the tooltip's structured binding enum, never its translated text. Item data provides
-- the base bind type only (Warbound Until Equipped may report as BoE), so use it as a fallback.
local function BindingFromTooltip(link)
    local lineTypes = Enum and Enum.TooltipDataLineType
    local bindings = Enum and Enum.TooltipDataItemBinding
    if not (C_TooltipInfo and C_TooltipInfo.GetHyperlink and lineTypes and bindings) then
        return nil
    end
    local hyperlink = link:match("|H(item:[^|]*)|h")
    if not hyperlink then
        return nil
    end
    local data = C_TooltipInfo.GetHyperlink(hyperlink)
    if type(data) ~= "table" or type(data.lines) ~= "table" then
        return nil
    end
    for _, line in ipairs(data.lines) do
        if line and not issecretvalue(line.type) and line.type == lineTypes.ItemBinding then
            local bonding = line.bonding
            if bonding ~= nil and not issecretvalue(bonding) then
                if bonding == bindings.Soulbound or bonding == bindings.BindOnPickup then
                    return "soulbound"
                end
                if bonding == bindings.BindOnEquip then
                    return "boe"
                end
                if bonding == bindings.Account or bonding == bindings.BnetAccount or bonding == bindings.BindToAccount or
                    bonding == bindings.BindToBnetAccount or bonding == bindings.AccountUntilEquipped or bonding ==
                    bindings.BindToAccountUntilEquipped then
                    return "warbound"
                end
                if bonding == bindings.Quest or bonding == bindings.BindOnUse then
                    return "none"
                end
            end
        end
    end
    return nil
end

local function BindingFromBindType(bindType)
    if bindType == nil then
        return nil
    end
    if bindType == BIND_PICKUP then
        return "soulbound"
    end
    if bindType == BIND_EQUIP then
        return "boe"
    end
    if WARBOUND[bindType] then
        return "warbound"
    end
    return "none"
end

local bindCache = {} -- [link] = kind, only when verified by structured binding data
local function BindingOf(link, e, info)
    if e.binding then
        return e.binding
    end
    local kind = bindCache[link]
    if kind == nil then
        kind = BindingFromTooltip(link)
        if kind then
            bindCache[link] = kind
        end
    end
    if kind then
        e.binding = kind -- only persist the result when structured binding data confirmed it
        return kind
    end
    return BindingFromBindType(info[14]) -- numeric fallback may be wrong for Warbound Until Equipped
end

-- cfg is db for the Loot windows or db.hist for the history windows: the same filters,
-- each with its own settings.
local function ShouldShow(e, cfg)
    if e.superseded then
        return false
    end -- an upgrade step that another step followed (see NoteUpgrade)
    -- The one who won a roll: his loot line is shown whatever the filters say (while the loot rolls are shown).
    if e.won and cfg == db and cfg.showRolls then
        return true
    end
    if e.received and not cfg.showReceived then
        return false
    end -- handed over (trade, mail, ...), not a loot drop
    if e.crafted and not cfg.showCrafts then
        return false
    end -- "You create: [Item]"
    local link = e.link
    if e.isSelf and not cfg.showSelf then
        return false
    end
    if not e.isSelf and not cfg.showOthers then
        return false
    end

    local itemID = tonumber(link:match("|Hitem:(%d+)") or link:match("|Hcurrency:(%d+)"))
    local name = link:match("%[(.-)%]")

    local white, black = whiteSet, blackSet
    if cfg ~= db then
        white, black = histWhiteSet, histBlackSet
    end
    if Matches(white, name, itemID) then
        return true
    end
    if Matches(black, name, itemID) then
        return false
    end

    if not cfg.qualities[math.min(QualityFromLink(link, e), 5)] then
        return false
    end

    if e.currency then
        return not cfg.hideClass.currency
    end

    local info = {C_Item.GetItemInfo(link)}
    local ilvl, classID, isReagent = info[4], info[12], info[17]
    if not classID and itemID then
        classID = select(6, C_Item.GetItemInfoInstant(itemID))
    end
    if classID and cfg.hideClass[classID] then
        return false
    end
    -- "Crafting reagents" also covers reagents that are not in the trade goods class.
    if isReagent and cfg.hideClass[CRAFTING_REAGENTS] then
        return false
    end

    -- Binding: soulbound / warbound / binds when equipped. Remembered in the entry once known;
    -- while the game has not loaded the item yet, the line is shown (and drawn again when it has).
    if cfg.showSoulbound == false or cfg.showWarbound == false or cfg.showBoE == false then
        local binding = BindingOf(link, e, info)
        if binding == nil then
            NeedItemInfo(link)
        elseif (binding == "soulbound" and cfg.showSoulbound == false) or
            (binding == "warbound" and cfg.showWarbound == false) or (binding == "boe" and cfg.showBoE == false) then
            return false
        end
    end

    if cfg.minItemLevel > 0 and ilvl and (classID == WEAPON or classID == ARMOR) then
        if ilvl < cfg.minItemLevel then
            return false
        end
    end
    return true
end
ns.ShouldShow = ShouldShow

---------------------------------------------------------------------------
-- Formatting
---------------------------------------------------------------------------

local BLANK = "Interface\\AddOns\\FrogskisChatLoot\\blank"
local MARK_OFF = "|cff0d0d0d>>|r " -- history window: invisible "match" marker slot
ns.MARK_OFF = MARK_OFF

local classOfName = {} -- player name -> class, learned from loot lines and from the group

-- A player is shown by the first name only: the game gives one word on retail and two on Forever ("Bolty Forever"),
-- and the first is what stays.
local function FirstName(name)
    local short = Ambiguate(name, "short")
    return short:match("^%S+") or short
end

local function ColorName(name, guid, isSelf, class, shown)
    local short = Ambiguate(name, "short")
    local text = shown or FirstName(name) -- `shown`: a cut name ("Cyber...") instead of the whole one
    if not db.classColor then
        return text
    end
    if not class then
        if guid and guid ~= "" and not issecretvalue(guid) then
            class = select(2, GetPlayerInfoByGUID(guid))
        elseif isSelf then
            class = select(2, UnitClass("player"))
        end
    end
    if class then
        classOfName[short] = class
    end
    local color = class and RAID_CLASS_COLORS[class]
    return color and ("|c%s%s|r"):format(color.colorStr, text) or text
end

-- Invisible spacer w pixels wide, used for the left margin.
local function Spacer(w)
    w = math.floor(w + 0.5)
    if w <= 0 then
        return ""
    end
    return ("|T%s:1:%d|t"):format(BLANK, w)
end

-- The instance the player is in (its name and kind: party, raid ...), nothing outside.
local function CurrentInstance()
    local inside, kind = IsInInstance()
    if inside then
        return (GetInstanceInfo()), kind
    end
end

-- True (and who adds them) when something else already stamps the chat lines.
local TIMESTAMP_ADDONS = {"Prat-3.0", "Chatter", "ElvUI", "WIM", "Glass"}
function ns.ExternalTimestamps()
    for _, name in ipairs(TIMESTAMP_ADDONS) do
        if C_AddOns.IsAddOnLoaded(name) then
            return true, (name:gsub("%-.*", ""))
        end
    end
    local cvar = C_CVar and C_CVar.GetCVar("showTimestamps")
    if cvar and cvar ~= "none" then
        return true, "Blizzard"
    end
    return false
end

-- "2026-10-06, 14:32", "14:32" or "2026-10-06" depending on the cfg's date/timestamp options.
local function TimeLabel(e, cfg)
    -- The Loot window already gets a timestamp from Blizzard or a chat addon: add none.
    if cfg == db and ns.ExternalTimestamps() then
        return
    end
    local when = e.time or time()
    if cfg.dates and cfg.timestamp then
        return date("%Y-%m-%d, %H:%M", when)
    end
    if cfg.dates then
        return date("%Y-%m-%d", when)
    end
    if cfg.timestamp then
        return date("%H:%M", when)
    end
end

-- Column alignment: the part in front of the item (our timestamp + name) is measured in
-- pixels with the window's own font, and a spacer pads it to the widest one, so every
-- item starts at the same x. The padding goes in front of the name (names are
-- right-aligned against the item). Every loot window measures with its own font.
local function TextWidth(W, text)
    local host = W.frame
    local font, size, flags = host:GetFont()
    if not W.measurer then
        W.measurer = host:CreateFontString(nil, "BACKGROUND")
        W.measurer:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
        W.measurer:SetAlpha(0)
    end
    local key = tostring(font) .. (size or 0) .. (flags or "")
    if key ~= W.cacheKey then
        W.cacheKey = key
        wipe(W.widthCache)
        W.measurer:SetFont(font, size, flags)
    end
    local w = W.widthCache[text]
    if not w then
        -- An inline picture (|A:atlas:height:width|a, like the crafting quality) is measured as a blank texture of
        -- its own width, and a named colour (|cnIQ4:) takes no room: the width of a line never depends on how the
        -- game counts those.
        local measured = text:gsub("|A:[^:|]+:%d+:(%d+)[^|]*|a", function(pictureWidth)
            return ("|T%s:1:%d|t"):format(BLANK, tonumber(pictureWidth))
        end)
        measured = measured:gsub("|cn[^:|]*:", "")
        W.measurer:SetText(measured)
        w = W.measurer:GetStringWidth()
        if w > 0 then
            W.widthCache[text] = w
        end -- never remember a failed measurement
    end
    return w
end

-- Text width units per spacer pixel (nil if it cannot be measured). An inline texture is
-- sized in pixels, a string in font units; the two differ with the UI scale, so a spacer
-- is measured, not assumed.
local function TextUnitsPerPixel(W)
    local w = TextWidth(W, ("|T%s:1:400|t"):format(BLANK))
    return (w and w > 1) and (w / 400) or nil
end

-- The name of a player as it is drawn in window W. With "Shorten long player names" a name wider than
-- the room it may have (db.nameMaxWidth) is cut and ends with "...": "Cyberchungus" becomes "Cyber...".
local function DisplayName(W, name)
    local short = FirstName(name)
    if not (W and db.shortenNames) then
        return short
    end
    local max = tonumber(db.nameMaxWidth) or 62
    local width = TextWidth(W, short)
    if not width or width <= max then
        return short
    end
    local chars = {}
    for ch in short:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        chars[#chars + 1] = ch
    end
    if #chars < 2 then
        return short
    end
    local lo, hi, best = 1, #chars - 1, 1
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        if TextWidth(W, table.concat(chars, "", 1, mid) .. "...") <= max then
            best = mid
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    if db.nameEllipsis == false then
        -- no dots: the three letters the dots would have taken stand there instead
        local n = best + 3
        if n >= #chars then
            return short
        end
        return table.concat(chars, "", 1, n)
    end
    return table.concat(chars, "", 1, best) .. "..."
end

-- The width of everything in front of the item's "[" (our timestamp, the name, the separator and the
-- spaces), measured as one string: its letters, spaces and arrow are laid out together, so the
-- little differences between names (letter pairs, rounding) are in the measurement. The "[" at the
-- end keeps the trailing space from being dropped; it is the same for every line.
local function LeftWidth(W, stamp, short)
    local sep = db.separator or ""
    return TextWidth(W, (stamp and (stamp .. " ") or "") .. short .. (sep ~= "" and (" " .. sep) or "") .. " [")
end

-- Sets the column of `cfg` in window W to the widest of `entries` (never narrower than a
-- 10 letter name). The column is what the names alone need, so it sits in the same place with
-- the timestamp on or off: the timestamp takes the room in front of the shorter names. It only
-- moves right when a name that is drawn is too long to fit its timestamp in front of it.
function ns.PrepareColumn(W, cfg, entries)
    local widest = LeftWidth(W, nil, "Abcdefghij")
    local shorten = cfg == db and db.shortenNames
    if shorten then
        -- names are cut to a set width: the column is exactly that wide, whatever the names are
        widest = (tonumber(db.nameMaxWidth) or 62) + LeftWidth(W, nil, "")
    end
    local withStamp = 0
    for _, e in ipairs(entries) do
        if e.name then
            local short = shorten and DisplayName(W, e.name) or FirstName(e.name)
            local bare = LeftWidth(W, nil, short)
            if bare > widest then
                widest = bare
            end
            local stamp = TimeLabel(e, cfg)
            if stamp then
                -- lines the filters hide are not drawn, so they do not push the column
                local w = LeftWidth(W, stamp, short)
                if w > withStamp and ShouldShow(e, cfg) then
                    withStamp = w
                end
            end
        end
    end
    W.columns[cfg] = math.max(widest, withStamp)
end

-- A long item name wraps in the window. The game wraps it flush left; here the line is broken
-- by this addon instead, and the continuation is indented to the item column, so the whole
-- name stays in the column. Every line is a link of its own (hover works on each line).
-- `extra` is the width of what other addons put in front (a timestamp). Returns nil when the
-- name fits (the game leaves it alone) or cannot be wrapped this way.
local function WrapItem(W, head, link, tail, extra)
    local unit = TextUnitsPerPixel(W)
    local frameWidth = W.frame:GetWidth()
    if not unit or not frameWidth or frameWidth <= 0 then
        return nil
    end
    local headWidth = TextWidth(W, head) + extra
    local avail = frameWidth - 22 - headWidth
    if avail < 60 then
        return nil
    end
    local color, body = link:match("^(|c%x%x%x%x%x%x%x%x)(.*)|r$")
    local opening, name = (body or ""):match("^(|H.-|h)%[(.-)%]|h$")
    if not name then
        return nil
    end
    local words = {}
    for word in name:gmatch("%S+") do
        words[#words + 1] = word
    end
    if #words < 2 then
        return nil
    end
    local plainTail = (tail:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
    local function LineWidth(first, list, last)
        return TextWidth(W, (first and "[" or "") .. table.concat(list, " ") .. (last and ("]" .. plainTail) or ""))
    end
    if LineWidth(true, words, true) <= avail then
        return nil
    end
    local lines, cur = {}, {}
    for i, word in ipairs(words) do
        cur[#cur + 1] = word
        if #cur > 1 and LineWidth(#lines == 0, cur, i == #words) > avail then
            cur[#cur] = nil
            lines[#lines + 1] = cur
            cur = {word}
        end
    end
    lines[#lines + 1] = cur
    if #lines < 2 then
        return nil
    end
    local indent = Spacer(headWidth / unit)
    local out = {}
    for k, list in ipairs(lines) do
        local isLast = k == #lines
        local piece = color .. opening .. (k == 1 and "[" or "") .. table.concat(list, " ") .. (isLast and "]" or "") ..
                          "|h|r"
        if k == 1 then
            out[#out + 1] = head .. piece
        else
            out[#out + 1] = "\n" .. indent .. piece
        end
        if isLast then
            out[#out + 1] = tail
        end
    end
    return table.concat(out)
end

-- The little crafting-quality picture inside an item's name is 17 pixels high, taller than the chat's letters, so
-- a line with it gets a taller row than the others. It is drawn at the height of the window's own letters
-- instead, so every line takes the same room.
local function FitIcons(W, text)
    if not W or type(text) ~= "string" or not text:find("|A:", 1, true) then
        return text
    end
    local _, size = W.frame:GetFont()
    size = tonumber(size)
    if not size or size <= 0 then
        return text
    end
    local height = math.max(8, math.floor(size * 0.85 + 0.5))
    return (text:gsub("|A:([^:|]+):(%d+):(%d+)([^|]*)|a", function(atlas, h, w, rest)
        local fitted = math.max(6, math.floor(height * tonumber(w) / math.max(1, tonumber(h)) + 0.5))
        return ("|A:%s:%d:%d%s|a"):format(atlas, height, fitted, rest)
    end))
end

-- Does a whole line fit on one row of the window? Nothing is added up from parts that were measured one by
-- one: the line is set in a hidden text made like the window's own lines (the same font object, as wide as
-- the window, minus what has proved to be needed) and the game's own text layout says whether it had to wrap
-- (a wrapped text is taller than the same text in one row). nil when that cannot be told.
local function TextFitsRow(W, text)
    local frame = W.frame
    local width = frame:GetWidth()
    if not width or width <= 60 then
        return nil
    end
    local probe = W.rowProbe
    if not probe then
        -- Far outside the screen and not a part of the chat window: whatever another addon does to the
        -- window's parts (its opacity, while the mouse is over it) can never make this text show.
        probe = UIParent:CreateFontString(nil, "BACKGROUND")
        probe:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -20000, 0)
        probe:SetAlpha(0)
        probe:SetJustifyH("LEFT")
        if probe.SetNonSpaceWrap then
            probe:SetNonSpaceWrap(true)
        end -- the window's lines are set like this
        W.rowProbe = probe
    end
    local fontObject = frame.GetFontObject and frame:GetFontObject() or nil
    local font, size, flags = frame:GetFont()
    local key = tostring(fontObject) .. tostring(font) .. tostring(size) .. tostring(flags)
    if key ~= W.rowProbeKey then
        if fontObject then
            probe:SetFontObject(fontObject)
        elseif font then
            probe:SetFont(font, size, flags)
        else
            return nil
        end
        W.rowProbeKey = key
    end
    probe:SetWidth(0) -- no limit: the height of the text in one row (a tall picture makes a row taller)
    probe:SetText(text)
    local natural = probe:GetStringHeight()
    if not (natural and natural > 0) then
        return nil
    end
    probe:SetWidth(math.max(40, width - 2 - (W.fitSlack or 0)))
    local height = probe:GetStringHeight()
    if not height then
        return nil
    end
    return height < natural * 1.5
end

-- Does the line (what stands in front of it, this addon's head and the rest) fit on one row?
local function RowFits(W, head, rest, extra)
    -- what stands in front: the real text another addon put there, else its width as a blank
    local prefix = W.prefixText
    if not prefix then
        local unit = TextUnitsPerPixel(W)
        local room = extra or W.prefixWidth or 0
        prefix = (unit and room > 0) and Spacer(room / unit) or ""
    end
    return TextFitsRow(W, prefix .. head .. rest)
end

-- "Cut long item names": the item's name in `rest` (the item link and whatever follows it) is cut and ends with
-- "...]", so the line stays on one line. The room is the window's own width, measured when the line is laid out
-- (and again when the window is resized), never a fixed number. `rest` comes back unchanged when it fits or
-- cannot be measured.
local function ShortenItem(W, head, rest, extra)
    local frameWidth = W.frame:GetWidth()
    if not frameWidth or frameWidth <= 0 then
        return rest
    end
    local avail = frameWidth - 8 - TextWidth(W, head) - (extra or 0) - 14
    if avail < 60 then
        return rest
    end
    local s, e, open, inner = rest:find("(|Hitem:[^|]-|h)(.-)|h")
    if not s then
        return rest
    end
    local label = inner:match("^%[(.*)%]$")
    if not label then
        return rest
    end
    local before, after = rest:sub(1, s - 1), rest:sub(e + 1)
    local function Build(l)
        return before .. open .. "[" .. l .. "]|h" .. after
    end
    -- fits: by the game's own layout of the whole line, else by the measured widths
    local function Fits(candidate)
        local fit = RowFits(W, head, candidate, extra)
        if fit ~= nil then
            return fit
        end
        return TextWidth(W, candidate) <= avail
    end
    if Fits(Build(label)) then
        return rest
    end
    -- the pictures at the end of the name (crafting quality...) stay, right behind the dots; only the letters are cut
    local name, picture = label, ""
    while true do
        local before2, chunk = name:match("^(.-)%s*(|A:[^|]*|a)$")
        if not before2 then
            before2, chunk = name:match("^(.-)%s*(|T[^|]*|t)$")
        end
        if not before2 then
            break
        end
        name, picture = before2, chunk .. picture
    end
    local chars = {}
    for ch in name:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        chars[#chars + 1] = ch
    end
    if #chars < 2 then
        return rest
    end
    local function Cut(n)
        return (table.concat(chars, "", 1, n):gsub("%s+$", "")) .. "..." .. picture
    end
    local lo, hi, best = 1, #chars - 1, 1
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        if Fits(Build(Cut(mid))) then
            best = mid
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return Build(Cut(best))
end

-- The last step for every line of this addon's, whatever it says ("Name -> [Item]", "(roll: 28)", "Passed on:",
-- "Need roll 7:"...): `text` is the whole line as it will stand in the window, what another addon put in front of it
-- included. If it does not fit on one row, the name of the item in it (the last item link) is cut, ending in
-- "...]", until it does. Comes back unchanged when it fits, when it has several rows on purpose, when it has no item
-- link or when it cannot be measured.
local function FitWhole(W, text)
    if not (db.shortenItems and W) or type(text) ~= "string" or issecretvalue(text) then
        return text
    end
    if text:find("\n", 1, true) or not text:find("|Hitem:", 1, true) then
        return text
    end
    if TextFitsRow(W, text) ~= false then
        return text
    end
    local s, e, open, inner
    local from = 1
    while true do
        local s2, e2, open2, inner2 = text:find("(|Hitem:[^|]-|h)(.-)|h", from)
        if not s2 then
            break
        end
        s, e, open, inner = s2, e2, open2, inner2
        from = e2 + 1
    end
    local label = inner and inner:match("^%[(.*)%]$")
    if not label then
        return text
    end
    local before, after = text:sub(1, s - 1), text:sub(e + 1)
    local function Build(l)
        return before .. open .. "[" .. l .. "]|h" .. after
    end
    -- the pictures at the end of the name (crafting quality...) stay behind the dots; only the letters are cut
    local name, picture = label, ""
    while true do
        local before2, chunk = name:match("^(.-)%s*(|A:[^|]*|a)$")
        if not before2 then
            before2, chunk = name:match("^(.-)%s*(|T[^|]*|t)$")
        end
        if not before2 then
            break
        end
        name, picture = before2, chunk .. picture
    end
    name = (name:gsub("%.%.%.$", "")) -- a name cut before by the first estimate: its dots are taken off first
    local chars = {}
    for ch in name:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        chars[#chars + 1] = ch
    end
    if #chars < 2 then
        return text
    end
    local function Cut(n)
        return (table.concat(chars, "", 1, n):gsub("%s+$", "")) .. "..." .. picture
    end
    local lo, hi, best = 1, #chars - 1, 1
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        if TextFitsRow(W, Build(Cut(mid))) then
            best = mid
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return Build(Cut(best))
end

-- The same for a line that is about to be handed to the window, before anything stands in front of it: what
-- stands there is taken to be what stood in front of the last line (another addon's timestamp); the line is
-- checked again with the real text once the window has it (see Record).
local function LiveFit(W, text)
    local guess = W.prefixText or ""
    local ok, fitted = pcall(FitWhole, W, guess .. text)
    if ok and type(fitted) == "string" and fitted ~= guess .. text and fitted:sub(1, #guess) == guess then
        return fitted:sub(#guess + 1)
    end
    return text
end

local function FormatEntry(e, cfg, W, extra)
    local parts = {Spacer(db.leftMargin)}
    local stamp = TimeLabel(e, cfg)
    if stamp then
        parts[#parts + 1] = "|cff888888" .. stamp .. "|r "
    end
    local shown = (cfg == db) and DisplayName(W, e.name) or FirstName(e.name)
    if db.alignColumn and W then
        local unit = TextUnitsPerPixel(W)
        local w = LeftWidth(W, stamp, shown)
        if unit and w > 0 then
            if w > (W.columns[cfg] or 0) then
                W.columns[cfg] = w
            end -- a longer name than any seen so far
            parts[#parts + 1] = Spacer((W.columns[cfg] - w) / unit)
        end
    end
    parts[#parts + 1] = ColorName(e.name, e.guid, e.isSelf, e.class, shown)
    if db.separator ~= "" then
        parts[#parts + 1] = " |cffaaaaaa" .. db.separator:gsub("|", "||") .. "|r"
    end
    parts[#parts + 1] = " "
    -- the one who won a roll says so, in grey like the roll: "Orthessa > (won) [Item]"
    if cfg == db and e.won and db.showRolls then
        parts[#parts + 1] = "|cff888888(won)|r "
    end
    local headCount = #parts
    parts[#parts + 1] = FitIcons(W, ColorizeLink(e.link, e))
    if db.showItemLevel then
        local ilvl = select(4, C_Item.GetItemInfo(e.link))
        if ilvl and ilvl > 1 then
            parts[#parts + 1] = " |cff888888(" .. ilvl .. ")|r"
        end
    end
    if db.showQuantity and e.count and e.count > 1 then
        parts[#parts + 1] = " x" .. e.count
    end
    local shortened = false
    if cfg == db and db.shortenItems and W then
        local rest = table.concat(parts, "", headCount + 1)
        local short = ShortenItem(W, table.concat(parts, "", 1, headCount), rest, extra or W.prefixWidth or 0)
        if short ~= rest then
            for i = #parts, headCount + 2, -1 do
                parts[i] = nil
            end
            parts[headCount + 1] = short
            shortened = true
        end
    end
    if cfg == db and db.alignColumn and W and not shortened and not db.shortenItems then
        local wrapped = WrapItem(W, table.concat(parts, "", 1, headCount), parts[headCount + 1],
            table.concat(parts, "", headCount + 2), extra or W.prefixWidth or 0)
        if wrapped then
            return wrapped
        end
    end
    return table.concat(parts)
end
ns.FormatEntry = FormatEntry

-- The "->" column as something to take hold of: a thin strip over the whole height of the chat window,
-- lit up under the mouse, that can be dragged left or right to make the names shorter or longer (only
-- with "Shorten long player names"). The lines are drawn again when it is let go.
local NAME_MIN, NAME_MAX = 30, 400
local function MakeArrowHandle(W)
    local handle = CreateFrame("Frame", nil, W.frame)
    handle:SetFrameLevel(W.frame:GetFrameLevel() + 8)
    handle:EnableMouse(true)
    handle.glow = handle:CreateTexture(nil, "OVERLAY")
    handle.glow:SetAllPoints()
    handle.glow:SetColorTexture(1, 0.85, 0.25, 0.6)
    handle.glow:Hide()
    handle:SetScript("OnEnter", function(self)
        self.glow:Show()
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetText("Drag left or right")
        GameTooltip:Show()
    end)
    handle:SetScript("OnLeave", function(self)
        if not self.dragging then
            self.glow:Hide()
        end
        GameTooltip:Hide()
    end)
    handle:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then
            return
        end
        self.dragging = true
        local scale = W.frame:GetEffectiveScale()
        local startCursor = GetCursorPosition() / scale
        local startMax = tonumber(db.nameMaxWidth) or 62
        local startLeft = self:GetLeft() - W.frame:GetLeft()
        self.pendingMax = startMax
        self:SetScript("OnUpdate", function(strip)
            local newMax =
                math.max(NAME_MIN, math.min(NAME_MAX, startMax + (GetCursorPosition() / scale - startCursor)))
            strip.pendingMax = newMax
            -- the strip follows the mouse; the lines are drawn when it is let go
            strip:ClearAllPoints()
            strip:SetPoint("TOPLEFT", W.frame, "TOPLEFT", startLeft + (newMax - startMax), 0)
            strip:SetPoint("BOTTOMLEFT", W.frame, "BOTTOMLEFT", startLeft + (newMax - startMax), 0)
        end)
    end)
    handle:SetScript("OnMouseUp", function(self)
        if not self.dragging then
            return
        end
        self.dragging = false
        self:SetScript("OnUpdate", nil)
        db.nameMaxWidth = math.floor((self.pendingMax or db.nameMaxWidth) + 0.5)
        if not self:IsMouseOver() then
            self.glow:Hide()
        end
        ns.Refresh()
        if ns.RefreshOptions then
            ns.RefreshOptions()
        end
    end)
    return handle
end

-- Where the arrows really are: measured in a line the window shows, so whatever another addon put in
-- front of the line (a timestamp) is in the measurement. Returns the x of the end of an arrow, or nil.
local function MeasureArrow(W, sep)
    local frame = W.frame
    local marker = " |cffaaaaaa" .. sep:gsub("|", "||") .. "|r"
    local count = frame:GetNumMessages()
    for i = count, math.max(1, count - 40), -1 do
        local text = frame:GetMessageInfo(i)
        if type(text) == "string" and not issecretvalue(text) then
            local at = text:find(marker, 1, true)
            if at then
                local upToArrow = text:sub(1, at + #marker - 1)
                -- a line with something above it ("<boss> drops:") has its timestamp on the first row only
                if not upToArrow:find("\n", 1, true) then
                    return TextWidth(W, upToArrow)
                end
            end
        end
    end
end

-- Puts the strip over the arrows (after every drawing of the window), or hides it.
function ns.UpdateArrowHandle(W)
    local handle = W.arrowHandle
    local sep = db.separator or ""
    local column = W.columns and W.columns[db]
    local unit = column and TextUnitsPerPixel(W)
    if not (W.active and db.shortenNames and db.alignColumn and sep ~= "" and column and unit) then
        if handle then
            handle:Hide()
        end
        return
    end
    if not handle then
        handle = MakeArrowHandle(W)
        W.arrowHandle = handle
    end
    if handle.dragging then
        return
    end
    local arrowEnd = MeasureArrow(W, sep)
    if not arrowEnd then
        -- no line to measure yet: worked out from the column
        local itemX = (W.prefixWidth or 0) + (db.leftMargin or 0) * unit + column - TextWidth(W, "[")
        arrowEnd = itemX - TextWidth(W, " ")
    end
    local center = arrowEnd - TextWidth(W, sep) / 2
    local width = 10
    handle:ClearAllPoints()
    handle:SetPoint("TOPLEFT", W.frame, "TOPLEFT", center - width / 2, 0)
    handle:SetPoint("BOTTOMLEFT", W.frame, "BOTTOMLEFT", center - width / 2, 0)
    handle:SetWidth(width)
    handle:Show()
end

-- The date line between two loot lines of different days: "Monday 10-Oct-2026" in grey.
local function DayKey(t)
    return date("%Y%m%d", t)
end

-- Little pictures that can stand next to the date and next to the name of an instance. They are
-- picked in the options window; the keys are what the settings hold.
local DATE_ICONS = {{"none", "None"}, {"calendar", "Calendar (with the day)"}, {"clock", "Pocket watch"},
                    {"note", "Note"}, {"scroll", "Scroll"}}
local PLACE_ICONS = {{"none", "None"}, {"map", "Dungeon / raid symbol"}, {"skull", "Skull"}, {"marker", "Skull marker"},
                     {"star", "Star marker"}, {"swords", "Sword"}, {"key", "Key"}}
-- The pictures of a boss's "<boss> drops:" line (an elite's and a rare's): the skulls and the two dragons of the name
-- plates. Any other picture is added by the name of a texture atlas (ns.AddCustomIcon).
local RANK_ICONS = {{"none", "None"}, {"skull", "Skull"}, {"marker", "Skull marker"},
                    {"nameplates-icon-elite-gold", "Elite (gold dragon)"},
                    {"nameplates-icon-elite-silver", "Rare (silver dragon)"}}
-- Pictures for a town (a city, an inn) and the player housing neighbourhood: the game's own map icons.
local TOWN_ICONS = {{"none", "None"}, {"house", "Player house"}, {"homestone", "Homestone"}, {"city", "City"},
                    {"inn", "Innkeeper"}, {"hearthstone", "Hearthstone"}, {"deed", "Housing deed"}}
-- Pictures for a place in the open world.
local WORLD_ICONS = {{"none", "None"}, {"worldmap", "Map"}, {"spyglass", "Spyglass"}}
local TOWN_ATLAS = {
    house = "housing-map-plot-player-house",
    homestone = "homestone-minimap-icon",
    city = "poi-majorcity",
    inn = "innkeeper",
    deed = "housing-map-deed"
}
ns.DATE_ICONS, ns.PLACE_ICONS, ns.TOWN_ICONS, ns.WORLD_ICONS = DATE_ICONS, PLACE_ICONS, TOWN_ICONS, WORLD_ICONS
ns.RANK_ICONS = RANK_ICONS

local function HasAtlas(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) and true or false
end

-- The chat markup of an icon: day is the day of the month (for the calendar), instanceType tells a
-- raid from a dungeon (for the map symbol). A symbol this game version lacks becomes a skull.
-- scale (0.5 - 1.5, default 1) makes the picture smaller or bigger than its normal size.
local function IconMarkup(kind, day, instanceType, scale)
    local function S(size)
        return math.max(1, math.floor(size * (tonumber(scale) or 1) + 0.5))
    end
    local function File(id)
        return ("|T%s:%d|t"):format(id, S(14))
    end
    local function Atlas(name, h, w)
        return ("|A:%s:%d:%d|a"):format(name, S(h), S(w or h))
    end
    if kind == "calendar" then
        local atlas = "ui-hud-calendar-" .. (day or 1) .. "-up"
        if HasAtlas(atlas) then
            return Atlas(atlas, 13, 15)
        end
        return File(134327)
    elseif kind == "clock" then
        return File(134376)
    elseif kind == "note" then
        return File(134327)
    elseif kind == "scroll" then
        return File(134939)
    elseif kind == "map" then
        local atlas = instanceType == "raid" and "raid" or "dungeon"
        if HasAtlas(atlas) then
            return Atlas(atlas, 16)
        end
        return File(133730)
    elseif kind == "skull" then
        return File(133730)
    elseif kind == "marker" then
        return File("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
    elseif kind == "star" then
        return File("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
    elseif kind == "swords" then
        return File(135274)
    elseif kind == "key" then
        return File(134237)
    elseif kind == "hearthstone" then
        return File(134414)
    elseif kind == "worldmap" then
        return File(134269)
    elseif kind == "spyglass" then
        return File(134441)
    elseif TOWN_ATLAS[kind] then
        -- a map icon this game version lacks becomes the hearthstone
        if HasAtlas(TOWN_ATLAS[kind]) then
            return Atlas(TOWN_ATLAS[kind], 16)
        end
        return File(134414)
    elseif type(kind) == "string" and kind ~= "none" and HasAtlas(kind) then
        -- a texture atlas added by its name in the options window, in its own proportions
        local info = C_Texture.GetAtlasInfo(kind)
        local ratio = info and info.width and info.height and info.height > 0 and info.width / info.height or 1
        return Atlas(kind, 16, math.max(4, math.min(48, math.floor(16 * ratio + 0.5))))
    end
end
ns.IconMarkup = IconMarkup

-- Texture atlases added by name in the options window: a list for each kind of line ("date", "place", "town",
-- "world", "eliteboss", "rareboss"), the same for every profile. The picture a profile already uses is in its list too.
do
    local BUILTIN_KIND = {}
    for _, list in ipairs({DATE_ICONS, PLACE_ICONS, TOWN_ICONS, WORLD_ICONS}) do
        for _, item in ipairs(list) do
            BUILTIN_KIND[item[1]] = true
        end
    end
    for kind in pairs(TOWN_ATLAS) do
        BUILTIN_KIND[kind] = true
    end

    local LISTS = {
        date = DATE_ICONS,
        place = PLACE_ICONS,
        town = TOWN_ICONS,
        world = WORLD_ICONS,
        eliteboss = RANK_ICONS,
        rareboss = RANK_ICONS
    }
    local function Listed(group, kind)
        for _, item in ipairs(LISTS[group] or {}) do
            if item[1] == kind then
                return true
            end
        end
    end

    local function FindName(list, name)
        for i, existing in ipairs(list) do
            if existing:lower() == name:lower() then
                return i
            end
        end
    end

    function ns.CustomIcons(group, using)
        if type(db.customIcons) ~= "table" then
            return {}
        end
        local list = db.customIcons[group]
        if type(list) ~= "table" then
            list = {}
            db.customIcons[group] = list
        end
        if type(using) == "string" and not BUILTIN_KIND[using] and not Listed(group, using) and
            not FindName(list, using) and HasAtlas(using) then
            list[#list + 1] = using
        end
        return list
    end

    -- Adds the texture atlas of that name to the list of a kind of line and uses it; says so when there is no such atlas.
    function ns.AddCustomIcon(group, field, name)
        name = strtrim(name or "")
        if name == "" then
            return false
        end
        local function Complain(text)
            Print(text)
            if UIErrorsFrame then
                UIErrorsFrame:AddMessage(text, 1, 0.1, 0.1)
            end
            return false
        end
        if BUILTIN_KIND[name] or Listed(group, name) then
            return Complain(('"%s" is one of the pictures of the list already.'):format(name))
        end
        if not HasAtlas(name) then
            return Complain(('There is no texture atlas called "%s" in this game version.'):format(name))
        end
        local list = ns.CustomIcons(group)
        local at = FindName(list, name)
        if at then
            name = list[at]
        else
            list[#list + 1] = name
        end
        db[field] = name
        ns.Refresh()
        if ns.RefreshOptions then
            ns.RefreshOptions()
        end
        return true
    end

    -- Takes a texture atlas out of the list of a kind of line; a profile that was using it goes back to no picture.
    function ns.RemoveCustomIcon(group, field, name)
        local list = ns.CustomIcons(group)
        local at = FindName(list, name)
        if at then
            table.remove(list, at)
        end
        if type(db[field]) == "string" and db[field]:lower() == name:lower() then
            db[field] = "none"
        end
        ns.Refresh()
        if ns.RefreshOptions then
            ns.RefreshOptions()
        end
    end
end

-- The text color of a line: the hex the options window saved, the old grey when it is missing or not a color.
local function LineColor(hex)
    return type(hex) == "string" and hex:match("^%x%x%x%x%x%x$") and hex or "888888"
end

-- One grey line: the indent, the text, and the picture on the chosen side.
local function GreyLine(text, icon, side, gap, color)
    gap = gap or " "
    local inner = "|cff" .. LineColor(color) .. text .. "|r"
    if icon then
        inner = (side == "right") and (inner .. gap .. icon) or (icon .. gap .. inner)
    end
    return Spacer(db.leftMargin) .. (" "):rep(db.separatorIndent or 4) .. inner
end

-- The date line. The indent and the icons are the chat's settings, for every window.
local function SeparatorText(t)
    return GreyLine(date("%A %d-%b-%Y", t), IconMarkup(db.dateIcon, tonumber(date("%d", t)), nil, db.dateIconScale),
        db.dateIconSide, db.dateIcon == "calendar" and "" or " ", db.dateColor)
end

ns.DayKey, ns.SeparatorText = DayKey, SeparatorText

-- The place line; instanceType is given for an instance (it gets the icon), not for a zone.
local function InstanceText(name, instanceType)
    return GreyLine(name, instanceType and IconMarkup(db.placeIcon, nil, instanceType, db.placeIconScale) or nil,
        db.placeIconSide, nil, db.placeColor)
end

-- The place line of a town or of the player housing neighbourhood: its own picture.
local function TownText(name)
    return GreyLine(name, IconMarkup(db.townIcon, nil, nil, db.townIconScale), db.townIconSide, nil, db.townColor)
end

-- The place line of a place in the open world: its own picture (none unless one is chosen).
local function WorldText(name)
    return GreyLine(name, IconMarkup(db.worldIcon, nil, nil, db.worldIconScale), db.worldIconSide, nil, db.worldColor)
end

-- What kind of place the player is in right now, outside an instance: "home" (the player housing
-- neighbourhood, a plot or a house), "town" (a city or an inn: where the player is resting), or nil.
local function PlaceKind()
    local housing = C_Housing
    if housing and ((housing.IsOnNeighborhoodMap and housing.IsOnNeighborhoodMap()) or
        (housing.IsInsideHouseOrPlot and housing.IsInsideHouseOrPlot())) then
        return "home"
    end
    if IsInInstance() then
        return nil
    end
    if IsResting() then
        return "town"
    end
    if C_PvP and C_PvP.GetZonePVPInfo and C_PvP.GetZonePVPInfo() == "sanctuary" then
        return "town"
    end
end

-- Never an error: a game version without the housing calls simply has no homes. `false` is an answer ("not a
-- town", kept with the loot entry); nil only means it could not be told.
local unlearnQueued
local function SafePlaceKind()
    local ok, kind = pcall(PlaceKind)
    if not ok then
        return nil
    end
    if kind then
        return kind
    end
    -- out in the open in a zone once learned as a town (the rest state lingered at its edge, or an inn in it was
    -- visited): a zone that is not a rest area everywhere is no town, so it is forgotten
    local known, zone = db.townZones, GetZoneText()
    if known and zone ~= "" and known[zone] == "town" and not IsInInstance() and not unlearnQueued then
        known[zone] = nil
        unlearnQueued = true
        C_Timer.After(0.5, function()
            unlearnQueued = false
            ns.Refresh()
        end)
    end
    return false
end

-- The kind of the place a loot entry came from. Entries recorded from now on carry it; for older
-- ones the zone name decides, if it has been seen as a town since.
local function PlaceOfEntry(e)
    if e.place ~= nil then
        return e.place or nil
    end
    if e.zone and not e.instance then
        local known = db.townZones
        return known and known[e.zone] or nil
    end
end
ns.PlaceOfEntry = PlaceOfEntry

-- The lines that go in front of a loot line: the date when the day changed, the instance name when
-- the loot is from another instance than the line before. `st` (day, inst) remembers the line before.
function ns.Separators(cfg, st, e)
    local out
    if cfg.dateSeparator and e.time then
        local day = DayKey(e.time)
        if st.day and st.day ~= day then
            out = {SeparatorText(e.time)}
        end
        st.day = day
    end
    local kind = PlaceOfEntry(e)
    -- a house is a place of its own, whatever the game calls the map it is on
    local inst = kind ~= "home" and e.instance or nil
    if cfg.zoneSeparator then
        -- every change of place: the instance (when its own option is on) or else the zone
        local isInstance = inst and cfg.instanceSeparator
        local loc = isInstance and inst or e.zone or inst or e.instance
        if loc and loc ~= st.loc then
            out = out or {}
            if isInstance then
                out[#out + 1] = InstanceText(loc, e.instanceType or "party")
            elseif kind then
                out[#out + 1] = TownText(loc)
            else
                out[#out + 1] = WorldText(loc)
            end
        end
        st.loc = loc
    else
        if cfg.instanceSeparator and inst and inst ~= st.inst then
            out = out or {}
            out[#out + 1] = InstanceText(inst, e.instanceType or "party")
        end
    end
    st.inst = inst
    return out
end

-- Called for a loot line that is about to be shown: if the loot line before it in this window
-- was on another day, the date line goes in first. It is added with the widget's own AddMessage,
-- which no addon hooks (nothing stamps it or records it; a redraw works the lines out again).
local function DateSeparatorBefore(W, entry)
    W.sep = W.sep or {}
    local lines = ns.Separators(db, W.sep, entry)
    if lines then
        local base = ScrollingMessageFrameSecureMixin or ScrollingMessageFrameMixin
        local rawAdd = (base and base.AddMessage) or W.frame.AddMessage
        local info = ChatTypeInfo.LOOT
        for _, text in ipairs(lines) do
            rawAdd(W.frame, text, info.r, info.g, info.b, info.id)
        end
    end
end

-- A line put into the window straight away, with the widget's own AddMessage that no addon hooks: nothing
-- stamps it or records it (a redraw works it out again from the line that follows).
local function AddRawLine(W, text)
    local base = ScrollingMessageFrameSecureMixin or ScrollingMessageFrameMixin
    local rawAdd = (base and base.AddMessage) or W.frame.AddMessage
    local info = ChatTypeInfo.LOOT
    rawAdd(W.frame, text, info.r, info.g, info.b, info.id)
end

---------------------------------------------------------------------------
-- Reading a loot line
---------------------------------------------------------------------------

local LOOT_GLOBALS = {"LOOT_ITEM", "LOOT_ITEM_MULTIPLE", "LOOT_ITEM_SELF", "LOOT_ITEM_SELF_MULTIPLE",
                      "LOOT_ITEM_PUSHED", "LOOT_ITEM_PUSHED_MULTIPLE", "LOOT_ITEM_PUSHED_SELF",
                      "LOOT_ITEM_PUSHED_SELF_MULTIPLE", "LOOT_ITEM_BONUS_ROLL", "LOOT_ITEM_BONUS_ROLL_MULTIPLE",
                      "LOOT_ITEM_BONUS_ROLL_SELF", "LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE", "LOOT_ITEM_CREATED_SELF",
                      "LOOT_ITEM_CREATED_SELF_MULTIPLE", "CREATED_ITEM", "CREATED_ITEM_MULTIPLE", -- "Name creates: [Item]." (a cauldron, a healthstone)
                      "CURRENCY_GAINED", "CURRENCY_GAINED_MULTIPLE", "CURRENCY_GAINED_MULTIPLE_BONUS"}
local lootPatterns

-- Formats about the player ("You receive loot: %s.") never name anyone; the others
-- ("%s receives loot: %s.") start with the looter's name, which is captured.
local function BuildLootPatterns()
    lootPatterns = {}
    for _, g in ipairs(LOOT_GLOBALS) do
        local fmt = _G[g]
        if type(fmt) == "string" then
            local isSelf = g:find("_SELF", 1, true) or g:find("^CURRENCY") and true or false
            local p = fmt:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
            p = p:gsub("%%%%%d%$d", "%%d+"):gsub("%%%%d", "%%d+")
            p = p:gsub("%%%%%d%$s", "%%s"):gsub("%%%%s", "%%s") -- placeholder per string slot
            if isSelf then
                p = p:gsub("%%s", ".+")
            else
                p = p:gsub("%%s", "(.-)", 1):gsub("%%s", ".+")
            end
            -- "receive item:" lines are items handed over (trade, mail, quest reward, vendor), not loot drops
            lootPatterns[#lootPatterns + 1] = {
                p = p,
                self = isSelf and true or false,
                pushed = g:find("^LOOT_ITEM_PUSHED") and true or false,
                created = (g:find("^LOOT_ITEM_CREATED") or g:find("^CREATED_ITEM")) and true or false
            }
        end
    end
end

-- The line as plain words: color codes removed, item and player links replaced by
-- their visible text.
local function PlainLine(text)
    local s = text:gsub("|Hitem:.-|h%[.-%]|h", "<item>"):gsub("|Hcurrency:.-|h%[.-%]|h", "<item>")
    s = s:gsub("|Hplayer:[^|]-|h%[?([^|%]]-)%]?|h", "%1")
    return (s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

-- Is this a loot line, and who looted? Decided from the wording itself, never from
-- "no player link means me": returns isLoot, isSelf, name, isHandedOver, isCrafted.
local function ParseLootLine(text)
    if not lootPatterns then
        BuildLootPatterns()
    end
    local plain = PlainLine(text)
    for _, pat in ipairs(lootPatterns) do
        if pat.self and plain:find(pat.p) then
            return true, true, nil, pat.pushed, pat.created
        end
    end
    for _, pat in ipairs(lootPatterns) do
        if not pat.self then
            local cap = plain:match(pat.p)
            if cap then
                -- the name in the player link is the whole name (two words on Forever: "Bolty Forever"); without a
                -- link it is the last word in front of the verb
                local linked = text:match("|Hplayer:([^:|]+)")
                return true, false, linked or cap:match("(%S+)%s*$"), pat.pushed, pat.created, strtrim(cap)
            end
        end
    end
    return false
end

local function FindLink(text, isCurrency)
    if isCurrency then
        return text:match("(|c%x+|Hcurrency:.-|h%[.-%]|h|r)") or text:match("(|Hcurrency:.-|h%[.-%]|h)")
    end
    return text:match("(|c%x+|Hitem:.-|h%[.-%]|h|r)") or text:match("(|Hitem:.-|h%[.-%]|h)")
end

-- Roll lines ("You have selected Need for: [Item]", "Need Roll - 70 for [Item] by Name",
-- "Name passed on: [Item]", "You won: [Item]"...): every LOOT_ROLL_* sentence of the game
-- that has a place for the item. Built from the client's own wording, whatever the language.
local rollPatterns
local function BuildRollPatterns()
    rollPatterns = {}
    for name, fmt in pairs(_G) do
        if type(name) == "string" and name:find("^LOOT_ROLL_") and type(fmt) == "string" and fmt:find("%%%d?%$?s") then
            local plain = fmt:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            local p = plain:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
            p = p:gsub("%%%%%d%$d", "%%d+"):gsub("%%%%d", "%%d+")
            p = p:gsub("%%%%%d%$s", ".+"):gsub("%%%%s", ".+")
            rollPatterns[#rollPatterns + 1] = p
        end
    end
end

-- An empty colour span at the start of a roll line this addon has laid out ("Name > (need roll: 16) [Item]"):
-- it shows nothing, and tells such a line from a loot line when the window is read back.
local ROLL_MARK = "|cff010203|r"
-- Invisible marks (an empty coloured text) on the "<boss> drops:" line (05) and on an item it dropped (06); the
-- colour holds the number of the encounter, so the lines can be found again in the window, and told apart.
local function DropMark(kind, encounterID)
    return ("|cff%02x%04x|r"):format(kind, (tonumber(encounterID) or 0) % 65536)
end

local function IsRollLine(text)
    if type(text) ~= "string" or issecretvalue(text) or not text:find("|Hitem:", 1, true) then
        return false
    end
    -- the game's own roll lines start with a link to the loot rolls: "[Loot]: ..."
    if text:find("|HlootHistory:", 1, true) or text:find(ROLL_MARK, 1, true) then
        return true
    end
    if not rollPatterns then
        BuildRollPatterns()
    end
    local plain = PlainLine(text)
    for _, p in ipairs(rollPatterns) do
        if plain:find(p) then
            return true
        end
    end
    return false
end

-- What a boss drops for a roll: the line the game writes as "[Loot]: [Item]", an item and nothing else
-- (given as the game wrote it, with the loot rolls link in front).
local function IsDropText(text)
    if type(text) ~= "string" or issecretvalue(text) then
        return false
    end
    local body, found = text:gsub("^|HlootHistory:%-?%d+|h%[.-%]|h: ", "", 1)
    if found == 0 then
        return false
    end
    return (body:find("^|c[^|]*|Hitem:") or body:find("^|Hitem:")) and true or false
end

-- Roll lines are laid out like loot lines: the "[Loot]:" in front is gone and the player's name stands
-- there instead, in the class color, with the roll next to it: "Arkinn > (need roll: 16) [Item]". The
-- column of the items is the loot lines' own. Built from the client's own wording, whatever the language.
local rollSets

local function PatternFromFormat(fmt)
    -- the "[Loot]:" link in front is taken off the text before it is matched, so off the format too
    fmt = fmt:gsub("^|HlootHistory:%%d|h%[.-%]|h: ", "")
    local p = fmt:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
    p = p:gsub("%%%%d", "(%%d+)"):gsub("%%%%s", "(.-)")
    return "^" .. p .. "$"
end

local function BuildRollSets()
    rollSets = {
        won = {},
        youWon = {},
        rolled = {},
        leading = {},
        mine = {},
        kind = {}
    }
    -- the kind of roll a sentence of the game is about ("need", "greed", "tmog", "disenchant"), from its name
    local function KindOf(global)
        if global:find("TRANSMOG", 1, true) then
            return "tmog"
        end
        if global:find("_DE$") or global:find("DISENCHANT", 1, true) then
            return "disenchant"
        end
        if global:find("GREED", 1, true) then
            return "greed"
        end
        if global:find("NEED", 1, true) then
            return "need"
        end
    end
    local function Add(list, globals)
        for _, g in ipairs(globals) do
            if type(_G[g]) == "string" then
                local p = PatternFromFormat(_G[g])
                list[#list + 1] = p
                rollSets.kind[p] = KindOf(g)
            end
        end
    end
    -- name, roll, item
    Add(rollSets.won, {"LOOT_ROLL_WON_NO_SPAM_NEED", "LOOT_ROLL_WON_NO_SPAM_GREED", "LOOT_ROLL_WON_NO_SPAM_DE",
                       "LOOT_ROLL_WON_NO_SPAM_NEED_OFF_SPEC", "LOOT_ROLL_WON_NO_SPAM_TRANSMOGRIFICATION"})
    -- roll, item
    Add(rollSets.youWon,
        {"LOOT_ROLL_YOU_WON_NO_SPAM_NEED", "LOOT_ROLL_YOU_WON_NO_SPAM_GREED", "LOOT_ROLL_YOU_WON_NO_SPAM_DE",
         "LOOT_ROLL_YOU_WON_NO_SPAM_NEED_OFF_SPEC", "LOOT_ROLL_YOU_WON_NO_SPAM_TRANSMOG"})
    -- roll, item, name
    Add(rollSets.rolled,
        {"LOOT_ROLL_ROLLED_NEED", "LOOT_ROLL_ROLLED_GREED", "LOOT_ROLL_ROLLED_DE", "LOOT_ROLL_ROLLED_NEED_ROLE_BONUS"})
    -- the name first, then the sentence: "Name passed on: [Item]"
    Add(rollSets.leading,
        {"LOOT_ROLL_PASSED", "LOOT_ROLL_NEED", "LOOT_ROLL_GREED", "LOOT_ROLL_DISENCHANT", "LOOT_ROLL_WON",
         "LOOT_ROLL_PASSED_AUTO", "LOOT_ROLL_PASSED_AUTO_FEMALE"})
    -- Your own roll lines are said in a few words: "Passed on: [Item]", "Need: [Item]", "Need roll 7: [Item]".
    local function AddMine(global, label)
        local f = _G[global]
        if type(f) ~= "string" then
            return
        end
        f = f:gsub("%s+|HlootHistory:%%d|h.-|h$", "") -- the "View Loot Rolls" link at the end is not shown
        rollSets.mine[#rollSets.mine + 1] = {
            p = PatternFromFormat(f),
            label = label
        }
    end
    AddMine("LOOT_ROLL_PASSED_SELF", "Passed on:")
    AddMine("LOOT_ROLL_PASSED_SELF_AUTO", "Auto-passed on:")
    AddMine("LOOT_ROLL_NEED_SELF", "Need:")
    AddMine("LOOT_ROLL_NEED_SELF_OFF_SPEC", "Need (Off-Spec):")
    AddMine("LOOT_ROLL_GREED_SELF", "Greed:")
    AddMine("LOOT_ROLL_DISENCHANT_SELF", "Disenchant:")
    AddMine("LOOT_ROLL_LOST_ROLL", false) -- "You have rolled Need - 7 for: [Item]": its words are the roll's own
end

-- The class of a player named in a roll line: the group's own roster by name (a name alone does not work as a
-- unit for players of another realm), else what a loot line told earlier.
local function RollClass(name)
    if not name then
        return
    end
    local short = Ambiguate(name, "short")
    if classOfName[short] then
        return classOfName[short]
    end
    local units = {}
    if IsInRaid and IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            units[#units + 1] = "raid" .. i
        end
    elseif IsInGroup and IsInGroup() then
        units[1] = "player"
        for i = 1, GetNumSubgroupMembers() do
            units[#units + 1] = "party" .. i
        end
    end
    for _, unit in ipairs(units) do
        if UnitExists(unit) then
            local full = (GetUnitName and GetUnitName(unit, true)) or UnitName(unit)
            if type(full) == "string" and Ambiguate(full, "short") == short then
                local class = select(2, UnitClass(unit))
                if class then
                    classOfName[short] = class
                    return class
                end
            end
        end
    end
    local ok, _, class = pcall(UnitClass, name)
    if ok and class then
        classOfName[short] = class
        return class
    end
end

-- The words of a roll line's text, each remembering the link it sits in (an item link, the "View Loot
-- Rolls" link), so a line can be broken between any two words and every piece stays a link of its own.
local function SplitRest(text)
    local atoms, pos, space = {}, 1, false
    local function AddPlain(seg)
        for ws, word in seg:gmatch("(%s*)(%S+)") do
            atoms[#atoms + 1] = {
                plain = word,
                sp = space or ws ~= ""
            }
            space = false
        end
        if seg:find("%s$") then
            space = true
        end
    end
    while pos <= #text do
        local s, e, open, inner = text:find("(|H[^|]-|h)(.-)|h", pos)
        if not s then
            AddPlain(text:sub(pos))
            break
        end
        -- the link's own colour sits right around it: |cffa335ee|Hitem:...|h[Name]|h|r (or |cnIQ4:|Hitem:...)
        local outerOpen, outerClose = "", ""
        local before = text:sub(pos, s - 1)
        local colour = before:match("(|c[^|]*)$")
        if colour then
            outerOpen = colour
            s = s - #colour
        end
        if text:sub(e + 1, e + 2) == "|r" and outerOpen ~= "" then
            outerClose = "|r"
            e = e + 2
        end
        AddPlain(text:sub(pos, s - 1))
        local pre, label, post = inner:match("^(.-)(%[.-%])(.*)$")
        if not label then
            pre, label, post = "", inner, ""
        end
        local link = {
            open = outerOpen .. open .. pre,
            close = post .. "|h" .. outerClose
        }
        local first = true
        for word in label:gmatch("%S+") do
            atoms[#atoms + 1] = {
                plain = word,
                sp = first and space or not first,
                link = link
            }
            first = false
        end
        space = false
        pos = e + 1
    end
    return atoms
end

-- The text of a roll line broken to fit the window, every line after the first indented to where the
-- text starts (after the arrow), the way a long item name is. nil when it fits (or cannot be measured).
local function WrapRest(W, head, rest)
    local unit = TextUnitsPerPixel(W)
    local frameWidth = W.frame:GetWidth()
    if not unit or not frameWidth or frameWidth <= 0 then
        return nil
    end
    local headWidth = TextWidth(W, head) + (W.prefixWidth or 0) -- what another addon puts in front counts too
    local avail = frameWidth - 22 - headWidth
    if avail < 60 then
        return nil
    end
    local atoms = SplitRest(rest)
    if #atoms < 2 then
        return nil
    end
    local lines, cur, plain = {}, {}, ""
    for _, a in ipairs(atoms) do
        local candidate = plain .. ((#cur > 0 and a.sp) and " " or "") .. a.plain
        if #cur > 0 and TextWidth(W, candidate) > avail then
            lines[#lines + 1] = cur
            cur, plain = {a}, a.plain
        else
            cur[#cur + 1] = a
            plain = candidate
        end
    end
    lines[#lines + 1] = cur
    if #lines < 2 then
        return nil
    end
    local function Emit(list)
        local out, i = {}, 1
        while i <= #list do
            local a = list[i]
            if i > 1 and a.sp then
                out[#out + 1] = " "
            end
            if a.link then
                local words, j = {a.plain}, i + 1
                while list[j] and list[j].link == a.link do
                    words[#words + 1] = list[j].plain
                    j = j + 1
                end
                out[#out + 1] = a.link.open .. table.concat(words, " ") .. a.link.close
                i = j
            else
                out[#out + 1] = a.plain
                i = i + 1
            end
        end
        return table.concat(out)
    end
    local indent = Spacer(headWidth / unit)
    local out = {Emit(lines[1])}
    for k = 2, #lines do
        out[#out + 1] = "\n" .. indent .. Emit(lines[k])
    end
    return table.concat(out)
end

-- "<margin><room to the column>Name > (need roll: 16) rest". `name` nil: no player (the roll started):
-- the item is lined up with the others. `kind`: what was rolled ("need", "greed", "tmog" ...).
local function LayRollLine(W, name, isSelf, roll, rest, kind)
    rest = FitIcons(W, rest)
    local sep = db.separator or ""
    local short = name and DisplayName(W, name)
    local parts = {ROLL_MARK, Spacer(db.leftMargin)}
    if db.alignColumn and W and W.columns[db] then
        local unit = TextUnitsPerPixel(W)
        if unit then
            local w = short and TextWidth(W, short .. (sep ~= "" and (" " .. sep) or "") .. " [") or TextWidth(W, "[")
            if w and w < W.columns[db] then
                parts[#parts + 1] = Spacer((W.columns[db] - w) / unit)
            end
        end
    end
    if short then
        local class
        if not isSelf then
            local okc, found = pcall(RollClass, name)
            class = okc and found or nil
        end
        parts[#parts + 1] = ColorName(name, nil, isSelf, class, short)
        if sep ~= "" then
            parts[#parts + 1] = " |cffaaaaaa" .. sep:gsub("|", "||") .. "|r"
        end
        parts[#parts + 1] = " "
        -- the roll stands after the arrow, so the arrows line up with those of the loot lines
        if roll then
            parts[#parts + 1] = "|cff888888(" .. (kind and (kind .. " ") or "") .. "roll: " .. roll .. ")|r "
        end
    end
    local head = table.concat(parts)
    if db.shortenItems and W then
        rest = ShortenItem(W, head, rest, W.prefixWidth or 0)
    end
    -- aligned in a column, a long line is broken here (the window's own indent is off then)
    local wrapped = db.alignColumn and W and not db.shortenItems and WrapRest(W, head, rest)
    return head .. (wrapped or rest)
end

-- Money lines ("You loot 3 Gold, 22 Silver, 84 Copper.") laid out like the loot lines: "Frogski -> 3g 22s 84c", with the
-- letters or with the little coin pictures. The words of the amount are the game's own (whatever the language).
local moneyPats
local MONEY_COLORS = {
    g = "|cffffd700",
    s = "|cffc7c7cf",
    c = "|cffeda55f"
}
local MONEY_ICON_FILES = {
    g = "Interface/MoneyFrame/UI-GoldIcon",
    s = "Interface/MoneyFrame/UI-SilverIcon",
    c = "Interface/MoneyFrame/UI-CopperIcon"
}

-- the game's own sharp coin pictures (atlases); the old small picture files where a client does not have them
local MONEY_ICON_ATLAS = {
    g = "Coin-Gold",
    s = "Coin-Silver",
    c = "Coin-Copper"
}

local function MoneyIcon(key)
    local size = math.max(6, math.min(32, tonumber(db.moneyIconSize) or 14))
    local drop = -math.max(0, math.min(12, tonumber(db.moneyIconDrop) or 3))
    local atlas = MONEY_ICON_ATLAS[key]
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
        return "|A:" .. atlas .. ":" .. size .. ":" .. size .. ":2:" .. drop .. "|a"
    end
    return "|T" .. MONEY_ICON_FILES[key] .. ":" .. size .. ":" .. size .. ":2:" .. drop .. "|t"
end

local function BuildMoneyPatterns()
    local function Escaped(fmt)
        return (fmt:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
    end
    local function Unit(global, fallback)
        local fmt = type(_G[global]) == "string" and _G[global] or fallback
        return (Escaped(fmt):gsub("%%%%d", "(%%d+)"))
    end
    moneyPats = {
        g = Unit("GOLD_AMOUNT", "%d Gold"),
        s = Unit("SILVER_AMOUNT", "%d Silver"),
        c = Unit("COPPER_AMOUNT", "%d Copper")
    }
    if type(LOOT_MONEY) == "string" then -- "%s loots %s.": somebody else
        local p = Escaped(LOOT_MONEY):gsub("%%%%s", "(.-)", 1)
        p = p:gsub("%%%%s", ".+", 1)
        moneyPats.who = "^" .. p .. "$"
    end
end

-- The line laid out, or nil when it is not a money line this can read.
local function FormatMoneyLine(W, text, guid)
    if type(text) ~= "string" or issecretvalue(text) then
        return nil
    end
    if not moneyPats then
        BuildMoneyPatterns()
    end
    local head = text:gsub("%s*%(.*$", "") -- "(... deposited to guild bank)" is left out
    local amount = {}
    for key in pairs(MONEY_ICON_FILES) do
        amount[key] = tonumber(head:match(moneyPats[key]))
    end
    if not (amount.g or amount.s or amount.c) then
        return nil
    end
    local me = UnitName("player")
    local name, isSelf = me, true
    local who = moneyPats.who and head:match(moneyPats.who)
    if who and who ~= "" then
        name = who
        isSelf = Ambiguate(name, "short") == me
    end
    local pieces = {}
    for _, key in ipairs({"g", "s", "c"}) do
        local n = amount[key]
        if n and n > 0 then
            local number = (key == "g" and BreakUpLargeNumbers) and BreakUpLargeNumbers(n) or tostring(n)
            if db.moneyIcons then
                pieces[#pieces + 1] = "|cffffffff" .. number .. "|r" .. MoneyIcon(key)
            else
                pieces[#pieces + 1] = MONEY_COLORS[key] .. number .. key .. "|r"
            end
        end
    end
    if #pieces == 0 then
        pieces[1] = db.moneyIcons and ("|cffffffff0|r" .. MoneyIcon("c")) or (MONEY_COLORS.c .. "0c|r")
    end
    local shown = DisplayName(W, name)
    local sep = db.separator or ""
    local parts = {Spacer(db.leftMargin)}
    -- the arrows line up with those of the loot lines
    if db.alignColumn and W.columns[db] then
        local unit = TextUnitsPerPixel(W)
        if unit then
            local w = TextWidth(W, shown .. (sep ~= "" and (" " .. sep) or "") .. " [")
            if w and w < W.columns[db] then
                parts[#parts + 1] = Spacer((W.columns[db] - w) / unit)
            end
        end
    end
    local class
    if not isSelf then
        local okc, found = pcall(RollClass, name)
        class = okc and found or nil
    end
    parts[#parts + 1] = ColorName(name, guid, isSelf, class, shown)
    if sep ~= "" then
        parts[#parts + 1] = " |cffaaaaaa" .. sep:gsub("|", "||") .. "|r"
    end
    parts[#parts + 1] = " " .. table.concat(pieces, " ")
    return table.concat(parts)
end

-- The name of the encounter the loot rolls link points to, only when the game still knows it: a name is
-- never guessed.
local function EncounterName(encounterID)
    local id = tonumber(encounterID)
    if not id or not (C_LootHistory and C_LootHistory.GetInfoForEncounter) then
        return
    end
    local ok, info = pcall(C_LootHistory.GetInfoForEncounter, id)
    local name = ok and info and info.encounterName
    if type(name) == "string" and name ~= "" and not issecretvalue(name) then
        return name
    end
end

-- What dropped a boss's loot, for the picture of its "<boss> drops:" line: "elite" (an elite or a world boss, which
-- is what the bosses of dungeons and raids are) or "rare" (a rare, elite or not); nil when it is not known. The loot
-- history knows only the name of the encounter, so the creatures the game shows are looked at, and remembered by name.
do
    local rankOfName = {}
    local RANK_OF = {
        elite = "elite",
        worldboss = "elite",
        rare = "rare",
        rareelite = "rare"
    }

    local function Learn(unit)
        local ok, name, class = pcall(function()
            if not UnitExists(unit) or UnitIsPlayer(unit) then
                return
            end
            return UnitName(unit), UnitClassification(unit)
        end)
        if ok and type(name) == "string" and type(class) == "string" and not issecretvalue(name) and
            not issecretvalue(class) and RANK_OF[class] then
            rankOfName[name] = RANK_OF[class]
        end
    end

    local units = {"target", "focus", "mouseover", "softenemy"}
    for i = 1, 8 do
        units[#units + 1] = "boss" .. i
    end

    -- The bosses of the dungeon the player is in, by name: the dungeon finder lists them (a normal dungeon starts no
    -- encounter, so the game never says the name of its boss). Only a list that has something in it is kept.
    local bossLists = {}
    local function InstanceBosses()
        local ok, lfgID = pcall(function()
            return (select(10, GetInstanceInfo()))
        end)
        if not ok or type(lfgID) ~= "number" or issecretvalue(lfgID) then
            return {}
        end
        if bossLists[lfgID] then
            return bossLists[lfgID]
        end
        local set, count = {}, 0
        if GetLFGDungeonNumEncounters and GetLFGDungeonEncounterInfo then
            local okn, n = pcall(GetLFGDungeonNumEncounters, lfgID)
            for i = 1, okn and type(n) == "number" and n or 0 do
                local okb, boss = pcall(GetLFGDungeonEncounterInfo, lfgID, i)
                if okb and type(boss) == "string" and boss ~= "" and not issecretvalue(boss) then
                    set[boss], count = true, count + 1
                end
            end
        end
        if count > 0 then
            bossLists[lfgID] = set
        end
        return set
    end

    -- What lies dead where the player looks (the target, the focus, what the mouse is over, the name plates, the bosses
    -- of an encounter) and is a boss: the name, and "rare" (a rare) or "elite" (a boss: a boss of this dungeon by name,
    -- a boss by its skull, a world boss). For a drop the game gave no name this is where the name comes from; an
    -- ordinary elite is none of these.
    local function BossCorpse(describe)
        local bosses = InstanceBosses()
        local list = {}
        for _, unit in ipairs(units) do
            list[#list + 1] = unit
        end
        for i = 1, 20 do
            list[#list + 1] = "nameplate" .. i
        end
        for _, unit in ipairs(list) do
            local ok, name, rank, info = pcall(function()
                if not (UnitExists(unit) and not UnitIsPlayer(unit)) then
                    return
                end
                local n, class, level, dead = UnitName(unit), UnitClassification(unit), UnitLevel(unit), UnitIsDead(unit)
                local why
                if class == "rare" or class == "rareelite" then
                    why = "rare"
                elseif class == "worldboss" or level == -1 or bosses[n] then
                    why = "elite"
                end
                local text = ("%s: %s, class %s, level %s, dead %s, boss of this dungeon %s"):format(unit, tostring(n),
                    tostring(class), tostring(level), tostring(dead), tostring(bosses[n] == true))
                if dead and why and type(n) == "string" then
                    return n, why, text
                end
                return nil, nil, text
            end)
            if describe and ok and info then
                describe(info)
            end
            if ok and not describe and type(name) == "string" and not issecretvalue(name) then
                return name, rank
            end
        end
    end
    ns.BossCorpse = BossCorpse

    -- the rank of a drop line ("[Loot]: [Item]"), from the name the loot history gives its encounter, and the name of
    -- what dropped it when the game gives none (a boss or a rare lying dead in front of the player; nothing else)
    function ns.RankOfDrop(text)
        if not IsDropText(text) then
            return
        end
        local name = EncounterName(text:match("^|HlootHistory:(%-?%d+)|h"))
        if not name then
            local bossName, rank = BossCorpse()
            return rank, bossName
        end
        for _, unit in ipairs(units) do
            Learn(unit)
        end
        return rankOfName[name]
    end

    -- creatures are learned as they show up: the target, the focus, what the mouse is over, the name plates and the
    -- bosses of an encounter (an encounter itself is a boss: an elite, when no creature of its name was seen)
    local watcher = CreateFrame("Frame")
    for _, event in ipairs({"PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "UPDATE_MOUSEOVER_UNIT",
                            "NAME_PLATE_UNIT_ADDED", "INSTANCE_ENCOUNTER_ENGAGE_UNIT", "ENCOUNTER_START"}) do
        pcall(watcher.RegisterEvent, watcher, event) -- a game version without one of them simply never learns from it
    end
    watcher:SetScript("OnEvent", function(_, event, arg1, arg2)
        if event == "PLAYER_TARGET_CHANGED" then
            Learn("target")
        elseif event == "PLAYER_FOCUS_CHANGED" then
            Learn("focus")
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            Learn("mouseover")
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            if arg1 then
                Learn(arg1)
            end
        elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
            for i = 1, 8 do
                Learn("boss" .. i)
            end
        elseif type(arg2) == "string" and not issecretvalue(arg2) and not rankOfName[arg2] then
            rankOfName[arg2] = "elite" -- ENCOUNTER_START
        end
    end)
end

-- "Nymrissa Wavecaller drops:", or "Boss drops:" when the encounter is not known any more. `rank`: "rare" when the boss
-- was a rare; an elite, and a boss that is not known to be a rare, use the elite boss settings.
local function DropHeader(encounterID, knownBoss, rank)
    local key = rank == "rare" and "rareBoss" or "eliteBoss"
    return GreyLine((knownBoss or EncounterName(encounterID) or "Boss") .. " drops:",
        IconMarkup(db[key .. "Icon"], nil, "raid", db[key .. "IconScale"]), db[key .. "IconSide"], nil,
        db[key .. "Color"])
end

-- The text of a roll line laid out, or nil when it is not one (or cannot be read). `knownBoss`: the name
-- the game gave the encounter when the line first came (kept with the line, for after a reload). `where`: the
-- place the line came in (kept the same way) and `st`: the window's date/place state, so that the place is
-- shown above the "<boss> drops:" line like it is above a loot line.
local function FormatRollLine(W, text, knownBoss, where, st)
    if type(text) ~= "string" or issecretvalue(text) or text:find(ROLL_MARK, 1, true) then
        return
    end
    if not text:find("|Hitem:", 1, true) or not IsRollLine(text) then
        return
    end
    if not rollSets then
        BuildRollSets()
    end
    local me = UnitName("player")
    local function IsMe(name)
        return Ambiguate(name, "short") == me
    end
    local body, prefixed = text:gsub("^|HlootHistory:%-?%d+|h%[.-%]|h: ", "", 1)
    -- the "[View Loot Rolls]" link at the end of a line is left out
    body = body:gsub("%s*|HlootHistory:%-?%d+|h.-|h", "")

    for _, p in ipairs(rollSets.youWon) do
        local roll, item = body:match(p)
        if roll then
            return LayRollLine(W, me, true, roll, item, rollSets.kind[p])
        end
    end
    for _, p in ipairs(rollSets.won) do
        local name, roll, item = body:match(p)
        if name then
            return LayRollLine(W, name, IsMe(name), roll, item, rollSets.kind[p])
        end
    end
    for _, p in ipairs(rollSets.rolled) do
        local roll, item, name = body:match(p)
        if roll then
            return LayRollLine(W, name, IsMe(name), roll, item, rollSets.kind[p])
        end
    end
    for _, m in ipairs(rollSets.mine) do
        local a, b, c = body:match(m.p)
        if a then
            if m.label then
                return LayRollLine(W, me, true, nil, m.label .. " " .. a)
            end
            -- type, number, item: "You have rolled Need - 7 for: [Item]"
            return LayRollLine(W, me, true, b, c, (a:lower():gsub("^transmog%w*", "tmog")))
        end
    end
    local youWord = _G.YOU or "You"
    if body:sub(1, #youWord + 1) == youWord .. " " then
        return LayRollLine(W, me, true, nil, body) -- "You passed on: [Item] [View Loot Rolls]"
    end
    for _, p in ipairs(rollSets.leading) do
        local name = body:match(p)
        if name and name ~= "" then
            return LayRollLine(W, name, IsMe(name), nil, body:sub(#name + 2))
        end
    end
    -- anything else with the loot rolls link in front ("[Loot]: [Item]", "Everyone passed on: [Item]"):
    -- just without the "[Loot]:"
    if prefixed > 0 then
        local line = LayRollLine(W, nil, false, nil, body)
        -- An item that drops for a roll ("[Loot]: [Item]", nothing else): the first of an encounter gets a
        -- grey line in front of it saying what dropped it, like the instance and town lines.
        local encounterID = text:match("^|HlootHistory:(%-?%d+)|h")
        -- an item link, in a colour of either kind: |cffa335ee|Hitem:... or |cnIQ4:|Hitem:...
        local isDrop = body:find("^|c[^|]*|Hitem:") or body:find("^|Hitem:")
        -- The game gives the same number to every kill of a boss: drops that come a good while after the last drop line
        -- are another kill, and get their own line.
        local when = where and where.time
        local nextKill = W.dropEncounter == encounterID and when and W.dropTime and when - W.dropTime > 30
        if encounterID and isDrop and when then
            W.dropTime = when
        end
        local fresh = encounterID and isDrop and (W.dropEncounter ~= encounterID or nextKill)
        if fresh then
            W.dropEncounter = encounterID
            -- A kill the game gave no name (no encounter was started: an ordinary elite, an item that drops for a roll
            -- in the open world) gets no "drops:" line, no picture and no tree, unless it was a rare.
            local named = knownBoss or EncounterName(encounterID) or (where and where.bossName)
            W.dropPlain = (not named and not (where and where.rank == "rare")) and encounterID or nil
        end
        if encounterID and isDrop and W.dropPlain ~= encounterID then
            line = DropMark(6, encounterID) .. line
        end
        if fresh and W.dropPlain ~= encounterID then
            -- the boss dies in a place: the date and the dungeon / raid are said first, when they changed
            local above = ""
            if where and st then
                local place = ns.Separators(db, st, {
                    instance = where.instance,
                    instanceType = where.instanceType,
                    zone = where.zone,
                    place = where.place,
                    time = where.time
                })
                if place then
                    above = table.concat(place, "\n") .. "\n"
                end
            end
            -- The header is a line of its own that the caller adds in front of the item line, straight into
            -- the window (so no other addon puts a timestamp on it, and the item line keeps its own).
            return line, ROLL_MARK .. DropMark(5, encounterID) .. above ..
                DropHeader(encounterID, knownBoss or (where and where.bossName), where and where.rank)
        end
        return line
    end
end

-- Roll winners. A win is remembered by the winner's name and the item for a couple of minutes; the loot line of that
-- item for that player is marked as won (see ShouldShow), whether it comes after the roll line or, if the game ever
-- writes it first, before it.
do
    local wins, count = {}, 0
    local KEEP = 120

    local function Key(name, link)
        local id = type(link) == "string" and link:match("|Hitem:(%d+)")
        if not id or type(name) ~= "string" or name == "" then
            return nil
        end
        return Ambiguate(name, "short") .. "|" .. id
    end

    local function KeyOf(entry)
        if entry.currency then
            return nil
        end
        return Key(entry.isSelf and UnitName("player") or entry.name, entry.link)
    end

    -- was the item of this loot entry won in a roll by the one who got it?
    function ns.WonByRoll(entry)
        local key = entry and KeyOf(entry)
        local at = key and wins[key]
        return at ~= nil and GetTime() - at <= KEEP
    end

    local function Mark(entry, key, now)
        if entry and not entry.won and entry.time and now - entry.time <= 15 and KeyOf(entry) == key then
            entry.won = true
            return true
        end
    end

    -- the key of the win a roll line tells of ("Name (Need - 98, Main-Spec) Won: [Item]", "You won: [Item]"), or nil
    local function WonKey(text)
        if type(text) ~= "string" or issecretvalue(text) then
            return nil
        end
        if not rollSets then
            BuildRollSets()
        end
        local body = text:gsub("^|HlootHistory:%-?%d+|h%[.-%]|h: ", "", 1)
        body = body:gsub("%s*|HlootHistory:%-?%d+|h.-|h", "")
        local name, item
        for _, p in ipairs(rollSets.youWon) do
            local roll, found = body:match(p)
            if roll then
                name, item = UnitName("player"), found
                break
            end
        end
        if not name then
            for _, p in ipairs(rollSets.won) do
                local who, roll, found = body:match(p)
                if who then
                    name, item = who, found
                    break
                end
            end
        end
        return Key(name, item)
    end

    -- Loot lines saved before the winners were marked: when a window loads its saved history, the loot of an item that a
    -- saved roll line says the one who got it won (within half a minute) is marked, so it is shown with the loot rolls.
    function ns.MarkSavedWins(W)
        local rolls, history = W.rolls, W.history
        if not (rolls and history) then
            return
        end
        local wonAt = {}
        for _, r in ipairs(rolls) do
            local key = r.time and WonKey(r.text)
            if key then
                wonAt[key] = wonAt[key] or {}
                table.insert(wonAt[key], r.time)
            end
        end
        if not next(wonAt) then
            return
        end
        for _, e in ipairs(history) do
            local key = not e.won and KeyOf(e)
            local times = key and wonAt[key]
            if times and e.time then
                for _, t in ipairs(times) do
                    if math.abs(e.time - t) <= 30 then
                        e.won = true
                        break
                    end
                end
            end
        end
    end

    local refreshQueued
    -- a roll line of the game: when it says who won, remember it, and mark the loot lines of it that are there already
    function ns.NoteWin(text)
        local key = WonKey(text)
        if not key then
            return
        end
        local now = GetTime()
        wins[key] = now
        count = count + 1
        if count > 100 then
            for k, at in pairs(wins) do
                if now - at > KEEP then
                    wins[k] = nil
                end
            end
            count = 0
        end
        local marked, stamp = false, time()
        for _, W in ipairs(ns.ActiveWindows()) do
            for i = #W.history, math.max(1, #W.history - 40), -1 do
                if Mark(W.history[i], key, stamp) then
                    marked = true
                end
            end
            for i = #W.shadow, math.max(1, #W.shadow - 40), -1 do
                if Mark(W.shadow[i].entry, key, stamp) then
                    marked = true
                end
            end
        end
        if marked and not refreshQueued then
            refreshQueued = true
            C_Timer.After(0.2, function()
                refreshQueued = false
                ns.Refresh()
            end)
        end
    end
end

-- Item upgrades. Every step of an upgrade sends a loot line of its own ("You receive loot: [Item]": the link of the item
-- with the next upgrade rank), several in a second, and a window that shows them all looks like the same item looted
-- again and again. They are not loot: of such a burst only the last line is shown (the earlier ones are marked
-- `superseded`: kept in the history, never shown). A step is one of the player's own lines for the same item, a few
-- seconds after the other, whose link is the same except for one number (the upgrade rank), and that went up by one.
-- Two drops of the same item (from two mobs, say) have the same link, or at least differ in more than that.
do
    local WITHIN = 5 -- seconds from one step to the next

    local function Fields(link)
        local payload = type(link) == "string" and link:match("|Hitem:([^|]*)|h")
        if not payload then
            return nil
        end
        local list = {}
        for field in (payload .. ":"):gmatch("([^:]*):") do
            list[#list + 1] = field
        end
        return list
    end

    local function Key(entry)
        if entry.currency or not entry.name or type(entry.link) ~= "string" then
            return nil
        end
        local id = entry.link:match("|Hitem:(%d+)")
        return id and (Ambiguate(entry.name, "short") .. "|" .. id) or nil
    end

    -- is `later` the next step of an upgrade that `earlier` was a step of?
    local function NextStep(earlier, later)
        if earlier == later or earlier.link == later.link then
            return false
        end
        if not (earlier.isSelf and later.isSelf) then
            return false
        end -- only the player's own items are upgraded
        if math.abs((later.time or 0) - (earlier.time or 0)) > WITHIN then
            return false
        end
        local key = Key(later)
        if not key or Key(earlier) ~= key then
            return false
        end
        local a, b = Fields(earlier.link), Fields(later.link)
        if not (a and b) or #a ~= #b then
            return false
        end
        local differing = 0
        for i = 1, #a do
            if a[i] ~= b[i] then
                differing = differing + 1
                local was, now = tonumber(a[i]), tonumber(b[i])
                if differing > 1 or not (was and now and now == was + 1) then
                    return false
                end
            end
        end
        return differing == 1
    end

    -- the lines saved before the steps were marked: marked when a window loads its saved history
    function ns.MarkSavedUpgrades(W)
        local last = {}
        for _, e in ipairs(W.history or {}) do
            local key = Key(e)
            if key then
                local prior = last[key]
                if prior and not prior.superseded and NextStep(prior, e) then
                    prior.superseded = true
                end
                last[key] = e
            end
        end
    end

    local refreshQueued
    -- a loot line has come: the earlier steps of the same upgrade, in the history and in the windows, are marked
    function ns.NoteUpgrade(entry)
        if not Key(entry) then
            return
        end
        local changed = false
        for _, W in ipairs(ns.ActiveWindows()) do
            local history = W.history
            for i = #history, math.max(1, #history - 12), -1 do
                local other = history[i]
                if not other.superseded and NextStep(other, entry) then
                    other.superseded, changed = true, true
                end
            end
            local shadow = W.shadow
            for i = #shadow, math.max(1, #shadow - 40), -1 do
                local other = shadow[i].entry
                if other and not other.superseded and NextStep(other, entry) then
                    other.superseded, changed = true, true
                end
            end
        end
        if changed and not refreshQueued then
            refreshQueued = true
            C_Timer.After(0.2, function()
                refreshQueued = false
                ns.Refresh()
            end)
        end
    end
end

-- Turns the arguments of a CHAT_MSG_LOOT / CHAT_MSG_CURRENCY event into an entry,
-- or nil for anything that is not an item or currency line (money, etc.).
local function BuildEntry(text, playerName, guid, isCurrency)
    if type(text) ~= "string" or issecretvalue(text) then
        return
    end
    if guid and issecretvalue(guid) then
        guid = nil
    end
    local link = FindLink(text, isCurrency)
    if not link then
        return
    end

    local me = UnitName("player")
    -- The wording of the line says who looted ("You receive..." vs "Name receives...");
    -- the event's name argument is only the fallback, and an empty one never means "me"
    -- for a line that names someone else.
    local isSelf, name
    local isLootLine, selfByText, nameByText, handedOver, crafted, wholeName = ParseLootLine(text)
    -- Only a line that says an item was received counts. Roll lines ("selected Need",
    -- "Greed Roll", "passed", "won") also carry the item link, and they appear just by
    -- opening a corpse's loot window; nothing has gone into anyone's bags then.
    if not isLootLine then
        return
    end
    isSelf = selfByText
    name = isSelf and me or nameByText
    if not name then
        name = isSelf and me or playerName
    end
    if not name or name == "" then
        return
    end
    -- A name of two words (Forever: "Bolty Forever") is read from the line as its last word only. The whole name is
    -- taken from where it stands whole: the event's own name, the one the game has for the player's guid, or the line
    -- itself when it holds nothing but a name of one or two words. It has to end with the word that was read.
    if not isSelf then
        local last = Ambiguate(name, "short"):match("(%S+)%s*$")
        local fromGuid
        if guid and guid ~= "" then
            local okg, found = pcall(function()
                return (select(6, GetPlayerInfoByGUID(guid)))
            end)
            fromGuid = okg and found or nil
        end
        local alone = type(wholeName) == "string" and (wholeName:match("^%S+$") or wholeName:match("^%S+%s+%S+$"))
        for _, candidate in ipairs({playerName or false, fromGuid or false, alone or false}) do
            if type(candidate) == "string" and not issecretvalue(candidate) and candidate ~= "" then
                local short = Ambiguate(candidate, "short")
                if last and short:match("(%S+)%s*$") == last then
                    name = short
                    break
                end
            end
        end
    end

    if not isSelf then
        pcall(ns.LearnName, guid, name) -- the whole name of this guid, for entries that only hold its last word
    end

    local zone = GetZoneText() ~= "" and GetZoneText() or nil
    return {
        name = name,
        guid = guid,
        link = link,
        count = tonumber(text:match("|h|r ?x(%d+)")),
        isSelf = isSelf,
        time = time(),
        currency = isCurrency or nil,
        received = handedOver or nil,
        crafted = crafted or nil,
        instance = CurrentInstance(),
        instanceType = select(2, CurrentInstance()),
        zone = zone,
        place = SafePlaceKind()
    }
end

---------------------------------------------------------------------------
-- A loot window: the filter, its record and its redraw
---------------------------------------------------------------------------

local AddFilter = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter

-- Every loot window keeps a record of what it shows (`W.shadow`), including the loot lines
-- the filters hid, so that loosening a filter brings them back: a filter change clears the
-- window and draws the record again. Nothing is drawn unless the user changed a filter.
--   W.shadow: { text, r, g, b, typeID, accessID, lineID } or { entry, hidden } or + entry/prefix
--   W.hiddenSeen: [lineID] = true, a hidden line is recorded once even if the filter runs twice
--   W.pending: [formatted text] = { entry, t }, lines we let through, tagged when they land
local MAX_SHADOW = 1000

local function Push(W, rec)
    local shadow = W.shadow
    shadow[#shadow + 1] = rec
    if #shadow > MAX_SHADOW then
        local old = table.remove(shadow, 1)
        if old.key then
            W.hiddenSeen[old.key] = nil
        end
    end
end

-- Money lines are recognised by their chat type, whoever formatted them.
local function IsMoneyType(typeID)
    local info = ChatTypeInfo and ChatTypeInfo.MONEY
    return info and typeID ~= nil and not issecretvalue(typeID) and typeID == info.id or false
end

-- Crafting lines ("Name creates: [Item]") are the game's tradeskill messages, recognised by chat type.
local function IsCraftType(typeID)
    local info = ChatTypeInfo and ChatTypeInfo.TRADESKILLS
    return info and typeID ~= nil and not issecretvalue(typeID) and typeID == info.id or false
end

-- Post-hook on the window's AddMessage: whatever the window got (Blizzard's or Prat's
-- line, a timestamp, colors...) is read back from the window itself and recorded.
-- The time another addon puts in front of a line ("[12:12] " in Prat, with its colours) is learned from a real line:
-- what stands before and after the time is kept, with the way the time is written. A line that is drawn again later
-- (after a reload, for instance) is then given exactly the same look.
local function LearnStamp(prefix, t)
    if type(prefix) ~= "string" or issecretvalue(prefix) or prefix == "" then
        return
    end
    local pre, token, post = prefix:match("^(.-)(%d%d:%d%d:%d%d)(.*)$")
    if not pre then
        pre, token, post = prefix:match("^(.-)(%d%d:%d%d)(.*)$")
    end
    if not pre or post:find("[AaPp][Mm]") then
        return
    end -- a 12 hour clock with AM / PM is not copied
    local formats = token:find(":%d%d:%d%d$") and {"%H:%M:%S", "%I:%M:%S"} or {"%H:%M", "%I:%M"}
    for _, fmt in ipairs(formats) do
        if date(fmt, t) == token then
            local known = db.stampTemplate
            if not (type(known) == "table" and known.pre == pre and known.post == post and known.fmt == fmt) then
                db.stampTemplate = {
                    pre = pre,
                    post = post,
                    fmt = fmt
                }
                -- lines drawn earlier with another look are drawn again with this one
                C_Timer.After(0.3, function()
                    ns.Refresh()
                end)
            end
            return
        end
    end
end

-- The time for a line this addon draws itself where another addon would have put one.
local function StampFor(t)
    local known = db.stampTemplate
    if type(known) == "table" and known.pre and known.post and known.fmt then
        return known.pre .. date(known.fmt, t) .. known.post
    end
    return "|cff888888" .. date("%H:%M", t) .. "|r "
end

local function Record(W)
    if not W.active or W.replaying then
        return
    end
    local frame = W.frame
    local n = frame:GetNumMessages()
    if n < 1 then
        return
    end
    local text, r, g, b, typeID, accessID, lineID = frame:GetMessageInfo(n)
    local rec = {
        text = text,
        r = r,
        g = g,
        b = b,
        typeID = typeID,
        accessID = accessID,
        lineID = lineID
    }
    if IsMoneyType(typeID) then
        rec.money = true
    end
    if IsCraftType(typeID) then
        rec.craft = true
    end
    if type(text) == "string" and not issecretvalue(text) then
        for formatted, p in pairs(W.pending) do
            local s = text:find(formatted, 1, true)
            if s then
                rec.entry, rec.prefix = p.entry, text:sub(1, s - 1) -- prefix: e.g. Prat's timestamp
                W.prefixWidth = (s > 1) and TextWidth(W, rec.prefix) or 0
                W.pending[formatted] = nil
                break
            end
        end
        if not rec.entry and not rec.money and IsRollLine(text) then
            rec.roll = true
        end
        -- A roll line this addon laid out keeps the line as the game wrote it, so a redraw can lay it out
        -- again (with "Align items in a column" off, for instance).
        if rec.roll and W.rollRaw then
            for laidOut, info in pairs(W.rollRaw) do
                local at = text:find(laidOut, 1, true)
                if at then
                    W.prefixWidth = (at > 1) and TextWidth(W, text:sub(1, at - 1)) or 0
                    rec.prefix = (at > 1) and text:sub(1, at - 1) or nil -- kept, so a redraw can put it back
                    rec.raw, rec.boss, rec.where = info.raw, info.boss, info.where
                    rec.drop = IsDropText(info.raw)
                    W.rollRaw[laidOut] = nil
                    break
                end
            end
        end
        -- a money line this addon laid out keeps the line as the game wrote it, and what stood in front of it
        if rec.money and W.moneyRaw then
            for laid, info in pairs(W.moneyRaw) do
                local at = text:find(laid, 1, true)
                if at then
                    rec.raw = info.raw
                    rec.prefix = (at > 1) and text:sub(1, at - 1) or nil
                    W.moneyRaw[laid] = nil
                    break
                end
            end
        end
    end
    -- What stands in front of this addon's own part of the line (another addon's timestamp) is measured in
    -- the line itself: the part starts at the little blank picture of the left margin.
    if rec.entry or rec.roll or rec.money then
        local at = type(text) == "string" and not issecretvalue(text) and text:find("|T" .. BLANK, 1, true)
        if at then
            local before = W.prefixWidth or 0
            local now = (at > 1) and TextWidth(W, text:sub(1, at - 1)) or 0
            W.prefixWidth = now
            W.prefixText = (at > 1) and text:sub(1, at - 1) or ""
            if math.abs(now - before) > 1 and not W.prefixRedraw then
                W.prefixRedraw = true
                C_Timer.After(0.2, function()
                    W.prefixRedraw = nil
                    if W.active then
                        ns.Refresh()
                    end
                end)
            end
        end
    end
    if rec.prefix and rec.prefix ~= "" then
        LearnStamp(rec.prefix, time())
    end
    -- The last step: the line as it really stands in the window (another addon's timestamp in front of it) must be
    -- one row. If it is not, the name of its item is cut further, in the window's own text.
    if db.shortenItems and (rec.entry or rec.roll) and type(text) == "string" and not issecretvalue(text) then
        local ok, fixed = pcall(FitWhole, W, text)
        if ok and type(fixed) == "string" and fixed ~= text then
            rec.text = fixed
            if frame.TransformMessages then
                pcall(frame.TransformMessages, frame, function(message)
                    return not issecretvalue(message) and message == text
                end, function(message, ...)
                    return fixed, ...
                end)
            end
            -- when the window's own text could not be changed, the window is drawn again (that draws the line cut)
            local now = frame:GetMessageInfo(frame:GetNumMessages())
            if now ~= fixed and not W.prefixRedraw then
                W.prefixRedraw = true
                C_Timer.After(0.2, function()
                    W.prefixRedraw = nil
                    if W.active then
                        ns.Refresh()
                    end
                end)
            end
        end
    end
    Push(W, rec)
end

-- A line that is already in the window and was written by this addon (it starts, after
-- whatever a chat addon put in front, with our margin spacer) is turned back into an
-- entry, so it can be re-laid-out and filtered like a new one. Anything else stays as it is.
local function AdoptOwnLine(rec, lookup)
    local text = rec.text
    if type(text) ~= "string" or issecretvalue(text) then
        return false
    end
    if text:find(ROLL_MARK, 1, true) then
        return false
    end -- a roll line laid out here: not a loot line
    local s = text:find(("|T%s:"):format(BLANK), 1, true)
    if not s then
        return false
    end
    -- A name that wrapped is several lines of one message: the first holds the name and the link's start.
    local line = text:match("^[^\n]*")
    local isCurrency = line:find("|Hcurrency:", 1, true) and true or nil
    local link = FindLink(line, isCurrency)
    local data = line:match("|H(item:[^|]*)|h") or line:match("|H(currency:[^|]*)|h")
    if not link and not data then
        return false
    end
    -- Plain words after the spacer: "[14:32 ]Name -> [Item]". Drop our own stamp, take the name.
    local plain = line:sub(s):gsub("|T.-|t", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    plain = plain:gsub("^[%d:,%-%s]+", "")
    local who = plain:match("^(%S+)")
    if not who then
        return false
    end
    local entry = lookup[who .. "|" .. (data or "")]
    if not entry and not link then
        return false
    end
    rec.entry = entry or {
        name = who,
        link = link,
        isSelf = (who == UnitName("player")),
        time = time(),
        currency = isCurrency,
        instance = CurrentInstance(),
        instanceType = select(2, CurrentInstance()),
        zone = GetZoneText() ~= "" and GetZoneText() or nil,
        place = SafePlaceKind()
    }
    rec.prefix = text:sub(1, s - 1)
    return true
end

local Replay

-- The chat window indents every wrapped line by a little ("indented word wrap"). While items are
-- aligned in a column that indent would push the second line of a long name away from the column
-- (the addon indents it exactly itself), so the window's own indent is off; it goes back to what it
-- was when the option is off or the window stops being a loot window.
local function ApplyWrapMode(W)
    local frame = W.frame
    if not (frame.SetIndentedWordWrap and frame.GetIndentedWordWrap) then
        return
    end
    if W.origIndented == nil then
        W.origIndented = frame:GetIndentedWordWrap()
    end
    if W.active and db.alignColumn then
        frame:SetIndentedWordWrap(false)
    else
        frame:SetIndentedWordWrap(W.origIndented)
    end
end

-- Reads the window's buffer into the record (and starts recording what it gets next).
-- Returns two booleans: it took over lines that should now be redrawn / the window already
-- holds loot lines (so something, maybe another addon, has brought the history back).
local function CheckDisplayed(W)
    if not (W.active and db.shortenItems) or W.replaying or (W.fitSlack or 0) >= 160 then
        return
    end
    local lines = W.frame.visibleLines
    if not lines then
        return
    end
    for _, line in ipairs(lines) do
        local info = line.messageInfo
        local message = info and info.message
        if line:IsShown() and type(message) == "string" and not issecretvalue(message) and
            message:find("|Hitem:", 1, true) and not message:find("\n", 1, true) and
            (message:find(ROLL_MARK, 1, true) or message:find("|T" .. BLANK, 1, true)) and TextFitsRow(W, message) ==
            true then
            -- measured to fit: is the line itself as tall as the same text in one row?
            local probe = W.rowProbe
            probe:SetWidth(0)
            probe:SetText(message)
            local natural, real = probe:GetStringHeight(), line:GetStringHeight()
            if natural and real and natural > 0 and real > natural * 1.5 then
                W.fitSlack = (W.fitSlack or 0) + 10
                if not W.slackRedraw then
                    W.slackRedraw = true
                    C_Timer.After(0.1, function()
                        W.slackRedraw = nil
                        if W.active then
                            ns.Refresh()
                        end
                    end)
                end
                return
            end
        end
    end
end

-- The tree: a thin vertical line down from the "<boss> drops:" line and a short horizontal line to the name of
-- every item it dropped. They are drawn over the window, from the real places of the lines on the screen (found
-- by the invisible marks), again after every drawing of the window by the game, so they stay with the lines
-- when the window is scrolled.
local TREE_ALPHA = 0.85
local function TreeTexture(W, index)
    W.treeTex = W.treeTex or {}
    local tex = W.treeTex[index]
    if not tex then
        tex = W.frame:CreateTexture(nil, "ARTWORK")
        tex:SetColorTexture(0.62, 0.62, 0.62, 1)
        W.treeTex[index] = tex
    end
    return tex
end

-- Does the item line at `lineIndex` have another item of the same boss right below it (out of sight)?
local function ContinuesBelow(frame, lineIndex, idHex)
    local buffer = frame.historyBuffer
    local messageIndex = lineIndex + (frame.GetScrollOffset and frame:GetScrollOffset() or 0) - 1
    if not (buffer and buffer.GetEntryAtIndex) or messageIndex < 1 then
        return false
    end
    local ok, entry = pcall(buffer.GetEntryAtIndex, buffer, messageIndex)
    local message = ok and entry and entry.message
    return
        type(message) == "string" and not issecretvalue(message) and message:find("|cff06" .. idHex .. "|r", 1, true) ~=
            nil
end

local function DrawDropTree(W)
    local used = 0
    local frame = W.frame
    local unit = TextUnitsPerPixel(W)
    local frameLeft, frameTop, frameBottom = frame:GetLeft(), frame:GetTop(), frame:GetBottom()
    if W.active and db.dropTree and frame.visibleLines and unit and frameLeft and frameTop and frameBottom then
        local entries = {}
        for lineIndex, line in ipairs(frame.visibleLines) do
            local message = line.messageInfo and line.messageInfo.message
            if line:IsShown() and type(message) == "string" and not issecretvalue(message) then
                local kind, id = "head", message:match("|cff05(%x%x%x%x)|r")
                if not id then
                    kind, id = "item", message:match("|cff06(%x%x%x%x)|r")
                end
                local top, bottom = line:GetTop(), line:GetBottom()
                if id and top and bottom then
                    entries[#entries + 1] = {
                        kind = kind,
                        id = id,
                        message = message,
                        top = top,
                        bottom = bottom,
                        alpha = line:GetAlpha(),
                        line = line,
                        index = lineIndex
                    }
                end
            end
        end
        table.sort(entries, function(a, b)
            return a.top > b.top
        end)
        -- one physical pixel in the window's units: the lines are two of them thick and sit on whole pixels
        local physicalHeight
        if GetPhysicalScreenSize then
            local _, h = GetPhysicalScreenSize()
            physicalHeight = h
        end
        local pixel = (physicalHeight and physicalHeight > 0) and (768 / physicalHeight) / frame:GetEffectiveScale() or
                          1
        local thick = pixel * 2
        local function Snap(v)
            return math.floor(v / pixel + 0.5) * pixel
        end
        -- every piece of a boss's tree takes the alpha of that boss's line (`from`), and keeps taking it (FollowTreeFade)
        local function Box(x1, y1, x2, y2, from)
            used = used + 1
            local tex = TreeTexture(W, used)
            tex:ClearAllPoints()
            tex:SetPoint("TOPLEFT", frame, "TOPLEFT", x1 - frameLeft, y1 - frameTop)
            tex:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", x2 - frameLeft, y2 - frameTop)
            tex.fclLine, tex.fclAlpha = from.line, from.alpha
            tex:SetAlpha((from.alpha or 1) * TREE_ALPHA)
            tex:Show()
        end
        -- where the vertical line stands: under the middle of the arrows (right under the boss line when the arrows
        -- are not in a column) ...
        local indentSpaces = db.separatorIndent or 0
        local indent = indentSpaces > 0 and (TextWidth(W, (" "):rep(indentSpaces) .. ".") - TextWidth(W, ".")) or 0
        local xv = frameLeft + (W.prefixWidth or 0) + (db.leftMargin or 0) * unit + indent + 8
        local sep = db.separator or ""
        local column = W.columns and W.columns[db]
        if db.alignColumn and sep ~= "" and column then
            local arrowEnd = MeasureArrow(W, sep)
            if not arrowEnd then
                local itemX = (W.prefixWidth or 0) + (db.leftMargin or 0) * unit + column - TextWidth(W, "[")
                arrowEnd = itemX - TextWidth(W, " ")
            end
            xv = frameLeft + arrowEnd - TextWidth(W, sep) / 2
        end
        W.dropEnd = W.dropEnd or {}
        local i = 1
        while i <= #entries do
            local first = entries[i]
            -- a boss line and the item lines right below it; or, when the boss line has scrolled out of sight, just the items
            local j, last = i, first
            while entries[j + 1] and entries[j + 1].kind == "item" and math.abs(last.bottom - entries[j + 1].top) < 4 do
                j = j + 1
                last = entries[j]
            end
            local hasHead = first.kind == "head"
            local rows = {}
            for k = hasHead and i + 1 or i, j do
                rows[#rows + 1] = entries[k]
            end
            if #rows > 0 then
                -- ... but never further right than the end of the boss name: the line stays joined to it
                local headEnd
                if hasHead then
                    headEnd = TextWidth(W, first.message:match("([^\n]*)$"))
                    W.dropEnd[first.id] = headEnd
                else
                    headEnd = W.dropEnd[first.id] -- remembered from when the boss line was in sight
                end
                local x = xv
                if headEnd then
                    x = math.min(x, frameLeft + headEnd - 4)
                end
                local vx = Snap(x)
                local lastRow = rows[#rows]
                -- from the boss line (or the top of the window) to the last item (or the bottom, if more items follow)
                local yTop = hasHead and first.bottom or math.min(first.top, frameTop)
                local yEnd = ContinuesBelow(frame, lastRow.index, lastRow.id) and frameBottom or
                                 (Snap((lastRow.top + lastRow.bottom) / 2) - thick / 2)
                Box(vx - thick / 2, yTop, vx + thick / 2, yEnd, first)
                for _, row in ipairs(rows) do
                    local at = row.message:find("|c%x%x%x%x%x%x%x%x|Hitem:") or row.message:find("|Hitem:", 1, true)
                    local itemX = at and frameLeft + TextWidth(W, row.message:sub(1, at - 1)) or nil
                    if itemX and itemX - 3 > vx then
                        local y = Snap((row.top + row.bottom) / 2)
                        Box(vx - thick / 2, y + thick / 2, itemX - 3, y - thick / 2, first)
                    end
                end
            end
            i = j + 1
        end
    end
    for k = used + 1, W.treeTex and #W.treeTex or 0 do
        W.treeTex[k]:Hide()
    end
end

-- The game fades the lines of a window one by one (Prat only sets how long they stay) and hides the faded ones,
-- without drawing the window again. So the tree reads the alpha of its boss line again on every frame, and fades
-- (and goes) with the boss name.
function ns.FollowTreeFade(W)
    local pieces = W.treeTex
    for k = 1, pieces and #pieces or 0 do
        local tex = pieces[k]
        local line = tex.fclLine
        if line and tex:IsShown() then
            local alpha = line:IsShown() and line:GetAlpha() or 0
            if alpha ~= tex.fclAlpha then
                tex.fclAlpha = alpha
                tex:SetAlpha(alpha * TREE_ALPHA)
            end
        end
    end
end

local function StartShadow(W)
    local frame = W.frame
    wipe(W.shadow)
    wipe(W.hiddenSeen)
    wipe(W.pending)
    -- The history knows more about a line (class, time, count) than the line does.
    local lookup = {}
    for i = #W.history, 1, -1 do
        local e = W.history[i]
        if e.name and e.link then
            local k = FirstName(e.name) .. "|" .. (e.link:match("|H(.-)|h") or "")
            if not lookup[k] then
                lookup[k] = e
            end
        end
    end
    local adopted, hasLoot = false, false
    for i = 1, frame:GetNumMessages() do
        local text, r, g, b, typeID, accessID, lineID = frame:GetMessageInfo(i)
        local rec = {
            text = text,
            r = r,
            g = g,
            b = b,
            typeID = typeID,
            accessID = accessID,
            lineID = lineID
        }
        if AdoptOwnLine(rec, lookup) then
            adopted = true
        end
        if IsMoneyType(typeID) then
            rec.money = true
        end
        if IsCraftType(typeID) then
            rec.craft = true
        end
        if not rec.entry and not rec.money and IsRollLine(text) then
            rec.roll = true
            -- a roll line the game printed in its own wording is already in the window: draw it again, laid out
            rec.drop = IsDropText(text)
            if ((rec.drop and db.showDrops) or (not rec.drop and db.showRolls)) and not text:find(ROLL_MARK, 1, true) then
                adopted = true
            end
        end
        if rec.entry or (type(text) == "string" and not issecretvalue(text) and
            (text:find("|Hitem:", 1, true) or text:find("|Hcurrency:", 1, true))) then
            hasLoot = true
        end
        Push(W, rec)
    end
    -- the day of the last loot line already in the window (a new one on another day gets a date line)
    W.sep = {}
    for i = #W.shadow, 1, -1 do
        local rec = W.shadow[i]
        if rec.entry and not rec.hidden and rec.entry.time then
            local inst = PlaceOfEntry(rec.entry) ~= "home" and rec.entry.instance or nil
            W.sep = {
                day = DayKey(rec.entry.time),
                inst = inst,
                loc = (inst and db.instanceSeparator) and inst or rec.entry.zone or inst
            }
            break
        end
    end
    if not W.hooked then
        W.hooked = true
        hooksecurefunc(frame, "AddMessage", function()
            Record(W)
        end)
    end
    -- after every drawing of the window by the game: are all the lines of this addon's one row?
    if not W.displayHooked and frame.AddOnDisplayRefreshedCallback then
        W.displayHooked = true
        frame:AddOnDisplayRefreshedCallback(function()
            pcall(CheckDisplayed, W)
            pcall(DrawDropTree, W)
        end)
        -- the fading of single lines is not a drawing of the window: the tree has to follow it on its own
        frame:HookScript("OnUpdate", function()
            pcall(ns.FollowTreeFade, W)
        end)
    end
    return adopted, hasLoot
end

-- After a reload the window is empty of loot unless another addon (Prat's scrollback...)
-- restored it. If there is none, the saved history of this window is put back in front of
-- whatever the window holds; the redraw that follows applies the current filters.
local function RestoreHistory(W)
    local n = #W.history
    -- how many of the newest history entries go back (the "chat window history lines" option)
    local count = math.max(0, math.min(tonumber(db.chatLines) or 1000, 1000))
    local rolls = W.rolls or {}
    if count == 0 or (n == 0 and #rolls == 0) then
        return false
    end
    local restored = {}
    -- "count" is a number of lines of the window, so enough of the newest entries go back that `count` of them
    -- are shown once the filters have had their say (the redraw then keeps the newest `count` lines).
    ns.RebuildLists()
    local first, shown = n + 1, 0
    for i = n, 1, -1 do
        first = i
        if ShouldShow(W.history[i], db) then
            shown = shown + 1
            if shown >= count then
                break
            end
        end
    end
    for i = first, n do
        restored[#restored + 1] = {
            entry = W.history[i],
            hidden = true
        }
    end
    -- the roll lines of the same stretch of time go back in between, in the order they happened
    local since = W.history[first] and W.history[first].time or 0
    local extra = {}
    for _, r in ipairs(rolls) do
        if (r.time or 0) >= since then
            if r.money then
                extra[#extra + 1] = {
                    money = true,
                    hidden = true,
                    text = r.text,
                    time = r.time
                }
            else
                extra[#extra + 1] = {
                    roll = true,
                    drop = IsDropText(r.text),
                    hidden = true,
                    text = r.text,
                    time = r.time,
                    boss = r.boss,
                    where = r.where
                }
            end
        end
    end
    if #extra > 0 then
        local function RecTime(rec)
            return (rec.entry and rec.entry.time) or rec.time or 0
        end
        -- the item a record is about: a loot entry has its link, a roll line has the link in its text
        local function ItemOf(rec)
            local text = rec.entry and rec.entry.link or rec.text
            return type(text) == "string" and not issecretvalue(text) and text:match("|Hitem:(%d+)") or nil
        end
        -- Times are whole seconds, and the roll and the loot of an item usually share one: the game rolls first and
        -- hands the item over after, so within the same second a roll line goes in front of the loot of its item.
        local function LootFirst(loot, roll)
            local lootTime, rollTime = RecTime(loot), RecTime(roll)
            if lootTime ~= rollTime then
                return lootTime < rollTime
            end
            local item = ItemOf(loot)
            return not (item and item == ItemOf(roll))
        end
        local merged, a, b = {}, 1, 1
        while a <= #restored or b <= #extra do
            if b > #extra or (a <= #restored and LootFirst(restored[a], extra[b])) then
                merged[#merged + 1] = restored[a]
                a = a + 1
            else
                merged[#merged + 1] = extra[b]
                b = b + 1
            end
        end
        restored = merged
        -- A drop saved before the place was kept with it: it was in the place of the loot that came after it
        -- (the same kill, within ten minutes), so the dungeon / raid is still said above "<boss> drops:".
        local following
        for i = #restored, 1, -1 do
            local rec = restored[i]
            if rec.entry then
                following = rec.entry
            elseif rec.roll and not rec.where and following and following.time and rec.time and following.time -
                rec.time <= 600 then
                rec.where = {
                    instance = following.instance,
                    instanceType = following.instanceType,
                    zone = following.zone,
                    place = following.place,
                    time = rec.time
                }
            end
        end
    end
    for _, rec in ipairs(W.shadow) do
        restored[#restored + 1] = rec
    end
    while #restored > MAX_SHADOW do
        table.remove(restored, 1)
    end
    W.shadow = restored
    return true
end

-- Clear the loot window and draw the record again under the current filters. `limit`: the window keeps only
-- its newest `limit` lines (and the record only what made them); used when the history is put back after a reload.
Replay = function(W, limit)
    if not W.active then
        return
    end
    local frame = W.frame
    -- where the window was scrolled to: drawing it again must not throw it back down to the newest lines
    local keepOffset = frame.GetScrollOffset and frame:GetScrollOffset() or 0
    -- During an encounter the window can hold secret lines that cannot be drawn again: then wait
    -- until the lockdown is over. Without such lines there is nothing to protect, so draw now.
    if InLockdown() then
        local hasSecret = false
        for _, rec in ipairs(W.shadow) do
            if rec.text ~= nil and issecretvalue(rec.text) then
                hasSecret = true
                break
            end
        end
        if hasSecret then
            if not W.replayWaiting then
                W.replayWaiting = true
                C_Timer.After(3, function()
                    W.replayWaiting = false;
                    Replay(W, limit)
                end)
            end
            return
        end
    end
    ns.RebuildLists()
    pcall(ns.KeepDropsTogether, W)
    local base = ScrollingMessageFrameSecureMixin or ScrollingMessageFrameMixin
    -- The widget's own AddMessage skips every addon hook: nothing is stamped or recorded twice.
    local drawAdd = (base and base.AddMessage) or frame.AddMessage
    -- The lines are worked out first and drawn at the end, so the newest `limit` of them can be picked.
    local queue, current = {}, nil
    local function rawAdd(_, ...)
        local message = {
            n = select("#", ...),
            ...
        }
        message.rec = current
        -- The last step: a line of this addon's, as it will stand in the window (what is in front of it
        -- included), is made to fit one row.
        local text = message[1]
        if type(text) == "string" and not issecretvalue(text) and
            (text:find(ROLL_MARK, 1, true) or text:find("|T" .. BLANK, 1, true)) then
            message[1] = FitWhole(W, text)
        end
        queue[#queue + 1] = message
    end
    local info = ChatTypeInfo.LOOT
    local entries = {}
    for _, e in ipairs(W.history) do
        entries[#entries + 1] = e
    end
    for _, rec in ipairs(W.shadow) do
        if rec.entry then
            entries[#entries + 1] = rec.entry
        end
    end
    ns.PrepareColumn(W, db, entries)
    -- Date lines are worked out again from the loot lines that are drawn.
    local st = {}
    local function Separator(e)
        local lines = ns.Separators(db, st, e)
        if lines then
            for _, text in ipairs(lines) do
                rawAdd(frame, text, info.r, info.g, info.b, info.id)
            end
        end
    end
    W.drawnWidth = frame:GetWidth() -- the width these lines are laid out for
    W.replaying = true
    W.dropEncounter, W.dropTime, W.dropPlain = nil, nil, nil -- the "<boss> drops:" lines are worked out again, in order
    frame:Clear()
    for _, rec in ipairs(W.shadow) do
        current = rec
        local ok, err = pcall(function() -- one bad line must never cost the lines after it
            local e = rec.entry
            if rec.money or rec.roll or rec.craft then
                -- money, roll and crafting lines: shown or not, by their checkboxes
                if (rec.money and db.showMoney) or
                    (rec.roll and ((rec.drop and db.showDrops) or (not rec.drop and db.showRolls))) or
                    (rec.craft and db.showCrafts) then
                    if rec.hidden then
                        local mi = (rec.money and ChatTypeInfo.MONEY) or (rec.craft and ChatTypeInfo.TRADESKILLS) or
                                       ChatTypeInfo.LOOT
                        local stamp = ns.ExternalTimestamps() and StampFor(rec.time) or ""
                        -- a roll line kept back while rolls were off comes out laid out like the others
                        local text = rec.text
                        if stamp ~= "" then
                            W.prefixWidth, W.prefixText = TextWidth(W, stamp), stamp
                        end
                        if rec.roll then
                            local ok, laidOut, header = pcall(FormatRollLine, W, text, rec.boss, rec.where, st)
                            if ok and laidOut then
                                text = laidOut
                                if header then
                                    rawAdd(frame, header, info.r, info.g, info.b, info.id)
                                end
                            end
                        end
                        if rec.money and db.moneyLines then
                            local okm, laid = pcall(FormatMoneyLine, W, text)
                            if okm and laid then
                                text = laid
                            end
                        end
                        rawAdd(frame, stamp .. text, mi.r, mi.g, mi.b, mi.id)
                    else
                        -- a roll line the game printed in its own wording is laid out like the others
                        local text = rec.text
                        if not rec.raw and W.dropHeaders and W.dropHeaders[text] then
                            W.dropEncounter = W.dropHeaders[text]
                        end
                        if rec.roll then
                            -- laid out again from the line as the game wrote it, with the current settings
                            if rec.raw and rec.prefix then
                                W.prefixWidth, W.prefixText = TextWidth(W, rec.prefix), rec.prefix
                            end
                            local ok, laidOut, header = pcall(FormatRollLine, W, rec.raw or text, rec.boss, rec.where,
                                st)
                            if ok and laidOut then
                                text = (rec.raw and rec.prefix or "") .. laidOut
                                if header then
                                    rawAdd(frame, header, info.r, info.g, info.b, info.id)
                                end
                            end
                        end
                        if rec.money and rec.raw then
                            -- a money line laid out here: laid out again from the line as the game wrote it
                            local okm, laid = pcall(FormatMoneyLine, W, rec.raw)
                            text = (rec.prefix or "") .. ((db.moneyLines and okm and laid) or rec.raw)
                        end
                        rawAdd(frame, text, rec.r, rec.g, rec.b, rec.typeID, rec.accessID, rec.lineID)
                    end
                end
            elseif not e then
                rawAdd(frame, rec.text, rec.r, rec.g, rec.b, rec.typeID, rec.accessID, rec.lineID)
            elseif ShouldShow(e, db) then
                Separator(e)
                if rec.hidden then
                    local stamp = ns.ExternalTimestamps() and StampFor(e.time) or ""
                    if stamp ~= "" then
                        W.prefixWidth, W.prefixText = TextWidth(W, stamp), stamp
                    end
                    rawAdd(frame, stamp .. FormatEntry(e, db, W, stamp ~= "" and TextWidth(W, stamp) or 0), info.r,
                        info.g, info.b, info.id)
                elseif rec.prefix then
                    W.prefixWidth = TextWidth(W, rec.prefix)
                    W.prefixText = rec.prefix
                    rawAdd(frame, rec.prefix .. FormatEntry(e, db, W, W.prefixWidth), rec.r, rec.g, rec.b, rec.typeID,
                        rec.accessID, rec.lineID)
                else
                    rawAdd(frame, rec.text, rec.r, rec.g, rec.b, rec.typeID, rec.accessID, rec.lineID)
                end
            end
        end)
        if not ok and not ns.reportedDrawError then
            ns.reportedDrawError = true
            Print("A line could not be drawn: " .. tostring(err))
        end
    end
    local firstLine = 1
    if limit and #queue > limit then
        firstLine = #queue - limit + 1
        -- the record keeps only what the window keeps
        local keep = queue[firstLine].rec
        if keep then
            for i, rec in ipairs(W.shadow) do
                if rec == keep then
                    local kept = {}
                    for j = i, #W.shadow do
                        kept[#kept + 1] = W.shadow[j]
                    end
                    W.shadow = kept
                    break
                end
            end
        end
    end
    for i = firstLine, #queue do
        local message = queue[i]
        drawAdd(frame, unpack(message, 1, message.n))
    end
    if keepOffset > 0 and frame.SetScrollOffset then
        frame:SetScrollOffset(keepOffset)
    end
    W.sep = st
    W.replaying = false
    ns.UpdateArrowHandle(W)
end

-- The sounds to choose from when an item that binds when equipped drops (sound kit numbers of the
-- game's own sounds).
local BOE_SOUNDS = {{31578, "Epic loot toast"}, {63971, "Legendary loot toast"}, {51561, "Warforged loot toast"},
                    {51402, "Raid loot toast"}, {50893, "Personal loot banner"}, {120, "Coin"}, {8960, "Ready check"},
                    {8959, "Raid warning"}, {878, "Quest complete"}, {73277, "World quest complete"},
                    {43502, "Mission success"}, {5274, "Auction window"}, {3175, "Map ping"}, {12889, "Alarm clock"},
                    {18019, "Battle.net toast"}}
ns.BOE_SOUNDS = BOE_SOUNDS

-- The sound is a sound kit number (BOE_SOUNDS) or the name of a sound in the shared media list (LibSharedMedia-3.0,
-- which other addons fill). A name that is not there any more (its addon is off) plays the first sound of BOE_SOUNDS.
function ns.PlayBoESound(id)
    id = id or db.boeSoundId or BOE_SOUNDS[1][1]
    if type(id) == "string" then
        local media = _G.LibStub and _G.LibStub("LibSharedMedia-3.0", true)
        local file = media and media:Fetch("sound", id, true)
        if file then
            PlaySoundFile(file, "Master")
            return
        end
        id = BOE_SOUNDS[1][1]
    end
    PlaySound(id, "Master")
end

-- An item that binds when equipped has dropped (shown, or hidden only because the "Binds when
-- equipped" box is off): if the sound is switched on, play the chosen sound (the item is read from
-- its tooltip, see BindingOf). The game may not know the item yet; then it is looked at again a
-- moment later.
local lastSounded = {}
local function NotifyBoE(entry)
    if not db.boeSound or entry.currency or entry.test then
        return
    end
    local link = entry.link
    local key = tostring(entry.name) .. link
    local now = GetTime()
    if lastSounded[key] and now - lastSounded[key] < 3 then
        return
    end -- the filter can see a line twice
    local kind = BindingOf(link, entry, {C_Item.GetItemInfo(link)})
    if kind == "boe" then
        lastSounded[key] = now
        ns.PlayBoESound()
    elseif kind == nil then
        C_Timer.After(1.5, function()
            if lastSounded[key] and GetTime() - lastSounded[key] < 3 then
                return
            end -- another loot window sounded it
            if db.boeSound and BindingOf(link, entry, {C_Item.GetItemInfo(link)}) == "boe" then
                lastSounded[key] = GetTime()
                ns.PlayBoESound()
            end
        end)
    end
end

-- A roll line is kept (in the saved variables) like a loot entry, so it is still there after a reload.
-- The line as the game wrote it goes in, and the boss's name when the game knows it: the line is laid out
-- again when it is drawn.
local MAX_ROLLS = 300

-- The list holds roll lines and money lines; each kind is trimmed on its own, so a lot of one cannot push the other out.
local function TrimKept(list, money)
    local count = 0
    for i = #list, 1, -1 do
        if (list[i].money and true or false) == money then
            count = count + 1
            if count > MAX_ROLLS then
                table.remove(list, i)
            end
        end
    end
end

-- Where a roll line came in: kept with it, so the dungeon / raid can be said above what the boss dropped. Also what
-- dropped it (`rank`, for a "<boss> drops:" line: elite or rare), worked out when the line comes.
local function CurrentWhere(text)
    local instance, instanceType = CurrentInstance()
    local rank, bossName = ns.RankOfDrop(text)
    return {
        bossName = bossName,
        instance = instance,
        instanceType = instanceType,
        time = time(),
        zone = GetZoneText() ~= "" and GetZoneText() or nil,
        place = SafePlaceKind(),
        rank = rank
    }
end

-- The filter of every loot window sees the same line, and the windows share one record: a line is kept once (the filter
-- can also run twice for one window).
local function FirstTime(kind, key)
    local kept = ns.kept
    if not kept then
        kept = {
            roll = {},
            rollCount = 0,
            money = {},
            moneyCount = 0
        }
        ns.kept = kept
    end
    if kept[kind][key] then
        return false
    end
    kept[kind][key] = true
    kept[kind .. "Count"] = kept[kind .. "Count"] + 1
    if kept[kind .. "Count"] > 500 then
        kept[kind], kept[kind .. "Count"] = {
            [key] = true
        }, 1
    end
    return true
end

local function RecordRoll(W, text, lineID, where)
    local list = W.rolls
    if not list then
        return
    end
    local key = lineID and not issecretvalue(lineID) and tostring(lineID) or nil
    if key and not FirstTime("roll", key) then
        return
    end
    local encounterID = text:match("^|HlootHistory:(%-?%d+)|h")
    list[#list + 1] = {
        text = text,
        time = time(),
        boss = encounterID and EncounterName(encounterID) or nil,
        where = where
    }
    TrimKept(list, false)
end

-- A money line is kept the same way (the line as the game wrote it), so it is still there after a reload.
local function RecordMoney(W, text, lineID)
    local list = W.rolls
    if not list then
        return
    end
    local key = lineID and not issecretvalue(lineID) and tostring(lineID) or nil
    if key and not FirstTime("money", key) then
        return
    end
    list[#list + 1] = {
        money = true,
        text = text,
        time = time()
    }
    TrimKept(list, true)
end

-- Everything a boss drops, not only what the player can roll on. The game writes a "[Loot]: [Item]" line only for the
-- items that go to a roll for this player; the loot history of the encounter lists them all. A moment after the last
-- drop line of a kill, every drop of that kill that got no line of its own is written as the game would have written it
-- ("[Loot]: [Item]") and goes through the same laying out, recording and header as the others (so it also comes back
-- after a reload).
do
    local function HistoryDrops(encounterID)
        local id = tonumber(encounterID)
        if not id or not (C_LootHistory and C_LootHistory.GetSortedDropsForEncounter) then
            return
        end
        local ok, drops = pcall(C_LootHistory.GetSortedDropsForEncounter, id)
        if ok and type(drops) == "table" then
            return drops
        end
    end

    local function ItemId(link)
        return type(link) == "string" and not issecretvalue(link) and link:match("|Hitem:(%d+)") or nil
    end

    -- The line is kept for after a reload too, among the roll lines, at the time of the kill.
    local function KeepDrop(W, text, key, kill)
        local list = W.rolls
        if not list or not FirstTime("roll", key) then
            return
        end
        local when = kill.where and kill.where.time or time()
        local at = #list
        while at > 0 and (list[at].time or 0) > when do
            at = at - 1
        end
        table.insert(list, at + 1, {
            text = text,
            time = when,
            boss = EncounterName(kill.id),
            where = kill.where
        })
        TrimKept(list, false)
    end

    local function Sweep(W, kill)
        if not W.active or not db.showDrops or db.showAllDrops == false then
            return
        end
        local drops = HistoryDrops(kill.id)
        if not drops then
            return
        end
        -- The added lines belong with the others of the kill, not at the end of the window (where what the players
        -- looted meanwhile would stand between them): they are put into the record right after the last drop line of
        -- the kill, and the window is drawn again from the record.
        local when = kill.where and kill.where.time or time()
        local marker = "|HlootHistory:" .. kill.id .. "|h"
        local added = false
        for _, d in ipairs(drops) do
            local listID = d.lootListID
            if listID ~= nil and ItemId(d.itemHyperlink) and not kill.matched[listID] and not kill.synth[listID] then
                kill.synth[listID] = true
                local text = marker .. "[Loot]|h: " .. d.itemHyperlink
                pcall(KeepDrop, W, text, "drop" .. kill.key .. ":" .. tostring(listID), kill)
                local shadow = W.shadow
                local at = #shadow
                for i = #shadow, 1, -1 do
                    local r = shadow[i]
                    local raw = r.roll and r.drop and (r.raw or r.text)
                    if type(raw) == "string" and not issecretvalue(raw) and raw:find(marker, 1, true) and
                        (not (r.where and r.where.time) or math.abs(r.where.time - when) <= 30) then
                        at = i
                        break
                    end
                end
                table.insert(shadow, at + 1, {
                    roll = true,
                    drop = true,
                    hidden = true,
                    text = text,
                    time = when,
                    boss = EncounterName(kill.id),
                    where = kill.where
                })
                added = true
            end
        end
        if added then
            Replay(W)
        end
    end

    -- What a player looted while a boss's drops were being written (an old record, or one that came back after a
    -- reload) stands below the drops of that kill, not in the middle of them. Only loot lines of players move; the order
    -- of everything else stays.
    function ns.KeepDropsTogether(W)
        local shadow = W.shadow
        local function Info(rec)
            if not (rec.roll and rec.drop) then
                return
            end
            local raw = rec.raw or rec.text
            if type(raw) ~= "string" or issecretvalue(raw) then
                return
            end
            return raw:match("^|HlootHistory:(%-?%d+)|h"), rec.where and rec.where.time
        end
        local function When(rec)
            return rec.entry and rec.entry.time or rec.time or rec.where and rec.where.time
        end
        local i = 1
        while i <= #shadow do
            local id, t = Info(shadow[i])
            local last = i
            if id then
                for j = i + 1, #shadow do
                    local other = shadow[j]
                    local jid, jt = Info(other)
                    local at = When(other)
                    if t and at and at > t + 30 then
                        break
                    end
                    if jid == id and (not (t and jt) or math.abs(jt - t) <= 30) then
                        last = j
                    end
                end
                if last > i then
                    local kept, moved = {}, {}
                    for j = i, last do
                        local rec = shadow[j]
                        if rec.entry and not rec.roll then
                            moved[#moved + 1] = rec
                        else
                            kept[#kept + 1] = rec
                        end
                    end
                    if #moved > 0 then
                        for k, rec in ipairs(kept) do
                            shadow[i + k - 1] = rec
                        end
                        for k, rec in ipairs(moved) do
                            shadow[i + #kept + k - 1] = rec
                        end
                    end
                end
            end
            i = last + 1
        end
    end

    -- A drop line of the game came for window W (`newKill`: it is the first of its kill).
    function ns.NoteDrop(W, text, where, newKill)
        if not db.showDrops or db.showAllDrops == false then
            return
        end
        local encounterID = text:match("^|HlootHistory:(%-?%d+)|h")
        local drops = encounterID and HistoryDrops(encounterID)
        if not drops or not drops[1] then
            return
        end
        W.dropKills = W.dropKills or {}
        local key = encounterID .. ":" .. tostring(drops[1].startTime)
        local kill = W.dropKills[key]
        if newKill or not kill then
            kill = {
                id = encounterID,
                key = key,
                where = where,
                matched = {},
                synth = {}
            }
            W.dropKills[key] = kill
        end
        -- the drop of the history this line is (the first of its item not taken yet)
        local item = ItemId(text)
        for _, d in ipairs(drops) do
            if d.lootListID ~= nil and ItemId(d.itemHyperlink) == item and not kill.matched[d.lootListID] and
                not kill.synth[d.lootListID] then
                kill.matched[d.lootListID] = true
                break
            end
        end
        W.dropSweep = (W.dropSweep or 0) + 1
        local token = W.dropSweep
        for _, delay in ipairs({1.5, 4}) do
            C_Timer.After(delay, function()
                if W.dropSweep == token then
                    pcall(Sweep, W, kill)
                end
            end)
        end
    end
end

local function LootFilter(self, event, ...)
    -- `fclWin` is a plain field on the chat frame: other chat addons (Prat) filter through
    -- a stand-in frame that copies the real one's fields, so this survives where
    -- `self == frame` does not. Frames that are not loot windows have none.
    local W = self.fclWin
    if not db or not W then
        return false
    end
    local text, playerName, _, _, _, _, _, _, _, _, lineID, guid = ...
    if event == "CHAT_MSG_MONEY" then
        if type(text) == "string" and not issecretvalue(text) then
            pcall(RecordMoney, W, text, lineID)
        end
        -- Money lines pass untouched (recognised by their chat type once they land) unless
        -- they are switched off: then they are hidden, but remembered like hidden loot.
        if db.showMoney and db.moneyLines and type(text) == "string" and not issecretvalue(text) then
            -- shown: laid out like a loot line ("Frogski -> 3g 22s 84c"); the line as the game wrote it goes with it
            local okm, laid = pcall(FormatMoneyLine, W, text, guid)
            if okm and laid then
                W.moneyRaw = W.moneyRaw or {}
                W.moneyRaw[laid] = {
                    raw = text
                }
                return false, laid, select(2, ...)
            end
        end
        if db.showMoney or type(text) ~= "string" or issecretvalue(text) then
            return false
        end
        local key = lineID and not issecretvalue(lineID) and tostring(lineID) or nil
        if not (key and W.hiddenSeen[key]) then
            if key then
                W.hiddenSeen[key] = true
            end
            Push(W, {
                money = true,
                hidden = true,
                text = text,
                time = time(),
                key = key
            })
        end
        return true
    end
    if event == "CHAT_MSG_TRADESKILLS" then
        -- Crafting lines: the same, with their own checkbox.
        if db.showCrafts or type(text) ~= "string" or issecretvalue(text) then
            return false
        end
        local key = lineID and not issecretvalue(lineID) and tostring(lineID) or nil
        if not (key and W.hiddenSeen[key]) then
            if key then
                W.hiddenSeen[key] = true
            end
            Push(W, {
                craft = true,
                hidden = true,
                text = text,
                time = time(),
                key = key
            })
        end
        return true
    end
    -- During an encounter the line is a secret value: it cannot be read, so it cannot be
    -- filtered either. Blizzard's own line is left exactly as it is.
    if issecretvalue(text) then
        return false
    end
    local entry = BuildEntry(text, playerName, guid, event == "CHAT_MSG_CURRENCY")
    if not entry then
        -- Not a received item. A roll line is hidden when rolls are switched off (but remembered,
        -- like hidden loot); anything else is left to the game. The items a boss drops for a roll
        -- ("[Loot]: [Item]") have their own switch.
        local isRoll = event == "CHAT_MSG_LOOT" and IsRollLine(text)
        if isRoll then
            pcall(ns.NoteWin, text)
        end
        local drop = isRoll and IsDropText(text) or false
        local rollShown = (drop and db.showDrops) or (not drop and db.showRolls)
        local where = isRoll and CurrentWhere(text) or nil
        if isRoll and not rollShown then
            local key = lineID and not issecretvalue(lineID) and tostring(lineID) or nil
            if not (key and W.hiddenSeen[key]) then
                if key then
                    W.hiddenSeen[key] = true
                end
                Push(W, {
                    roll = true,
                    drop = drop,
                    where = where,
                    hidden = true,
                    text = text,
                    time = time(),
                    key = key
                })
            end
            pcall(RecordRoll, W, text, lineID, where)
            return true
        end
        -- Roll lines that stay are laid out like loot lines: no "[Loot]:", the name in its class color.
        if rollShown and event == "CHAT_MSG_LOOT" then
            -- The filter can run twice for one line: the second run gets the same text back (the
            -- "<boss> drops:" line must not be lost to a second pass).
            local key = lineID and not issecretvalue(lineID) and tostring(lineID) or nil
            W.rollOut = W.rollOut or {}
            if key and W.rollOut[key] then
                return false, W.rollOut[key], select(2, ...)
            end
            W.sep = W.sep or {}
            local ok, laidOut, header = pcall(FormatRollLine, W, text, nil, where, W.sep)
            if ok and laidOut then
                if header then
                    AddRawLine(W, header)
                end
                if drop then
                    pcall(ns.NoteDrop, W, text, where, header ~= nil)
                end
                laidOut = LiveFit(W, laidOut)
                if key then
                    W.rollOutCount = (W.rollOutCount or 0) + 1
                    if W.rollOutCount > 200 then
                        W.rollOut, W.rollOutCount = {}, 1
                    end
                    W.rollOut[key] = laidOut
                end
                -- the line as the game wrote it goes with the laid-out one, until the window has recorded it
                W.rollRaw = W.rollRaw or {}
                local encounterID = text:match("^|HlootHistory:(%-?%d+)|h")
                W.rollRaw[laidOut] = {
                    raw = text,
                    boss = encounterID and EncounterName(encounterID) or nil,
                    where = where
                }
                pcall(RecordRoll, W, text, lineID, where)
                return false, laidOut, select(2, ...)
            end
        end
        if event == "CHAT_MSG_LOOT" and IsRollLine(text) then
            pcall(RecordRoll, W, text, lineID, where)
        end
        return false
    end
    if ns.WonByRoll(entry) then
        entry.won = true
    end
    if not ShouldShow(entry, db) then
        -- A hidden item that binds when equipped still sounds, when it was hidden only for that
        -- reason (every other filter would have let it through).
        if db.showBoE == false and db.boeSound then
            db.showBoE = true
            local others = ShouldShow(entry, db)
            db.showBoE = false
            if others then
                NotifyBoE(entry)
            end
        end
        -- Hidden, but remembered (once, even if the filter runs twice for the same line).
        local key = lineID and not issecretvalue(lineID) and tostring(lineID) or nil
        if not (key and W.hiddenSeen[key]) then
            if key then
                W.hiddenSeen[key] = true
            end
            Push(W, {
                entry = entry,
                hidden = true,
                key = key
            })
        end
        return true
    end
    NotifyBoE(entry)
    DateSeparatorBefore(W, entry)
    local formatted = LiveFit(W, FormatEntry(entry, db, W))
    local now = GetTime()
    for k, p in pairs(W.pending) do
        if now - p.t > 10 then
            W.pending[k] = nil
        end -- lines that never landed
    end
    W.pending[formatted] = {
        entry = entry,
        t = now
    }
    return false, formatted, select(2, ...)
end
AddFilter("CHAT_MSG_LOOT", LootFilter)
AddFilter("CHAT_MSG_CURRENCY", LootFilter)
AddFilter("CHAT_MSG_MONEY", LootFilter)
AddFilter("CHAT_MSG_TRADESKILLS", LootFilter)

---------------------------------------------------------------------------
-- History (everything is remembered, filters only decide what is shown)
---------------------------------------------------------------------------

local function TrimHistory(W)
    local max = math.max(MIN_HISTORY, math.min(MAX_HISTORY, db.maxHistory or 5000))
    while #W.history > max do
        table.remove(W.history, 1)
    end
end

-- Draws the last `limit` history entries of window W that pass cfg's filters into a
-- history window's own message frame. Optional `isMatch(entry)` marks matching lines with
-- a green arrow (and `current`, the number of one match, draws that whole line green);
-- returns the positions (1 = oldest line drawn) of the marked lines and the number of
-- lines drawn.
local MARK_ON = "|cff33ff33>>|r "
function ns.RenderTo(W, target, cfg, limit, isMatch, current)
    ns.RebuildLists()
    target:Clear()
    local history = W.history
    local visible = {}
    for i = #history, 1, -1 do
        if ShouldShow(history[i], cfg) then
            visible[#visible + 1] = history[i]
            if #visible >= limit then
                break
            end
        end
    end

    ns.PrepareColumn(W, cfg, visible)
    local matches, drawn = {}, 0
    local st = {}
    for i = #visible, 1, -1 do
        -- a date line between two lines of different days (it takes a line of its own)
        local lines = ns.Separators(cfg, st, visible[i])
        if lines then
            for _, text in ipairs(lines) do
                target:AddMessage(MARK_OFF .. text)
                drawn = drawn + 1
            end
        end
        local text = FormatEntry(visible[i], cfg, W)
        drawn = drawn + 1
        if isMatch and isMatch(visible[i]) then
            matches[#matches + 1] = drawn
            if #matches == current then
                text = MARK_ON .. text:gsub("|c%x%x%x%x%x%x%x%x", "|cff33ff33") -- the match the view is on
            else
                text = MARK_ON .. text
            end
        else
            text = MARK_OFF .. text -- keeps every line at the same indent as the marked ones
        end
        target:AddMessage(text)
    end
    return matches, drawn, st
end

-- The loot windows that are active right now, lowest chat window id first.
function ns.ActiveWindows()
    local list = {}
    for _, W in pairs(windows) do
        if W.active then
            list[#list + 1] = W
        end
    end
    table.sort(list, function(a, b)
        return a.id < b.id
    end)
    return list
end

-- A change in the settings redraws every loot window from its record (hidden lines come
-- back, shown ones can go) and the history windows.
function ns.Refresh()
    for _, W in ipairs(ns.ActiveWindows()) do
        TrimHistory(W)
        ApplyWrapMode(W)
        Replay(W)
        if ns.OnHistoryChanged then
            ns.OnHistoryChanged(W)
        end
    end
end

-- Every setting back to its default. The saved loot history, the gear position and the sizes of
-- the windows are not settings and stay.
-- The settings of the ready-made profiles ("Dungeon", "Raid", "Show everything"); nil for any other
-- name. They are what a new install starts with and what "Restore defaults" brings such a profile
-- back to.
local function PresetSettings(name)
    local p = {}
    if name == "Dungeon" or name == "Raid" then
        -- they hide the usual clutter; the raid one also hides soulbound and warbound items and
        -- shows the loot rolls; the dungeon one shows the greens and the money lines
        CopyDefaults(SETTING_DEFAULTS, p)
        p.showSelf, p.showOthers = true, true
        p.instanceSeparator, p.zoneSeparator = true, true
        p.qualities = {
            [0] = false,
            [1] = false,
            [2] = name == "Dungeon",
            [3] = true,
            [4] = true,
            [5] = true
        }
        p.hideClass = {
            [0] = true,
            [1] = true,
            [3] = true,
            [7] = true,
            [12] = true,
            [17] = true,
            [20] = true,
            currency = true
        }
        p.showSoulbound, p.showWarbound, p.showBoE = name ~= "Raid", name ~= "Raid", true
        p.showReceived, p.showCrafts = false, false
        p.showMoney = name == "Dungeon"
        p.showRolls = name == "Raid"
        p.showDrops = true
        p.minItemLevel = 0
        p.boeSound = name == "Raid"
        p.boeSoundId = 63971 -- Legendary loot toast
        if name == "Raid" then
            -- no money lines here: their style stays the plain one
            p.moneyLines, p.moneyIcons, p.moneyIconSize = false, false, 14
        end
        return p
    elseif name == "Show everything" then
        -- every line, every quality, no filter
        CopyDefaults(SETTING_DEFAULTS, p)
        p.showSelf, p.showOthers = true, true
        p.qualities = {
            [0] = true,
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true,
            [5] = true
        }
        p.minItemLevel = 0
        p.hideClass = {}
        p.blacklist, p.whitelist = "", ""
        p.showSoulbound, p.showWarbound, p.showBoE = true, true, true
        p.showReceived, p.showMoney, p.showRolls, p.showCrafts = true, true, true, true
        p.showDrops = true
        p.separatorIndent = 1
        p.boeSound, p.boeSoundId = true, 63971 -- Legendary loot toast
        return p
    end
end

-- The profile in use back to its own defaults: a ready-made profile to what it started as, any
-- other profile to the plain defaults. The History window's settings go back to theirs too.
function ns.RestoreDefaults()
    local preset = PresetSettings(profileName)
    for k in pairs(DEFAULTS) do
        if k ~= "histories" and k ~= "winHist" and k ~= "winRolls" and k ~= "gearPos" and k ~= "townZones" and k ~=
            "customIcons" and not CHAR_KEYS[k] then
            db[k] = nil
        end
    end
    CopyDefaults(DEFAULTS, db)
    if preset then
        for k, v in pairs(preset) do
            db[k] = v
        end
    end
    ns.RebuildLists()
    ns.Refresh()
end

function ns.GetHistoryCount(W)
    return #W.history
end

function ns.ClearHistory(W)
    wipe(W.history)
    if W.rolls then
        wipe(W.rolls)
    end
    TrimHistory(W)
    if ns.OnHistoryChanged then
        ns.OnHistoryChanged(W)
    end
end

function ns.WindowName(W)
    return (GetChatWindowInfo(W.id)) or ("Chat " .. W.id)
end

local function OnLoot(text, playerName, guid, isCurrency)
    local entry = BuildEntry(text, playerName, guid, isCurrency)
    if not entry then
        return
    end
    if ns.WonByRoll(entry) then
        entry.won = true
    end
    -- the loot windows share one history: the line is written once, whatever the number of windows
    local W = ns.ActiveWindows()[1]
    if not W then
        return
    end
    W.history[#W.history + 1] = entry
    TrimHistory(W)
    if ns.OnNewEntry then
        ns.OnNewEntry(entry)
    end
    pcall(ns.NoteUpgrade, entry)
end

---------------------------------------------------------------------------
-- Which chat windows are loot windows (follows the chat settings live)
---------------------------------------------------------------------------

local function HasLootGroup(frame)
    return frame and frame.messageTypeList and tContains(frame.messageTypeList, "LOOT") or false
end

-- Where the gear sits in a window: dragged anywhere inside it; the spot is saved per
-- window (offset from the window's top left corner).
local function MakeGear(W)
    local frame = W.frame
    local gear = ns.AddGearButton(frame, function(self)
        if self.fclDragged then
            self.fclDragged = false
            return
        end -- the release of a drag is not a click
        ns.ToggleQuickFilters(self, db, ns.Refresh, true, W)
    end, _G[frame:GetName() .. "Background"])

    local function Place(x, y)
        gear:ClearAllPoints()
        gear:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
    end
    -- The saved spot stays as it is, but the gear is always drawn inside the window: a window made smaller
    -- (in Edit Mode, say) would otherwise leave it outside.
    local function Fit(width, height)
        local pos = db.gearPos[W.id]
        if not pos then
            return
        end
        local x = math.max(0, math.min(pos.x, (width or frame:GetWidth()) - gear:GetWidth()))
        local y = math.min(0, math.max(pos.y, -((height or frame:GetHeight()) - gear:GetHeight())))
        Place(x, y)
    end
    Fit()
    frame:HookScript("OnSizeChanged", function(_, width, height)
        Fit(width, height)
    end)
    gear:RegisterForDrag("LeftButton")
    gear:HookScript("OnMouseDown", function(self)
        self.fclDragged = false
    end)
    -- The gear follows the mouse while it is dragged, but never leaves the window: the spot under the
    -- mouse is limited to the window's area at every moment (it is not moved by the game's own
    -- dragging, which would let it out and only pull it back afterwards).
    gear:SetScript("OnDragStart", function(self)
        self.fclDragged = true
        local scale = self:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        local grabX, grabY = cx / scale - self:GetLeft(), cy / scale - self:GetTop() -- where the gear was taken
        local fade = self:GetScript("OnUpdate") -- the gear fades with the window; put back at the end
        self.fclFade = fade
        self:SetScript("OnUpdate", function(button)
            if fade then
                fade(button)
            end
            local mx, my = GetCursorPosition()
            local left, top = frame:GetLeft(), frame:GetTop()
            if not (left and top) then
                return
            end
            local x = mx / scale - grabX - left
            local y = my / scale - grabY - top
            x = math.max(0, math.min(x, frame:GetWidth() - button:GetWidth()))
            y = math.min(0, math.max(y, -(frame:GetHeight() - button:GetHeight())))
            button.fclX, button.fclY = x, y
            Place(x, y)
        end)
    end)
    gear:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", self.fclFade)
        self.fclFade = nil
        if self.fclX then
            db.gearPos[W.id] = {
                x = self.fclX,
                y = self.fclY
            }
            self.fclX, self.fclY = nil, nil
        end
    end)
    return gear
end

-- The loot history and the roll lines of a character are one for all its loot windows: kept once, in the saved
-- variables, and every loot window reads and writes the same lists. (Before, each window had lists of its own, and the
-- same loot was written to each of them: those lists are put together the first time, a line that is in several of them
-- once.)
local LoadHistory
do
    -- the lists put together: the longest is the base, and of the others only what the base lacks is added (a line the same
    -- in two lists is one line, a line that is twice in a list stays twice), in the order of the time they came
    local function MergeLists(lists, keyOf)
        local sets = {}
        for _, list in ipairs(lists) do
            if type(list) == "table" and #list > 0 then
                sets[#sets + 1] = list
            end
        end
        if #sets == 0 then
            return {}
        end
        table.sort(sets, function(a, b)
            return #a > #b
        end)
        local merged = sets[1]
        if #sets == 1 then
            return merged
        end
        local have = {}
        for _, item in ipairs(merged) do
            local key = keyOf(item)
            have[key] = (have[key] or 0) + 1
        end
        local added = false
        for i = 2, #sets do
            local seen = {}
            for _, item in ipairs(sets[i]) do
                local key = keyOf(item)
                seen[key] = (seen[key] or 0) + 1
                if seen[key] > (have[key] or 0) then
                    have[key] = seen[key]
                    merged[#merged + 1] = item
                    added = true
                end
            end
        end
        if added then
            local order = {}
            for i, item in ipairs(merged) do
                order[item] = i
            end
            table.sort(merged, function(a, b)
                local ta, tb = a.time or 0, b.time or 0
                if ta ~= tb then
                    return ta < tb
                end
                return order[a] < order[b] -- lines of the same second keep their places
            end)
        end
        return merged
    end

    local function HistoryKey(e)
        return (e.time or 0) .. "|" .. tostring(e.name) .. "|" .. tostring(e.link) .. "|" .. tostring(e.count)
    end

    local function RollKey(r)
        return (r.time or 0) .. "|" .. (r.money and "m" or "r") .. "|" .. tostring(r.text)
    end

    -- the lists a character has by chat window number are put together and taken out of the table
    local function Gather(byChar, keyOf)
        local ids, lists = {}, {}
        for id in pairs(byChar) do
            if type(id) == "number" then
                ids[#ids + 1] = id
            end
        end
        table.sort(ids)
        for _, id in ipairs(ids) do
            lists[#lists + 1] = byChar[id]
            byChar[id] = nil
        end
        return MergeLists(lists, keyOf)
    end

    LoadHistory = function(W)
        local byChar = db.winHist[charKey]
        if not byChar then
            byChar = {}
            db.winHist[charKey] = byChar
        end
        if type(byChar.shared) ~= "table" then
            byChar.shared = Gather(byChar, HistoryKey)
        end
        local rollsByChar = db.winRolls[charKey]
        if not rollsByChar then
            rollsByChar = {}
            db.winRolls[charKey] = rollsByChar
        end
        if type(rollsByChar.shared) ~= "table" then
            rollsByChar.shared = Gather(rollsByChar, RollKey)
        end
        W.history, W.rolls = byChar.shared, rollsByChar.shared
    end
end

-- Whole names of players. Entries saved before the whole name was kept hold only the last word of a two-word name
-- ("Forever" for "Bolty Forever", on Forever every player has that word), and the guid beside it is the one thing
-- that says who it was. The whole name of a guid is remembered whenever it is seen (the loot line, the group's
-- roster, what the game knows), and the entries saved with the last word alone get it back.
do
    local function Usable(s)
        return type(s) == "string" and s ~= "" and not issecretvalue(s)
    end

    local function Store()
        FrogskisChatLootDB.names = FrogskisChatLootDB.names or {}
        return FrogskisChatLootDB.names
    end

    function ns.LearnName(guid, name)
        if not (Usable(guid) and Usable(name)) then
            return
        end
        local short = Ambiguate(name, "short")
        if short:find("^%S+%s+%S+") then -- one word needs no remembering
            Store()[guid] = short
        end
    end

    function ns.LearnNames()
        local units = {"player"}
        if IsInRaid and IsInRaid() then
            for i = 1, GetNumGroupMembers() do
                units[#units + 1] = "raid" .. i
            end
        elseif IsInGroup and IsInGroup() then
            for i = 1, GetNumSubgroupMembers() do
                units[#units + 1] = "party" .. i
            end
        end
        for _, unit in ipairs(units) do
            if UnitExists(unit) then
                local guid = UnitGUID(unit)
                local name = (GetUnitName and GetUnitName(unit, true)) or UnitName(unit)
                pcall(ns.LearnName, guid, name)
            end
        end
    end

    local function WholeNameOf(guid)
        local known = Store()[guid]
        if known then
            return known
        end
        local ok, found = pcall(function()
            return (select(6, GetPlayerInfoByGUID(guid)))
        end)
        if ok and Usable(found) then
            ns.LearnName(guid, found)
            return Store()[guid]
        end
    end

    -- true when an entry got its whole name
    function ns.HealNames(W)
        local changed, looked = false, {}
        for _, e in ipairs(W.history or {}) do
            if not e.isSelf and Usable(e.guid) and Usable(e.name) and not e.name:find("%s") then
                if looked[e.guid] == nil then
                    looked[e.guid] = WholeNameOf(e.guid) or false
                end
                local whole = looked[e.guid]
                if whole and whole:match("(%S+)%s*$") == e.name then
                    e.name = whole
                    changed = true
                end
            end
        end
        return changed
    end

    -- every loot window's history looked at again (the group changed); the windows are drawn again only if a name changed
    function ns.HealAllNames()
        pcall(ns.LearnNames)
        local changed = false
        for _, W in ipairs(ns.ActiveWindows()) do
            local ok, healed = pcall(ns.HealNames, W)
            changed = changed or (ok and healed)
        end
        if changed then
            ns.Refresh()
        end
    end
end

-- A chat window got Loot ticked: it becomes a loot window.
-- How another addon stamps a line is found out without waiting for a loot line: a line with a mark goes through the
-- window's own AddMessage (so the other addon puts its time in front of it), what stands in front of the mark is
-- learned, and the line is taken out again at once, before anything can be drawn.
local STAMP_MARK = "FCLSTAMP"
local function ProbeStamp(W)
    local frame = W.frame
    if not ns.ExternalTimestamps() or InLockdown() or not frame.RemoveMessagesByPredicate then
        return
    end
    W.replaying = true -- the window's own hook must not record this line
    pcall(function()
        frame:AddMessage(STAMP_MARK)
        local text = frame:GetMessageInfo(frame:GetNumMessages())
        if type(text) == "string" and not issecretvalue(text) then
            local at = text:find(STAMP_MARK, 1, true)
            if at and at > 1 then
                LearnStamp(text:sub(1, at - 1), time())
            end
        end
    end)
    pcall(frame.RemoveMessagesByPredicate, frame, function(message)
        return type(message) == "string" and not issecretvalue(message) and message:find(STAMP_MARK, 1, true) ~= nil
    end)
    W.replaying = false
end

local function Activate(frame)
    local id = frame:GetID()
    local W = windows[id]
    if not W then
        W = {
            frame = frame,
            id = id,
            shadow = {},
            hiddenSeen = {},
            pending = {},
            widthCache = {},
            columns = {}
        }
        windows[id] = W
    end
    if W.active then
        return
    end
    W.active = true
    frame.fclWin = W
    ApplyWrapMode(W)
    ProbeStamp(W)
    LoadHistory(W)
    pcall(ns.LearnNames)
    pcall(ns.HealNames, W) -- entries saved with the last word of a two-word name get the whole one back
    pcall(ns.MarkSavedWins, W)
    pcall(ns.MarkSavedUpgrades, W)
    local adopted, hasLoot = StartShadow(W)
    local restored = not hasLoot and RestoreHistory(W) -- nothing brought the history back: do it
    ns.PrepareColumn(W, db, W.history) -- names seen in earlier sessions set the column width
    -- the lines already in the window, laid out like new ones; after a restore the window holds `chatLines` lines
    if adopted or restored then
        Replay(W, restored and math.max(1, math.min(tonumber(db.chatLines) or 1000, 1000)) or nil)
    end
    ns.SetupTooltips(frame)
    if not W.sizeHooked then
        W.sizeHooked = true
        W.lastWidth = frame:GetWidth()
        W.drawnWidth = W.drawnWidth or W.lastWidth
        frame:HookScript("OnSizeChanged", function(_, width)
            -- compared with the width the lines were last laid out for, not with the previous step of a drag:
            -- a resize is many small steps, and the last one must still be drawn again
            if W.drawnWidth and math.abs(width - W.drawnWidth) > 2 and not W.resizeQueued then
                W.resizeQueued = true
                C_Timer.After(0.5, function()
                    W.resizeQueued = false
                    Replay(W)
                end)
            end
            W.lastWidth = width
        end)
    end
    if not W.gear then
        W.gear = MakeGear(W)
    end
    W.gear:Show()
end

local StopTest

-- Loot was unticked in a chat window: the gear and the history window go, the filter lets go.
local function Deactivate(W)
    StopTest(W)
    W.active = false
    ApplyWrapMode(W)
    ns.UpdateArrowHandle(W)
    pcall(DrawDropTree, W)
    W.frame.fclWin = nil
    if W.gear then
        W.gear:Hide()
    end
    if ns.CloseHistory then
        ns.CloseHistory(W)
    end
end

-- The first run after the update: the single history and gear position of the old version
-- go to the window that was the loot window ("Loot" if there is one, else the lowest).
local migrated = false
local function Migrate(ids)
    if migrated or #ids == 0 then
        return
    end
    migrated = true
    local first = ids[1]
    for _, id in ipairs(ids) do
        if (GetChatWindowInfo(id)) == "Loot" then
            first = id
            break
        end
    end
    local old = db.histories[charKey]
    if old and #old > 0 then
        db.winHist[charKey] = db.winHist[charKey] or {}
        if not db.winHist[charKey][first] then
            db.winHist[charKey][first] = old
        end
    end
    db.histories[charKey] = nil
    if db.gearPos.x then
        db.gearPos = {
            [first] = {
                x = db.gearPos.x,
                y = db.gearPos.y
            }
        }
    end
end

local FRAME_HOOKS = {"AddMessageGroup", "RemoveMessageGroup", "RegisterForMessages", "UnregisterAllMessageGroups",
                     "RemoveAllMessageGroups", "AddSingleMessageType"}
local GLOBAL_HOOKS = {"FCF_Close", "FCF_DockFrame", "FCF_UnDockFrame", "FCF_OpenNewWindow", "ChatFrame_AddMessageGroup",
                      "ChatFrame_RemoveMessageGroup"}

local scanQueued, scanHooked, hintShown = false, false, false

local function ScanNow()
    scanQueued = false
    if not db or not charKey then
        return
    end
    local want, ids = {}, {}
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local frame = _G["ChatFrame" .. i]
        if frame then
            -- Every chat window reports changes of its message settings (once per frame).
            if not frame.fclScanHooked then
                frame.fclScanHooked = true
                for _, name in ipairs(FRAME_HOOKS) do
                    if type(frame[name]) == "function" then
                        hooksecurefunc(frame, name, ns.Scan)
                    end
                end
            end
            local _, _, _, _, _, _, shown, _, docked = GetChatWindowInfo(i)
            if (shown or docked) and HasLootGroup(frame) then
                want[frame:GetID()] = frame
                ids[#ids + 1] = frame:GetID()
            end
        end
    end
    table.sort(ids)
    Migrate(ids)
    -- Every chat window that has Loot ticked is a loot window, and they all work as one: the same settings and one
    -- history (see LoadHistory).
    for _, W in pairs(windows) do
        if W.active and not want[W.id] then
            Deactivate(W)
        end
    end
    for _, frame in pairs(want) do
        Activate(frame)
    end
    if #ids == 0 and not hintShown then
        hintShown = true
        Print("No chat window with Loot enabled found. Right-click a chat tab > Settings > tick Loot.")
    end
end

-- Settings of a chat window change in many small steps: look once, a moment later.
function ns.Scan()
    if not scanQueued then
        scanQueued = true
        C_Timer.After(0.1, ScanNow)
    end
end

local function HookScanning()
    if scanHooked then
        return
    end
    scanHooked = true
    for _, name in ipairs(GLOBAL_HOOKS) do
        if type(_G[name]) == "function" then
            hooksecurefunc(name, ns.Scan)
        end
    end
end

---------------------------------------------------------------------------
-- Test output: a few sample lines run through the same filters and formatting
---------------------------------------------------------------------------

-- The test output: a big set of sample lines picked so that EVERY option can be tried: each quality,
-- each item type, each binding (soulbound, warbound, binds when equipped), gear of a low and a high
-- item level, loot of yours and of others, items handed over (trade, mail...), crafted items,
-- money lines, roll lines and crafting lines, spread over three days (for the date line). The items
-- are real ones from your saved loot histories (plus some well known ones); what they are
-- (type, quality, binding, item level) is looked up when the test starts, so what you see is what
-- the filters really do. The lines are part of the window's record: they follow every filter, live.
local TEST_CLASSES = {0, 1, 2, 3, 4, 7, 9, 12, 15, 17, 19, 20, "currency"}
local TEST_NAMES = {{"Leeroyjenkin", "PALADIN"}, {"Thrallmart", "SHAMAN"}, {"Ragnaroast", "MAGE"},
                    {"Murlocbucks", "ROGUE"}, {"Guldandruff", "WARLOCK"}, {"Needonall", "ROGUE"},
                    {"Jainafonda", "MAGE"}, {"Sylvanaswift", "HUNTER"}, {"Zugzugmom", "WARRIOR"},
                    {"Barrenschat", "PRIEST"}, {"Magtheridude", "WARLOCK"}, {"Khadgarlic", "MAGE"},
                    {"Sheepmepls", "MAGE"}, {"Illidunno", "WARLOCK"}, {"Dkpforever", "PALADIN"},
                    {"Boomkinboom", "DRUID"}, {"Anduinsane", "PRIEST"}, {"Pallytankme", "PALADIN"},
                    {"Tyrandelion", "DRUID"}, {"Mrglmrgl", "SHAMAN"}, {"Nozdormuffin", "WARRIOR"},
                    {"Healzplzthx", "PRIEST"}, {"Hearthstoned", "MAGE"}, {"Wipeonpull", "WARRIOR"}}
-- { item ID, name, quality }: used when the histories do not have enough
local TEST_EXTRA = {{2934, "Ruined Leather Scraps", 0}, {2589, "Linen Cloth", 1}, {2592, "Wool Cloth", 1},
                    {4306, "Silk Cloth", 1}, {2318, "Light Leather", 1}, {2319, "Medium Leather", 1},
                    {2672, "Stringy Wolf Meat", 1}, {6948, "Hearthstone", 1}, {2455, "Minor Mana Potion", 1},
                    {1251, "Linen Bandage", 1}, {4496, "Small Brown Pouch", 1}, {5498, "Small Lustrous Pearl", 2},
                    {774, "Malachite", 2}, {1210, "Shadowgem", 2}, {7909, "Aquamarine", 2}, {12811, "Righteous Orb", 2},
                    {12940, "Dal'Rend's Sacred Charge", 3}, {11815, "Hand of Justice", 3},
                    {14551, "Edgemaster's Handguards", 3}, {19364, "Ashkandi, Greatsword of the Brotherhood", 4},
                    {17076, "Bonereaver's Edge", 4}, {18348, "Quel'Serrar", 4},
                    {19019, "Thunderfury, Blessed Blade of the Windseeker", 5},
                    {17182, "Sulfuras, Hand of Ragnaros", 5}, {2092, "Worn Dagger", 1}, {6096, "Apprentice's Shirt", 1},
                    {14152, "Robe of the Archmage", 4}, {929, "Healing Potion", 1}, {4241, "Green Woolen Bag", 2}}
-- { currency ID, name, quality }
local TEST_CURRENCIES = {{3008, "Valorstones", 3}, {2917, "Gilded Harbinger Crest", 4}, {1792, "Honor", 1}}

-- Instance names for the instance lines of the sample: one dungeon and one raid are picked each time.
local TEST_DUNGEONS = {"The Stonevault", "Ara-Kara, City of Echoes", "City of Threads", "The Dawnbreaker",
                       "Cinderbrew Meadery", "Darkflame Cleft", "Priory of the Sacred Flame", "The Rookery",
                       "Operation: Floodgate", "Eco-Dome Al'dani", "Halls of Atonement", "Tazavesh, the Veiled Market"}
local TEST_RAIDS = {"Liberation of Undermine", "Nerub-ar Palace", "Manaforge Omega", "Amirdrassil, the Dream's Hope",
                    "Aberrus, the Shadowed Crucible", "Vault of the Incarnates", "Sepulcher of the First Ones",
                    "Castle Nathria", "Sanctum of Domination", "Ny'alotha, the Waking City"}

local TEST_ZONES = {"Dornogal", "Isle of Dorn", "The Ringing Deeps", "Hallowfall", "Azj-Kahet", "Orgrimmar",
                    "Stormwind City", "Valdrakken", "Silvermoon City"}

local function Shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

-- Candidate items with what the filters look at: type, quality, binding, item level.
local function TestPool()
    local pool, seen, fromHistory = {}, {}, {}
    for _, W in ipairs(ns.ActiveWindows()) do
        for _, e in ipairs(W.history) do
            if e.link and not seen[e.link] then
                seen[e.link] = true
                fromHistory[#fromHistory + 1] = e
            end
        end
    end
    Shuffle(fromHistory)
    for i = 1, math.min(#fromHistory, 400) do
        local e = fromHistory[i]
        local quality = math.min(QualityFromLink(e.link, e), 5)
        pool[#pool + 1] = {
            link = e.link,
            quality = quality,
            known = e.quality,
            currency = e.currency
        }
    end
    for _, x in ipairs(TEST_EXTRA) do
        local link = ("|Hitem:%d::::::::::::|h[%s]|h"):format(x[1], x[2])
        if not seen[link] then
            seen[link] = true
            pool[#pool + 1] = {
                link = link,
                quality = x[3],
                known = x[3]
            }
        end
    end
    for _, x in ipairs(TEST_CURRENCIES) do
        pool[#pool + 1] = {
            link = ("|Hcurrency:%d|h[%s]|h"):format(x[1], x[2]),
            quality = x[3],
            known = x[3],
            currency = true
        }
    end
    for _, item in ipairs(pool) do
        if item.currency then
            item.class = "currency"
        else
            local id = tonumber(item.link:match("|Hitem:(%d+)"))
            if id then
                item.class = select(6, C_Item.GetItemInfoInstant(id))
            end
            local info = {C_Item.GetItemInfo(item.link)}
            item.ilvl = info[4]
            item.binding = BindingOf(item.link, {}, info)
        end
    end
    return pool
end

local function TestEntry(item)
    -- `known` is nil while the game has not loaded the item: its quality is then looked up when drawn
    local e = {
        link = item.link,
        count = 1,
        quality = item.known,
        currency = item.currency
    }
    if math.random(3) == 1 then
        e.name, e.isSelf = UnitName("player"), true
    else
        local who = TEST_NAMES[math.random(#TEST_NAMES)]
        e.name, e.class, e.isSelf = who[1], who[2], false
    end
    return e
end

local function GameText(global, ...)
    local format = _G[global]
    if type(format) ~= "string" then
        return nil
    end
    local ok, text = pcall(string.format, format, ...)
    return ok and text or nil
end

-- The sample lines (records for the window): a few of everything, see the comment above.
local function BuildTestRecs()
    local pool = TestPool()
    local order = {}
    for i = 1, #pool do
        order[i] = i
    end
    Shuffle(order)

    local used, items = {}, {}
    local function Take(match, n)
        local taken = 0
        for _, i in ipairs(order) do
            if taken >= n then
                break
            end
            local item = pool[i]
            if not used[i] and match(item) then
                used[i] = true
                items[#items + 1] = item
                taken = taken + 1
            end
        end
    end
    for q = 0, 5 do
        Take(function(it)
            return it.quality == q
        end, 2)
    end
    for _, class in ipairs(TEST_CLASSES) do
        Take(function(it)
            return it.class == class
        end, 2)
    end
    for _, kind in ipairs({"soulbound", "boe", "warbound"}) do
        Take(function(it)
            return it.binding == kind
        end, 2)
    end
    -- the gear with the lowest and the highest item level (the minimum item level filter)
    local gear = {}
    for i, it in ipairs(pool) do
        if (it.class == 2 or it.class == 4) and it.ilvl and it.ilvl > 1 then
            gear[#gear + 1] = i
        end
    end
    table.sort(gear, function(a, b)
        return pool[a].ilvl < pool[b].ilvl
    end)
    for _, i in ipairs({gear[1], gear[#gear]}) do
        if i and not used[i] then
            used[i] = true
            items[#items + 1] = pool[i]
        end
    end

    local recs = {}
    for _, item in ipairs(items) do
        recs[#recs + 1] = {
            entry = TestEntry(item),
            hidden = true,
            test = true
        }
    end
    -- the same kind of lines handed over (trade, mail...) and crafted
    for _, flag in ipairs({"received", "crafted"}) do
        for _ = 1, 3 do
            local item = items[math.random(#items)]
            if item then
                local e = TestEntry(item)
                e[flag] = true
                recs[#recs + 1] = {
                    entry = e,
                    hidden = true,
                    test = true
                }
            end
        end
    end

    -- money, roll and crafting lines (the game's own wording)
    local link = items[1] and items[1].link or "|Hitem:2589::::::::::::|h[Linen Cloth]|h"
    local who = TEST_NAMES[math.random(#TEST_NAMES)][1]
    local function Line(flag, text)
        if text then
            recs[#recs + 1] = {
                [flag] = true,
                hidden = true,
                test = true,
                text = text
            }
        end
    end
    for _ = 1, 2 do
        local coinText = (C_CurrencyInfo and C_CurrencyInfo.GetCoinText) or _G.GetCoinText
        local coins = coinText and coinText(math.random(1, 90000), " ") or "1 Silver"
        Line("money", GameText("YOUR_LOOT_SHARE", coins) or ("Your share of the loot is " .. coins .. "."))
    end
    Line("roll", GameText("LOOT_ROLL_NEED_SELF", link))
    Line("roll", GameText("LOOT_ROLL_ROLLED_NEED", math.random(1, 100), link, who))
    Line("roll", GameText("LOOT_ROLL_PASSED", who, link))
    Line("roll", GameText("LOOT_ROLL_YOU_WON", link))
    Line("craft", GameText("TRADESKILL_LOG_THIRDPERSON", who, link))
    Line("craft", GameText("TRADESKILL_LOG_FIRSTPERSON", link))

    -- in a random order, over three days (so the date line shows)
    Shuffle(recs)
    local now, n = time(), #recs
    local testZones = Shuffle({unpack(TEST_ZONES)})
    local testDungeon, testRaid = TEST_DUNGEONS[math.random(#TEST_DUNGEONS)], TEST_RAIDS[math.random(#TEST_RAIDS)]
    for i, rec in ipairs(recs) do
        local t
        if i <= n / 3 then
            t = now - 2 * 86400 + i * 17
        elseif i <= 2 * n / 3 then
            t = now - 86400 + i * 17
        else
            t = now - (n - i) * 17
        end
        if rec.entry then
            rec.entry.time = t
            -- outside, a dungeon, outside again, a raid (so every kind of line shows)
            if i > 3 * n / 4 then
                rec.entry.instance, rec.entry.zone, rec.entry.instanceType = testRaid, testRaid, "raid"
            elseif i > n / 2 then
                rec.entry.zone = testZones[2]
            elseif i > n / 4 then
                rec.entry.instance, rec.entry.zone, rec.entry.instanceType = testDungeon, testDungeon, "party"
            else
                rec.entry.zone = testZones[1]
            end
        else
            rec.time = t
        end
    end
    return recs
end

-- Removes the sample lines from a loot window (they are dropped from its record and
-- the window is redrawn without them).
StopTest = function(W)
    if not W.testActive then
        return
    end
    W.testActive = false
    for i = #W.shadow, 1, -1 do
        if W.shadow[i].test then
            table.remove(W.shadow, i)
        end
    end
    Replay(W)
end

local function StartTest(W, recs)
    W.testActive = true
    for _, rec in ipairs(recs) do
        W.shadow[#W.shadow + 1] = rec
    end
    Replay(W)
end

function ns.StopTest()
    for _, W in ipairs(ns.ActiveWindows()) do
        StopTest(W)
    end
end

-- The "Test output" button / "/fcl test": the first press puts the sample lines into every loot
-- window (they follow the filters live: change an option and the lines come and go), the next
-- press removes them again (so does closing the options window). They are not remembered.
function ns.Test()
    local list = ns.ActiveWindows()
    if #list == 0 then
        return Print("No loot window found. Tick Loot in a chat tab's settings.")
    end
    local any = false
    for _, W in ipairs(list) do
        any = any or W.testActive
    end
    if any then
        return ns.StopTest()
    end
    local recs = BuildTestRecs()
    for _, W in ipairs(list) do
        StartTest(W, recs)
    end
end

---------------------------------------------------------------------------
-- Profiles
---------------------------------------------------------------------------

-- Where you are. Each place can load its own profile (the Automation tab of the options window).
local SCENARIOS = {{"world", "In the world"}, {"dungeon", "In a dungeon"}, {"raid", "In a raid"},
                   {"scenario", "In a scenario or delve"}}
ns.SCENARIOS = SCENARIOS
-- anything else (a battleground, an arena) counts as the world
local INSTANCE_SCENARIO = {
    party = "dungeon",
    raid = "raid",
    scenario = "scenario"
}

local function CurrentScenario()
    local inInstance, kind = IsInInstance()
    if not inInstance then
        return "world"
    end
    return INSTANCE_SCENARIO[kind] or "world"
end
ns.CurrentScenario = CurrentScenario

function ns.ScenarioLabel(scenario)
    for _, entry in ipairs(SCENARIOS) do
        if entry[1] == scenario then
            return entry[2]
        end
    end
    return scenario
end

local function RefreshOptions()
    if ns.RefreshOptions then
        ns.RefreshOptions()
    end
end

-- Called once when the saved variables are loaded: the settings of earlier versions become the profile
-- "Default"; this character gets its profile choice; every profile gets the settings added since.
local function InitProfiles()
    root = FrogskisChatLootDB
    charKey = UnitName("player") .. "-" .. GetRealmName()
    if type(root.profiles) ~= "table" then
        local settings = {}
        for key in pairs(ISPROFILE) do
            if root[key] ~= nil then
                settings[key] = root[key]
                root[key] = nil
            end
        end
        root.profiles = {
            Default = settings
        }
        -- the ready-made profiles for groups (see PresetSettings)
        for _, name in ipairs({"Dungeon", "Raid"}) do
            root.profiles[name] = PresetSettings(name)
        end
        -- a new install has nothing to carry over: every one-time change below is already in the defaults
        if next(settings) == nil then
            root.showByBindingDone, root.boeSoundDefaultsApplied, root.dateLineDefaultsApplied = true, true, true
            root.iconDefaultsApplied, root.showDropsApplied = true, true
            root.shortenItemsApplied, root.lineLookApplied = true, true
        end
    end
    -- The binding boxes used to say "hide ..."; they say "show ..." now (the same choice, turned round).
    if not root.showByBindingDone then
        root.showByBindingDone = true
        local function Turn(t)
            if t.hideSoulbound ~= nil then
                t.showSoulbound, t.hideSoulbound = not t.hideSoulbound, nil
            end
            if t.hideWarbound ~= nil then
                t.showWarbound, t.hideWarbound = not t.hideWarbound, nil
            end
            if t.hideBoE ~= nil then
                t.showBoE, t.hideBoE = not t.hideBoE, nil
            end
        end
        for _, p in pairs(root.profiles) do
            Turn(p)
        end
        if type(root.hist) == "table" then
            Turn(root.hist)
        end
    end
    for _, p in pairs(root.profiles) do
        CopyDefaults(SETTING_DEFAULTS, p)
    end
    -- The signs around the date and place lines are gone (the lines have no signs now).
    for _, p in pairs(root.profiles) do
        p.dateSignL, p.dateSignR, p.placeSignL, p.placeSignR, p.townSignL, p.townSignR = nil, nil, nil, nil, nil, nil
    end
    -- The plain boss picture is gone (the "<boss> drops:" line is an elite boss's or a rare's), and so are its settings.
    for _, p in pairs(root.profiles) do
        p.bossIcon, p.bossIconSide, p.bossIconScale, p.bossColor = nil, nil, nil, nil
    end
    -- The texture atlases that were added to its list now belong to the lists of both.
    if type(root.customIcons) == "table" and type(root.customIcons.boss) == "table" then
        for _, group in ipairs({"eliteboss", "rareboss"}) do
            local list = root.customIcons[group]
            if type(list) ~= "table" then
                list = {}
                root.customIcons[group] = list
            end
            for _, name in ipairs(root.customIcons.boss) do
                local known = false
                for _, existing in ipairs(list) do
                    if existing:lower() == name:lower() then
                        known = true
                    end
                end
                for _, item in ipairs(RANK_ICONS) do
                    if item[1]:lower() == name:lower() then
                        known = true
                    end -- it is one of the pictures of the list already
                end
                if not known then
                    list[#list + 1] = name
                end
            end
        end
        root.customIcons.boss = nil
    end
    -- The sound for items that bind when equipped: on in the profile "Raid" (the legendary loot
    -- toast), off in every other one. Given once to the profiles that already exist.
    if not root.boeSoundDefaultsApplied then
        root.boeSoundDefaultsApplied = true
        for name, p in pairs(root.profiles) do
            p.boeSound = name == "Raid"
            if name == "Raid" then
                p.boeSoundId = 63971
            end
        end
    end
    -- The newer defaults of the date and place lines, given once to the profiles that already exist.
    if not root.dateLineDefaultsApplied then
        root.dateLineDefaultsApplied = true
        for _, p in pairs(root.profiles) do
            p.zoneSeparator, p.separatorIndent = true, 0
            p.dateIcon, p.placeIcon = "calendar", "map"
        end
    end
    -- The pictures of the date, instance and town lines (the innkeeper for towns, all at 80% size) are
    -- the default now: given once to the profiles that already exist.
    if not root.iconDefaultsApplied then
        root.iconDefaultsApplied = true
        for _, p in pairs(root.profiles) do
            p.dateIcon, p.dateIconSide, p.dateIconScale = "calendar", "left", 0.8
            p.placeIcon, p.placeIconSide, p.placeIconScale = "map", "left", 0.8
            p.townIcon, p.townIconSide, p.townIconScale = "inn", "left", 0.8
        end
    end
    -- What a boss drops got a switch of its own (it used to follow "Loot rolls"): every profile that exists
    -- starts with the same as its rolls, so nothing changes until it is switched.
    if not root.showDropsApplied then
        root.showDropsApplied = true
        for _, p in pairs(root.profiles) do
            p.showDrops = p.showRolls and true or false
        end
    end
    -- "Cut long item names" is on by default now: switched on once in the profiles that already exist.
    if not root.shortenItemsApplied then
        root.shortenItemsApplied = true
        for _, p in pairs(root.profiles) do
            p.shortenItems = true
        end
    end
    -- The look of the date, instance, town, open world, elite boss and rare boss lines (picture, side, size and font
    -- color) is the same in every profile now, as the defaults say: given once to the profiles that already exist.
    if not root.lineLookApplied then
        root.lineLookApplied = true
        for _, p in pairs(root.profiles) do
            for _, row in ipairs({"date", "place", "town", "world", "eliteBoss", "rareBoss"}) do
                for _, suffix in ipairs({"Icon", "IconSide", "IconScale", "Color"}) do
                    p[row .. suffix] = SETTING_DEFAULTS[row .. suffix]
                end
            end
        end
    end
    -- "Show everything": every line, every quality, no filter. Added once (also for earlier installs);
    -- if it is deleted later it stays deleted.
    if not root.showEverythingAdded then
        root.showEverythingAdded = true
        if not root.profiles["Show everything"] then
            root.profiles["Show everything"] = PresetSettings("Show everything")
        end
    end
    root.chars = root.chars or {}
    char = root.chars[charKey]
    if not char then
        char = {}
        root.chars[charKey] = char
        -- a new character starts with the places set up: dungeons and scenarios load the dungeon profile, raids their own
        if root.profiles.Dungeon and root.profiles.Raid then
            char.auto = true
            char.rules = {
                dungeon = "Dungeon",
                raid = "Raid",
                scenario = "Dungeon"
            }
            for _, entry in ipairs(SCENARIOS) do
                char.rules[entry[1]] = char.rules[entry[1]] or
                                           (root.profiles.Default and "Default" or next(root.profiles))
            end
        end
    end
    char.rules = char.rules or {}
    -- The character's own two settings start from what the profiles and the global setting held before.
    if char.chatLines == nil then
        local best
        for _, p in pairs(root.profiles) do
            local v = tonumber(p.chatLines)
            if v and (not best or v > best) then
                best = v
            end
        end
        char.chatLines = best or DEFAULTS.chatLines
    end
    if char.maxHistory == nil then
        char.maxHistory = tonumber(root.maxHistory) or DEFAULTS.maxHistory
    end
    if char.announce == nil then
        char.announce = false
    end
    if not (char.profile and root.profiles[char.profile]) then
        char.profile = root.profiles.Default and "Default" or next(root.profiles)
    end
    profileName = char.profile
    profile = root.profiles[profileName]
end

function ns.GetProfiles()
    local names = {}
    for name in pairs(root.profiles) do
        names[#names + 1] = name
    end
    table.sort(names, function(a, b)
        return a:lower() < b:lower()
    end)
    return names
end

function ns.ActiveProfileName()
    return profileName
end

-- A usable name: the trimmed name, or nil and the reason.
local function CheckName(name, except)
    name = strtrim(name or "")
    if name == "" then
        return nil, "The name cannot be empty."
    end
    if #name > 24 then
        return nil, "The name is too long (24 letters at most)."
    end
    for existing in pairs(root.profiles) do
        if existing:lower() == name:lower() and existing ~= except then
            return nil, ('There is already a profile called "%s".'):format(existing)
        end
    end
    return name
end

function ns.SwitchProfile(name)
    local p = root.profiles[name]
    if not p then
        return false
    end
    profileName, profile, char.profile = name, p, name
    ns.RebuildLists()
    ns.Refresh()
    RefreshOptions()
    return true
end

-- A new profile with the default settings, loaded at once.
function ns.NewProfile(name)
    local good, why = CheckName(name)
    if not good then
        return Print(why)
    end
    local p = {}
    CopyDefaults(SETTING_DEFAULTS, p)
    root.profiles[good] = p
    ns.SwitchProfile(good)
    Print(('Profile "%s" created.'):format(good))
end

-- A copy of the profile in use, loaded at once.
function ns.CopyProfile(name)
    local good, why = CheckName(name)
    if not good then
        return Print(why)
    end
    local from = profileName
    local p = {}
    CopyDefaults(profile, p)
    root.profiles[good] = p
    ns.SwitchProfile(good)
    Print(('Profile "%s" created from "%s".'):format(good, from))
end

function ns.RenameProfile(name)
    local old = profileName
    local good, why = CheckName(name, old)
    if not good then
        return Print(why)
    end
    if good == old then
        return
    end
    root.profiles[good] = root.profiles[old]
    root.profiles[old] = nil
    for _, c in pairs(root.chars) do
        if c.profile == old then
            c.profile = good
        end
        for scenario, target in pairs(c.rules) do
            if target == old then
                c.rules[scenario] = good
            end
        end
    end
    profileName = good
    RefreshOptions()
    Print(('Profile "%s" is now called "%s".'):format(old, good))
end

function ns.DeleteProfile(name)
    local count = 0
    for _ in pairs(root.profiles) do
        count = count + 1
    end
    if count < 2 then
        return Print("There has to be at least one profile.")
    end
    if not root.profiles[name] then
        return
    end
    -- whoever used it (any character, any place) moves to Default, or else to the first other profile
    local fallback = (name ~= "Default" and root.profiles.Default) and "Default" or nil
    if not fallback then
        for _, other in ipairs(ns.GetProfiles()) do
            if other ~= name then
                fallback = other
                break
            end
        end
    end
    root.profiles[name] = nil
    for _, c in pairs(root.chars) do
        if c.profile == name then
            c.profile = fallback
        end
        for scenario, target in pairs(c.rules) do
            if target == name then
                c.rules[scenario] = fallback
            end
        end
    end
    if profileName == name then
        ns.SwitchProfile(fallback)
    else
        RefreshOptions()
    end
    Print(('Profile "%s" deleted.'):format(name))
end

-- Automation: when you change area, the profile of the place you are in is loaded. Picking a profile
-- yourself keeps it until the next area change.
local lastScenario
local function CheckScenario(force)
    local scenario = CurrentScenario()
    if scenario == lastScenario and not force then
        return
    end
    lastScenario = scenario
    RefreshOptions()
    if not (char and char.auto) then
        return
    end
    local target = char.rules[scenario]
    if target and target ~= profileName and root.profiles[target] then
        ns.SwitchProfile(target)
        if char.announce then
            Print(('%s: profile "%s".'):format(ns.ScenarioLabel(scenario), target))
        end
    end
end

function ns.GetAuto()
    return char.auto and true or false, char.announce and true or false
end

function ns.SetAuto(on)
    char.auto = on and true or false
    if char.auto then
        -- every place starts with the profile in use, so nothing changes until a place is changed
        for _, entry in ipairs(SCENARIOS) do
            local rule = char.rules[entry[1]]
            if not (rule and root.profiles[rule]) then
                char.rules[entry[1]] = profileName
            end
        end
        CheckScenario(true)
    end
    RefreshOptions()
end

function ns.SetAnnounce(on)
    char.announce = on and true or false
end

-- The profile a place loads (the one in use when none is set).
function ns.GetRule(scenario)
    local rule = char.rules[scenario]
    if rule and root.profiles[rule] then
        return rule
    end
    return profileName
end

function ns.SetRule(scenario, name)
    if not root.profiles[name] then
        return
    end
    char.rules[scenario] = name
    if char.auto and scenario == CurrentScenario() then
        CheckScenario(true)
    else
        RefreshOptions()
    end
end

-- Every setting back to a fresh install: all profiles (the ready-made ones are made again), the characters' profile
-- choices and automation, the history window's own settings and the pictures added by hand. The remembered loot
-- history stays (the lists the windows share), with what it was learned from (the towns, the timestamp format) and where
-- the gear and the history window sit: the same things "Reset this profile to defaults" leaves alone.
function ns.NukeAll()
    local kept = {}
    for _, key in ipairs({"winHist", "winRolls", "histories", "townZones", "stampTemplate", "gearPos", "histSize"}) do
        kept[key] = root[key]
    end
    wipe(root)
    for key, value in pairs(kept) do
        root[key] = value
    end
    InitProfiles()
    CopyDefaults(DEFAULTS, db)
    ns.RebuildLists()
    CheckScenario(true)
    ns.Refresh()
    RefreshOptions()
    Print("All settings were reset to their defaults. The loot history was kept.")
end

---------------------------------------------------------------------------
-- Events and slash commands
---------------------------------------------------------------------------

-- A zone you step into that is a rest area from the first moment (a city), or the housing neighbourhood,
-- is remembered as a town: loot recorded there before the town lines existed gets its town line too.
-- (Only on entering a zone, so an inn in the middle of the countryside does not turn the zone into a town.)
local function LearnPlace()
    local known = db.townZones
    if not known then
        return
    end
    local zone = GetZoneText()
    local kind = SafePlaceKind()
    if zone ~= "" and kind and known[zone] ~= kind then
        known[zone] = kind
        ns.Refresh()
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("UPDATE_CHAT_WINDOWS")
f:RegisterEvent("GET_ITEM_INFO_RECEIVED")
f:RegisterEvent("CHAT_MSG_LOOT")
f:RegisterEvent("CHAT_MSG_CURRENCY")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= ADDON then
            return
        end
        FrogskisChatLootDB = FrogskisChatLootDB or {}
        InitProfiles()
        if db.minQuality and not db.qualities then -- from 1.0.x
            db.qualities = {}
            for q = 0, 5 do
                db.qualities[q] = q >= db.minQuality
            end
        end
        db.minQuality, db.hideFromOtherWindows, db.removedFrom, db.alignItems = nil, nil, nil, nil
        CopyDefaults(DEFAULTS, db)
        -- A saved history table from before has none of the newer keys: add what is missing.
        for k, v in pairs(DEFAULTS.hist) do
            if db.hist[k] == nil then
                if type(v) == "table" then
                    db.hist[k] = {}
                    CopyDefaults(v, db.hist[k])
                else
                    db.hist[k] = v
                end
            end
        end
        ns.db = db
        ns.RebuildLists()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- every loading screen: where are we now? The first time (login, reload) the profile of this place
        -- is loaded even if it did not change; later only when the place changes.
        local first = not f.started
        if first then
            f.started = true
            charKey = UnitName("player") .. "-" .. GetRealmName()
            HookScanning()
            C_Timer.After(1, ScanNow) -- chat windows are set up by now
        end
        C_Timer.After(0.3, function()
            CheckScenario(first)
        end)
        C_Timer.After(2.5, LearnPlace) -- after the chat windows are set up and the rest state is known
        if first then
            C_Timer.After(4, function() -- the group is known by now
                pcall(ns.HealAllNames)
            end)
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        C_Timer.After(0.3, function()
            CheckScenario(false)
        end)
        C_Timer.After(2.5, LearnPlace)
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- the group's players are known whole now (a burst of events is looked at once)
        if not f.namesQueued then
            f.namesQueued = true
            C_Timer.After(1, function()
                f.namesQueued = false
                pcall(ns.HealAllNames)
            end)
        end
    elseif event == "UPDATE_CHAT_WINDOWS" then
        ns.Scan()
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        -- An item we asked about is loaded: draw the loot windows again (once for a burst of answers).
        local itemID = ...
        if outstanding[itemID] then
            outstanding[itemID] = nil
            if not f.refreshQueued then
                f.refreshQueued = true
                C_Timer.After(0.3, function()
                    f.refreshQueued = false
                    ns.Refresh()
                end)
            end
        end
    elseif root then
        local text, playerName = ...
        local guid = select(12, ...)
        local ok, err = pcall(OnLoot, text, playerName, guid, event == "CHAT_MSG_CURRENCY")
        if not ok then
            Print("error: " .. tostring(err))
        end
    end
end)

SLASH_FROGSKISCHATLOOT1 = "/fcl"
SLASH_FROGSKISCHATLOOT2 = "/chatloot"
SlashCmdList["FROGSKISCHATLOOT"] = function(msg)
    msg = strtrim(msg or ""):lower()
    if msg == "test" then
        ns.Test()
    elseif msg:find("^type") then
        -- /fcl type [item link]: shows which item type the filters see for an item.
        local raw = strtrim(msg:sub(5))
        local id = tonumber(raw:match("item:(%d+)")) or tonumber(raw)
        if not id then
            return Print("Usage: /fcl type [shift-click an item link]")
        end
        local _, typeName, subName, _, _, classID, subID = C_Item.GetItemInfoInstant(id)
        Print(("item %d: type %s (%s), subtype %s (%s)"):format(id, tostring(classID), tostring(typeName),
            tostring(subID), tostring(subName)))
    elseif msg == "boss" then
        -- /fcl boss: what the "<boss> drops:" line would be told by the creatures around right now (a nameless kill).
        Print("Looking at the creatures around for a dead boss or rare:")
        ns.BossCorpse(function(info)
            Print("  " .. info)
        end)
        local name, found = ns.BossCorpse()
        Print(name and ("A drop now would be \"" .. name .. " drops:\" (" .. tostring(found) .. ").") or
                  "No dead boss or rare found: a drop with no name would get no \"drops:\" line.")
    elseif msg == "align" then
        -- /fcl align: what the column alignment measures right now (first loot window).
        local W = ns.ActiveWindows()[1]
        if not W then
            return Print("No loot window found.")
        end
        local font, size = W.frame:GetFont()
        Print(("align=%s font=%s size=%s margin=%s"):format(tostring(db.alignColumn), tostring(font), tostring(size),
            tostring(db.leftMargin)))
        Print(("width of 'Frogski' = %s, 'Orthessa' = %s, column(db) = %s"):format(tostring(TextWidth(W, "Frogski")),
            tostring(TextWidth(W, "Orthessa")), tostring(W.columns[db])))
        local sample = FormatEntry({
            name = "Frogski",
            link = "|cffffffff|Hitem:6948::::::::::::|h[Hearthstone]|h|r",
            isSelf = true,
            time = time()
        }, db, W)
        Print(("text units per spacer pixel = %s"):format(tostring(TextUnitsPerPixel(W))))
        Print("sample line: " .. sample:gsub("|", "||"))
    elseif msg:find("^profile") then
        -- /fcl profile            the one in use and the others
        -- /fcl profile <name>     load that profile
        local wanted = strtrim(msg:sub(8))
        if wanted == "" then
            Print(('Profile: "%s". All profiles: %s. /fcl profile <name> loads one.'):format(profileName, table.concat(
                ns.GetProfiles(), ", ")))
        else
            local found
            for _, name in ipairs(ns.GetProfiles()) do
                if name:lower() == wanted then
                    found = name
                    break
                end
            end
            if found then
                ns.SwitchProfile(found)
                Print(('Profile: "%s".'):format(found))
            else
                Print(('There is no profile called "%s".'):format(wanted))
            end
        end
    elseif msg == "history" then
        ns.ToggleAllHistory()
    elseif msg == "clear" then
        for _, W in ipairs(ns.ActiveWindows()) do
            ns.ClearHistory(W)
        end
        Print("History cleared (every loot window).")
    elseif msg == "reset" then
        ScanNow()
        local names = {}
        for _, W in ipairs(ns.ActiveWindows()) do
            names[#names + 1] = W.frame:GetName() .. " (" .. ns.WindowName(W) .. ")"
        end
        Print(#names > 0 and ("Loot windows: " .. table.concat(names, ", ")) or "No loot window found.")
    else
        ns.ToggleOptions()
    end
end
