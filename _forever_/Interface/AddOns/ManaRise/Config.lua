-- ManaRise - Config.lua
-- SavedVariables (account-wide) and slash commands.

local _, ns = ...

ns.defaults = {
    enabled   = true,
    smooth    = true,   -- interpolate between observed power updates
    glow      = true,   -- brief flash (resource color) when a spell becomes affordable
    pulse     = false,  -- brighten the fill edge on each observed gain
    style     = "liquid", -- "liquid" (waves + bubbles) or "flat" (original look)
    debug     = false,
    resource  = "all",  -- "all" (mana, rage, energy, focus) or "mana"
    -- fill color per resource (also the crest, bubbles and ready flash)
    colors    = {
        mana   = { r = 0x25 / 255, g = 0x89 / 255, b = 0xE8 / 255 }, -- #2589E8 arcane blue
        rage   = { r = 0xE0 / 255, g = 0x26 / 255, b = 0x1E / 255 }, -- #E0261E
        energy = { r = 0xFF / 255, g = 0xD8 / 255, b = 0x1A / 255 }, -- #FFD81A
        focus  = { r = 0xFF / 255, g = 0x80 / 255, b = 0x40 / 255 }, -- #FF8040 (Blizzard's focus color)
    },
    fillAlpha = 0.70,
    darkAlpha = 0.55,
    waves     = "normal", -- wave speed: "calm" (slow), "normal" or "lively" (fast)
    waveHeight = "low",   -- wave intensity: "low", "medium" or "high"
    bubbles   = true,
    overlay   = true,     -- draw the out-of-resource fill (the ready flash is separate)
    -- Per bar category (see ns.CATEGORIES). cats[name] = { custom = true,
    -- enabled, style, waveHeight, waves, glow, overlay, colors = {...} }.
    -- Without "custom" a category follows the global settings above; only
    -- "enabled" always applies. Created on demand, so old profiles keep working.
    cats      = {},
    -- Fill style per resource: resStyles[resource] = a style name. A resource
    -- without an entry uses the main style. Global: applies to every bar category.
    resStyles = {},
    -- Settings of one resource for one style: resSettings[resource][style] =
    -- { waves, waveHeight, bubbles, fillAlpha, darkAlpha }. A missing entry
    -- means "same as the main setting".
    resSettings = {},
    -- Custom colors of the ready flash, edge pulse and ready sweep/double:
    -- fxColors["flash_mana"] = { r, g, b, a }. No entry = automatic (the
    -- resource color made lighter).
    fxColors = {},
    preset    = "classic", -- name of the color preset the colors match, or "custom"
    -- optional signals (all off by default)
    range       = false,  -- mark icons while the target is out of range
    rangeColor  = "D91A1A", -- hex color of the out-of-range mark
    rangeAlpha  = 0.40,   -- strength of the mark (0.05-1)
    rangeStyle  = "tint", -- "tint" (color over the icon), "grey" or "border"
    rangeUsable = true,   -- skip the mark on spells you could not cast anyway (no mana, etc.)
    sound       = "off",  -- ready sound: "off", a built-in name, "custom" or "lsm:<name>"
    soundCustom = "",     -- file path or numeric sound ID used when sound is "custom"
    soundOnly   = false,  -- true: the ready sound plays only for the abilities in soundSpells
    soundSpells = {},     -- [spellID] = true, chosen with /mr soundspell or the options panel
    readyAnim   = "flash", -- "flash", "sweep" or "double"
}
-- Ready sounds: names of the game's built-in sound kits, looked up when played.
ns.SOUND_ORDER = { "tick", "chime", "bell" }
ns.SOUNDS = {
    tick  = "IG_MAINMENU_OPTION_CHECKBOX_ON",
    chime = "UI_BNET_TOAST",
    bell  = "READY_CHECK",
}
ns.SOUND_PACK_PATH = "Interface\\AddOns\\ManaRise\\Sounds\\"
-- Bundled alert sounds (CC0 / CC BY 3.0 / MIT; see Sounds/Licenses). value = "pack:<file>"
ns.SOUND_PACK = {
    { "AirHorn", "Air Horn" },
    { "AlertToastWarm", "Alert Toast Warm" },
    { "Applause", "Applause" },
    { "Blast", "Blast" },
    { "Bleat", "Bleat" },
    { "BoxingArenaSound", "Boxing Arena Gong" },
    { "CartoonVoiceBaritone", "Cartoon Voice Baritone" },
    { "CartoonWalking", "Cartoon Walking" },
    { "CatMeow2", "Cat Meow" },
    { "CowMooing", "Cow Mooing" },
    { "Focus", "Focus" },
    { "HeartbeatSingle", "Heartbeat Single" },
    { "KittenMeow", "Kitten Meow" },
    { "LossaHealerTrinket", "Lossa Healer Trinket" },
    { "LossaTrinket", "Lossa Trinket" },
    { "Notification18", "Notification 18" },
    { "Notification38", "Notification 38" },
    { "RingingPhone", "Ringing Phone" },
    { "RoaringLion", "Roaring Lion" },
    { "RobotBlip", "Robot Blip" },
    { "SheepBleat", "Sheep Bleat" },
    { "Shotgun", "Shotgun" },
    { "Sonar", "Sonar" },
    { "TempleBellHuge", "Temple Bell" },
    { "Torch", "Torch" },
    { "WarningSiren", "Warning Siren" },
    { "WatchOut", "Watch Out" },
    { "WaterDrop", "Water Drop" },
}
ns.SOUND_PACK_NAME, ns.SOUND_PACK_ARG = {}, {}
for _, e in ipairs(ns.SOUND_PACK) do
    ns.SOUND_PACK_NAME["pack:" .. e[1]] = e[2]
    ns.SOUND_PACK_ARG[string.lower(e[1])] = "pack:" .. e[1]
end
-- Account-level settings that never move into a per-class profile.
ns.metaDefaults = {
    perClass    = false,                     -- kept in step with profileMode == "class" (older versions)
    profileMode = false,                     -- "account", "class" or "character"; false = not chosen yet
    characters  = {},                        -- ["Name-Realm"] = settings table (profileMode "character")
    minimap     = { hide = false, angle = 215, locked = true },
    lastVersion = false,                     -- version that last greeted the player
    classes     = {},                        -- [CLASS] = settings table (perClass)
}
-- Color presets: hex per resource. "classic" is the default look.
ns.PRESET_ORDER = { "classic", "fel", "frost", "colorblind" }
ns.PRESETS = {
    classic    = { mana = "2589E8", rage = "E0261E", energy = "FFD81A", focus = "FF8040" },
    fel        = { mana = "4DFF4D", rage = "FF3B1E", energy = "D6FF3A", focus = "FF9A3C" },
    frost      = { mana = "6FD3FF", rage = "FF6B6B", energy = "FFF2A8", focus = "FFB347" },
    -- Okabe-Ito palette: stays distinguishable with the common kinds of color blindness
    colorblind = { mana = "0072B2", rage = "D55E00", energy = "F0E442", focus = "CC79A7" },
}
ns.DEFAULT_COLOR_HEX = { mana = "2589E8", rage = "E0261E", energy = "FFD81A", focus = "FF8040" }
ns.defaultColorHex = ns.DEFAULT_COLOR_HEX.mana
ns.RESOURCE_KEYS = { "mana", "rage", "energy", "focus" }
local IS_RESOURCE = { mana = true, rage = true, energy = true, focus = true }
ns.RESOURCE_SET = IS_RESOURCE

local function CopyDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = DeepCopy(v) end
    return c
end

-- A copy of the profile keys (defaults only) from one table to another.
local function CopyProfile(src, dst)
    for k, v in pairs(ns.defaults) do
        local sv = src[k]
        if k == "cats" or k == "resSettings" then
            dst[k] = DeepCopy(sv) or {}
        elseif type(v) == "table" then
            dst[k] = {}
            if type(sv) == "table" then
                for ck, cv in pairs(sv) do
                    dst[k][ck] = type(cv) == "table" and { r = cv.r, g = cv.g, b = cv.b, a = cv.a } or cv
                end
            end
        else
            dst[k] = sv
        end
    end
end

-- Name of the preset whose colors the profile uses, or "custom".
local function MatchPreset(db)
    for _, name in ipairs(ns.PRESET_ORDER) do
        local same = true
        for res, hex in pairs(ns.PRESETS[name]) do
            if not db.colors[res] or ns.ColorHex(db.colors[res]) ~= hex then same = false end
        end
        if same then return name end
    end
    return "custom"
end

-- ns.root is the whole SavedVariables table (account settings); ns.db is the
-- profile in use: the root itself, or this class's own table.
ns.PROFILE_MODES = { account = true, class = true, character = true }

-- "Name-Realm" of the logged-in character, so same-named characters on
-- different realms get their own settings.
function ns.CharacterKey()
    local name = UnitName and UnitName("player")
    local realm = GetRealmName and GetRealmName()
    if not name or name == "" then return "UNKNOWN" end
    return name .. "-" .. (realm or "")
end

-- Before 1.12.27 wave speed and intensity per resource were two tables
-- (resWaves, resWaveHeights). They now live per resource and style; an old
-- value goes to the style that resource was using.
function ns:MigrateResSettings(profile)
    local old = { waves = profile.resWaves, waveHeight = profile.resWaveHeights }
    if type(profile.resSettings) ~= "table" then profile.resSettings = {} end
    for setting, src in pairs(old) do
        if type(src) == "table" then
            for res, value in pairs(src) do
                if self.RESOURCE_SET[res] then
                    local style = type(profile.resStyles) == "table" and profile.resStyles[res]
                    if not self.STYLE_CHOICES[style] then style = self.STYLE_CHOICES[profile.style] and profile.style or "liquid" end
                    local choices = setting == "waves" and self.WAVE_CHOICES or self.WAVE_HEIGHT_CHOICES
                    if choices[value] then
                        if type(profile.resSettings[res]) ~= "table" then profile.resSettings[res] = {} end
                        if type(profile.resSettings[res][style]) ~= "table" then profile.resSettings[res][style] = {} end
                        if profile.resSettings[res][style][setting] == nil then
                            profile.resSettings[res][style][setting] = value
                        end
                    end
                end
            end
        end
    end
    profile.resWaves, profile.resWaveHeights = nil, nil
end

function ns:SelectProfile()
    local root = self.root
    local profile = root
    local mode = root.profileMode
    if not ns.PROFILE_MODES[mode] then mode = root.perClass and "class" or "account" end
    if mode == "character" then
        local key = ns.CharacterKey()
        if type(root.characters) ~= "table" then root.characters = {} end
        if type(root.characters[key]) ~= "table" then
            root.characters[key] = {}
            CopyProfile(root, root.characters[key])   -- start from the account settings
        end
        profile = root.characters[key]
    elseif mode == "class" then
        local class
        if UnitClass then class = select(2, UnitClass("player")) end
        class = class or "UNKNOWN"
        if type(root.classes[class]) ~= "table" then
            root.classes[class] = {}
            CopyProfile(root, root.classes[class])   -- start from the account settings
        end
        profile = root.classes[class]
    end
    CopyDefaults(self.defaults, profile)
    self:MigrateResSettings(profile)
    -- the gradient and bar styles were removed in 1.6.4
    if not ns.STYLE_CHOICES[profile.style] then profile.style = self.defaults.style end
    profile.preset = MatchPreset(profile)
    self.db = profile
end

function ns:InitDB()
    self.isNewInstall = type(ManaRiseDB) ~= "table" or next(ManaRiseDB) == nil
    if type(ManaRiseDB) ~= "table" then
        ManaRiseDB = {}
    end
    local db = ManaRiseDB
    -- 1.2.0 and earlier: one color (mana) and a fixed mana-only flag
    if type(db.color) == "table" then
        db.colors = db.colors or {}
        if type(db.colors.mana) ~= "table" then db.colors.mana = db.color end
        db.color = nil
    end
    db.manaOnly = nil
    CopyDefaults(self.metaDefaults, db)
    CopyDefaults(self.defaults, db)
    -- 1.12.24: the per-class switch became a three-way mode
    if not self.PROFILE_MODES[db.profileMode] then db.profileMode = db.perClass and "class" or "account" end
    db.perClass = db.profileMode == "class"
    self.root = db
    self:SelectProfile()
end

-- Back to defaults for the profile in use. Account-level settings (minimap
-- button, per-class switch, other classes' profiles) are kept.
function ns:ResetDB()
    for k in pairs(self.defaults) do self.db[k] = nil end
    CopyDefaults(self.defaults, self.db)
    self.db.preset = MatchPreset(self.db)
end

---------------------------------------------------------------------------
-- Changing settings
-- The slash commands and the options panel both go through ns:SetOption, so
-- validation and side effects live in one place. After a change from a slash
-- command the panel is told to redraw; a change made in the panel is already
-- shown there.
---------------------------------------------------------------------------
ns.WAVE_CHOICES = { calm = true, normal = true, lively = true }
ns.WAVE_HEIGHT_CHOICES = { low = true, medium = true, high = true }
local WAVE_ALIAS = { slow = "calm", fast = "lively" }   -- /mr waves slow | fast
local STYLE_CHOICES = { liquid = true, flat = true, ice = true, paper = true, parchment = true }
ns.STYLE_CHOICES = STYLE_CHOICES
ns.ANIM_ORDER = { "flash", "sweep", "double" }
ns.RANGE_STYLES = { tint = true, grey = true, border = true }
local ANIM_CHOICES = { flash = true, sweep = true, double = true }
local RESOURCE_CHOICES = { all = true, mana = true }
local TOGGLES = { enabled = true, overlay = true, smooth = true, glow = true, pulse = true, bubbles = true,
    range = true, rangeUsable = true, soundOnly = true }

-- "#2589E8", "2589e8" or "ff2589e8" (the panel's AARRGGBB) -> r, g, b in 0..1
function ns.ParseHexColor(s)
    if type(s) ~= "string" then return nil end
    s = string.gsub(s, "^#", "")
    if (#s ~= 6 and #s ~= 8) or string.find(s, "[^%x]") then return nil end
    -- an 8-digit value is AARRGGBB; the fourth result is its opacity (0-1)
    local a
    if #s == 8 then a = tonumber(string.sub(s, 1, 2), 16) / 255; s = string.sub(s, 3) end
    return tonumber(string.sub(s, 1, 2), 16) / 255,
           tonumber(string.sub(s, 3, 4), 16) / 255,
           tonumber(string.sub(s, 5, 6), 16) / 255, a
end

-- A resource color: r, g, b and an optional opacity a (missing = fully opaque).
-- A value without an opacity keeps the one the color already had.
local function MakeColor(r, g, b, a, prev)
    a = a or (prev and prev.a)
    if a and a >= 0.995 then a = nil end
    return { r = r, g = g, b = b, a = a }
end
ns.FX_KEYS = { flash = true, pulse = true, sweep = true }
ns.FX_ORDER = { "flash", "pulse", "sweep" }
function ns.ColorOpacity(c) return c and c.a or 1 end
-- "AARRGGBB" as the options page's color settings use it
function ns.ColorHexA(c)
    return string.format("%02X", math.floor(ns.ColorOpacity(c) * 255 + 0.5)) .. ns.ColorHex(c)
end

function ns.ColorHex(c)
    return string.format("%02X%02X%02X", math.floor(c.r * 255 + 0.5),
        math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5))
end

---------------------------------------------------------------------------
-- Bar categories. Every tracked button belongs to one (ActionBars.Classify).
-- Settings are read through CatGet / CatColor / CatEnabled; a nil category
-- (preview windows) reads the global settings.
---------------------------------------------------------------------------
ns.CATEGORIES = { "main", "additional", "stance", "cooldown", "other" }
local IS_CATEGORY = {}
for _, c in ipairs(ns.CATEGORIES) do IS_CATEGORY[c] = true end
local CAT_KEYS = { style = true, waveHeight = true, waves = true, glow = true, overlay = true }

local function CatTable(cat)
    local db = ns.db
    local t = db and cat and db.cats and db.cats[cat]
    return type(t) == "table" and t or nil
end

function ns:CatGet(cat, key)
    local t = CatTable(cat)
    if t and t.custom and t[key] ~= nil then return t[key] end
    return self.db[key]
end

function ns:CatColor(cat, res)
    local t = CatTable(cat)
    if t and t.custom and t.colors and t.colors[res] then return t.colors[res] end
    return self.db.colors[res]
end

-- The fill style of a button: the resource's own style if one is set (these
-- are global and apply to every bar category), else the main style of that
-- category.
function ns:StyleFor(cat, res)
    res = res or "mana"
    local own = type(self.db.resStyles) == "table" and self.db.resStyles[res] or nil
    if own and STYLE_CHOICES[own] then return own end
    return self:CatGet(cat, "style")
end

-- The per-resource settings behind the panel keys and /mr resset: key prefix
-- -> the setting name and how its value is checked. They are saved per
-- resource AND style (db.resSettings[res][style][setting]).
local RES_FIELDS = {
    reswaves      = { setting = "waves" },
    reswaveheight = { setting = "waveHeight" },
    resbubbles    = { setting = "bubbles" },
    resopacity    = { setting = "fillAlpha" },
    resdark       = { setting = "darkAlpha" },
}
ns.RES_FIELDS = RES_FIELDS
local function ResKey(key)
    local prefix, res = key:match("^(%a+)_(%a+)$")
    if prefix and RES_FIELDS[prefix] then return RES_FIELDS[prefix], res end
end

local function ValidResValue(self, setting, value)
    if setting == "waves" then return self.WAVE_CHOICES[value] and true or false end
    if setting == "waveHeight" then return self.WAVE_HEIGHT_CHOICES[value] and true or false end
    if setting == "bubbles" then return type(value) == "boolean" end
    return type(value) == "number" and value >= 0 and value <= 1
end

-- Which styles use which per-resource settings: opacity and darkness every
-- style, waves and bubbles all but flat.
function ns:StyleUses(style, setting)
    if setting == "fillAlpha" or setting == "darkAlpha" then return true end
    return style ~= "flat"
end

-- The value saved for a resource and style (nil: none, or not valid).
local function OwnValue(self, res, style, setting)
    local src = self.db.resSettings
    if type(src) ~= "table" or type(src[res]) ~= "table" or type(src[res][style]) ~= "table" then return nil end
    local v = src[res][style][setting]
    if v ~= nil and ValidResValue(self, setting, v) then return v end
end

-- A setting of a button: the resource's own value for the style the button
-- uses, if set (global, like StyleFor), else the category's / main one.
function ns:ResSettingFor(cat, res, setting)
    res = res or "mana"
    local own = OwnValue(self, res, self:StyleFor(cat, res), setting)
    if own ~= nil then return own end
    return self:CatGet(cat, setting)
end

-- The value the resource has of its own (nil: same as the main setting).
function ns:ResSettingOwn(res, setting, style)
    return OwnValue(self, res, style or self:StyleFor(nil, res), setting)
end

-- A wave setting ("waves" speed or "waveHeight" intensity) of a button.
function ns:WaveFor(cat, res, setting)
    return self:ResSettingFor(cat, res, setting)
end

function ns:CatEnabled(cat)
    local t = CatTable(cat)
    return not (t and t.enabled == false)
end

function ns:CatCustom(cat)
    local t = CatTable(cat)
    return t ~= nil and t.custom == true
end

-- What the panel shows for a category's setting key (own value, else global).
function ns:CatValue(cat, key)
    if key == "enabled" then return self:CatEnabled(cat) end
    if key == "custom" then return self:CatCustom(cat) end
    if key:sub(1, 6) == "color_" then return self.ColorHexA(self:CatColor(cat, key:sub(7))) end
    return self:CatGet(cat, key)
end

-- A category starts its own settings from what the global ones are now, so
-- nothing jumps when it stops following them.
local function MakeCustom(t)
    local db = ns.db
    if t.custom then return end
    for k in pairs(CAT_KEYS) do if t[k] == nil then t[k] = db[k] end end
    t.colors = t.colors or {}
    for _, res in ipairs(ns.RESOURCE_KEYS) do
        local c = t.colors[res] or db.colors[res]
        t.colors[res] = { r = c.r, g = c.g, b = c.b, a = c.a }
    end
    t.custom = true
end

-- Returns true if the value was valid and saved. Changing a look setting
-- (anything but "enabled" and "custom") also switches the category to its own
-- settings.
function ns:SetCatOption(cat, key, value, fromPanel)
    local db = self.db
    if not db or not IS_CATEGORY[cat] then return false end
    if type(db.cats) ~= "table" then db.cats = {} end
    local t = db.cats[cat]
    if type(t) ~= "table" then t = {}; db.cats[cat] = t end
    if key == "enabled" then
        if type(value) ~= "boolean" then return false end
        t.enabled = value
    elseif key == "custom" then
        if type(value) ~= "boolean" then return false end
        if value then MakeCustom(t) end
        t.custom = value
    elseif key:sub(1, 6) == "color_" then
        local res = key:sub(7)
        if not IS_RESOURCE[res] then return false end
        local r, g, b, a = self.ParseHexColor(value)
        if not r then return false end
        MakeCustom(t)
        t.colors[res] = MakeColor(r, g, b, a, t.colors[res])
    elseif CAT_KEYS[key] then
        if key == "style" then
            if not STYLE_CHOICES[value] then return false end
        elseif key == "waves" then
            value = WAVE_ALIAS[value] or value
            if not self.WAVE_CHOICES[value] then return false end
        elseif key == "waveHeight" then
            if not self.WAVE_HEIGHT_CHOICES[value] then return false end
        elseif type(value) ~= "boolean" then
            return false
        end
        MakeCustom(t)
        t[key] = value
    else
        return false
    end
    self:ApplySettings()
    if not fromPanel and self.Options then self.Options:RefreshCategory() end
    return true
end

-- Returns true if the value was valid and saved.
function ns:SetOption(key, value, fromPanel)
    local db = self.db
    if not db then return false end
    if key == "minimap" then
        if type(value) ~= "boolean" then return false end
        self.root.minimap.hide = not value
        if self.Minimap then self.Minimap:Update() end
        if not fromPanel and self.Options then self.Options:Refresh(key) end
        return true
    elseif key == "perClass" or key == "profileMode" then
        if key == "perClass" then
            if type(value) ~= "boolean" then return false end
            value = value and "class" or "account"
        elseif not self.PROFILE_MODES[value] then
            return false
        end
        self.root.profileMode = value
        self.root.perClass = value == "class"
        self:SelectProfile()
        if self.Mana and self.Mana.InvalidateCosts then self.Mana:InvalidateCosts() end
        self:ApplySettings()
        if self.apiOK then self:Schedule("slots") end
        if self.Options then self.Options:Refresh() end   -- every control shows the new profile
        return true
    elseif key == "preset" then
        if value ~= "custom" and not self.PRESETS[value] then return false end
        if value ~= "custom" then
            for res, hex in pairs(self.PRESETS[value]) do
                local r, g, b = self.ParseHexColor(hex)
                db.colors[res] = { r = r, g = g, b = b }
            end
        end
        db.preset = MatchPreset(db)
        self:ApplySettings()
        if self.Options then self.Options:Refresh() end
        return true
    elseif TOGGLES[key] then
        if type(value) ~= "boolean" then return false end
        db[key] = value
    elseif key == "style" then
        if not STYLE_CHOICES[value] then return false end
        db.style = value
    elseif string.sub(key, 1, 9) == "resstyle_" and IS_RESOURCE[string.sub(key, 10)] then
        if value ~= "default" and not STYLE_CHOICES[value] then return false end
        if type(db.resStyles) ~= "table" then db.resStyles = {} end
        db.resStyles[string.sub(key, 10)] = value ~= "default" and value or nil
        if self.Options and self.Options.RefreshResource then self.Options:RefreshResource(string.sub(key, 10)) end
    elseif ResKey(key) then
        local f, res = ResKey(key)
        if not IS_RESOURCE[res] then return false end
        if f.setting == "waves" then value = WAVE_ALIAS[value] or value end
        if value ~= "default" and not ValidResValue(self, f.setting, value) then return false end
        if type(value) == "number" then value = math.floor(value * 100 + 0.5) / 100 end
        local style = self:StyleFor(nil, res)
        if type(db.resSettings) ~= "table" then db.resSettings = {} end
        if value == "default" then
            local t = db.resSettings[res] and db.resSettings[res][style]
            if t then t[f.setting] = nil end
        else
            if type(db.resSettings[res]) ~= "table" then db.resSettings[res] = {} end
            if type(db.resSettings[res][style]) ~= "table" then db.resSettings[res][style] = {} end
            db.resSettings[res][style][f.setting] = value
        end
        if self.Options and self.Options.RefreshResource then self.Options:RefreshResource(res) end
    elseif string.match(key, "^fx_%a+_%a+$") then
        local fx, res = string.match(key, "^fx_(%a+)_(%a+)$")
        if not self.FX_KEYS[fx] or not IS_RESOURCE[res] then return false end
        if type(db.fxColors) ~= "table" then db.fxColors = {} end
        if value == "auto" or value == "default" then
            db.fxColors[fx .. "_" .. res] = nil
        else
            if type(value) ~= "string" then return false end
            local r, g, b, a = self.ParseHexColor(value)
            if not r then return false end
            db.fxColors[fx .. "_" .. res] = MakeColor(r, g, b, a, db.fxColors[fx .. "_" .. res])
        end
    elseif key == "rangeStyle" then
        if not self.RANGE_STYLES[value] then return false end
        db.rangeStyle = value
    elseif key == "rangeColor" then
        local r, g, b = self.ParseHexColor(value)
        if not r then return false end
        db.rangeColor = self.ColorHex({ r = r, g = g, b = b })
        if self.Options then self.Options:Refresh("rangeColor") end
    elseif key == "rangeAlpha" then
        if type(value) ~= "number" or value < 0.05 or value > 1 then return false end
        db.rangeAlpha = math.floor(value * 100 + 0.5) / 100
    elseif key == "readyAnim" then
        if not ANIM_CHOICES[value] then return false end
        db.readyAnim = value
    elseif key == "sound" then
        if type(value) ~= "string" then return false end
        local named = value == "off" or value == "custom" or self.SOUNDS[value] or self.SOUND_PACK_NAME[value]
            or (string.sub(value, 1, 4) == "lsm:" and #value > 4 and #value <= 120)
        if not named then return false end
        db[key] = value
    elseif key == "soundCustom" then
        if type(value) ~= "string" or #value > 240 then return false end
        db[key] = strtrim(value)
    elseif key == "waves" then
        value = WAVE_ALIAS[value] or value
        if not self.WAVE_CHOICES[value] then return false end
        db.waves = value
    elseif key == "waveHeight" then
        if not self.WAVE_HEIGHT_CHOICES[value] then return false end
        db.waveHeight = value
    elseif key == "fillAlpha" or key == "darkAlpha" then
        if type(value) ~= "number" or value < 0 or value > 1 then return false end
        db[key] = math.floor(value * 100 + 0.5) / 100
    elseif key == "resource" then
        if not RESOURCE_CHOICES[value] then return false end
        db.resource = value
        if self.Mana and self.Mana.InvalidateCosts then self.Mana:InvalidateCosts() end
        if self.apiOK and db.enabled then self:Schedule("slots") end
    elseif string.sub(key, 1, 6) == "color_" and IS_RESOURCE[string.sub(key, 7)] then
        local r, g, b, a = self.ParseHexColor(value)
        if not r then return false end
        local res = string.sub(key, 7)
        db.colors[res] = MakeColor(r, g, b, a, db.colors[res])
        db.preset = MatchPreset(db)
        if self.Options then self.Options:Refresh("preset") end
    else
        return false
    end
    self:ApplySettings()
    if not fromPanel and self.Options then self.Options:Refresh(key) end
    return true
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
local L = ns.L

local function OnOff(v)
    return v and ("|cff40ff40" .. L.ON .. "|r") or ("|cffff4040" .. L.OFF .. "|r")
end

-- A resource key (mana, rage, energy, focus) in the client's language.
function ns.ResourceName(key)
    return L["RES_" .. (key or "mana")]
end

local function PrintStatus()
    local db = ns.db
    ns:Print("v%s", ns.version)
    ns:Print(L.STATUS_SETTINGS,
        OnOff(db.enabled), db.style, OnOff(db.smooth), OnOff(db.glow), OnOff(db.pulse), OnOff(db.debug))
    ns:Print(L.STATUS_RESOURCES,
        db.resource == "mana" and L.RESOURCES_MANA_ONLY or L.RESOURCES_ALL,
        math.floor(db.fillAlpha * 100 + 0.5), math.floor(db.darkAlpha * 100 + 0.5))
    local colors = {}
    for _, key in ipairs(ns.RESOURCE_KEYS) do
        local hex = ns.ColorHex(db.colors[key])
        colors[#colors + 1] = string.format("%s |cff%s#%s|r", ns.ResourceName(key), hex, hex)
    end
    ns:Print(L.STATUS_COLORS, table.concat(colors, "   "))
    ns:Print(L.STATUS_WAVES, db.waves, OnOff(db.bubbles),
        ns.Options and ns.Options:StatusText() or L.NOT_LOADED)
    ns:Print(L.STATUS_WAVE_HEIGHT, db.waveHeight)
    do
        local own = {}
        for _, key in ipairs(ns.RESOURCE_KEYS) do
            if db.resStyles and db.resStyles[key] then
                own[#own + 1] = ns.ResourceName(key) .. " " .. db.resStyles[key]
            end
        end
        if #own > 0 then ns:Print(L.STATUS_RESOURCE_STYLES, table.concat(own, ", ")) end
    end
    do
        local own = {}
        for _, key in ipairs(ns.RESOURCE_KEYS) do
            for _, f in ipairs({ "waves", "waveHeight", "bubbles", "fillAlpha", "darkAlpha" }) do
                local v = ns:ResSettingOwn(key, f)
                if v ~= nil then
                    own[#own + 1] = string.format("%s %s %s", ns.ResourceName(key), f, tostring(v))
                end
            end
        end
        if #own > 0 then ns:Print(L.STATUS_RESOURCE_SETTINGS, table.concat(own, ", ")) end
    end
    ns:Print(L.STATUS_EXTRA, L["PRESET_" .. tostring(db.preset)], OnOff(not ns.root.minimap.hide), L["PROFILE_NAME_" .. string.upper(ns.root.profileMode)])

    ns:Print(L.STATUS_RANGELOOK, L["OPT_RANGE_STYLE_" .. string.upper(db.rangeStyle)], db.rangeColor,
        math.floor(db.rangeAlpha * 100 + 0.5), OnOff(db.rangeUsable))
    ns:Print(L.STATUS_SIGNALS, OnOff(db.range),
        ns.ActionBars:SoundLabel("ready"), L["OPT_ANIM_" .. string.upper(db.readyAnim)])
    ns:Print(L.STATUS_SOUNDSPELLS, OnOff(db.soundOnly), ns.ActionBars:SoundSpellList())

    if not ns.apiOK then
        ns:Print(L.STATUS_INACTIVE, table.concat(ns.missingAPIs or {}, ", "))
        return
    end

    local AB = ns.ActionBars
    local tracked, withCost, showing = AB:Counts()
    ns:Print(L.STATUS_BUTTONS, tracked, withCost, showing)
    ns:Print(L.STATUS_BAR_ADDONS, ns.BarAddons:Summary())
    local cdmIcons, cdmViewers = AB:CooldownManagerInfo()
    if cdmIcons then
        ns:Print(L.STATUS_CDM, cdmIcons, cdmViewers)
    else
        ns:Print(L.STATUS_CDM_NONE)
    end
    ns:Print(L.STATUS_GAMEPAD, AB.gamepadSkipped)
    local built, total, problem = AB:LiquidInfo()
    if built == total then
        ns:Print(L.STATUS_LIQUID_READY, total,
            ns.Animation:LiquidPlayingCount(), tostring(ns.Animation.scrollMethod),
            ns.Animation.bubbleProblem and string.format(L.STATUS_BUBBLES_OFF, ns.Animation.bubbleProblem) or "")
    else
        ns:Print(L.STATUS_LIQUID_PARTIAL, built, total, problem or L.UNKNOWN_REASON)
    end

    local states = {}
    for _, key in ipairs(ns.RESOURCE_KEYS) do
        if ns.Mana:IsTracked(key) and ns.Mana:HasPool(key) then
            local _, secret = ns.Mana:GetCurrent(key)
            states[#states + 1] = string.format(secret and L.RES_SECRET or L.RES_READABLE, ns.ResourceName(key))
        end
    end
    ns:Print(L.STATUS_YOUR_RESOURCES,
        #states > 0 and table.concat(states, ", ") or L.NONE_RIGHT_NOW,
        ns.Animation.hasNativeInterpolation and L.YES or L.NATIVE_NO)

    local notes = AB:FeatureNotes()
    if #notes > 0 then ns:Print(L.STATUS_FEATURES, table.concat(notes, "; ")) end
    if #ns.errors > 0 then ns:Print(L.STATUS_ERRORS, #ns.errors) end
end

-- The command stays English (that is what you type); the text is translated.
local HELP = {
    { "/mr options", "HELP_OPTIONS" },
    { "/mr on | off", "HELP_ONOFF" },
    { "/mr status", "HELP_STATUS" },
    { "/mr style liquid | flat | ice | paper | parchment", "HELP_STYLE" },
    { "/mr resourcestyle <mana|rage|energy|focus> <style> | default", "HELP_RESOURCE_STYLE" },
    { "/mr resset <res> <setting> <value>", "HELP_RESSET" },
    { "/mr range on | off", "HELP_RANGE" },
    { "/mr range color <hex> | opacity <5-100> | style tint | grey | border | usable on | off", "HELP_RANGE_LOOK" },
    { "/mr sound off | tick | chime | bell | custom <file or ID> | test", "HELP_SOUND" },
    { "/mr soundspell add <ability> | remove <ability> | list | clear | only on | off", "HELP_SOUNDSPELL" },
    { "/mr anim flash | sweep | double", "HELP_ANIM" },
    { "/mr resource all | mana", "HELP_RESOURCE" },
    { "/mr color [mana|rage|energy|focus] <hex> | reset", "HELP_COLOR" },
    { "/mr fxcolor <flash|pulse|sweep> <res> <hex>|auto", "HELP_FXCOLOR" },
    { "/mr opacity 0-100", "HELP_OPACITY" },
    { "/mr dark 0-100", "HELP_DARK" },
    { "/mr waves slow | normal | fast", "HELP_WAVES" },
    { "/mr intensity low | medium | high", "HELP_WAVE_HEIGHT" },
    { "/mr bubbles on | off", "HELP_BUBBLES" },
    { "/mr smooth on | off", "HELP_SMOOTH" },
    { "/mr glow on | off", "HELP_GLOW" },
    { "/mr pulse on | off", "HELP_PULSE" },
    { "/mr preset classic | fel | frost | colorblind", "HELP_PRESET" },
    { "/mr minimap on | off", "HELP_MINIMAP" },
    { "/mr profile account | class | character", "HELP_PROFILE" },
    { "/mr report", "HELP_REPORT" },
    { "/mr debug", "HELP_DEBUG" },
    { "/mr scan", "HELP_SCAN" },
    { "/mr test", "HELP_TEST" },
    { "/mr reset", "HELP_RESET" },
}
ns.HELP = HELP   -- for tests

local function SetToggle(key, cmd, arg, label)
    local value
    if arg == "on" then
        value = true
    elseif arg == "off" then
        value = false
    else
        ns:Print(L.USAGE_TOGGLE, cmd, ns.db[key] and L.ON or L.OFF)
        return
    end
    ns:SetOption(key, value)
    ns:Print(L.TOGGLE_SET, label, OnOff(ns.db[key]))
end

-- Percent settings (0-100, saved as 0-1). Accepts "40" or "40%".
local function SetPercent(key, cmd, arg, label)
    local n = tonumber((string.gsub(arg or "", "%%$", "")))
    if not n or n < 0 or n > 100 then
        ns:Print(L.USAGE_PERCENT, cmd, math.floor(ns.db[key] * 100 + 0.5))
        return
    end
    n = math.floor(n + 0.5)
    ns:SetOption(key, n / 100)
    ns:Print(L.PERCENT_SET, label, n)
end

local function Slash(input)
    if not ns.db then return end
    local rawInput = input
    input = string.lower(strtrim and strtrim(input or "") or (input or ""))
    local cmd, arg, arg2 = string.match(input, "^(%S*)%s*(%S*)%s*(%S*)")

    if cmd == "" or cmd == "help" then
        ns:Print(L.TAGLINE)
        for i = 1, #HELP do
            ns:Print("  %-23s - %s", HELP[i][1], L[HELP[i][2]])
        end
    elseif cmd == "options" or cmd == "config" then
        if ns.Options then ns.Options:Open() end
    elseif cmd == "on" then
        ns:SetOption("enabled", true)
        ns:Print(L.ENABLED)
    elseif cmd == "off" then
        ns:SetOption("enabled", false)
        ns:Print(L.DISABLED)
    elseif cmd == "status" then
        PrintStatus()
    elseif cmd == "style" then
        if not ns:SetOption("style", arg) then
            ns:Print(L.USAGE_STYLE, ns.db.style)
            return
        end
        ns:Print(L.STYLE_SET, arg)
        if ns.ActionBars and ns.ActionBars.restyleAfterCombat then
            ns:Print(L.STYLE_AFTER_COMBAT)
        end
    elseif cmd == "color" or cmd == "colour" then
        -- /mr color <hex>            mana (as before 1.3.0)
        -- /mr color rage <hex>       one resource
        -- /mr color reset            every resource back to its default
        -- /mr color energy reset     one resource back to its default
        local which, value = "mana", arg
        if IS_RESOURCE[arg] then which, value = arg, arg2 end
        if value == "reset" or value == "default" then
            local keys = (which == "mana" and not IS_RESOURCE[arg]) and ns.RESOURCE_KEYS or { which }
            for _, key in ipairs(keys) do ns:SetOption("color_" .. key, "FF" .. ns.DEFAULT_COLOR_HEX[key]) end
            if #keys > 1 then
                ns:Print(L.COLORS_RESET_ALL)
            else
                ns:Print(L.COLOR_RESET_ONE, ns.ResourceName(which))
            end
            return
        end
        if not ns:SetOption("color_" .. which, value) then
            ns:Print(L.USAGE_COLOR, ns.ResourceName(which), ns.ColorHex(ns.db.colors[which]))
            return
        end
        local hex = ns.ColorHex(ns.db.colors[which])
        ns:Print(L.COLOR_SET, ns.ResourceName(which), hex, hex)
    elseif cmd == "fxcolor" or cmd == "fxcolour" then
        -- /mr fxcolor <flash|pulse|sweep> <mana|rage|energy|focus> <hex>|auto
        -- /mr fxcolor reset          every effect color back to automatic
        local fx, res, value = string.match(input, "^%S+%s+(%S+)%s+(%S+)%s*(%S*)")
        if fx == "reset" or arg == "reset" then
            for _, f in ipairs(ns.FX_ORDER) do
                for _, r in ipairs(ns.RESOURCE_KEYS) do ns:SetOption("fx_" .. f .. "_" .. r, "auto") end
            end
            ns:Print(L.FXCOLORS_RESET)
            return
        end
        if not (fx and ns.FX_KEYS[fx] and res and IS_RESOURCE[res] and value ~= ""
            and ns:SetOption("fx_" .. fx .. "_" .. res, value)) then
            ns:Print(L.USAGE_FXCOLOR)
            return
        end
        local c = ns:EffectColor(res, fx)
        if c then
            local hex = ns.ColorHex(c)
            ns:Print(L.FXCOLOR_SET, fx, ns.ResourceName(res), hex, hex)
        else
            ns:Print(L.FXCOLOR_AUTO, fx, ns.ResourceName(res))
        end
    elseif cmd == "resource" or cmd == "resources" then
        if not ns:SetOption("resource", arg) then
            ns:Print(L.USAGE_RESOURCE, ns.db.resource)
            return
        end
        ns:Print(arg == "mana" and L.RESOURCE_SET_MANA or L.RESOURCE_SET_ALL)
    elseif cmd == "waves" then
        if not ns:SetOption("waves", arg) then
            ns:Print(L.USAGE_WAVES, ns.db.waves)
            return
        end
        ns:Print(L.WAVES_SET, arg)
    elseif cmd == "resourcestyle" or cmd == "resstyle" then
        if not IS_RESOURCE[arg] or not ns:SetOption("resstyle_" .. arg, arg2) then
            ns:Print(L.USAGE_RESOURCE_STYLE)
            return
        end
        ns:Print(L.RESOURCE_STYLE_SET, ns.ResourceName(arg), arg2)
    elseif cmd == "resset" then
        -- /mr resset <resource> waves|intensity|bubbles|opacity|dark <value>|default
        local res, what, value = string.match(input, "^%S+%s+(%S+)%s+(%S+)%s*(%S*)")
        local prefix = ({ waves = "reswaves", intensity = "reswaveheight", bubbles = "resbubbles",
            opacity = "resopacity", dark = "resdark" })[what or ""]
        local v = value
        if prefix == "resbubbles" and value ~= "default" then
            v = ({ on = true, off = false })[value]
        elseif (prefix == "resopacity" or prefix == "resdark") and value ~= "default" then
            local n = tonumber((string.gsub(value, "%%$", "")))
            v = n and n >= 0 and n <= 100 and n / 100 or nil
        end
        if not (res and IS_RESOURCE[res] and prefix and value ~= "" and v ~= nil
            and ns:SetOption(prefix .. "_" .. res, v)) then
            ns:Print(L.USAGE_RESSET)
            return
        end
        ns:Print(L.RESSET_SET, ns.ResourceName(res), what, value)
    elseif cmd == "intensity" then
        if not ns:SetOption("waveHeight", arg) then
            ns:Print(L.USAGE_WAVE_HEIGHT, ns.db.waveHeight)
            return
        end
        ns:Print(L.WAVE_HEIGHT_SET, arg)
    elseif cmd == "bubbles" then
        SetToggle("bubbles", "bubbles", arg, L.LBL_BUBBLES)
    elseif cmd == "opacity" or cmd == "alpha" or cmd == "transparency" then
        SetPercent("fillAlpha", "opacity", arg, L.LBL_OPACITY)
    elseif cmd == "dark" then
        SetPercent("darkAlpha", "dark", arg, L.LBL_DARK)
    elseif cmd == "smooth" then
        SetToggle("smooth", "smooth", arg, L.LBL_SMOOTH)
    elseif cmd == "glow" then
        SetToggle("glow", "glow", arg, L.LBL_GLOW)
    elseif cmd == "pulse" then
        SetToggle("pulse", "pulse", arg, L.LBL_PULSE)
    elseif cmd == "range" and arg == "color" then
        if ns:SetOption("rangeColor", arg2) then
            ns:Print(L.RANGE_SET, L.OPT_RANGE_COLOR, "#" .. ns.db.rangeColor)
        else
            ns:Print(L.USAGE_RANGE, ns.db.rangeColor)
        end
    elseif cmd == "range" and (arg == "opacity" or arg == "alpha") then
        local n = tonumber((string.gsub(arg2, "%%$", "")))
        if n and ns:SetOption("rangeAlpha", n / 100) then
            ns:Print(L.RANGE_SET, L.OPT_RANGE_ALPHA, math.floor(ns.db.rangeAlpha * 100 + 0.5) .. "%")
        else
            ns:Print(L.USAGE_RANGE, ns.db.rangeColor)
        end
    elseif cmd == "range" and arg == "style" then
        if ns:SetOption("rangeStyle", arg2) then
            ns:Print(L.RANGE_SET, L.OPT_RANGE_STYLE, L["OPT_RANGE_STYLE_" .. string.upper(ns.db.rangeStyle)])
        else
            ns:Print(L.USAGE_RANGE, ns.db.rangeColor)
        end
    elseif cmd == "range" and arg == "usable" then
        if arg2 == "on" or arg2 == "off" then
            ns:SetOption("rangeUsable", arg2 == "on")
            ns:Print(L.RANGE_SET, L.OPT_RANGE_USABLE, OnOff(ns.db.rangeUsable))
        else
            ns:Print(L.USAGE_RANGE, ns.db.rangeColor)
        end
    elseif cmd == "range" then
        SetToggle("range", "range", arg, L.LBL_RANGE)
    elseif cmd == "sound" then
        local slot, key = "ready", "sound"
        local usage, label = L.USAGE_SOUND, L.SLOT_READY
        local AB = ns.ActionBars
        local function Name() return AB:SoundLabel(slot) end
        if arg == "test" then
            AB:PlaySlot(slot, ns.db[key] ~= "off" and ns.db[key] or "tick", true)
        elseif arg == "custom" then
            -- everything after "custom" is the file path or ID, in the case it was typed
            local text = string.match(strtrim(rawInput or ""), "^%S+%s+%S+%s+(.+)$")
            if not text or not ns:SetOption(key .. "Custom", text) then
                ns:Print(usage, Name())
            else
                ns:SetOption(key, "custom")
                ns:Print(L.SOUND_SET, label, Name())
                AB:PlaySlot(slot, "custom", true)
            end
        elseif not ns:SetOption(key, ns.SOUND_PACK_ARG[arg] or arg) then
            ns:Print(usage, Name())
        else
            ns:Print(L.SOUND_SET, label, Name())
            if arg ~= "off" then AB:PlaySlot(slot, ns.db[key], true) end
        end
    elseif cmd == "soundspell" then
        local AB = ns.ActionBars
        -- the ability is everything after the sub-command, in the case it was typed
        local rest = string.match(strtrim(rawInput or ""), "^%S+%s+%S+%s*(.*)$") or ""
        if arg == "add" and rest ~= "" then
            local id, name = AB:ResolveSpellText(rest)
            if id then
                ns.db.soundSpells[id] = true
                ns:Print(L.SOUNDSPELL_ADDED, name or rest, id)
                if not ns.db.soundOnly then ns:Print(L.SOUNDSPELL_HINT) end
            else
                ns:Print(L.SOUNDSPELL_UNKNOWN, rest)
            end
        elseif arg == "remove" and rest ~= "" then
            local id, name = AB:ResolveSpellText(rest)
            if id and ns.db.soundSpells[id] then
                ns.db.soundSpells[id] = nil
                ns:Print(L.SOUNDSPELL_REMOVED, name or rest)
            else
                ns:Print(L.SOUNDSPELL_UNKNOWN, rest)
            end
        elseif arg == "list" then
            ns:Print(L.SOUNDSPELL_LIST, AB:SoundSpellList())
        elseif arg == "clear" then
            wipe(ns.db.soundSpells)
            ns:Print(L.SOUNDSPELL_CLEARED)
        elseif arg == "only" and (arg2 == "on" or arg2 == "off") then
            ns:SetOption("soundOnly", arg2 == "on")
            ns:Print(L.SOUNDONLY_SET, OnOff(ns.db.soundOnly), AB:SoundSpellList())
        else
            ns:Print(L.USAGE_SOUNDSPELL)
        end
    elseif cmd == "anim" or cmd == "animation" then
        if not ns:SetOption("readyAnim", arg) then
            ns:Print(L.USAGE_ANIM, L["OPT_ANIM_" .. string.upper(ns.db.readyAnim)])
        else
            ns:Print(L.ANIM_SET, L["OPT_ANIM_" .. string.upper(arg)])
        end
    elseif cmd == "minimap" then
        local value
        if arg == "on" then value = true elseif arg == "off" then value = false end
        if value == nil then
            ns:Print(L.USAGE_TOGGLE, "minimap", ns.root.minimap.hide and L.OFF or L.ON)
            return
        end
        ns:SetOption("minimap", value)
        ns:Print(L.TOGGLE_SET, L.LBL_MINIMAP, OnOff(value))
        if not value then ns:Print(L.MM_HIDDEN_HINT) end
    elseif cmd == "panel" then
        -- troubleshooting: take ManaRise out of the game's settings window
        -- (applies after /reload)
        local modes = { on = false, off = "off" }
        if modes[arg] == nil and arg ~= "on" then
            ns:Print("/mr panel on | off  (now: " .. tostring(ns.root.panelMode or "on") .. "). Needs /reload.")
            return
        end
        ns.root.panelMode = modes[arg] or nil
        ns:Print("settings page mode: " .. (arg) .. ". Type /reload to apply.")
    elseif cmd == "preset" then
        if not ns.PRESETS[arg] or not ns:SetOption("preset", arg) then
            ns:Print(L.USAGE_PRESET, L["PRESET_" .. tostring(ns.db.preset)])
            return
        end
        ns:Print(L.PRESET_SET, L["PRESET_" .. arg])
    elseif cmd == "profile" then
        if not ns.PROFILE_MODES[arg] then
            ns:Print(L.USAGE_PROFILE, ns.root.profileMode)
            return
        end
        ns:SetOption("profileMode", arg)
        if arg == "character" then
            ns:Print(L.PROFILE_CHARACTER, ns.CharacterKey())
        elseif arg == "class" then
            ns:Print(L.PROFILE_CLASS, (UnitClass and UnitClass("player")) or "?")
        else
            ns:Print(L.PROFILE_ACCOUNT)
        end
    elseif cmd == "report" then
        if ns.Report then ns.Report:Show() end
    elseif cmd == "debug" then
        ns.db.debug = not ns.db.debug
        ns:Print(L.DEBUG_SET, OnOff(ns.db.debug))
        if ns.db.debug and ns.ActionBars then
            ns.ActionBars:ResetReasons()
            ns:Schedule("slots")
        end
    elseif cmd == "scan" then
        if ns.apiOK then ns.ActionBars:PrintScan() end
    elseif cmd == "test" then
        if not ns.apiOK then return end
        if arg == "stop" then
            ns.ActionBars:StopSimulation(false)
        else
            ns.ActionBars:StartSimulation()
        end
    elseif cmd == "reset" then
        ns:ResetDB()
        ns:Print(L.SETTINGS_RESET)
        ns:ApplySettings()
        if ns.Options then ns.Options:Refresh() end
    else
        ns:Print(L.UNKNOWN_COMMAND, cmd)
    end
end

SLASH_MANARISE1 = "/manarise"
SLASH_MANARISE2 = "/mr"
SlashCmdList["MANARISE"] = Slash
