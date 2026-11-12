local GQ = _G.GearQuest
if not GQ then return end

-- Shared sentence rules for locales without a hand-written rules file.
-- A locale calls GQ.AddPhraseRules(P) with a phrase table: each entry is a
-- template where {1}, {2}... are the already translated pieces (names via
-- GQ.LocaleNames and the client, numbers as they are). A missing entry
-- leaves that sentence shape in English.
--
-- frFR and deDE keep their own rules files: their grammar (articles,
-- elision, cases) needs more than templates.

local L = GQ.L

local function Fill(template, ...)
    local args = { ... }
    return (template:gsub("{(%d)}", function(i)
        return tostring(args[tonumber(i)] or "")
    end))
end

function GQ.AddPhraseRules(P)
    local rules = GQ.LocaleRules
    GQ.LocaleObjectiveLabel = P.objective or GQ.LocaleObjectiveLabel

    local function Any(name)
        return GQ.TAny(name)
    end
    local function Zone(name)
        return GQ.TN("zone", name)
    end
    local function Quest(name)
        return Fill(P.quote or "'{1}'", GQ.TN("quest", name))
    end
    local function Thing(name)
        local bare = name:gsub("^[Tt]he ", ""):gsub("^an? ", "")
        local translated = Any(bare)
        if translated ~= bare then
            return translated
        end
        if bare:sub(-1) == "s" and Any(bare:sub(1, -2)) ~= bare:sub(1, -2) then
            return Any(bare:sub(1, -2))
        end
        return name
    end
    local function List(text)
        text = text:gsub(",? and ", ", ")
        local parts = {}
        for piece in (text .. ", "):gmatch("(.-), ") do
            local count, name = piece:match("^(%d+) (.+)$")
            if count then
                parts[#parts + 1] = Fill(P.count or "{1}x {2}", count, Thing(name))
            elseif piece ~= "" then
                parts[#parts + 1] = Thing(piece)
            end
        end
        if #parts == 1 then
            return parts[1] or text
        end
        return table.concat(parts, P.comma or ", ", 1, #parts - 1) .. (P["and"] or " & ") .. parts[#parts]
    end
    local function NpcAt(text)
        local who, where = text:match("^(.+) in (.+)$")
        if not who then
            who, where = text:match("^(.+) at (.+)$")
            where = where and where:gsub("^the ", "")
        end
        if who then
            return Fill(P.npc_at or "{1} ({2})", Any(who), Zone(where))
        end
        return Any(text)
    end
    local function Stat(name)
        local word = P.stats and P.stats[name]
        if word then
            return word
        end
        local translated = L[name]
        if translated ~= name then
            return translated
        end
        local cap = name:sub(1, 1):upper() .. name:sub(2):lower()
        translated = L[cap]
        return translated ~= cap and translated or nil
    end
    local function Rest(text)
        if GQ.TL then
            return GQ.TL(text)
        end
        return GQ.LocaleTranslateSentence(text)
    end
    -- "A, B, and C in Zone, from D in Zone, and from E in Zone."
    local function DropPlace(chunk)
        local names, zone = chunk:match("^(.*) in (.-)$")
        if names and names ~= "" and zone and zone ~= "" then
            zone = zone:gsub("^the ", "")
            return Fill(P.names_in or "{1} ({2})", List(names), Zone(zone))
        end
        return List(chunk)
    end
    local function DropPlaces(text)
        local marked = text:gsub(", and from ", "\n"):gsub(" and from ", "\n"):gsub(", from ", "\n")
        local parts = {}
        for piece in (marked .. "\n"):gmatch("(.-)\n") do
            if piece ~= "" then
                parts[#parts + 1] = DropPlace(piece)
            end
        end
        if #parts <= 1 then
            return parts[1] or List(text)
        end
        return table.concat(parts, P.place_sep or "; ")
    end

    -- add(key, pattern, function(captures...) return piece1, piece2... end)
    local function add(key, pattern, pieces)
        local template = P[key]
        if not template then
            return
        end
        rules[#rules + 1] = { pattern, function(...)
            if pieces then
                return Fill(template, pieces(...))
            end
            return Fill(template, ...)
        end }
    end
    local function Standing(s)
        return L[s]
    end
    local function Faction(f)
        return GQ.TN("faction", f)
    end

    -- Sources
    add("reward_quest_pick", "^Reward from the quest '(.+)'%. Pick it over the other reward choices%.$", function(q) return Quest(q) end)
    add("reward_quest_last", "^Reward from the quest '(.+)', the last of (%a+) steps%.$", function(q, n) return Quest(q), (P.numbers and P.numbers[n]) or n end)
    add("reward_quest", "^Reward from the quest '(.+)'%.$", function(q) return Quest(q) end)
    add("reward_quest", '^Reward from the quest "(.+)"%.$', function(q) return Quest(q) end)
    add("reward_either", "^Reward from '(.+)' %(Alliance%) or '(.+)' %(Horde%)%.$", function(a, b) return Quest(a), Quest(b) end)
    add("starts_with", "^Starts with (.+)%.$", function(x) return NpcAt(x) end)
    add("chain_starts", "^The chain starts with (.+)%.$", function(x) return NpcAt(x) end)
    add("quest_in", "^The quest is in (.+)%.$", function(z) return Zone(z) end)
    add("quest_in", "^This quest is in (.+)%.$", function(z) return Zone(z) end)
    add("step_level", "^That step is level (%d+)%.$")
    add("drops_trash", "^Drops from trash in (.+)%.$", function(z) return Zone((z:gsub("^the ", ""))) end)
    add("drops_in", "^Drops in the (.+)%.$", function(z) return Zone(z) end)
    add("drops_in", "^Drops in (.+)%.$", function(z) return Zone(z) end)
    add("drops_from_in", "^Drops from (.+) in (.+)%.$", function(w, z) return List(w), Zone(z) end)
    add("drops_from", "^Drops from (.+)%.$", function(w) return List(w) end)
    add("drops_from", "^Dropped by (.+)%.$", function(w) return List(w) end)
    add("pattern_drops", "^The (%a[%a ]-) pattern drops from (.+)%.$", function(p, who) return L[p], DropPlaces(who) end)
    add("pattern_dropped", "^The (%a[%a ]-) pattern is dropped by (.+)%.$", function(p, who) return L[p], DropPlaces(who) end)
    add("pattern_is_drop", "^The (%a[%a ]-) pattern is the drop%.$", function(p) return L[p] end)
    add("world_drop_range", "^World drop around level (%d+)%-(%d+)%.$")
    add("world_drop_level", "^World drop around level (%d+)%.$")
    add("world_drop", "^World drop%.$")
    add("bought_either", "^Bought from (.+) %((%a+)%) or (.+) %((%a+)%)%.$", function(a, fa, b, fb) return NpcAt(a), L[fa], NpcAt(b), L[fb] end)
    add("bought_tokens", "^Bought from (.+) %- costs tokens or reputation%.$", function(w) return NpcAt(w) end)
    add("bought_honor", "^Bought from (.+)%. Costs Honor Points and tokens %(Marks of Honor%)%.$", function(w) return NpcAt(w) end)
    if P.bought_vendor then
        rules[#rules + 1] = { "^Bought from a vendor%.$", function() return P.bought_vendor end }
    end
    add("bought_from", "^Bought from (.+)%.$", function(w) return NpcAt(w) end)
    add("crafted_skill", "^Crafted with (%a[%a ]-) %(requires skill (%d+)%)%.$", function(p, n) return L[p], n end)
    add("crafted", "^Crafted with (%a[%a ]-)%.$", function(p) return L[p] end)
    add("craft_item", "^Craft (.+) %((%a+)%)%.$", function(item, p) return Thing(item), L[p] end)
    add("requires_level", "^Requires level (%d+)%.$")
    add("requires_rep", "^Requires (.+) %- (%a+)%.$", function(f, s) return Standing(s), Faction(f) end)
    add("set_piece_in", "^Set piece of (.+) %((.+)%)%.$", function(s, z) return Any(s), Zone(z) end)
    add("set_piece", "^Set piece of (.+)%.$", function(s) return Any(s) end)
    add("pickup_level", "^Requires level (%d+) to pick up%.$")
    add("quest_level", "^The quest requires level (%d+)%.$")
    add("found_in", "^Found in (.+)%.$", function(x) return Thing(x) end)
    add("combined", "^Combined from (.+) and (.+)%.$", function(a, b) return Thing(a), Thing(b) end)
    add("alliance_at", "^Alliance: (.+) at (.+)%.$", function(w, z) return Any(w), Zone(z) end)
    add("horde_at", "^Horde: (.+) at (.+)%.$", function(w, z) return Any(w), Zone(z) end)
    add("rank_behind", "^Rank (%d+) behind (.+)%.$", function(n, x) return n, Thing(x) end)
    add("rank_at_behind", "^Rank (%d+) at ([%d–%-]+) behind (.+)%.$", function(n, lvl, x) return n, lvl, Thing(x) end)
    add("rep_extra", "^You must also attain (%a+) reputation with (.+) to complete this quest%.$", function(s, f) return Standing(s), Faction(f) end)
    add("rep_extra", "^You must also obtain (%a+) reputation with (.+) to complete this quest%.$", function(s, f) return Standing(s), Faction(f) end)
    add("rep_extra", "^You must also attain (%a+) reputation with (.+) to be able to complete this quest%.$", function(s, f) return Standing(s), Faction(f) end)
    add("rep_extra", "^You must also be of (%a+) reputation with (.+)%.$", function(s, f) return Standing(s), Faction(f) end)
    add("costs", "^Costs (.+)%.$")

    -- Objectives with no client text.
    add("objective_line", "^Objective: (.+)$", function(rest) return Rest(rest) end)
    add("bring", "^Bring (.+) to (.+)%.$", function(w, who) return List(w), NpcAt(who) end)
    add("bring", "^Take (.+) to (.+)%.$", function(w, who) return List(w), NpcAt(who) end)
    add("collect", "^Collect (.+)%.$", function(w) return List(w) end)
    add("kill", "^Kill (.+)%.$", function(w) return List(w) end)
    add("speak", "^Speak with (.+)%.$", function(w) return NpcAt(w) end)
    add("speak", "^Talk to (.+)%.$", function(w) return NpcAt(w) end)
    add("return_if", "^Return to (.+) if you succeed%.$", function(w) return Any(w) end)
    add("return_mission", "^Return to (.+) when the mission is complete%.$", function(w) return Any(w) end)
    add("return_should", "^Return to (.+) should you succeed%.$", function(w) return Any(w) end)
    add("return_task", "^Return to (.+) when the task is completed%.$", function(w) return Any(w) end)
    add("return_this", "^Return to (.+) when this task is complete%.$", function(w) return Any(w) end)
    add("return_news", "^Return to (.+) to report the good news%.$", function(w) return Any(w) end)
    add("return_fluid", "^Return to (.+) when you have collected enough of the blessed fluid%.$", function(w) return Any(w) end)
    add("do_not_perish", "^Do not let (.+) perish%.$", function(w) return Any(w) end)
    add("do_not_slay", "^Do not slay (.+)%.$", function(w) return Any(w) end)
    add("await_who", "^Await (.+)%.$", function(w) return Any(w) end)
    add("defend_yourself", "^Defend yourself%.$")
    add("hours_task", "^You have (%d+) hours to complete this task%.$")
    add("effect_sec", "^Effect lasts for (%d+) sec%.$")
    add("apply_times", "^Can be applied up to (%d+) times%.$")
    add("affect_targets", "^Will affect up to (%d+) targets%.$")
    add("once_every", "^This effect cannot occur more than once every (%d+) sec%.$")
    add("once_every_only", "^Can only occur once every (%d+) sec%.$")
    add("once_every_this", "^This effect can only occur once every (%d+) sec%.$")
    add("qiraji_stun", "^Qiraji and Silithid targets are stunned for (%d+) sec%.$")
    add("quest_faction", "^This quest also requires (%a+) faction with (.+)%.$", function(s, f) return Standing(s), Faction(f) end)
    add("zandalar_be", "^You must also be (%a+) with Zandalar%.$", function(s) return Standing(s), Faction("Zandalar") end)
    add("zandalar_rep", "^You must also have a reputation equal to or greater than (%a+) with the Zandalar Tribe%.$", function(s) return Standing(s), Faction("Zandalar Tribe") end)
    add("located_on", "^(.+) is located on (.+), (.+)%.$", function(w, a, b) return Any(w), Zone(a), Zone(b) end)
    add("deals_times", "^Deals (%d+) times as much damage to (.+)%.$", function(n, who) return n, Thing(who) end)
    add("deals_facing", "^Deals (%d+) times as much damage if the target is facing you%.$")
    add("inflicts_beast", "^Inflicts (%d+) times as much damage to Beast and Serpentine targets%.$")
    add("ogre_stun", "^Ogres are Stunned for (%d+) sec and refund (%d+)%% of the cooldown%.$")
    add("no_stealth", "^While affected, the target cannot stealth or turn invisible%.$")
    add("lasts_sec", "^Lasts (%d+) sec%.?$")
    add("lasts_min", "^Lasts (%d+) min%.?$")
    add("stacks", "^Stacks up to (%d+) times%.?$")
    add("min_cd", "^%((%d+) Min Cooldown%)$")
    add("hour_cd", "^%((%d+) Hours? Cooldown%)$")
    add("hrs_cd", "^%((%d+) Hrs Cooldown%)$")
    add("min_sec_cd", "^%((%d+) Min, (%d+) Sec Cooldown%)$")
    add("sec_cd", "^%((%d+) Sec Cooldown%)$")
    add("unit_cd", "^%((%d+)(m?s?) cooldown%)$", function(n, unit)
        local word = unit == "m" and (P.unit_min or "min") or unit == "ms" and "ms" or (P.unit_sec or "s")
        return n .. " " .. word
    end)
    add("proc_chance", "^%(Proc chance: (%d+%%)%)$")
    add("proc_chance_cd", "^%(Proc chance: (%d+%%), (%d+)(m?s?) cooldown%)$", function(p, n, unit)
        local word = unit == "m" and (P.unit_min or "min") or unit == "ms" and "ms" or (P.unit_sec or "s")
        return p, n .. " " .. word
    end)

    -- Stat lines: "+10 Intellect", "(2) +10 Intellect.", "+7 Intellect, +6 Stamina".
    local function StatPart(part)
        local alternatives = {}
        for alt in (part .. " / "):gmatch("(.-) / ") do
            local sign, value, stat = alt:match("^([%+%-]?)(%d+%-?%d*%%?) (.+)$")
            local word = value and Stat(stat)
            if not word then
                return nil
            end
            alternatives[#alternatives + 1] = Fill(P.stat or "{1} {2}", sign .. value, word)
        end
        return table.concat(alternatives, " / ")
    end
    local function StatList(text)
        local parts = {}
        for part in (text .. ", "):gmatch("(.-), ") do
            local translated = StatPart(part)
            if not translated then
                return nil
            end
            parts[#parts + 1] = translated
        end
        return table.concat(parts, P.comma or ", ")
    end
    GQ.LocaleStatList = StatList
    rules[#rules + 1] = { "^%((%d)%) ([%+%-]%d[^%.]*)%.$", function(n, text)
        local stats = StatList(text)
        return stats and ("(" .. n .. ") " .. stats .. (P.stop or "."))
    end }
    rules[#rules + 1] = { "^([%+%-]?%d[^%.]*)%.$", function(text)
        local stats = StatList(text)
        return stats and (stats .. (P.stop or "."))
    end }
    rules[#rules + 1] = { "^([%+%-]%d[^%.]*)$", function(text)
        return StatList(text)
    end }

    -- Tooltip prefixes; the effect text after them goes through the rules again.
    add("equip", "^Equip: (.+)$", function(rest) return Rest(rest) end)
    add("use", "^Use: (.+)$", function(rest) return Rest(rest) end)
    add("chance_on_hit", "^Chance on hit: (.+)$", function(rest) return Rest(rest) end)
    add("set_bonus", "^%((%d+)%) Set ?: (.+)$", function(n, rest) return n, Rest(rest) end)

    -- Wowhead tooltip lines for items the client does not know yet.
    add("item_level", "^Item Level (%d+)$")
    add("req_level_tip", "^Requires Level (%d+)$")
    add("armor_tip", "^(%d+) Armor$")
    add("durability", "^Durability (%d+) / (%d+)$")
    add("damage_tip", "^(%d+) %- (%d+) Damage$")
    add("dps_tip", "^%(([%d%.]+) damage per second%)$")
    add("speed_tip", "^Speed ([%d%.]+)$")
    add("sell_price", "^Sell Price: (.+)$")
    add("bop", "^Binds when picked up$")
    add("boe", "^Binds when equipped$")
    add("bou", "^Binds when used$")
    add("unique_equipped", "^Unique%-Equipped$")
    add("quest_item", "^Quest Item$")
    add("classes", "^Classes: (.+)$", function(list)
        local names = {}
        for class in (list .. ", "):gmatch("(.-), ") do
            local client = type(LOCALIZED_CLASS_NAMES_MALE) == "table" and LOCALIZED_CLASS_NAMES_MALE[class:upper()]
            names[#names + 1] = type(client) == "string" and client or class
        end
        return table.concat(names, P.comma or ", ")
    end)
    add("requires_skill_tip", "^Requires (%a[%a ]-) %((%d+)%)$", function(s, n) return L[s], n end)
    add("heal_spell", "^Increases healing done by spells and effects by up to (%d+)%.?$")
    add("dmg_heal_spell", "^Increases damage and healing done by magical spells and effects by up to (%d+)%.?$")
    add("mp5", "^Restores %+?(%d+) mana per 5 sec%.?$")
    add("hit", "^Improves your chance to hit by ([%d%.]+%%)%.$")
    add("crit", "^Improves your chance to get a critical strike by ([%d%.]+%%)%.$")
    add("spell_crit", "^Improves your chance to get a critical strike with spells by ([%d%.]+%%)%.$")
    add("defense_tip", "^Increased Defense %+(%d+)%.?$")

    if P.words then
        rules[#rules + 1] = { "^([%a][%a%- ]*)$", function(word) return P.words[word] end }
    end
    if P.sentences then
        for english, translated in pairs(P.sentences) do
            GQ.LocaleSentences[english] = translated
        end
    end
end
