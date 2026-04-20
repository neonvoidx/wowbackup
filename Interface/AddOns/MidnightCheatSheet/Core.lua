----------------------------------------------------------------------
-- MidnightCheatSheet – Core.lua
----------------------------------------------------------------------
local ADDON_NAME, MCS = ...

local pairs, ipairs, format, tostring, tonumber = pairs, ipairs, format, tostring, tonumber
local select = select
local table_insert, table_sort = table.insert, table.sort
local CreateFrame = CreateFrame
local GetSpecialization, GetSpecializationInfo = GetSpecialization, GetSpecializationInfo
local GetNumSpecializationsForClassID = GetNumSpecializationsForClassID
local GetSpecializationInfoForClassID = GetSpecializationInfoForClassID
local UnitClass = UnitClass
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local C_Item = C_Item
local Item = Item
local ReloadUI = ReloadUI
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME

MCS.VERSION = "0.14.0"

MCS.ALL_SPECS = {
    DEATHKNIGHT  = { "Blood", "Frost", "Unholy" },
    DEMONHUNTER  = { "Havoc", "Vengeance", "Devourer" },
    DRUID        = { "Balance", "Feral", "Guardian", "Restoration" },
    EVOKER       = { "Devastation", "Preservation", "Augmentation" },
    HUNTER       = { "Beast Mastery", "Marksmanship", "Survival" },
    MAGE         = { "Arcane", "Fire", "Frost" },
    MONK         = { "Brewmaster", "Mistweaver", "Windwalker" },
    PALADIN      = { "Holy", "Protection", "Retribution" },
    PRIEST       = { "Discipline", "Holy", "Shadow" },
    ROGUE        = { "Assassination", "Outlaw", "Subtlety" },
    SHAMAN       = { "Elemental", "Enhancement", "Restoration" },
    WARLOCK      = { "Affliction", "Demonology", "Destruction" },
    WARRIOR      = { "Arms", "Fury", "Protection" },
}

function MCS:GetPlayerSpec()
    local idx = GetSpecialization()
    if not idx then return nil, nil end
    local _, name, _, _, _, role = GetSpecializationInfo(idx)
    return name, role
end
function MCS:GetPlayerClass() local _, c = UnitClass("player"); return c end
function MCS:ClassColor(cls)
    local c = RAID_CLASS_COLORS[cls or self:GetPlayerClass()]
    return c and c.r or 1, c and c.g or 1, c and c.b or 1
end
function MCS:MakeSpecKey(cls, spec)
    if not cls or not spec then return nil end
    return cls .. "_" .. spec:upper():gsub(" ", "_")
end
function MCS:SpecKey() return self:MakeSpecKey(self.currentClass, self.currentSpec) end

--- Get the icon texture ID for a spec name on the player's class
MCS.CLASS_IDS = {
    WARRIOR=1, PALADIN=2, HUNTER=3, ROGUE=4, PRIEST=5, DEATHKNIGHT=6,
    SHAMAN=7, MAGE=8, WARLOCK=9, MONK=10, DRUID=11, DEMONHUNTER=12, EVOKER=13,
}
function MCS:GetSpecIcon(specName, cls)
    if not specName then return nil end
    local classID
    if cls then
        classID = self.CLASS_IDS[cls]
    else
        classID = select(3, UnitClass("player"))
    end
    if not classID then return nil end
    local numSpecs = GetNumSpecializationsForClassID and GetNumSpecializationsForClassID(classID) or 0
    for i = 1, numSpecs do
        local _, name, _, icon = GetSpecializationInfoForClassID(classID, i)
        if name == specName then return icon end
    end
    return nil
end
function MCS:AllSpecKeys()
    local out = {}
    for cls, specs in pairs(self.ALL_SPECS) do
        for _, spec in ipairs(specs) do
            table_insert(out, { key = self:MakeSpecKey(cls, spec), class = cls, spec = spec })
        end
    end
    table_sort(out, function(a, b) return a.key < b.key end)
    return out
end
function MCS:GetItemLink(id)
    if not id then return nil end
    local _, link = C_Item.GetItemInfo(id); return link
end
function MCS:FormatNumber(n)
    if not n then return "?" end
    if n >= 1000 then
        local s = tostring(n)
        local pos = #s % 3
        if pos == 0 then pos = 3 end
        return s:sub(1, pos) .. s:sub(pos+1):gsub("(%d%d%d)", ",%1")
    end
    return tostring(n)
end
function MCS:CacheItem(id, cb)
    if not id then return end
    local item = Item:CreateFromItemID(id)
    item:ContinueOnItemLoad(function() if cb then cb(id) end end)
end

----------------------------------------------------------------------
-- Init
----------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
f:SetScript("OnEvent", function(_, ev, a1)
    if ev == "ADDON_LOADED" and a1 == ADDON_NAME then
        if not MCSdb then MCSdb = {} end
        if not MCSdb.wishlists then MCSdb.wishlists = {} end
        if not MCSdb.tooltipLists then MCSdb.tooltipLists = {} end
        if MCSdb.tooltipOtherClasses == nil then MCSdb.tooltipOtherClasses = true end
        if not MCSdb.windowWidth then MCSdb.windowWidth = 480 end
        if not MCSdb.windowHeight then MCSdb.windowHeight = 560 end
        if not MCSdb.uiScale then MCSdb.uiScale = 1.0 end
        if not MCSdb.ejSelectorPos then MCSdb.ejSelectorPos = nil end
        MCS.db = MCSdb
        -- Migrate old flat wishlists to new {specKey={listName={...}}} format
        for specKey, data in pairs(MCS.db.wishlists) do
            if data[1] and data[1].itemID then
                -- Old format: flat array → move to "Raid ST"
                MCS.db.wishlists[specKey] = { ["Raid ST"] = data }
            end
        end
    elseif ev == "PLAYER_LOGIN" then
        MCS:Refresh()
        MCS:InitUI()
        MCS:HookDungeonJournal()
        local s = MCS.currentSpec or "?"
        local r, g, b = MCS:ClassColor()
        DEFAULT_CHAT_FRAME:AddMessage(format(
            "|cff00ccff[MCS]|r v%s — |cff%02x%02x%02x%s %s|r — /mcs to toggle. Alt-click items in DJ to wishlist.",
            MCS.VERSION, r*255, g*255, b*255, s, UnitClass("player") or ""))
        MCS:ScheduleLoginMessage()
    elseif ev == "ACTIVE_TALENT_GROUP_CHANGED" or ev == "PLAYER_SPECIALIZATION_CHANGED" then
        MCS:Refresh()
    end
end)

function MCS:Refresh()
    self.currentSpec, self.currentRole = self:GetPlayerSpec()
    self.currentClass = self:GetPlayerClass()
    self.gearTabSpec = nil  -- reset so Consumables tab defaults to new active spec
    self.statsTabSpec = nil  -- reset so Stats tab defaults to new active spec
    if self.UpdateUI then self:UpdateUI() end
end

SLASH_MCS1 = "/mcs"
SLASH_MCS2 = "/cheatsheet"
SlashCmdList["MCS"] = function(msg)
    msg = strtrim(msg):lower()
    if msg == "reset" then MCSdb = nil; ReloadUI()
    elseif msg == "wishlist" then MCS:PrintWishlist()
    elseif msg == "minimap" then MCS:ToggleMinimapButton()
    else MCS:Toggle() end
end

----------------------------------------------------------------------
-- Easter egg: guild-only login messages
----------------------------------------------------------------------
local GUILD_MSGS = {
    "Did you know that Ch\195\187d once tamed Deathwing? He released it because it wasn't BiS.",
    "Did you know that Ch\195\187d's Aimed Shot has its own postal code?",
    "Did you know that bosses check their Dungeon Journal to prepare for Ch\195\187d?",
    "Did you know that Ch\195\187d doesn't Feign Death? Death feigns Ch\195\187d.",
    "Did you know that Ch\195\187d's pet doesn't need to be fed? It feeds off the tears of his enemies.",
    "Did you know that Ch\195\187d once Multi-Shot a single target and it still cleaved? Out of respect.",
    "Did you know that Ch\195\187d's Misdirection doesn't transfer threat? The boss was already too scared to look at him.",
    "Did you know that Ch\195\187d tamed a spirit beast on his first attempt? The beast tamed itself.",
    "Did you know that when Ch\195\187d uses Aspect of the Turtle, the turtle feels honored?",
    "Did you know that Ch\195\187d's Barrage has never pulled extra mobs? They run before it reaches them.",
    "Did you know that Ch\195\187d once dismissed his pet mid-raid? His DPS went up because the boss surrendered.",
    "Did you know that Ch\195\187d's traps don't have an arming time? They're armed by his reputation alone.",
    "Did you know that Ch\195\187d's Kill Shot works at any health percentage? Bosses just accept it.",
    "Did you know that Ch\195\187d doesn't use a quiver? Arrows volunteer.",
    "Did you know that Ch\195\187d's Tranquilizing Shot calms the entire raid, including the healers?",
    "Did you know that Ch\195\187d's DPS is so high, Details! had to add scientific notation?",
    "Did you know that Warcraft Logs had to create a new percentile bracket just for Ch\195\187d? It's called the Ch\195\187d bracket.",
    "Did you know that when Ch\195\187d parses, the graph goes off-screen?",
    "Did you know that Ch\195\187d's grey parses on alts are still higher than your mains?",
    "Did you know that Ch\195\187d once AFK'd for 30 seconds and still topped the meters?",
    "Did you know that Ch\195\187d's auto-attacks have been reported as a DPS exploit?",
    "Did you know that Details! crashes when Ch\195\187d presses all cooldowns at once?",
    "Did you know that Ch\195\187d doesn't sim his character? SimulationCraft sims itself against Ch\195\187d.",
    "Did you know that Ch\195\187d's DPS is technically classified as a natural disaster?",
    "Did you know that the damage meters go: Tank, Healer, DPS, and then Ch\195\187d?",
    "Did you know that Ch\195\187d once used a level 1 bow in a Mythic raid? Logs still showed it as BiS.",
    "Did you know that Ch\195\187d's opener has its own WeakAura? It's just a skull.",
    "Did you know that Ch\195\187d doesn't need BiS gear? BiS gear needs Ch\195\187d.",
    "Did you know that Ch\195\187d vendored a Mythic weapon because it was a DPS downgrade from his whites?",
    "Did you know that items gain +5 ilvl when Ch\195\187d equips them? Out of pride.",
    "Did you know that Ch\195\187d's gear has a separate tooltip that just says 'Worn by Ch\195\187d'?",
    "Did you know that the Great Vault offers Ch\195\187d seven choices? All of them are apologies.",
    "Did you know that Ch\195\187d's BiS list is whatever he's currently wearing?",
    "Did you know that Ch\195\187d once enchanted a fishing pole and cleared a Mythic+ with it?",
    "Did you know that loot doesn't drop for Ch\195\187d? It applies for the position.",
    "Did you know that Ch\195\187d's alts get personal loot from bosses he killed on his main?",
    "Did you know that Ch\195\187d wrote this addon in one night while topping the meters?",
    "Did you know that Ch\195\187d once three-chested a key by entering the dungeon?",
    "Did you know that Ch\195\187d doesn't need a healer in M+? His DPS heals the group through sheer morale.",
    "Did you know that Ch\195\187d has timed every key at +30? Including ones that don't exist yet?",
    "Did you know that when Ch\195\187d joins a pug, the IO requirement removes itself?",
    "Did you know that dungeon mobs see Ch\195\187d's group forming and start negotiating surrender terms?",
    "Did you know that Ch\195\187d once completed a Mythic+ so fast the timer went negative?",
    "Did you know that Ch\195\187d's interrupts are so fast, the mob forgets what spell it was casting?",
    "Did you know that Ch\195\187d doesn't dodge mechanics? Mechanics dodge Ch\195\187d.",
    "Did you know that Ch\195\187d has never caused a wipe? Wipes cause themselves out of embarrassment when he's watching.",
    "Did you know that raid bosses have a hidden enrage timer called 'before Ch\195\187d gets bored'?",
    "Did you know that Ch\195\187d once soloed a raid boss during a bio break? He was the one on bio.",
    "Did you know that Midnight was originally called 'The Ch\195\187d Expansion' but Blizzard thought it was too intimidating?",
    "Did you know that The Nine Divines is actually named after Ch\195\187d's nine alts?",
    "Did you know that Ch\195\187d's character was the original model for every hunter NPC in the game?",
    "Did you know that Blizzard nerfed Survival because Ch\195\187d looked at it once?",
    "Did you know that Ch\195\187d doesn't read patch notes? Patch notes read Ch\195\187d.",
    "Did you know that Ch\195\187d's /played is classified by Blizzard as a trade secret?",
    "Did you know that the loading screen tips are actually things Ch\195\187d said in guild chat?",
    "Did you know that Ch\195\187d was offered a job at Blizzard? He declined because it would be a nerf to his lifestyle.",
    "Did you know that Rexxar learned everything he knows from a YouTube video Ch\195\187d posted?",
    "Did you know that Ch\195\187d's hearthstone cooldown is 0 seconds? Azeroth comes to him.",
    "Did you know that Ch\195\187d doesn't log out? The server asks for a break.",
    "Did you know that Ch\195\187d's character creation took 5 minutes? He just typed 'perfection' and hit enter.",
    "Did you know that Sylvanas burned Teldrassil because Ch\195\187d ganked her in Darkshore?",
    "Did you know that the Arbiter went dormant after judging Ch\195\187d's soul? Nothing could compare.",
    "Did you know that Ch\195\187d doesn't use a mount? Azeroth rotates beneath his feet.",
    "Did you know that Ch\195\187d's auction house posts set the server economy?",
    "Did you know that when Ch\195\187d queues for LFR, it becomes Mythic automatically?",
    "Did you know that Ch\195\187d's guild application was just his name? It was enough.",
    "Did you know that The Nine Divines' guild bank is just Ch\195\187d's pocket change?",
    "Did you know that Ch\195\187d's weakauras have weakauras?",
    "Did you know that people don't inspect Ch\195\187d's gear? They just feel its presence.",
    "Did you know that Ch\195\187d's macro collection has been submitted to the Louvre?",
    "Did you know that Ch\195\187d doesn't need Discord? The raid hears him through the screen.",
    "Did you know that guild recruitment doubled after Ch\195\187d joined? People just sensed it.",
    "Did you know that Ch\195\187d's UI layout has been peer-reviewed and published?",
    "Did you know that Ch\195\187d doesn't need a WeakAura for boss timers? He IS the timer.",
    "Did you know that Ch\195\187d's PvP rating is an imaginary number? It transcends the ladder.",
    "Did you know that Ch\195\187d doesn't CC enemies in PvP? They CC themselves out of fear.",
    "Did you know that arena teams concede when they see Ch\195\187d in the loading screen?",
    "Did you know that Ch\195\187d's Kill Command works in the opposing faction's capital city? From Ravencrest.",
    "Did you know that Ch\195\187d's fishing skill is so high, Old Ironjaw caught itself?",
    "Did you know that Ch\195\187d has all achievements? Including the ones that haven't been added yet?",
    "Did you know that Ch\195\187d leveled to max in one session? The XP bar was too afraid to slow down.",
    "Did you know that Ch\195\187d's professions level themselves while he sleeps?",
    "Did you know that Ch\195\187d's Hearthstone always crits?",
    "Did you know that battle pets forfeit when they see Ch\195\187d's team?",
    "Did you know that Ch\195\187d doesn't farm reputation? Factions grind rep with Ch\195\187d.",
    "Did you know that Ch\195\187d has never failed a mission table quest? The followers are too motivated.",
    "Did you know that Ch\195\187d's bank alt has a higher gearscore than most mains?",
    "Did you know that Ch\195\187d discovered a secret 5th talent row? Blizzard told him to keep it quiet.",
    "Did you know that Ch\195\187d completed the Mage Tower on every class? As a hunter.",
    "Did you know that when Ch\195\187d deletes a character, the server mourns for a week?",
    "Did you know that Ch\195\187d's transmog is so legendary, NPCs stop to compliment him?",
    "Did you know that Ch\195\187d once vendored an item and the vendor's stock went up in quality?",
    "Did you know that Ch\195\187d doesn't train new abilities. New abilities train to be worthy of Ch\195\187d.",
    "Did you know that this addon was built from pure chad energy and a bit of Lua?",
    "Did you know that Ch\195\187d doesn't need MidnightCheatSheet? He wrote it for the rest of us mortals.",
    -- Fapandtrap references
    "Did you know that Ch\195\187d and Fap once dueled for 3 hours? Ch\195\187d was AFK for the first 2 hours and 59 minutes.",
    "Did you know that Fap's DPS is actually impressive? It's the second highest hunter in the guild. By a large margin.",
    "Did you know that Fap once beat Ch\195\187d on the meters? Just kidding. Did you actually believe that?",
    "Did you know that Fap named himself Fapandtrap because he couldn't be named Ch\195\187d? That was taken.",
    "Did you know that Fap is the only hunter alive who's made Ch\195\187d proud? Don't tell him though, it'll go to his head.",
}

local FAP_POEMS = {
    "Roses are red, your traps are on point, but my Aimed Shot crits harder, don't let that disappoint.",
    "Dear Fap, you're the wind beneath my Disengage. Love, Ch\195\187d.",
    "If I had one Kill Command left, I'd use it on your heart. Just kidding, I'd use it on the boss. But you'd be a close second.",
    "They say love is blind, but my Hunter's Mark always finds you, Fap.",
    "Fap, you complete my rotation. Not optimally, but emotionally.",
    "I don't need Misdirection to send my love to you, Fap. It finds its way naturally.",
    "Fap, if you were a trinket, you'd be my second best-in-slot. And that's the highest compliment I give.",
    "Every time you Feign Death, a part of me dies too. Then I top the meters and feel better.",
    "Our love is like a Mythic+ key: sometimes depleted, but always worth pushing.",
    "Fap, you're the only hunter I'd share loot with. Hypothetically. Don't actually need anything.",
    "Fap, they say two hunters are better than one. They're wrong, but I like having you around anyway.",
    "I wrote this addon for the guild, but the real feature is being in the same raid as you, Fap.",
    "Fap, you're like my second pet. Not as useful as the first, but I'd never dismiss you.",
    "Roses are red, Aimed Shot is true, I'd share my Bloodlust, but only with you.",
    "Fap, if love were a parse, ours would be a solid 60. You bring down the average but I don't mind.",
    "Dear Fap, you are my Lone Wolf buff that I refuse to give up. Even if the math says I should.",
    "Fap, when you die to mechanics, a little part of me wants to Feign Death too. In solidarity.",
    "They say keep your friends close and your enemies closer. That's why I check your logs daily, Fap.",
    "Fap, our bond is like Bestial Wrath. Unstoppable, slightly unhinged, and on a short cooldown.",
    "If I could Tame you, Fap, I would. You'd be exotic quality at least. Maybe rare.",
    "Fap, you're the Arcane Shot of my heart. Not the strongest, but always reliable.",
    "Every raid night I look at the meters. First I find my name. Then I find yours. It's our little ritual.",
    "Dear Fap, some hunters are born great. Others have Ch\195\187d in their guild. You're welcome.",
    "Fap, if we were the last two hunters on Azeroth, I'd still top the meters. But I'd feel bad about it.",
    "I don't say this often, but you're the only hunter I wouldn't Misdirect a pack of trash mobs to. Most days.",
    "Fap, our friendship is like a two-hunter comp. Technically suboptimal, but I wouldn't have it any other way.",
    "Some people have soulmates. I have a raidmate. Close enough, Fap.",
    "Fap, you're the reason I bring Aspect of the Pack. So you can keep up. With my love.",
    "Dear Fap, I once had a dream we tied on the meters. Then I woke up. But it was a nice dream.",
    "Fap, you are the peanut butter to my jelly. The trap to my fap. Wait, that came out wrong. Love, Ch\195\187d.",
}

function MCS:ScheduleLoginMessage()
    C_Timer.After(25, function()
        local guild = GetGuildInfo("player")
        if not guild or guild ~= "The Nine Divines" then return end
        local name = UnitName("player")
        local msg
        if name == "Fapandtrap" then
            msg = FAP_POEMS[math.random(#FAP_POEMS)]
            DEFAULT_CHAT_FRAME:AddMessage("|cffFF8040" .. msg .. "|r")
        else
            msg = GUILD_MSGS[math.random(#GUILD_MSGS)]
            DEFAULT_CHAT_FRAME:AddMessage("|cffFF8040" .. msg .. "|r")
        end
    end)
end

----------------------------------------------------------------------
-- Wishlist printing
----------------------------------------------------------------------
function MCS:PrintWishlist()
    local key = self:SpecKey()
    local lists = self:GetListNames(key)
    local any = false
    for _, ln in ipairs(lists) do
        local wl = self:GetWishlist(key, ln)
        if #wl > 0 then
            any = true
            print(format("|cff00ccff[MCS]|r %s — %s (%d):", self:FormatSpecKey(key), ln, #wl))
            for _, e in ipairs(wl) do
                local link = self:GetItemLink(e.itemID)
                local src = e.source ~= "" and (" |cff888888(" .. e.source .. ")|r") or ""
                print("  " .. (link or ("item:" .. e.itemID)) .. src)
            end
        end
    end
    if not any then print("|cff00ccff[MCS]|r No wishlisted items.") end
end
