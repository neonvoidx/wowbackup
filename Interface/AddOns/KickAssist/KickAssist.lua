local ADDON = ...

-- Forward-declared: the options-panel checkbox setter (~line 689) references this
-- lexically ABOVE the definition further down, so without this declaration the name
-- there binds to a nil global and throws "attempt to call a nil value" on click.
-- The definition below assigns to this local instead of creating a new one.
local SyncInterruptAlert

--------------------------------------------------------------------------------
-- Kick Assist
-- Pick your interrupt (kick) raid marker, announce it to the group, and keep
-- your interrupt macro's marker number in sync with your pick. The popup
-- auto-shows on ready check and / or Mythic+ start.
--
-- Marking note: SetRaidTarget is a PROTECTED function (addons may not call it).
-- The game already ships a secure /tm command (Blizzard's TARGET_MARKER slash)
-- that does the marking. This addon never calls SetRaidTarget and never registers
-- /tm; it only rewrites the marker NUMBER inside your macro so the built-in /tm
-- marks with whatever you picked.
--
-- Announce note: a message sent from a button click is always allowed. Automated
-- announce on the trigger works outside instanced content; inside an instance it
-- can be blocked, in which case the button still works.
--------------------------------------------------------------------------------

-- {interrupt} = your spec's interrupt, {marker} = your marker. Marking is always on
-- @focus, and the ~ before {marker} marks only if your focus has no marker yet, so the
-- marker is placed when you set your focus and then stays put: re-pressing kicks the
-- focus and never moves the marker onto whatever you happen to be targeting. The
-- default Focus+Kick casts before setting focus, so the first press sets focus and the
-- next press kicks it (no modifier, no mouseover).
local DEFAULT_MACRO =
	"#showtooltip {interrupt}\n" ..
	"/cast [@focus,harm,nodead] {interrupt}\n" ..
	"/focus [@focus,noexists] target\n" ..
	"/tm [@focus] ~{marker}"

-- Set focus + mark; no #showtooltip so it keeps the targeting icon.
local SET_FOCUS_MACRO =
	"/focus target\n" ..
	"/tm [@focus] ~{marker}"

-- Auto tab kick (default): tab to the nearest enemy, interrupt, return to your target.
local AUTOTAB_MACRO =
	"#showtooltip {interrupt}\n" ..
	"/cleartarget\n" ..
	"/targetenemy\n" ..
	"/cast {interrupt}\n" ..
	"/targetlasttarget"

-- Auto tab kick (focus first): kick your focus if you have one, else tab-interrupt
-- a casting mob without losing your current target.
local AUTOTAB_FOCUS_MACRO =
	"#showtooltip {interrupt}\n" ..
	"/cast [@focus,exists,nodead,harm] {interrupt}\n" ..
	"/stopmacro [@focus,exists,nodead,harm]\n" ..
	"/focus target\n" ..
	"/cleartarget\n" ..
	"/targetenemy\n" ..
	"/cast {interrupt}\n" ..
	"/target focus\n" ..
	"/clearfocus\n" ..
	"/startattack"

-- Auto tab kick (mouseover override): kick your mouseover or focus if valid, else
-- tab-interrupt without losing your current target.
local AUTOTAB_MOUSEOVER_MACRO =
	"#showtooltip\n" ..
	"/cast [@mouseover,harm,nodead][@focus,harm,nodead,exists] {interrupt}\n" ..
	"/stopmacro [@mouseover,harm,nodead][@focus,harm,nodead,exists]\n" ..
	"/focus target\n" ..
	"/cleartarget\n" ..
	"/targetenemy\n" ..
	"/cast {interrupt}\n" ..
	"/target focus\n" ..
	"/clearfocus"

-- Templates per macro slot: the editor shows the set for whichever macro is selected.
local TEMPLATES = {
	kick = {
		{ name = "Focus + Kick (default, re-press to kick)", body = DEFAULT_MACRO },
		{ name = "Focus + Kick (Ctrl to kick your target)",
		  body = "#showtooltip {interrupt}\n/cast [nomod:ctrl,@focus,harm,nodead][] {interrupt}\n/focus [@focus,noexists] target\n/tm [@focus] ~{marker}" },
		{ name = "Focus + Kick (mouseover)",
		  body = "#showtooltip {interrupt}\n/cast [@focus,harm,nodead] {interrupt}\n/focus [@mouseover,harm,nodead,exists] mouseover\n/tm [@focus] ~{marker}" },
	},
	focus = {
		{ name = "Set focus (target)", body = SET_FOCUS_MACRO },
		{ name = "Set focus (mouseover)",
		  body = "/focus [@mouseover,exists] mouseover\n/tm [@focus] ~{marker}" },
	},
	autotab = {
		{ name = "Auto Tab Kick (tab to nearest)", body = AUTOTAB_MACRO },
		{ name = "Auto Tab Kick (focus first, else tab)", body = AUTOTAB_FOCUS_MACRO },
		{ name = "Auto Tab Kick (mouseover or focus, else tab)", body = AUTOTAB_MOUSEOVER_MACRO },
	},
}

-- The three macro slots the editor can edit (Focus+Kick, Set Focus, Auto Tab Kick).
local SLOT_CFG = {
	kick    = { label = "Focus + Kick",  nameKey = "macroName",    tmplKey = "macroTemplate",    defName = "FocusKick",   defBody = DEFAULT_MACRO },
	focus   = { label = "Set Focus",     nameKey = "setFocusName", tmplKey = "setFocusTemplate", defName = "SetFocus",    defBody = SET_FOCUS_MACRO },
	autotab = { label = "Auto Tab Kick", nameKey = "autoTabName",  tmplKey = "autoTabTemplate",  defName = "AutoTabKick", defBody = AUTOTAB_MACRO },
}
local SLOT_ORDER = { "kick", "focus", "autotab" }

local DEFAULTS = {
	marker               = 8,            -- 1..8 raid target index, 0 = no marker (skull default)
	showOnReadyCheck     = true,         -- show on ready check while in a Mythic+ dungeon
	announceOnReadyCheck = true,         -- post your kick to chat on a ready check (sends before a key; auto-skips once chat is locked)
	-- Which instances the ready-check popup/announce fires in (default: Mythic dungeons only).
	contexts             = { mplus = true, mythic = true, heroic = false, normal = false, raid = false },
	smartOpen            = false,        -- on a ready check, wait and open only if someone else calls your marker
	classicLook          = false,        -- use the old Blizzard-styled marker window instead of the Arc look
	customKick           = "",           -- blank = use the class/spec default; a spell NAME or ID overrides it
	optW                 = 460,          -- remembered options-window size. Listed here so that
	optH                 = 540,          -- enabling account-wide SEEDS it (the seed walks DEFAULTS)
	                                     -- instead of snapping the window back to its default size.
	toggleStyle          = "checkbox",   -- the Arc theme toggle is the WoW-style square checkbox
	interruptAlert       = false,        -- sound/TTS when your FOCUS starts casting and your interrupt is ready
	interruptAlertTTS    = false,        -- alert via spoken text (TTS) instead of a sound
	interruptAlertText   = "Kick",       -- the TTS phrase
	interruptAlertSound  = "Default",    -- sound to play (non-TTS): "Default", "None", a built-in name, or a LibSharedMedia sound
	interruptAlertChannel = "Master",    -- sound channel
	message              = "My Focus Kick is %MARKER%",
	point                = { "CENTER", "CENTER", 0, 140 },

	macroEnabled         = false,        -- opt-in: do not touch macros until the user enables it
	macroName            = "FocusKick",  -- set-focus-and-kick macro
	macroTemplate        = DEFAULT_MACRO,
	setFocusName         = "SetFocus",   -- set-focus-and-mark macro
	setFocusTemplate     = SET_FOCUS_MACRO,
	autoTabName          = "AutoTabKick",-- auto tab-interrupt macro
	autoTabTemplate      = AUTOTAB_MACRO,
	macroPoint           = { "CENTER", "CENTER", 0, 0 },

	minimap              = { angle = 214, hide = false },
}

local MARKER_NAMES = {
	[0] = "No Marker",
	"Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross", "Skull",
}

local PREFIX = "|cff33ff99Kick Assist|r: "
local QUESTION_ICON = "INV_Misc_QuestionMark"
local FOCUS_ICON = 132212  -- set-focus macro icon (fileID)

local DB           -- active settings store (per-character or account-wide), resolved at ADDON_LOADED
local CDB          -- per-character store (KickAssistDB)
local ADB          -- account store (KickAssistAccountDB): the account-wide flag + shared settings
local RefreshKAOptions  -- assigned in the options-window block; re-reads DB into the open panel
local OpenKAOptions     -- assigned in the options-window block; opens the branded settings window
local arcPopup          -- the branded (Arc look) marker-picker popup
local CreateArcPopup    -- assigned in the options block; builds the branded popup
local RefreshArcPopup   -- assigned in the options block; re-reads DB into the branded popup
local frame        -- main popup, created lazily
local macroFrame   -- macro editor, created lazily
local settingsCategory  -- Blizzard settings category (set in CreateSettingsPanel)
local myName             -- our character name, cached while readable (UnitName is secret inside M+)
local smartOpenExpire = 0  -- GetTime() until which Smart Open watches party chat

-- Cache our own name while it is readable. UnitName("player") is secret inside instances,
-- so we grab it on login / zoning (out in the world it is not secret) and reuse that string
-- to recognize our own chat echo during a key.
local function RememberMyName()
	local n = UnitName("player")
	if n and not issecretvalue(n) then myName = n end
end

--------------------------------------------------------------------------------
-- Account-wide vs per-character storage
--
-- Default is per-character: each toon has its own settings and its own macros.
-- Turning on "account-wide" points everything at a shared account store and makes the
-- kick macros account (general) macros, so one setup covers every character and the macro
-- auto-updates to each class on login. Switching modes never deletes data: the per-character
-- store is kept intact and just goes inactive while account-wide is on.
--------------------------------------------------------------------------------

local function FillDefaults(store)
	for k, v in pairs(DEFAULTS) do
		if store[k] == nil then
			store[k] = (type(v) == "table") and CopyTable(v) or v
		end
	end
end

-- Point DB at the active store and make sure it has every default key.
local function ResolveActiveDB()
	DB = (ADB and ADB.accountWide) and ADB or CDB
	FillDefaults(DB)
end

local function AccountWideMacros()
	return (ADB and ADB.accountWide) and true or false
end

-- Find a macro by name in a specific bucket (account macros 1..numAccount, character macros
-- at MAX_ACCOUNT_MACROS+1..). GetMacroIndexByName searches account-first and can't target a
-- bucket, which misfires when the same name exists in both; this looks in exactly the bucket
-- the current mode uses, so enabling/disabling account mode stays clean and reversible.
-- Macro-layout constants live in Blizzard_UIParent on live but are nil early and on the 12.1
-- PTR (they moved to the load-on-demand macro UI), so fall back to the fixed game values.
local ACCT_MACRO_CAP = MAX_ACCOUNT_MACROS or 120
local CHAR_MACRO_CAP = MAX_CHARACTER_MACROS or 30

local function FindMacroInBucket(name, perChar)
	local numAccount, numChar = GetNumMacros()
	if perChar then
		for i = 1, (numChar or 0) do
			local gi = ACCT_MACRO_CAP + i
			if GetMacroInfo(gi) == name then return gi end
		end
	else
		for i = 1, (numAccount or 0) do
			if GetMacroInfo(i) == name then return i end
		end
	end
	return nil
end

local function FindManagedMacroIndex(name)
	return FindMacroInBucket(name, not AccountWideMacros())
end

-- Create the managed macro in the bucket for the current mode, guarding that bucket's slots.
local function CreateManagedMacro(name, icon, body)
	local perChar = not AccountWideMacros()
	local numAccount, numChar = GetNumMacros()
	local used = perChar and numChar or numAccount
	local cap  = perChar and CHAR_MACRO_CAP or ACCT_MACRO_CAP
	if used and used >= cap then
		print(PREFIX .. "no free " .. (perChar and "character" or "account") .. " macro slots for '" .. name .. "'.")
		return
	end
	CreateMacro(name, icon, body, perChar)
end

-- Marker index -> spoken token names, so Smart Open also catches manual callouts.
local MARKER_TOKENS = {
	[1] = { "star" }, [2] = { "circle", "coin" }, [3] = { "diamond" }, [4] = { "triangle" },
	[5] = { "moon" }, [6] = { "square" }, [7] = { "cross", "x" }, [8] = { "skull" },
}

-- Does an incoming chat message call out YOUR marker? Matches {rtN}, the named token
-- ({skull} etc.) and the rendered icon escape. Pure string parsing, so taint-safe in M+.
local function MessageCallsMyMarker(text)
	local m = DB and DB.marker
	if not text or issecretvalue(text) or not m or m < 1 or m > 8 then return false end
	text = text:lower()
	if text:find("{rt" .. m .. "}", 1, true) then return true end
	if text:find("raidtargetingicon_" .. m, 1, true) then return true end
	for _, name in ipairs(MARKER_TOKENS[m]) do
		if text:find("{" .. name .. "}", 1, true) then return true end
	end
	return false
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- Chat substitution token for a raid marker; the chat system renders the icon.
local function ChatToken(index)
	if index and index >= 1 and index <= 8 then
		return "{rt" .. index .. "}"
	end
	return "no marker"
end

-- Set a texture to a single cell of the 4x4 raid-target sprite sheet.
local function SetMarkerTexture(tex, index)
	tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
	local col  = (index - 1) % 4
	local row  = math.floor((index - 1) / 4)
	local left = col * 0.25
	local top  = row * 0.25
	tex:SetTexCoord(left, left + 0.25, top, top + 0.25)
end

-- Where group chat should go right now (nil = not grouped).
local function GroupChannel()
	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
	if IsInRaid() then return "RAID" end
	if IsInGroup() then return "PARTY" end
	return nil
end

-- Trigger contexts the popup/announce can fire in. Difficulty IDs (DifficultyUtil):
-- 1 Normal, 2 Heroic, 23 Mythic, 8 Mythic Keystone (M+); raids via instanceType.
local CONTEXT_DEFAULTS = { mplus = true, mythic = true, heroic = false, normal = false, raid = false }
local CONTEXT_ORDER    = { "mplus", "mythic", "heroic", "normal", "raid" }
local CONTEXT_LABELS   = {
	mplus  = "Mythic+ (keystone)",
	mythic = "Mythic dungeon",
	heroic = "Heroic dungeon",
	normal = "Normal dungeon",
	raid   = "Raids",
}

-- Which trigger context (if any) the player is currently in.
local function CurrentContextKey()
	local inInstance, instanceType = IsInInstance()
	if not inInstance then return nil end
	if instanceType == "raid" then return "raid" end
	if instanceType == "party" then
		local diff = select(3, GetInstanceInfo())
		if diff == 8  then return "mplus"  end
		if diff == 23 then return "mythic" end
		if diff == 2  then return "heroic" end
		if diff == 1  then return "normal" end
	end
	return nil
end

-- Is this context enabled? Falls back to the default when the player hasn't set it.
local function ContextEnabled(key)
	local v = DB.contexts and DB.contexts[key]
	if v == nil then v = CONTEXT_DEFAULTS[key] end
	return v and true or false
end

-- True when the current instance is one the player enabled for the popup/announce.
local function ShouldTriggerHere()
	local key = CurrentContextKey()
	return key ~= nil and ContextEnabled(key)
end

-- True when addons may post to chat right now. The Chat restriction
-- (Enum.AddOnRestrictionType.Chat) is OFF before a Mythic+ key starts and flips
-- ON once the key is active, where an addon SendChatMessage is blocked. Checking
-- it lets the ready-check announce go out before the key and stand down after it,
-- with no blocked-action error. C_RestrictedActions is 12.0+; guarded for safety.
local function ChatAllowed()
	local C = C_RestrictedActions
	if C and C.IsAddOnRestrictionActive and Enum and Enum.AddOnRestrictionType then
		return not C.IsAddOnRestrictionActive(Enum.AddOnRestrictionType.Chat)
	end
	return true
end

-- Interrupt ("kick") spell per class, with spec overrides keyed by specialization
-- ID. Verified against warcraft.wiki.gg/wiki/Interrupt. Missing = spec has no kick.
local INTERRUPTS = {
	DEATHKNIGHT = { default = 47528  },                  -- Mind Freeze
	DEMONHUNTER = { default = 183752 },                  -- Disrupt
	DRUID       = { default = 106839, [102] = 78675  },  -- Skull Bash; Balance = Solar Beam
	EVOKER      = { default = 351338 },                  -- Quell
	HUNTER      = { default = 147362, [255] = 187707 },  -- Counter Shot; Survival = Muzzle
	MAGE        = { default = 2139   },                  -- Counterspell
	MONK        = { default = 116705 },                  -- Spear Hand Strike
	PALADIN     = { default = 96231  },                  -- Rebuke (all specs)
	PRIEST      = {                   [258] = 15487 },   -- Shadow = Silence; Disc/Holy none
	ROGUE       = { default = 1766   },                  -- Kick
	SHAMAN      = { default = 57994  },                  -- Wind Shear
	-- Spell Lock is the Felhunter's. Demonology runs a Felguard instead, whose stop
	-- is Axe Toss (a stun, which is why the wiki's interrupt list omits it -- no
	-- school lockout -- but it is what Demo uses to stop a cast). Cast via Command
	-- Demon in the spellbook; "/cast Axe Toss" is the macro form the class guides use.
	WARLOCK     = { default = 19647, [266] = 89766 },    -- Spell Lock; Demonology = Axe Toss
	WARRIOR     = { default = 6552   },                  -- Pummel
}

-- A kick spell the user typed in beats the table above -- for a pet ability, a
-- spec the defaults get wrong, or anything new Blizzard adds mid-patch. Accepts a
-- spell NAME or a numeric spell ID; blank (the default) means "use my class".
-- ALWAYS per-character (CDB), never the account store, even in account-wide mode:
-- a kick spell belongs to one class, so sharing it would put a warlock's Axe Toss
-- on every alt -- exactly the "flip it back for other toons" chore this replaces.
local function CustomKick()
	local raw = CDB and CDB.customKick
	if type(raw) ~= "string" then return nil end
	raw = raw:match("^%s*(.-)%s*$") or ""
	if raw == "" then return nil end
	return raw
end

-- The current character's interrupt spell ID (nil if this spec has none).
local function GetMyInterruptID()
	local custom = CustomKick()
	if custom then
		local id = tonumber(custom)
		if id then return id end
		-- a typed name: resolve it so the ready-check cooldown has an ID to read
		return (C_Spell.GetSpellIDForSpellIdentifier and C_Spell.GetSpellIDForSpellIdentifier(custom)) or nil
	end
	local _, classToken = UnitClass("player")
	local data = classToken and INTERRUPTS[classToken]
	if not data then return nil end
	local specIndex = GetSpecialization()
	local specID = specIndex and GetSpecializationInfo(specIndex)
	return (specID and data[specID]) or data.default
end

local function GetMyInterruptName()
	local custom = CustomKick()
	if custom then
		local id = tonumber(custom)
		-- an ID resolves to its real name; a typed name goes into the macro as typed
		if id then return C_Spell.GetSpellName(id) or custom end
		return custom
	end
	local id = GetMyInterruptID()
	return id and C_Spell.GetSpellName(id) or nil
end

-- Post the kick marker to group chat. `fromTrigger` = fired by an event (e.g. the
-- ready check) rather than a click; on a trigger we stay silent when we can't send.
-- We never send while chat is locked (an active Mythic+ key), so this never throws
-- a blocked-action error -- whether called from a click or the ready-check trigger.
local function Announce(fromTrigger)
	local token   = ChatToken(DB.marker)
	local msg     = (tostring(DB.message or DEFAULTS.message):gsub("%%MARKER%%", token))
	local channel = GroupChannel()
	if not channel then
		if not fromTrigger then print(PREFIX .. msg .. " (not in a group, shown locally)") end
		return
	end
	if not ChatAllowed() then
		if not fromTrigger then print(PREFIX .. "chat is locked right now (Mythic+ in progress); announce skipped.") end
		return
	end
	SendChatMessage(msg, channel)
end

--------------------------------------------------------------------------------
-- Macro management (text only; the built-in /tm does the marking)
--------------------------------------------------------------------------------

-- Swap marker numbers (0-8) that are real /tm arguments for a replacement, while
-- leaving any digits inside [condition] brackets alone. Returns the new string and
-- the number of markers replaced.
local function ReplaceTmMarkers(s, replacement)
	local out, depth, count = {}, 0, 0
	for i = 1, #s do
		local c = s:sub(i, i)
		if c == "[" then
			depth = depth + 1; out[#out + 1] = c
		elseif c == "]" then
			if depth > 0 then depth = depth - 1 end
			out[#out + 1] = c
		elseif depth == 0 and c >= "0" and c <= "8" then
			out[#out + 1] = replacement; count = count + 1
		else
			out[#out + 1] = c
		end
	end
	return table.concat(out), count
end

-- Make an existing macro body marker-managed for the "pick existing macro" flow:
-- in its first /tm line swap the marker number(s) for {marker} (adding ~{marker} if that
-- line has no number yet); if there is no /tm line at all, append one. Everything
-- else in the macro is left exactly as the player wrote it.
local function ManageMarkerInBody(body)
	body = tostring(body or ""):gsub("[\r\n]+$", "")
	if body == "" then return "/tm [@focus] ~{marker}" end
	local lines, handled = {}, false
	for line in (body .. "\n"):gmatch("(.-)\n") do
		if not handled then
			local prefix, rest = line:match("^(%s*/[tT][mM])(.*)$")
			if prefix and (rest == "" or rest:match("^[%s%[~!0-8]")) then
				local newRest, n = ReplaceTmMarkers(rest, "{marker}")
				line = prefix .. newRest
				if n == 0 then line = line .. " ~{marker}" end
				handled = true
			end
		end
		lines[#lines + 1] = line
	end
	if not handled then
		lines[#lines + 1] = "/tm [@focus] ~{marker}"
	end
	return table.concat(lines, "\n")
end

-- Rewrite the managed macro so {marker} matches the chosen marker. Out of combat
-- only (EditMacro / CreateMacro are blocked in combat).
local function UpdateManagedMacro()
	if not (DB and DB.macroEnabled) then return end
	if InCombatLockdown() then return end

	local name = DB.macroName ~= "" and DB.macroName or DEFAULTS.macroName
	local interrupt = GetMyInterruptName() or ""
	local body = tostring(DB.macroTemplate or DEFAULT_MACRO)
	body = body:gsub("{interrupt}", interrupt):gsub("{marker}", tostring(DB.marker)):gsub("{kick}", tostring(DB.marker))
	if body == "" then return end

	local idx = FindManagedMacroIndex(name)
	if idx then
		EditMacro(idx, name, QUESTION_ICON, body)
	else
		CreateManagedMacro(name, QUESTION_ICON, body)
	end
end

-- The fixed "set focus + mark" macro. Synced if it exists; created when create=true.
local function UpdateSetFocusMacro(create)
	if InCombatLockdown() then return end
	local name = DB.setFocusName ~= "" and DB.setFocusName or DEFAULTS.setFocusName
	local interrupt = GetMyInterruptName() or ""
	local body = tostring(DB.setFocusTemplate or SET_FOCUS_MACRO):gsub("{interrupt}", interrupt):gsub("{marker}", tostring(DB.marker)):gsub("{kick}", tostring(DB.marker))
	local idx = FindManagedMacroIndex(name)
	if idx then
		EditMacro(idx, name, FOCUS_ICON, body)
	elseif create then
		CreateManagedMacro(name, FOCUS_ICON, body)
	end
end

-- The auto-tab-interrupt macro. Synced if it exists; created when create=true.
local function UpdateAutoTabMacro(create)
	if InCombatLockdown() then return end
	local name = DB.autoTabName ~= "" and DB.autoTabName or DEFAULTS.autoTabName
	local interrupt = GetMyInterruptName() or ""
	local body = tostring(DB.autoTabTemplate or AUTOTAB_MACRO):gsub("{interrupt}", interrupt):gsub("{marker}", tostring(DB.marker)):gsub("{kick}", tostring(DB.marker))
	local idx = FindManagedMacroIndex(name)
	if idx then
		EditMacro(idx, name, QUESTION_ICON, body)
	elseif create then
		CreateManagedMacro(name, QUESTION_ICON, body)
	end
end

-- Keep all managed macros in sync with the chosen marker; only edits ones that exist.
local function SyncMacros()
	UpdateManagedMacro()
	UpdateSetFocusMacro(false)
	UpdateAutoTabMacro(false)
end

--------------------------------------------------------------------------------
-- Main popup UI
--------------------------------------------------------------------------------

local function UpdateSelection()
	if not frame then return end
	for i = 1, 8 do
		frame.markerButtons[i].sel:SetShown(DB.marker == i)
	end
	frame.noneButton.sel:SetShown(DB.marker == 0)
end

local function MakeSelTexture(parent)
	local t = parent:CreateTexture(nil, "OVERLAY")
	t:SetTexture("Interface\\Buttons\\CheckButtonHilight")
	t:SetBlendMode("ADD")
	t:SetPoint("TOPLEFT", -3, 3)
	t:SetPoint("BOTTOMRIGHT", 3, -3)
	t:Hide()
	return t
end

local function MakeCheck(parent, label, x, y, get, set)
	local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	cb:SetPoint("TOPLEFT", x, y)
	cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
	local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
	fs:SetText(label)
	cb.Refresh = function(self) self:SetChecked(get() and true or false) end
	return cb
end

-- Refresh a popup's drag-box icons. `target` defaults to the classic popup `frame`.
local function RefreshDragIconsFor(target)
	target = target or frame
	if not target or not target.dragIcons then return end
	local id = GetMyInterruptID()
	local spellTex = (id and C_Spell.GetSpellTexture(id)) or 134400
	if target.dragIcons.kick then
		target.dragIcons.kick:SetTexture(spellTex)
		target.dragIcons.kick:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
	if target.dragIcons.autotab then
		target.dragIcons.autotab:SetTexture(spellTex)
		target.dragIcons.autotab:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
	if target.dragIcons.focus then
		if type(FOCUS_ICON) == "number" then
			target.dragIcons.focus:SetTexture(FOCUS_ICON)
		else
			target.dragIcons.focus:SetTexture("Interface\\Icons\\" .. FOCUS_ICON)
		end
		target.dragIcons.focus:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
end
local function RefreshDragIcons() RefreshDragIconsFor(frame) end

-- Pick up a managed macro onto the cursor (creates/syncs it first). File-level so both
-- the classic and the branded popups can drop macros onto the action bars.
local function KAPickupSlot(nameKey, defName, updateFn)
	if InCombatLockdown() then return end
	local name = (DB[nameKey] and DB[nameKey] ~= "") and DB[nameKey] or defName
	updateFn(true)
	local idx = FindManagedMacroIndex(name)
	if idx then PickupMacro(idx) end
end

local function CreateUI()
	if frame then return frame end

	frame = CreateFrame("Frame", "KickAssistFrame", UIParent, "BackdropTemplate")
	frame:SetSize(300, 560)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetBackdrop({
		bgFile   = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = false, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	})
	frame:SetBackdropColor(0.04, 0.04, 0.04, 0.9)

	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local p, _, rp, x, y = self:GetPoint()
		DB.point = { p, rp, x, y }
	end)

	tinsert(UISpecialFrames, "KickAssistFrame")

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -16)
	title:SetText("Kick Assist")

	local instr = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	instr:SetPoint("TOP", title, "BOTTOM", 0, -6)
	instr:SetText("Pick your kick marker")

	-- 8 marker buttons, 4 per row.
	frame.markerButtons = {}
	for i = 1, 8 do
		local btn = CreateFrame("Button", nil, frame)
		btn:SetSize(40, 40)
		local col = (i - 1) % 4
		local row = math.floor((i - 1) / 4)
		btn:SetPoint("TOPLEFT", 55 + col * 50, -58 - row * 50)

		local icon = btn:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints()
		SetMarkerTexture(icon, i)

		btn.sel = MakeSelTexture(btn)
		btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		btn:SetScript("OnClick", function()
			DB.marker = i
			UpdateSelection()
			RefreshDragIcons()
			SyncMacros()
			Announce()
		end)
		btn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(MARKER_NAMES[i])
			GameTooltip:Show()
		end)
		btn:SetScript("OnLeave", GameTooltip_Hide)

		frame.markerButtons[i] = btn
	end

	-- "No Marker" choice.
	local none = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	none:SetSize(100, 22)
	none:SetPoint("TOP", 0, -162)
	none:SetText("No Marker")
	none.sel = MakeSelTexture(none)
	none:SetScript("OnClick", function()
		DB.marker = 0
		UpdateSelection()
		RefreshDragIcons()
		SyncMacros()
	end)
	frame.noneButton = none

	-- Toggles.
	frame.readyCB = MakeCheck(frame, "Show on ready check", 22, -196,
		function() return DB.showOnReadyCheck end,
		function(v) DB.showOnReadyCheck = v end)

	frame.smartCB = MakeCheck(frame, "Smart open (only on a marker clash)", 22, -220,
		function() return DB.smartOpen end,
		function(v) DB.smartOpen = v end)

	frame.announceCB = MakeCheck(frame, "Announce on ready check", 22, -244,
		function() return DB.announceOnReadyCheck end,
		function(v) DB.announceOnReadyCheck = v end)

	-- Editable announce message. %MARKER% is replaced with your marker icon.
	local msgLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	msgLabel:SetPoint("TOPLEFT", 22, -274)
	msgLabel:SetText("Message (%MARKER% = your icon):")

	local msgBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	msgBox:SetSize(246, 20)
	msgBox:SetPoint("TOPLEFT", 28, -292)
	msgBox:SetAutoFocus(false)
	msgBox:SetText(DB.message or DEFAULTS.message)
	msgBox:SetScript("OnEscapePressed", msgBox.ClearFocus)
	msgBox:SetScript("OnEnterPressed", function(self)
		DB.message = self:GetText()
		self:ClearFocus()
	end)
	msgBox:SetScript("OnEditFocusLost", function(self) DB.message = self:GetText() end)
	frame.msgBox = msgBox

	-- Announce: always allowed from a click.
	local announce = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	announce:SetSize(170, 26)
	announce:SetPoint("TOP", 0, -324)
	announce:SetText("Announce to Group")
	announce:SetScript("OnClick", function()
		DB.message = msgBox:GetText()
		Announce()
	end)

	-- Edit Macro + Options sit side by side on one row.
	local macroBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	macroBtn:SetSize(140, 24)
	macroBtn:SetPoint("TOP", -73, -358)
	macroBtn:SetText("Edit Macro...")
	macroBtn:SetScript("OnClick", function() KickAssist_ShowMacroEditor() end)

	-- Opens the branded Kick Assist settings window.
	local optionsBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	optionsBtn:SetSize(140, 24)
	optionsBtn:SetPoint("TOP", 73, -358)
	optionsBtn:SetText("Options...")
	optionsBtn:SetScript("OnClick", function() OpenKAOptions() end)

	-- Drag-to-bars: two ready macros new users can drop straight onto their bars.
	local dragHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	dragHeader:SetPoint("TOP", 0, -384)
	dragHeader:SetText("New? Drag a macro to your action bar:")

	frame.dragIcons = {}

	local function PickupSlot(nameKey, defName, updateFn)
		if InCombatLockdown() then return end
		local name = (DB[nameKey] and DB[nameKey] ~= "") and DB[nameKey] or defName
		updateFn(true)
		local idx = FindManagedMacroIndex(name)
		if idx then PickupMacro(idx) end
	end

	local function MakeDragBox(xOff, labelText, desc, key, pickup)
		local box = CreateFrame("Button", nil, frame, "BackdropTemplate")
		box:SetSize(40, 40)
		box:SetPoint("TOP", xOff, -402)
		box:RegisterForDrag("LeftButton")
		box:RegisterForClicks("LeftButtonUp")
		box:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
		box:SetBackdropBorderColor(1, 0.82, 0, 0.9)
		local ic = box:CreateTexture(nil, "ARTWORK")
		ic:SetPoint("TOPLEFT", 2, -2)
		ic:SetPoint("BOTTOMRIGHT", -2, 2)
		box:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		frame.dragIcons[key] = ic
		box:SetScript("OnDragStart", pickup)
		box:SetScript("OnClick", pickup)
		box:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(labelText)
			GameTooltip:AddLine(desc, 1, 1, 1, true)
			GameTooltip:AddLine("Drag onto an action bar, or click then a bar slot.", 0.6, 0.6, 0.6, true)
			GameTooltip:Show()
		end)
		box:SetScript("OnLeave", GameTooltip_Hide)
		local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		lbl:SetPoint("TOP", box, "BOTTOM", 0, -4)
		lbl:SetText(labelText)
		return box
	end

	MakeDragBox(-78, "Focus + Kick", "Interrupts your focus. First press focuses your target, then re-press to kick.", "kick", function()
		DB.macroEnabled = true
		PickupSlot("macroName", DEFAULTS.macroName, UpdateManagedMacro)
	end)
	MakeDragBox(0, "Set Focus", "Sets your current target as your focus and marks it.", "focus", function()
		PickupSlot("setFocusName", DEFAULTS.setFocusName, UpdateSetFocusMacro)
	end)
	MakeDragBox(78, "Tab Kick", "Interrupts the nearest casting enemy, then returns to your target.", "autotab", function()
		PickupSlot("autoTabName", DEFAULTS.autoTabName, UpdateAutoTabMacro)
	end)
	RefreshDragIcons()

	-- Interrupt Alert: surfaced here so it's discoverable. The enable toggle lives
	-- here; the sound/TTS/channel choices are in Options.
	local alertHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	alertHeader:SetPoint("TOPLEFT", 22, -464)
	alertHeader:SetText("Interrupt Alert")

	frame.alertCB = MakeCheck(frame, "Play a sound when your focus casts", 22, -482,
		function() return DB.interruptAlert end,
		function(v) DB.interruptAlert = v; SyncInterruptAlert() end)

	local alertHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	alertHint:SetPoint("TOPLEFT", 26, -508)
	alertHint:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
	alertHint:SetJustifyH("LEFT")
	alertHint:SetText("Fires when your focus casts and your kick is ready. Pick the sound, TTS, and channel in Options.")

	local p = DB.point or DEFAULTS.point
	frame:ClearAllPoints()
	frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])

	frame:Hide()
	return frame
end

-- Re-read the active DB into the main window's widgets (no-op if it isn't built yet).
local function RefreshMainWindow()
	if not frame then return end
	UpdateSelection()
	frame.readyCB:Refresh()
	frame.smartCB:Refresh()
	frame.announceCB:Refresh()
	frame.alertCB:Refresh()
	frame.msgBox:SetText(DB.message or DEFAULTS.message)
	RefreshDragIcons()
end

local function ShowUI(fromEvent)
	if InCombatLockdown() then
		-- Only tell the user when THEY asked (a trigger like a mid-key ready check stays silent).
		if not fromEvent then print(PREFIX .. "in combat, not opening (this is an out-of-combat tool).") end
		return
	end
	if DB.classicLook then
		CreateUI(); RefreshMainWindow(); SyncMacros(); frame:Show(); frame:Raise()
	else
		CreateArcPopup(); RefreshArcPopup(); SyncMacros(); arcPopup:Show(); arcPopup:Raise()
	end
end

-- Refresh whatever UI is currently built (used after the account-wide toggle swaps the store).
local function RefreshOpenUI()
	RefreshMainWindow()
	if RefreshArcPopup then RefreshArcPopup() end
	if RefreshKAOptions then RefreshKAOptions() end
end

-- Global opener so ArcUI (or any addon) can open the window.
KickAssist_Show = ShowUI

--------------------------------------------------------------------------------
-- Macro editor UI
--------------------------------------------------------------------------------

local editorSlot = "kick"  -- which macro the editor edits: "kick" or "focus"

local function MacroNoteText()
	return "{interrupt} fills in your interrupt (now: " ..
		(GetMyInterruptName() or "none for this spec") .. "); {marker} fills in your marker."
end

function KickAssist_ShowMacroEditor()
	if macroFrame then
		macroFrame.note:SetText(MacroNoteText())
		macroFrame:Show()
		macroFrame:Raise()
		macroFrame.ReloadFields()
		return
	end

	macroFrame = CreateFrame("Frame", "KickAssistMacroFrame", UIParent, "BackdropTemplate")
	macroFrame:SetSize(420, 416)
	macroFrame:SetFrameStrata("DIALOG")
	macroFrame:SetToplevel(true)
	macroFrame:SetClampedToScreen(true)
	macroFrame:SetBackdrop({
		bgFile   = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = false, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	})
	macroFrame:SetBackdropColor(0.04, 0.04, 0.04, 0.9)
	macroFrame:SetMovable(true)
	macroFrame:EnableMouse(true)
	macroFrame:RegisterForDrag("LeftButton")
	macroFrame:SetScript("OnDragStart", macroFrame.StartMoving)
	macroFrame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local pt, _, rp, x, y = self:GetPoint()
		DB.macroPoint = { pt, rp, x, y }
	end)
	tinsert(UISpecialFrames, "KickAssistMacroFrame")

	local close = CreateFrame("Button", nil, macroFrame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)

	local title = macroFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -16)
	title:SetText("Edit Macro")

	local nameLabel = macroFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	nameLabel:SetPoint("TOPLEFT", 24, -80)
	nameLabel:SetText("Macro name:")

	local nameBox = CreateFrame("EditBox", nil, macroFrame, "InputBoxTemplate")
	nameBox:SetSize(130, 20)
	nameBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
	nameBox:SetAutoFocus(false)
	nameBox:SetScript("OnEscapePressed", nameBox.ClearFocus)
	nameBox:SetScript("OnEnterPressed", nameBox.ClearFocus)
	macroFrame.nameBox = nameBox

	local note = macroFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	note:SetPoint("TOPLEFT", 24, -106)
	note:SetPoint("TOPRIGHT", -24, -106)
	note:SetJustifyH("LEFT")
	macroFrame.note = note
	note:SetText(MacroNoteText())

	local bodyLabel = macroFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	bodyLabel:SetPoint("TOPLEFT", 24, -132)
	bodyLabel:SetText("Macro body ({interrupt} and {marker} are filled in for you):")

	local scroll = CreateFrame("ScrollFrame", "KickAssistMacroScroll", macroFrame, "InputScrollFrameTemplate")
	scroll:SetSize(372, 96)
	scroll:SetPoint("TOPLEFT", 24, -152)
	scroll.EditBox:SetMultiLine(true)
	scroll.EditBox:SetMaxLetters(255)
	scroll.EditBox:SetWidth(360)
	scroll.EditBox:SetFontObject(ChatFontNormal)
	if scroll.CharCount then scroll.CharCount:Hide() end
	macroFrame.scroll = scroll

	-- Frame border around the scroll for clarity.
	local border = CreateFrame("Frame", nil, macroFrame, "BackdropTemplate")
	border:SetPoint("TOPLEFT", scroll, "TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 22, -6)
	border:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
	})

	-- Which macro this editor is editing.
	local function CurrentName()
		local cfg = SLOT_CFG[editorSlot]
		local n = DB[cfg.nameKey]
		return (n and n ~= "") and n or cfg.defName
	end
	local function CurrentTemplate()
		local cfg = SLOT_CFG[editorSlot]
		return DB[cfg.tmplKey] or cfg.defBody
	end
	local markerBtn  -- created below; only shown for the kick/focus slots (Tab Kick has no marker)
	local function ReloadFields()
		nameBox:SetText(CurrentName())
		nameBox:SetCursorPosition(0)
		scroll.EditBox:SetText(CurrentTemplate())
		scroll.EditBox:SetCursorPosition(0)
		scroll:SetVerticalScroll(0)
		if markerBtn then markerBtn:SetShown(editorSlot == "kick" or editorSlot == "focus") end
	end
	local function ApplySlot(name, template)
		local cfg = SLOT_CFG[editorSlot]
		DB[cfg.nameKey] = name
		DB[cfg.tmplKey] = template
		if editorSlot == "kick" then
			DB.macroEnabled = true
			UpdateManagedMacro()
		elseif editorSlot == "focus" then
			UpdateSetFocusMacro(true)
		else
			UpdateAutoTabMacro(true)
		end
	end
	macroFrame.ReloadFields = ReloadFields

	-- Slot selector: pick which macro to edit.
	local editLabel = macroFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	editLabel:SetPoint("TOPLEFT", 24, -50)
	editLabel:SetText("Editing:")

	local slotDrop = CreateFrame("DropdownButton", nil, macroFrame, "WowStyle1DropdownTemplate")
	slotDrop:SetSize(160, 22)
	slotDrop:SetPoint("LEFT", editLabel, "RIGHT", 10, 0)
	local function SlotIsSelected(sk) return editorSlot == sk end
	local function SlotSetSelected(sk) editorSlot = sk; C_Timer.After(0, ReloadFields) end
	slotDrop:SetupMenu(function(dropdown, root)
		for _, key in ipairs(SLOT_ORDER) do
			root:CreateRadio(SLOT_CFG[key].label, SlotIsSelected, SlotSetSelected, key)
		end
	end)

	-- Pick an existing macro to load it. Built as a plain ScrollFrame + buttons rather
	-- than a WowStyle1Dropdown: the dropdown's ScrollBox compares a secret content
	-- extent inside instances and throws under our taint. A plain ScrollFrame (same
	-- tech as the body editor) is taint-safe, so the editor stays usable in dungeons.
	local pickBtn = CreateFrame("Button", nil, macroFrame, "UIPanelButtonTemplate")
	pickBtn:SetSize(150, 22)
	pickBtn:SetPoint("LEFT", nameBox, "RIGHT", 12, 0)
	pickBtn:SetText("Import Existing")

	local pickPanel = CreateFrame("Frame", nil, pickBtn, "BackdropTemplate")
	pickPanel:SetSize(196, 210)
	pickPanel:SetPoint("TOPLEFT", pickBtn, "BOTTOMLEFT", 0, -2)
	pickPanel:SetFrameStrata("FULLSCREEN_DIALOG")
	pickPanel:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	pickPanel:SetBackdropColor(0.05, 0.05, 0.05, 0.97)
	pickPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	pickPanel:Hide()

	local pickScroll = CreateFrame("ScrollFrame", nil, pickPanel)
	pickScroll:SetPoint("TOPLEFT", 6, -6)
	pickScroll:SetPoint("BOTTOMRIGHT", -6, 6)
	pickScroll:EnableMouseWheel(true)
	local pickChild = CreateFrame("Frame", nil, pickScroll)
	pickChild:SetSize(180, 10)
	pickScroll:SetScrollChild(pickChild)
	pickScroll:SetScript("OnMouseWheel", function(self, delta)
		local maxScroll = math.max(0, pickChild:GetHeight() - self:GetHeight())
		self:SetVerticalScroll(math.min(maxScroll, math.max(0, self:GetVerticalScroll() - delta * 36)))
	end)

	local pickRows = {}
	local function PopulatePicker()
		for _, r in ipairs(pickRows) do r:Hide() end
		local count = 0
		local function AddRow(actualIndex)
			local mname = GetMacroInfo(actualIndex)
			if not mname or mname == "" then return end
			count = count + 1
			local r = pickRows[count]
			if not r then
				r = CreateFrame("Button", nil, pickChild)
				r:SetHeight(18)
				r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
				r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				r.text:SetPoint("LEFT", 6, 0)
				r.text:SetPoint("RIGHT", -4, 0)
				r.text:SetJustifyH("LEFT")
				pickRows[count] = r
			end
			r:SetPoint("TOPLEFT", pickChild, "TOPLEFT", 0, -(count - 1) * 18)
			r:SetPoint("TOPRIGHT", pickChild, "TOPRIGHT", 0, -(count - 1) * 18)
			r.text:SetText(mname)
			r._idx = actualIndex
			r:SetScript("OnClick", function(self)
				-- Import the BODY only into the slot you're editing. The addon keeps
				-- managing its own macro (the name above is unchanged) -- picking copies
				-- commands in as a starting point, it does NOT repoint to this macro.
				local _, _, body = GetMacroInfo(self._idx)
				scroll.EditBox:SetText(body or "")
				scroll.EditBox:SetCursorPosition(0)
				scroll:SetVerticalScroll(0)
				pickPanel:Hide()
			end)
			r:Show()
		end
		local numAccount, numChar = GetNumMacros()
		for i = 1, numAccount do AddRow(i) end
		for i = 1, numChar do AddRow(ACCT_MACRO_CAP + i) end
		pickChild:SetHeight(math.max(1, count * 18))
		pickScroll:SetVerticalScroll(0)
	end

	pickBtn:SetScript("OnClick", function()
		if pickPanel:IsShown() then
			pickPanel:Hide()
		else
			PopulatePicker()
			pickPanel:Show()
			pickPanel:Raise()
		end
	end)

	local info = macroFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	info:SetPoint("TOPLEFT", 24, -256)
	info:SetPoint("TOPRIGHT", -24, -256)
	info:SetJustifyH("LEFT")
	info:SetText("Import Existing copies a macro's commands in as a starting point; Save writes them to the macro named above (the addon's own). For Focus + Kick and Set Focus, click \"Add / Sync Marker Line\" first to add the marker line.")

	local saveBtn = CreateFrame("Button", nil, macroFrame, "UIPanelButtonTemplate")
	saveBtn:SetSize(170, 24)
	saveBtn:SetPoint("BOTTOMLEFT", 30, 18)
	saveBtn:SetText("Save & Update Macro")
	saveBtn:SetScript("OnClick", function()
		local nm = (nameBox:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if nm == "" then nm = CurrentName() end
		ApplySlot(nm, scroll.EditBox:GetText())
		nameBox:SetText(nm)
	end)

	-- Add or sync the {marker} marker line in the body (kick/focus slots only; shown via ReloadFields).
	markerBtn = CreateFrame("Button", nil, macroFrame, "UIPanelButtonTemplate")
	markerBtn:SetSize(210, 22)
	markerBtn:SetPoint("BOTTOM", 0, 50)
	markerBtn:SetText("Add / Sync Marker Line")
	markerBtn:SetScript("OnClick", function()
		scroll.EditBox:SetText(ManageMarkerInBody(scroll.EditBox:GetText()))
		scroll.EditBox:SetCursorPosition(0)
		scroll:SetVerticalScroll(0)
	end)

	local templateDrop = CreateFrame("DropdownButton", nil, macroFrame, "WowStyle1DropdownTemplate")
	templateDrop:SetSize(190, 24)
	templateDrop:SetPoint("BOTTOMRIGHT", -30, 18)
	templateDrop:SetDefaultText("Choose a template...")
	templateDrop:SetupMenu(function(dropdown, root)
		root:SetScrollMode(20 * 16)
		for _, t in ipairs(TEMPLATES[editorSlot] or {}) do
			local body = t.body
			root:CreateButton(t.name, function()
				scroll.EditBox:SetText(body)
				local nm = (nameBox:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
				if nm == "" then nm = CurrentName() end
				ApplySlot(nm, body)
				nameBox:SetText(nm)
			end)
		end
	end)

	local p = DB.macroPoint or DEFAULTS.macroPoint
	macroFrame:ClearAllPoints()
	macroFrame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
	macroFrame:Show()
	macroFrame:Raise()
	ReloadFields()
end

--------------------------------------------------------------------------------
-- Minimap button + Blizzard options panel
--------------------------------------------------------------------------------

local minimapBtn

-- Opens the branded settings window (the Blizzard AddOns canvas still exists as a launcher).
local function OpenSettings()
	OpenKAOptions()
end

local function UpdateMinimapShown()
	if not minimapBtn then return end
	if DB.minimap.hide then minimapBtn:Hide() else minimapBtn:Show() end
end

local function UpdateMinimapPos()
	if not minimapBtn then return end
	local angle = math.rad(DB.minimap.angle or 214)
	local r = (Minimap:GetWidth() / 2) + 5
	minimapBtn:ClearAllPoints()
	minimapBtn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

local function CreateMinimapButton()
	if minimapBtn then return end
	local b = CreateFrame("Button", "KickAssistMinimapButton", Minimap)
	b:SetSize(31, 31)
	b:SetFrameStrata("MEDIUM")
	b:SetFrameLevel(8)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b:RegisterForDrag("LeftButton")

	local bg = b:CreateTexture(nil, "BACKGROUND")
	bg:SetSize(20, 20)
	bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	bg:SetPoint("TOPLEFT", 7, -5)

	local icon = b:CreateTexture(nil, "ARTWORK")
	icon:SetSize(18, 18)
	icon:SetPoint("TOPLEFT", 7, -6)
	SetMarkerTexture(icon, 8) -- skull

	local overlay = b:CreateTexture(nil, "OVERLAY")
	overlay:SetSize(53, 53)
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	overlay:SetPoint("TOPLEFT")

	b:SetScript("OnClick", function(_, button)
		if button == "RightButton" then OpenSettings() else ShowUI() end
	end)

	-- Drag around the minimap edge; OnUpdate only runs while dragging.
	b:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local scale = Minimap:GetEffectiveScale()
			local px, py = GetCursorPosition()
			px, py = px / scale, py / scale
			DB.minimap.angle = math.deg(math.atan2(py - my, px - mx))
			UpdateMinimapPos()
		end)
	end)
	b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText("Kick Assist")
		GameTooltip:AddLine("Left-click: open window", 1, 1, 1)
		GameTooltip:AddLine("Right-click: options", 1, 1, 1)
		GameTooltip:AddLine("Drag: move button", 1, 1, 1)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)

	minimapBtn = b
	UpdateMinimapPos()
	UpdateMinimapShown()
end

--------------------------------------------------------------------------------
-- Interrupt Alert: sound/TTS when your FOCUS starts casting AND your interrupt is
-- ready. We cannot tell if the cast is interruptible (UnitCastingInfo.notInterruptible
-- is secret in M+, and the INTERRUPTIBLE events don't fire for enemies), so this fires
-- on any focus cast while your kick is up; pair with a cast-bar addon for the visual
-- interruptible cue. Everything here is non-secret.
--------------------------------------------------------------------------------

-- Hidden shadow Cooldown for a non-secret "is my interrupt ready" read: feed the
-- interrupt's cooldown duration object, then IsShown() == on cooldown.
local interruptCD = CreateFrame("Cooldown", nil, UIParent, "CooldownFrameTemplate")
interruptCD:SetSize(1, 1)
interruptCD:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -100, -100)
interruptCD:SetAlpha(0)
interruptCD:EnableMouse(false)
interruptCD:SetHideCountdownNumbers(true)
interruptCD:SetDrawEdge(false)
interruptCD:SetDrawBling(false)
interruptCD:Show()

local function InterruptReady()
	local id = GetMyInterruptID()
	if not id or not (C_Spell and C_Spell.GetSpellCooldownDuration) then return false end
	local dur = C_Spell.GetSpellCooldownDuration(id, true)
	if not dur then return false end
	interruptCD:SetCooldownFromDurationObject(dur, true)
	return not interruptCD:IsShown()
end

local function TTSVoice()
	local v = C_VoiceChat and C_VoiceChat.GetTtsVoices and C_VoiceChat.GetTtsVoices()
	return (v and v[1] and v[1].voiceID) or 0
end

-- Built-in alert sounds, always available (no LibSharedMedia needed). "Default"
-- maps to Ready Check (the original alert sound).
local BUILTIN_SOUNDS = {
	["Ready Check"]  = SOUNDKIT.READY_CHECK,
	["Raid Warning"] = SOUNDKIT.RAID_WARNING,
	["Alarm Clock"]  = SOUNDKIT.ALARM_CLOCK_WARNING_3,
	["Boss Whisper"] = SOUNDKIT.UI_RAID_BOSS_WHISPER_WARNING,
	["Map Ping"]     = SOUNDKIT.MAP_PING,
	["BNet Toast"]   = SOUNDKIT.UI_BNET_TOAST,
	["Whisper"]      = SOUNDKIT.TELL_MESSAGE,
}
local BUILTIN_ORDER = { "Ready Check", "Raid Warning", "Alarm Clock", "Boss Whisper", "Map Ping", "BNet Toast", "Whisper" }

-- Ordered list of selectable sounds: Default, the built-ins, any LibSharedMedia
-- sounds (if another addon provides the library), then None. LibStub is guarded
-- so the standalone works with or without LSM present.
local function GetSoundList()
	local list, seen = { "Default" }, { Default = true, None = true }
	for _, name in ipairs(BUILTIN_ORDER) do
		if not seen[name] then list[#list + 1] = name; seen[name] = true end
	end
	local lsm = LibStub and LibStub("LibSharedMedia-3.0", true)
	if lsm then
		for _, name in ipairs(lsm:List("sound") or {}) do
			if not seen[name] then list[#list + 1] = name; seen[name] = true end
		end
	end
	list[#list + 1] = "None"
	return list
end

-- Play the configured interrupt-alert sound.
local function PlayInterruptSound()
	local name    = DB.interruptAlertSound or "Default"
	local channel = DB.interruptAlertChannel or "Master"
	if name == "None" then return end
	if name == "Default" then PlaySound(SOUNDKIT.READY_CHECK, channel); return end
	local builtin = BUILTIN_SOUNDS[name]
	if builtin then PlaySound(builtin, channel); return end
	local lsm = LibStub and LibStub("LibSharedMedia-3.0", true)
	local path = lsm and lsm:Fetch("sound", name, true)
	if path then PlaySoundFile(path, channel)
	else PlaySound(SOUNDKIT.READY_CHECK, channel) end
end

local lastInterruptAlert = 0
local function FireInterruptAlert()
	if (GetTime() - lastInterruptAlert) < 1.5 then return end  -- throttle
	lastInterruptAlert = GetTime()
	if DB.interruptAlertTTS then
		if C_VoiceChat and C_VoiceChat.SpeakText then
			C_VoiceChat.SpeakText(TTSVoice(), DB.interruptAlertText or "Kick", 0, 100)
		end
	else
		PlayInterruptSound()
	end
end

local alertFrame = CreateFrame("Frame")
alertFrame:SetScript("OnEvent", function()
	if DB and DB.interruptAlert and InterruptReady() then FireInterruptAlert() end
end)

-- Register the focus cast events only while the alert is enabled (zero idle cost).
-- (Assigns to the forward-declared local near the top of the file.)
function SyncInterruptAlert()
	if DB and DB.interruptAlert then
		alertFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "focus")
		alertFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "focus")
	else
		alertFrame:UnregisterAllEvents()
	end
end

-- Flip account-wide mode. First time it's turned on, the account store is seeded from THIS
-- character (your main), so your current setup carries over. No per-character data is lost.
local function SetAccountWide(enabled)
	enabled = enabled and true or false
	if enabled and not ADB.seeded then
		for k, v in pairs(DEFAULTS) do
			-- customKick is per-character BY DESIGN (a kick spell belongs to one class),
			-- so it is never copied into the shared store and never read from it.
			if k ~= "customKick" then
				local cur = CDB[k]
				if cur ~= nil then
					ADB[k] = (type(cur) == "table") and CopyTable(cur) or cur
				end
			end
		end
		ADB.seeded = true
	end
	ADB.accountWide = enabled
	ResolveActiveDB()          -- point DB at the now-active store
	SyncInterruptAlert()       -- the active store may differ in the alert setting
	UpdateMinimapShown()       -- and in minimap show/hide
	SyncMacros()               -- rewrite macros for the active store + current class
	RefreshOpenUI()            -- update any open windows to the active store
	if enabled then
		print(PREFIX .. "account-wide mode ON. Settings and macros are now shared across all your characters; re-drag the Kick macro to your bars if it changed.")
	else
		print(PREFIX .. "account-wide mode OFF. Back to per-character settings and macros.")
	end
end

--------------------------------------------------------------------------------
-- Arc UI 2.0 makeover: branded options window
--
-- Hand-built to match the Arc Ping Feed standalone panel (navy body, cyan accent,
-- underline tabs, striped rows, sliding switches, windowed dropdowns). Self-contained
-- primitives copied from that template since Kick Assist has no AceConfig.
--------------------------------------------------------------------------------

local WHITE = "Interface\\Buttons\\WHITE8X8"
local COL = {
	bg      = { 0.043, 0.059, 0.102 },
	panel   = { 0.063, 0.094, 0.153 },
	well    = { 0.039, 0.067, 0.125 },
	line    = { 0.114, 0.165, 0.247 },
	line2   = { 0.165, 0.231, 0.341 },
	box     = { 0.055, 0.078, 0.130 },  -- section container fill (slightly raised from bg)
	ink     = { 0.950, 0.970, 1.000 },
	dim     = { 0.700, 0.780, 0.880 },
	faint   = { 0.550, 0.650, 0.780 },
	arc     = { 0.247, 0.788, 0.949 },
	arcDeep = { 0.078, 0.353, 0.451 },
}

local function Skin(f, bg, borderCol)
	f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
	f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
	local b = borderCol or COL.line
	f:SetBackdropBorderColor(b[1], b[2], b[3], 1)
end

local kaWin            -- the options window (built lazily)
local kaActiveTab      -- current tab name
local kaOpenDropdown   -- the one open dropdown pullout, if any

local function CloseDropdown()
	if kaOpenDropdown then kaOpenDropdown:Hide(); kaOpenDropdown = nil end
end

-- Sliding on/off switch with fully ROUNDED ends (canonical ProcTracker/ArcSkin port):
-- capsule track (two masked half-circles + middle) + a circular knob that slides.
local function MakeSwitch(parent)
	local s = CreateFrame("Button", nil, parent)
	s:SetSize(28, 14)
	local function circle(tex)
		local m = s:CreateMaskTexture()
		m:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		m:SetAllPoints(tex); tex:AddMaskTexture(m)
	end
	local function pillTex(layer, h, inset)
		local capL = s:CreateTexture(nil, layer)
		capL:SetTexture(WHITE); capL:SetSize(h, h); capL:SetPoint("LEFT", inset, 0); circle(capL)
		local capR = s:CreateTexture(nil, layer)
		capR:SetTexture(WHITE); capR:SetSize(h, h); capR:SetPoint("RIGHT", -inset, 0); circle(capR)
		local mid = s:CreateTexture(nil, layer)
		mid:SetTexture(WHITE)
		mid:SetPoint("TOPLEFT", capL, "TOP", 0, 0); mid:SetPoint("BOTTOMRIGHT", capR, "BOTTOM", 0, 0)
		local texs = { capL, capR, mid }
		return { SetColor = function(_, r, g, b, a) for i = 1, 3 do texs[i]:SetVertexColor(r, g, b, a or 1) end end }
	end
	s.border = pillTex("BACKGROUND", 14, 0)
	s.fill   = pillTex("BORDER", 12, 1)
	s.knob = s:CreateTexture(nil, "OVERLAY"); s.knob:SetTexture(WHITE); s.knob:SetSize(10, 10); circle(s.knob)
	function s:SetOn(on)
		self.knob:ClearAllPoints()
		if on then
			self.border:SetColor(COL.arcDeep[1], COL.arcDeep[2], COL.arcDeep[3], 1)
			self.fill:SetColor(COL.arc[1] * 0.22, COL.arc[2] * 0.22, COL.arc[3] * 0.22, 1)
			self.knob:SetPoint("RIGHT", -2, 0)
			self.knob:SetVertexColor(COL.arc[1], COL.arc[2], COL.arc[3], 1)
		else
			self.border:SetColor(COL.line[1], COL.line[2], COL.line[3], 1)
			self.fill:SetColor(COL.well[1], COL.well[2], COL.well[3], 1)
			self.knob:SetPoint("LEFT", 2, 0)
			self.knob:SetVertexColor(COL.faint[1], COL.faint[2], COL.faint[3], 1)
		end
	end
	s._glow = s:CreateTexture(nil, "ARTWORK")
	s._glow:SetTexture("Interface\\Buttons\\ButtonHilight-Square"); s._glow:SetBlendMode("ADD")
	s._glow:SetVertexColor(COL.arc[1], COL.arc[2], COL.arc[3], 0.5)
	s._glow:SetPoint("TOPLEFT", -4, 4); s._glow:SetPoint("BOTTOMRIGHT", 4, -4); s._glow:Hide()
	function s:SetHover(on) self._glow:SetShown(on and true or false) end
	return s
end

-- WoW-style square checkbox (alt to the pill switch). The BOX stays constant (fill + border
-- never change) -- only the checkmark is added/removed, exactly like Blizzard. The mark is the
-- clean modern flat atlas "checkmark-minimal" tinted to the Arc cyan, sized to sit INSIDE the
-- box so the border stays visible.
local function MakeCheckbox(parent)
	local c = CreateFrame("Button", nil, parent, "BackdropTemplate")
	c:SetSize(18, 18); Skin(c, COL.well, COL.line2)   -- stronger, clearer border
	c.check = c:CreateTexture(nil, "OVERLAY")
	c.check:SetAtlas("checkmark-minimal")
	c.check:SetDesaturated(true)                        -- grey the green atlas so the tint reads as pure cyan
	c.check:SetVertexColor(COL.arc[1], COL.arc[2], COL.arc[3], 1)
	c.check:SetSize(20, 20); c.check:SetPoint("CENTER", 0, 0)   -- slightly bigger than the 18px box, so it overhangs like WoW's
	c.check:Hide()
	c._glow = c:CreateTexture(nil, "ARTWORK")
	c._glow:SetTexture("Interface\\Buttons\\ButtonHilight-Square"); c._glow:SetBlendMode("ADD")
	c._glow:SetVertexColor(COL.arc[1], COL.arc[2], COL.arc[3], 0.55)
	c._glow:SetPoint("TOPLEFT", -3, 3); c._glow:SetPoint("BOTTOMRIGHT", 3, -3); c._glow:Hide()
	function c:SetHover(on) self._glow:SetShown(on and true or false) end
	function c:SetOn(on) self.check:SetShown(on and true or false) end
	return c
end

-- Arc action button (EllesmereUI style): a slightly-raised SOLID slate fill + a defined STEEL
-- border, white text. The subtle raised fill + clear border is what reads as a button, distinct
-- from the darker sunken input fields. Cyan border + lighter fill on hover.
local BTN_FILL   = { 0.110, 0.161, 0.243 }   -- darker navy-blue fill (#1C293E)
local BTN_BORDER = { 0.298, 0.400, 0.549 }   -- steel border (#4C668C)
local BTN_HOVER  = { 0.150, 0.205, 0.295 }   -- lighter on hover
local function MakeSmallButton(parent, label, w)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(w or 92, 22); Skin(b, BTN_FILL, BTN_BORDER)
	local bevel = b:CreateTexture(nil, "ARTWORK"); bevel:SetTexture(WHITE)  -- subtle top highlight
	bevel:SetVertexColor(1, 1, 1, 0.06); bevel:SetPoint("TOPLEFT", 1, -1); bevel:SetPoint("TOPRIGHT", -1, -1); bevel:SetHeight(1)
	local fs = b:CreateFontString(nil, "OVERLAY"); fs:SetFont(STANDARD_TEXT_FONT, 11, "")
	fs:SetPoint("CENTER"); fs:SetTextColor(COL.ink[1], COL.ink[2], COL.ink[3]); fs:SetText(label)
	b.fs = fs
	b:SetScript("OnEnter", function()
		b:SetBackdropColor(BTN_HOVER[1], BTN_HOVER[2], BTN_HOVER[3], 1)
		b:SetBackdropBorderColor(COL.arc[1], COL.arc[2], COL.arc[3], 1)
	end)
	b:SetScript("OnLeave", function()
		b:SetBackdropColor(BTN_FILL[1], BTN_FILL[2], BTN_FILL[3], 1)
		b:SetBackdropBorderColor(BTN_BORDER[1], BTN_BORDER[2], BTN_BORDER[3], 1)
	end)
	return b
end

-- Boxed close button (EUI treatment): the "x" in a bordered square, cyan on hover.
local function MakeCloseBox(parent, onClick)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(22, 22); Skin(b, COL.well, COL.line)
	local cx = b:CreateFontString(nil, "OVERLAY"); cx:SetFont(STANDARD_TEXT_FONT, 13, ""); cx:SetPoint("CENTER"); cx:SetText("x")
	cx:SetTextColor(COL.dim[1], COL.dim[2], COL.dim[3])
	b:SetScript("OnEnter", function() b:SetBackdropBorderColor(COL.arc[1],COL.arc[2],COL.arc[3],1); cx:SetTextColor(COL.arc[1],COL.arc[2],COL.arc[3]) end)
	b:SetScript("OnLeave", function() b:SetBackdropBorderColor(COL.line[1],COL.line[2],COL.line[3],1); cx:SetTextColor(COL.dim[1],COL.dim[2],COL.dim[3]) end)
	b:SetScript("OnClick", onClick)
	return b
end

-- Discord: the main Arc UI community invite (same link as ArcUI). Addons can't open URLs,
-- so the button shows a small copy popup with the URL selected for Ctrl+C.
local KA_DISCORD = "https://discord.gg/yMZmnFjUTd"
local BLURPLE = { 0.345, 0.396, 0.949 }   -- #5865F2
local kaDiscordCopy

local function ShowDiscordCopy(anchor)
	if not kaDiscordCopy then
		local d = CreateFrame("Frame", "KickAssistDiscordCopy", UIParent, "BackdropTemplate")
		d:SetSize(300, 70); d:SetFrameStrata("FULLSCREEN_DIALOG"); d:SetToplevel(true)
		Skin(d, COL.panel, COL.arc)
		local t = d:CreateFontString(nil, "OVERLAY"); t:SetFont(STANDARD_TEXT_FONT, 12, ""); t:SetPoint("TOP", 0, -10)
		t:SetTextColor(COL.ink[1], COL.ink[2], COL.ink[3]); t:SetText("Press Ctrl+C to copy, then open it in your browser")
		local box = CreateFrame("EditBox", nil, d, "BackdropTemplate"); box:SetSize(272, 22); box:SetPoint("TOP", 0, -32); Skin(box, COL.well)
		box:SetFont(STANDARD_TEXT_FONT, 12, ""); box:SetTextInsets(6, 6, 0, 0); box:SetTextColor(COL.ink[1], COL.ink[2], COL.ink[3])
		box:SetAutoFocus(false)
		box:SetScript("OnEscapePressed", function() d:Hide() end)
		box:SetScript("OnEnterPressed", function() d:Hide() end)
		box:SetScript("OnEditFocusLost", function() d:Hide() end)
		tinsert(UISpecialFrames, "KickAssistDiscordCopy")
		d.box = box
		kaDiscordCopy = d
	end
	kaDiscordCopy:ClearAllPoints()
	kaDiscordCopy:SetPoint("CENTER", anchor or UIParent, "CENTER", 0, 0)
	kaDiscordCopy:Show(); kaDiscordCopy:Raise()
	kaDiscordCopy.box:SetText(KA_DISCORD); kaDiscordCopy.box:SetFocus(); kaDiscordCopy.box:HighlightText()
end

-- Small "Discord" button (blurple accent) that opens the copy popup.
local function MakeDiscordButton(parent)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(84, 20); Skin(b, COL.well)
	local fs = b:CreateFontString(nil, "OVERLAY"); fs:SetFont(STANDARD_TEXT_FONT, 11, "")
	fs:SetPoint("CENTER"); fs:SetText("|cff7289DADiscord|r")
	b:SetScript("OnEnter", function()
		b:SetBackdropBorderColor(BLURPLE[1], BLURPLE[2], BLURPLE[3], 1)
		GameTooltip:SetOwner(b, "ANCHOR_BOTTOM"); GameTooltip:AddLine("Join the Arc UI Discord", 1, 1, 1)
		GameTooltip:AddLine("Questions, help, and updates", 0.7, 0.7, 0.7); GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() b:SetBackdropBorderColor(COL.line[1], COL.line[2], COL.line[3], 1); GameTooltip:Hide() end)
	b:SetScript("OnClick", function() ShowDiscordCopy(parent) end)
	return b
end

local ROW_H = 24
local TOGGLE_H = 24   -- toggle row height (a bit of breathing room between rows)

-- Add a row to the CURRENT section's box (or the page, pre-section). LayoutPage positions it.
local function AddRow(pg, h, visibleFn)
	h = h or ROW_H
	local sec = pg._curSection
	local parent = (sec and sec.box) or pg
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(h); row._h = h; row._visibleFn = visibleFn
	if sec then sec.rows[#sec.rows + 1] = row else pg._rows[#pg._rows + 1] = row end
	return row
end

local function RowLabel(row, text)
	local fs = row:CreateFontString(nil, "OVERLAY")
	fs:SetFont(STANDARD_TEXT_FONT, 12, ""); fs:SetPoint("LEFT", 10, 0)
	fs:SetTextColor(COL.ink[1], COL.ink[2], COL.ink[3]); fs:SetText(text)
	return fs
end

-- Start a titled, bordered section BOX (ProcTracker "Deck Position Text" look): a cyan
-- mini-title above a bordered container. Rows added after this go inside the box.
local function Section(pg, text)
	local title = pg:CreateFontString(nil, "OVERLAY")
	title:SetFont(STANDARD_TEXT_FONT, 11, "")
	title:SetTextColor(COL.arc[1], COL.arc[2], COL.arc[3]); title:SetText(text)
	local box = CreateFrame("Frame", nil, pg, "BackdropTemplate")
	Skin(box, COL.box, COL.line)
	local sec = { title = title, box = box, rows = {} }
	pg._sections[#pg._sections + 1] = sec
	pg._curSection = sec
	return box
end

-- Small dim helper text inside the current section box.
local function RowDesc(pg, text)
	local row = AddRow(pg, 20)
	local fs = row:CreateFontString(nil, "OVERLAY")
	fs:SetFont(STANDARD_TEXT_FONT, 10, ""); fs:SetPoint("LEFT", 10, 1); fs:SetPoint("RIGHT", -10, 1)
	fs:SetJustifyH("LEFT"); fs:SetTextColor(COL.dim[1], COL.dim[2], COL.dim[3]); fs:SetText(text)
	return row
end

-- Lay out a page: each section = a cyan title + a bordered box sized to its VISIBLE rows.
local function LayoutPage(pg)
	local y = -4
	for _, row in ipairs(pg._rows) do   -- pre-section rows (rare)
		if row._sync then row._sync() end
		local vis = (not row._visibleFn) or row._visibleFn()
		if vis then
			row:ClearAllPoints(); row:SetPoint("TOPLEFT", 2, y); row:SetPoint("TOPRIGHT", -2, y); row:Show()
			y = y - row._h
		else row:Hide() end
	end
	-- ONE toggle column for the whole page: every toggle across every section lines up.
	local tcol = 0
	for _, sec in ipairs(pg._sections) do
		for _, row in ipairs(sec.rows) do
			if row._tglLabel and ((not row._visibleFn) or row._visibleFn()) then
				tcol = math.max(tcol, 10 + row._tglLabel:GetStringWidth())
			end
		end
	end
	tcol = tcol + 18
	for _, sec in ipairs(pg._sections) do
		sec.title:ClearAllPoints(); sec.title:SetPoint("TOPLEFT", 4, y - 2); sec.title:Show()
		y = y - 13   -- title hugs its box (like Blizzard's header-over-rows)
		sec.box:ClearAllPoints(); sec.box:SetPoint("TOPLEFT", 0, y); sec.box:SetPoint("TOPRIGHT", 0, y)
		local by = -1
		for _, row in ipairs(sec.rows) do
			if row._sync then row._sync() end
			local vis = (not row._visibleFn) or row._visibleFn()
			if vis then
				row:ClearAllPoints()
				row:SetPoint("TOPLEFT", sec.box, "TOPLEFT", 6, by)
				row:SetPoint("TOPRIGHT", sec.box, "TOPRIGHT", -6, by)
				row:Show()
				if row._tglSw then
					row._tglSw:ClearAllPoints(); row._tglSw:SetPoint("LEFT", row, "LEFT", tcol, 0)
					row._tglCb:ClearAllPoints(); row._tglCb:SetPoint("LEFT", row, "LEFT", tcol, 0)
				end
				by = by - row._h
			else row:Hide() end
		end
		sec.box:SetHeight(math.max(10, -by + 2))
		y = y - (-by + 2) - 8
	end
end

local function RowToggle(pg, label, get, set, visibleFn, desc)
	local row = AddRow(pg, TOGGLE_H, visibleFn)
	local lbl = RowLabel(row, label)
	-- Control is column-aligned by LayoutPage (all toggles in a section share a column).
	local sw = MakeSwitch(row); sw:SetPoint("LEFT", lbl, "RIGHT", 14, 0)
	local cb = MakeCheckbox(row); cb:SetPoint("LEFT", lbl, "RIGHT", 14, 0)
	row._tglLabel = lbl; row._tglSw = sw; row._tglCb = cb
	local function refresh()
		local useCheck = (DB.toggleStyle == "checkbox")
		sw:SetShown(not useCheck); cb:SetShown(useCheck)
		sw:SetOn(get()); cb:SetOn(get())
	end
	local function flip()
		set(not get())
		PlaySound(get() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
		refresh(); LayoutPage(pg)
	end
	sw:SetScript("OnClick", flip); cb:SetScript("OnClick", flip)
	local function onEnter()
		sw:SetHover(true); cb:SetHover(true)
		if desc then
			GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
			GameTooltip:AddLine(label, 1, 1, 1)
			GameTooltip:AddLine(desc, 0.75, 0.82, 0.92, true)
			GameTooltip:Show()
		end
	end
	local function onLeave() sw:SetHover(false); cb:SetHover(false); GameTooltip:Hide() end
	row:EnableMouse(true); row:SetScript("OnMouseUp", flip)
	row:SetScript("OnEnter", onEnter); row:SetScript("OnLeave", onLeave)
	sw:HookScript("OnEnter", onEnter); sw:HookScript("OnLeave", onLeave)
	cb:HookScript("OnEnter", onEnter); cb:HookScript("OnLeave", onLeave)
	row._sync = refresh
	refresh()
	return row
end

-- desc may be a string, or a FUNCTION for a tooltip that reports live state (the
-- custom kick row uses that to show which spell it actually resolved to).
-- hint works the same way: dim placeholder text drawn INSIDE the box while it is
-- empty, so a row can show what is currently in effect (your class default kick)
-- without pre-filling the field -- pre-filling would turn "I left it alone" into
-- a saved override the moment the box committed.
local function RowInput(pg, label, get, set, visibleFn, desc, hint)
	local row = AddRow(pg, ROW_H, visibleFn)
	RowLabel(row, label)
	local box = CreateFrame("EditBox", nil, row, "BackdropTemplate")
	box:SetSize(180, 18); box:SetPoint("RIGHT", -12, 0); Skin(box, COL.well)
	box:SetFont(STANDARD_TEXT_FONT, 11, ""); box:SetTextInsets(6, 6, 0, 0)
	box:SetTextColor(COL.ink[1], COL.ink[2], COL.ink[3]); box:SetAutoFocus(false)
	box:SetText(get() or "")

	local hintFS
	if hint then
		hintFS = box:CreateFontString(nil, "OVERLAY")
		hintFS:SetFont(STANDARD_TEXT_FONT, 11, "")
		hintFS:SetPoint("LEFT", 6, 0); hintFS:SetPoint("RIGHT", -6, 0)
		hintFS:SetJustifyH("LEFT")
		hintFS:SetTextColor(COL.faint[1], COL.faint[2], COL.faint[3])
	end
	local function SyncHint()
		if not hintFS then return end
		hintFS:SetText(((type(hint) == "function") and hint()) or hint or "")
		hintFS:SetShown((box:GetText() or "") == "")
	end
	SyncHint()
	box:SetScript("OnTextChanged", SyncHint)

	-- The tooltip has to follow the mouse across the WHOLE row, the input field
	-- included: the box is a child that eats mouse events, so hooking only the row
	-- meant hovering the field itself showed nothing.
	if desc then
		local function ShowTip(owner)
			local body = (type(desc) == "function") and desc() or desc
			if not body or body == "" then return end
			GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
			GameTooltip:AddLine(label, 1, 1, 1)
			GameTooltip:AddLine(body, 0.75, 0.82, 0.92, true)
			GameTooltip:Show()
		end
		local function HideTip() GameTooltip:Hide() end
		row:EnableMouse(true)
		row:HookScript("OnEnter", function() ShowTip(row) end)
		row:HookScript("OnLeave", HideTip)
		box:HookScript("OnEnter", function() ShowTip(box) end)
		box:HookScript("OnLeave", HideTip)
	end

	local function commit() set(box:GetText() or ""); box:SetText(get() or ""); SyncHint() end
	box:SetScript("OnEnterPressed", function() box:ClearFocus() end)   -- commit runs in OnEditFocusLost
	box:SetScript("OnEscapePressed", function() box:SetText(get() or ""); box:ClearFocus() end)
	box:SetScript("OnEditFocusGained", function() box:SetBackdropBorderColor(COL.arcDeep[1], COL.arcDeep[2], COL.arcDeep[3], 1) end)
	box:SetScript("OnEditFocusLost", function() commit(); box:SetBackdropBorderColor(COL.line[1], COL.line[2], COL.line[3], 1) end)
	row._sync = function()
		if not box:HasFocus() then box:SetText(get() or "") end
		SyncHint()
	end
	return row
end

-- Centered action button row.
local function RowButton(pg, label, onClick, visibleFn)
	local row = AddRow(pg, ROW_H, visibleFn)
	local b = MakeSmallButton(row, label, 180); b:SetPoint("CENTER", 0, 0)
	b:SetScript("OnClick", function() CloseDropdown(); onClick() end)
	return row
end

-- Windowed-scroll dropdown row. itemsFn() -> array of { value=, text= }.
local function RowDropdown(pg, label, get, set, itemsFn, visibleFn)
	local row = AddRow(pg, ROW_H, visibleFn)
	RowLabel(row, label)
	local field = CreateFrame("Button", nil, row, "BackdropTemplate")
	field:SetSize(180, 20); field:SetPoint("RIGHT", -12, 0); Skin(field, COL.well)
	local vf = field:CreateFontString(nil, "OVERLAY"); vf:SetFont(STANDARD_TEXT_FONT, 11, "")
	vf:SetPoint("LEFT", 8, 0); vf:SetPoint("RIGHT", -18, 0); vf:SetJustifyH("LEFT")
	vf:SetTextColor(COL.ink[1], COL.ink[2], COL.ink[3])
	local arrow = field:CreateFontString(nil, "OVERLAY"); arrow:SetFont(STANDARD_TEXT_FONT, 9, "")
	arrow:SetPoint("RIGHT", -6, -1); arrow:SetTextColor(COL.arc[1], COL.arc[2], COL.arc[3]); arrow:SetText("v")
	field:SetScript("OnEnter", function() field:SetBackdropBorderColor(COL.arcDeep[1], COL.arcDeep[2], COL.arcDeep[3], 1) end)
	field:SetScript("OnLeave", function() field:SetBackdropBorderColor(COL.line[1], COL.line[2], COL.line[3], 1) end)

	local function curText()
		local v = get()
		for _, it in ipairs(itemsFn()) do if it.value == v then return it.text end end
		return tostring(v)
	end
	local function syncText() vf:SetText(curText()) end
	syncText()

	field:SetScript("OnClick", function()
		if kaOpenDropdown and kaOpenDropdown._owner == field then CloseDropdown(); return end
		CloseDropdown()
		local items = itemsFn()
		local VISIBLE = math.min(#items, 12)
		local list = CreateFrame("Frame", nil, kaWin, "BackdropTemplate")
		list:SetFrameLevel(kaWin:GetFrameLevel() + 30)
		list:SetWidth(180); list:SetHeight(VISIBLE * 20 + 2)
		Skin(list, COL.panel, COL.arcDeep)
		list:SetPoint("TOPRIGHT", field, "BOTTOMRIGHT", 0, -1)
		list._owner = field
		list:EnableMouse(true)
		local offset = 0
		local maxOff = math.max(0, #items - VISIBLE)
		-- start scrolled to the current value
		local curVal = get()
		for i, it in ipairs(items) do if it.value == curVal then offset = math.min(maxOff, math.max(0, i - 1)) end end
		local rows = {}
		for i = 1, VISIBLE do
			local ib = CreateFrame("Button", nil, list); ib:SetSize(176, 20)
			ib:SetPoint("TOPLEFT", 1, -1 - (i - 1) * 20)
			ib:SetHighlightTexture(WHITE); ib:GetHighlightTexture():SetVertexColor(COL.arcDeep[1], COL.arcDeep[2], COL.arcDeep[3], 0.5)
			local t = ib:CreateFontString(nil, "OVERLAY"); t:SetFont(STANDARD_TEXT_FONT, 11, "")
			t:SetPoint("LEFT", 8, 0); t:SetPoint("RIGHT", -6, 0); t:SetJustifyH("LEFT")
			ib.t = t; rows[i] = ib
		end
		local function draw()
			for i = 1, VISIBLE do
				local it = items[i + offset]
				local ib = rows[i]
				if it then
					ib.t:SetText(it.text)
					if it.value == get() then ib.t:SetTextColor(COL.arc[1], COL.arc[2], COL.arc[3])
					else ib.t:SetTextColor(COL.ink[1], COL.ink[2], COL.ink[3]) end
					ib:SetScript("OnClick", function() set(it.value); syncText(); CloseDropdown(); LayoutPage(pg) end)
					ib:Show()
				else ib:Hide() end
			end
		end
		list:SetScript("OnMouseWheel", function(_, d)
			offset = math.min(maxOff, math.max(0, offset - d * 3)); draw()
		end)
		list:EnableMouseWheel(true)
		draw()
		kaOpenDropdown = list
	end)

	row._sync = syncText
	return row
end

-- Build one tab page (holds section boxes; LayoutPage flows them from the top).
local function NewPage()
	local pg = CreateFrame("Frame", nil, kaWin)
	pg._rows = {}; pg._sections = {}; pg._curSection = nil
	function pg:Refresh() LayoutPage(self) end
	pg:Hide()
	return pg
end

local MARKER_ORDER = { 1, 2, 3, 4, 5, 6, 7, 8, 0 }
local function MarkerItems()
	local t = {}
	for _, i in ipairs(MARKER_ORDER) do t[#t + 1] = { value = i, text = MARKER_NAMES[i] } end
	return t
end
local function SoundItems()
	local t = {}
	for _, s in ipairs(GetSoundList()) do t[#t + 1] = { value = s, text = s } end
	return t
end
local CHANNEL_ITEMS = {
	{ value = "Master", text = "Master" }, { value = "SFX", text = "SFX" },
	{ value = "Music", text = "Music" }, { value = "Ambience", text = "Ambience" },
	{ value = "Dialog", text = "Dialog" },
}

local function SelectKATab(name)
	kaActiveTab = name
	for tabName, data in pairs(kaWin._tabs) do
		local sel = (tabName == name)
		data.page:SetShown(sel)
		if sel then
			Skin(data.chip, COL.panel, COL.arc); data.fs:SetTextColor(COL.arc[1], COL.arc[2], COL.arc[3])
			data.page:Refresh()
		else
			Skin(data.chip, COL.well, COL.line); data.fs:SetTextColor(COL.dim[1], COL.dim[2], COL.dim[3])
		end
	end
end

local function BuildKAOptions()
	if kaWin then return kaWin end

	local p = CreateFrame("Frame", "KickAssistOptions", UIParent, "BackdropTemplate")
	-- 480 floor, and the saved height is clamped to it: these pages do not scroll, so
	-- a window shorter than the tallest tab (Macros, with the body editor) would
	-- silently clip its Save button off the bottom.
	local KA_MIN_W, KA_MIN_H = 400, 480
	p:SetSize(math.max(KA_MIN_W, DB.optW or 460), math.max(KA_MIN_H, DB.optH or 540))
	p:SetPoint("CENTER", 0, 40)
	p:SetFrameStrata("DIALOG"); p:SetToplevel(true); p:SetClampedToScreen(true)
	p:SetMovable(true); p:SetResizable(true); p:EnableMouse(true); p:RegisterForDrag("LeftButton")
	p:SetScript("OnDragStart", p.StartMoving); p:SetScript("OnDragStop", p.StopMovingOrSizing)
	p:SetScript("OnMouseDown", CloseDropdown); p:SetScript("OnHide", CloseDropdown)
	if p.SetResizeBounds then p:SetResizeBounds(KA_MIN_W, KA_MIN_H, 900, 1000) end
	Skin(p, COL.bg, COL.line2)
	tinsert(UISpecialFrames, "KickAssistOptions")
	kaWin = p

	-- Title bar
	local bar = CreateFrame("Frame", nil, p, "BackdropTemplate")
	bar:SetPoint("TOPLEFT", 1, -1); bar:SetPoint("TOPRIGHT", -1, -1); bar:SetHeight(30)
	Skin(bar, COL.panel)
	local t1 = bar:CreateFontString(nil, "OVERLAY"); t1:SetFont(STANDARD_TEXT_FONT, 14, "")
	t1:SetPoint("LEFT", 12, 0); t1:SetText("|cff3fc9f2Kick|r|cffd5e2f2 Assist|r")
	local ver = bar:CreateFontString(nil, "OVERLAY"); ver:SetFont(STANDARD_TEXT_FONT, 10, "")
	ver:SetPoint("LEFT", t1, "RIGHT", 8, -1); ver:SetTextColor(COL.dim[1], COL.dim[2], COL.dim[3])
	ver:SetText(C_AddOns.GetAddOnMetadata(ADDON, "Version") or "")
	local close = MakeCloseBox(bar, function() p:Hide() end); close:SetPoint("RIGHT", -4, 0)

	-- Tab strip (physical chips)
	local TABS = { "General", "Macros", "Ready Check", "Alerts" }
	p._tabs = {}
	local chipX = 10
	for _, name in ipairs(TABS) do
		local tb = CreateFrame("Button", nil, p, "BackdropTemplate"); tb:SetHeight(24)
		local fs = tb:CreateFontString(nil, "OVERLAY"); fs:SetFont(STANDARD_TEXT_FONT, 12, "")
		fs:SetPoint("CENTER"); fs:SetText(name)
		tb:SetWidth(math.max(70, fs:GetStringWidth() + 22))
		tb:SetPoint("TOPLEFT", chipX, -34)
		chipX = chipX + tb:GetWidth() + 3
		Skin(tb, COL.well, COL.line); fs:SetTextColor(COL.dim[1], COL.dim[2], COL.dim[3])
		tb:SetScript("OnClick", function() CloseDropdown(); SelectKATab(name) end)
		tb:SetScript("OnEnter", function()
			if kaActiveTab ~= name then tb:SetBackdropBorderColor(COL.arcDeep[1], COL.arcDeep[2], COL.arcDeep[3], 1); fs:SetTextColor(COL.ink[1], COL.ink[2], COL.ink[3]) end
		end)
		tb:SetScript("OnLeave", function()
			if kaActiveTab ~= name then tb:SetBackdropBorderColor(COL.line[1], COL.line[2], COL.line[3], 1); fs:SetTextColor(COL.dim[1], COL.dim[2], COL.dim[3]) end
		end)
		local page = NewPage()
		page:SetPoint("TOPLEFT", 10, -61); page:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -10, 40)
		p._tabs[name] = { chip = tb, fs = fs, page = page }
	end
	-- Cyan accent line just under the chip row (ProcTracker attached-tab look), continuous.
	local tabLine = p:CreateTexture(nil, "ARTWORK"); tabLine:SetTexture(WHITE)
	tabLine:SetVertexColor(COL.arc[1], COL.arc[2], COL.arc[3], 1)
	tabLine:SetPoint("TOPLEFT", 10, -59); tabLine:SetPoint("TOPRIGHT", -10, -59); tabLine:SetHeight(1)

	-- ===== General =====
	local g = p._tabs["General"].page
	Section(g, "Setup")
	RowButton(g, "Open Kick Assist window", function() ShowUI() end)
	RowButton(g, "Edit kick macro", function() SelectKATab("Macros") end)
	Section(g, "Marker")
	RowDropdown(g, "Kick marker",
		function() return DB.marker end,
		function(v) DB.marker = v; UpdateSelection(); SyncMacros() end,
		MarkerItems)
	Section(g, "Account")
	RowToggle(g, "Account-wide settings and macro",
		function() return AccountWideMacros() end,
		function(v) SetAccountWide(v) end,
		nil, "Set up once and share your settings and kick macro across all characters.")
	RowToggle(g, "Show minimap button",
		function() return not DB.minimap.hide end,
		function(v) DB.minimap.hide = not v; UpdateMinimapShown() end)
	Section(g, "Look")
	RowToggle(g, "Classic marker window",
		function() return DB.classicLook end,
		function(v)
			DB.classicLook = v and true or false
			local wasOpen = (frame and frame:IsShown()) or (arcPopup and arcPopup:IsShown())
			if frame then frame:Hide() end
			if arcPopup then arcPopup:Hide() end
			if wasOpen then ShowUI() end
		end,
		nil, "Use the old Blizzard-styled marker window instead of the Arc look.")

	-- ===== Macros =====
	-- The old Edit Macro window was the last Blizzard-styled surface left, so the
	-- whole thing lives here now in the Arc look. The kick spell sits at the top
	-- because it is what {interrupt} in every macro body resolves to.
	local m = p._tabs["Macros"].page
	Section(m, "Kick Spell")
	RowInput(m, "Custom kick spell",
		function() return (CDB and CDB.customKick) or "" end,
		function(v)
			if not CDB then return end
			CDB.customKick = tostring(v or ""):match("^%s*(.-)%s*$") or ""
			SyncMacros()          -- the macro body embeds the spell NAME, so rewrite it
		end,
		nil,
		function()
			local name, id = GetMyInterruptName(), GetMyInterruptID()
			local using
			if name and id then using = name .. " (" .. id .. ")"
			elseif name then using = name .. " (not a spell I could look up)"
			else using = "nothing -- this spec has no default kick" end
			return "This is the spell {interrupt} becomes in your macros.\n\n"
				.. "Leave it blank to use your class and spec default. Type a spell name or a spell ID to override it, for a pet ability or a spec the defaults get wrong.\n\n"
				.. "Always per-character, so it never follows you to an alt of another class.\n\n"
				.. "Using now: " .. using
		end,
		function()   -- dim placeholder: what is in effect while the box is empty
			local name = GetMyInterruptName()
			return name and (name .. "  (your default)") or "no kick for this spec"
		end)
	RowButton(m, "Use my class default", function()
		if CDB then CDB.customKick = "" end
		SyncMacros()
		m:Refresh()
	end, function() return CustomKick() ~= nil end)

	Section(m, "Macro")
	local function SlotCfg() return SLOT_CFG[editorSlot] end
	local function SlotName()
		local cfg = SlotCfg()
		local n = DB[cfg.nameKey]
		return (n and n ~= "") and n or cfg.defName
	end
	local function SlotBody()
		local cfg = SlotCfg()
		return DB[cfg.tmplKey] or cfg.defBody
	end
	local bodyBox     -- the multi-line editor, built just below
	-- A typed name stays PENDING until Save, exactly like the old editor. Writing it
	-- to the DB on focus-loss would repoint the addon at a macro that does not exist
	-- yet, so the next sync would create a SECOND macro and orphan the one already
	-- sitting on your action bars.
	local pendingName
	local function ApplySlot(name, template)
		local cfg = SlotCfg()
		DB[cfg.nameKey] = name
		DB[cfg.tmplKey] = template
		if editorSlot == "kick" then
			DB.macroEnabled = true
			UpdateManagedMacro()
		elseif editorSlot == "focus" then
			UpdateSetFocusMacro(true)
		else
			UpdateAutoTabMacro(true)
		end
	end
	local function SaveSlot()
		if InCombatLockdown() then
			print(PREFIX .. "macros can't be changed in combat; try again when you're out.")
			return
		end
		ApplySlot(pendingName or SlotName(), (bodyBox and bodyBox:GetText()) or SlotBody())
		pendingName = nil
		m:Refresh()
	end

	RowDropdown(m, "Editing",
		function() return editorSlot end,
		function(v) editorSlot = v; pendingName = nil; m:Refresh() end,
		function()
			local out = {}
			for _, key in ipairs(SLOT_ORDER) do
				out[#out + 1] = { value = key, text = SLOT_CFG[key].label }
			end
			return out
		end)
	RowInput(m, "Macro name",
		function() return pendingName or SlotName() end,
		function(v)
			local nm = tostring(v or ""):match("^%s*(.-)%s*$") or ""
			pendingName = (nm ~= "" and nm ~= SlotName()) and nm or nil
		end,
		nil,
		"The macro this addon creates and keeps updated. Type a new name and press Save to start managing that one instead; nothing moves until you save.")
	RowDropdown(m, "Load a template",
		function() return "" end,
		function(v)
			local list = TEMPLATES[editorSlot] or {}
			local t = list[tonumber(v) or 0]
			if not t then return end
			if bodyBox then bodyBox:SetText(t.body); bodyBox:SetCursorPosition(0) end
			ApplySlot(pendingName or SlotName(), t.body)
			pendingName = nil
			m:Refresh()
		end,
		function()
			local out = {}
			for i, t in ipairs(TEMPLATES[editorSlot] or {}) do
				out[#out + 1] = { value = tostring(i), text = t.name }
			end
			if #out == 0 then out[1] = { value = "", text = "no templates for this one" } end
			return out
		end)
	RowDropdown(m, "Copy from a macro",
		function() return "" end,
		function(v)
			local idx = tonumber(v)
			if not idx then return end
			local _, _, body = GetMacroInfo(idx)
			if bodyBox and body then bodyBox:SetText(body); bodyBox:SetCursorPosition(0) end
		end,
		function()
			-- Read live: the player's macro list changes outside this panel. Copies the
			-- BODY in as a starting point; it never repoints the addon at that macro.
			local out = {}
			local numAccount, numChar = GetNumMacros()
			for i = 1, numAccount do
				local n = GetMacroInfo(i)
				if n and n ~= "" then out[#out + 1] = { value = tostring(i), text = n } end
			end
			for i = 1, numChar do
				local realIdx = ACCT_MACRO_CAP + i
				local n = GetMacroInfo(realIdx)
				if n and n ~= "" then out[#out + 1] = { value = tostring(realIdx), text = n } end
			end
			if #out == 0 then out[1] = { value = "", text = "you have no macros yet" } end
			return out
		end)

	-- Multi-line body editor. A tall row with an Arc-skinned scrolling EditBox --
	-- the row engine has no multi-line primitive, so this one is hand-built.
	do
		local row = AddRow(m, 118)
		local lbl = row:CreateFontString(nil, "OVERLAY")
		lbl:SetFont(STANDARD_TEXT_FONT, 11, "")
		lbl:SetPoint("TOPLEFT", 10, -1)
		lbl:SetTextColor(COL.dim[1], COL.dim[2], COL.dim[3])
		lbl:SetText("Macro body  ({interrupt} and {marker} are filled in for you)")
		local well = CreateFrame("Frame", nil, row, "BackdropTemplate")
		well:SetPoint("TOPLEFT", 10, -16)
		well:SetPoint("BOTTOMRIGHT", -12, 4)
		Skin(well, COL.well)
		local sf = CreateFrame("ScrollFrame", nil, well)
		sf:SetPoint("TOPLEFT", 4, -4); sf:SetPoint("BOTTOMRIGHT", -4, 4)
		local eb = CreateFrame("EditBox", nil, sf)
		eb:SetMultiLine(true)
		eb:SetMaxLetters(255)
		eb:SetAutoFocus(false)
		eb:SetFont(STANDARD_TEXT_FONT, 12, "")
		eb:SetTextColor(COL.ink[1], COL.ink[2], COL.ink[3])
		eb:SetWidth(1)      -- widened on layout; a 0/nil width renders nothing
		eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
		eb:SetScript("OnEditFocusGained", function() well:SetBackdropBorderColor(COL.arcDeep[1], COL.arcDeep[2], COL.arcDeep[3], 1) end)
		eb:SetScript("OnEditFocusLost", function() well:SetBackdropBorderColor(COL.line[1], COL.line[2], COL.line[3], 1) end)
		sf:SetScrollChild(eb)
		sf:SetScript("OnSizeChanged", function(_, w) if w and w > 1 then eb:SetWidth(w) end end)
		bodyBox = eb
		-- Re-read the body whenever the page refreshes (slot change, template load),
		-- but never yank text out from under someone mid-edit.
		row._sync = function()
			if not eb:HasFocus() then
				eb:SetText(SlotBody())
				eb:SetCursorPosition(0)
				sf:SetVerticalScroll(0)
			end
			local w = sf:GetWidth() or 0
			if w > 1 then eb:SetWidth(w) end
		end
	end

	RowButton(m, "Add or sync the marker line", function()
		if bodyBox then
			bodyBox:SetText(ManageMarkerInBody(bodyBox:GetText()))
			bodyBox:SetCursorPosition(0)
		end
	end, function() return editorSlot == "kick" or editorSlot == "focus" end)
	RowButton(m, "Save and update macro", SaveSlot)

	-- ===== Ready Check =====
	local r = p._tabs["Ready Check"].page
	Section(r, "When")
	RowToggle(r, "Open picker on ready check",
		function() return DB.showOnReadyCheck end, function(v) DB.showOnReadyCheck = v end)
	RowToggle(r, "Smart open (only on a marker clash)",
		function() return DB.smartOpen end, function(v) DB.smartOpen = v end,
		function() return DB.showOnReadyCheck end)
	RowToggle(r, "Announce on ready check",
		function() return DB.announceOnReadyCheck end, function(v) DB.announceOnReadyCheck = v end)
	Section(r, "Instances")
	for _, key in ipairs(CONTEXT_ORDER) do
		RowToggle(r, CONTEXT_LABELS[key],
			function() return ContextEnabled(key) end,
			function(v) DB.contexts = DB.contexts or {}; DB.contexts[key] = v and true or false end)
	end
	Section(r, "Announce")
	RowInput(r, "Message (%MARKER% = icon)",
		function() return DB.message end, function(v) DB.message = (v ~= "" and v) or DEFAULTS.message end)
	RowButton(r, "Announce to group now", function() Announce() end)

	-- ===== Alerts =====
	local a = p._tabs["Alerts"].page
	Section(a, "Interrupt Alert")
	RowToggle(a, "Alert when focus casts and kick is ready",
		function() return DB.interruptAlert end,
		function(v) DB.interruptAlert = v; SyncInterruptAlert() end,
		nil, "Watches your focus; fires while your interrupt is off cooldown.")
	RowToggle(a, "Speak it (TTS) instead of a sound",
		function() return DB.interruptAlertTTS end, function(v) DB.interruptAlertTTS = v end,
		function() return DB.interruptAlert end)
	RowInput(a, "Spoken phrase",
		function() return DB.interruptAlertText end,
		function(v) DB.interruptAlertText = (v ~= "" and v) or "Kick" end,
		function() return DB.interruptAlert and DB.interruptAlertTTS end)
	RowDropdown(a, "Alert sound",
		function() return DB.interruptAlertSound or "Default" end,
		function(v) DB.interruptAlertSound = v; PlayInterruptSound() end,
		SoundItems,
		function() return DB.interruptAlert and not DB.interruptAlertTTS end)
	RowDropdown(a, "Sound channel",
		function() return DB.interruptAlertChannel or "Master" end,
		function(v) DB.interruptAlertChannel = v end,
		function() return CHANNEL_ITEMS end,
		function() return DB.interruptAlert and not DB.interruptAlertTTS end)
	RowButton(a, "Preview sound", function() PlayInterruptSound() end,
		function() return DB.interruptAlert and not DB.interruptAlertTTS end)

	-- Footer: Arc UI Discord link (always visible under the tab pages).
	local footLine = p:CreateTexture(nil, "ARTWORK"); footLine:SetTexture(WHITE)
	footLine:SetVertexColor(COL.line[1], COL.line[2], COL.line[3], 1)
	footLine:SetPoint("BOTTOMLEFT", 10, 34); footLine:SetPoint("BOTTOMRIGHT", -10, 34); footLine:SetHeight(1)
	local discord = MakeDiscordButton(p); discord:SetPoint("BOTTOMLEFT", 10, 9)
	local dhint = p:CreateFontString(nil, "OVERLAY"); dhint:SetFont(STANDARD_TEXT_FONT, 10, "")
	dhint:SetPoint("LEFT", discord, "RIGHT", 8, 0); dhint:SetTextColor(COL.dim[1], COL.dim[2], COL.dim[3])
	dhint:SetText("Questions or help? Join the Arc UI Discord")

	-- Bottom-right resize grip (drag to resize; size is remembered).
	local grip = CreateFrame("Button", nil, p); grip:SetSize(16, 16); grip:SetPoint("BOTTOMRIGHT", -3, 3)
	grip:SetFrameLevel(p:GetFrameLevel() + 40)
	local gtex = grip:CreateTexture(nil, "OVERLAY"); gtex:SetAllPoints()
	gtex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up"); gtex:SetVertexColor(COL.arc[1], COL.arc[2], COL.arc[3], 0.7)
	grip:SetScript("OnEnter", function() gtex:SetVertexColor(COL.arc[1], COL.arc[2], COL.arc[3], 1) end)
	grip:SetScript("OnLeave", function() gtex:SetVertexColor(COL.arc[1], COL.arc[2], COL.arc[3], 0.7) end)
	grip:SetScript("OnMouseDown", function() CloseDropdown(); p:StartSizing("BOTTOMRIGHT") end)
	grip:SetScript("OnMouseUp", function()
		p:StopMovingOrSizing()
		DB.optW = math.floor(p:GetWidth() + 0.5); DB.optH = math.floor(p:GetHeight() + 0.5)
		if kaActiveTab and p._tabs[kaActiveTab] then p._tabs[kaActiveTab].page:Refresh() end
	end)

	p:Hide()
	return p
end

-- Re-read the active store into the open panel (assigns the forward-declared local).
function RefreshKAOptions()
	if kaWin and kaWin:IsShown() and kaActiveTab and kaWin._tabs[kaActiveTab] then
		kaWin._tabs[kaActiveTab].page:Refresh()
	end
end

function OpenKAOptions(tab)
	BuildKAOptions()
	SelectKATab(tab or kaActiveTab or "General")
	kaWin:Show(); kaWin:Raise()
end

--------------------------------------------------------------------------------
-- Branded (Arc look) marker-picker popup -- the Arc UI version of the main window.
-- Same clean layout (marker grid, drag-to-bar macros, quick toggles) in the Arc theme.
--------------------------------------------------------------------------------

-- Cyan selection border for the marker buttons.
local function ArcMakeSel(parent)
	local b = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	b:SetPoint("TOPLEFT", -2, 2); b:SetPoint("BOTTOMRIGHT", 2, -2)
	b:SetBackdrop({ edgeFile = WHITE, edgeSize = 2 })
	b:SetBackdropBorderColor(COL.arc[1], COL.arc[2], COL.arc[3], 1)
	b:Hide()
	return b
end

function RefreshArcPopup()
	if not arcPopup then return end
	for i = 1, 8 do arcPopup.markerBtns[i].sel:SetShown(DB.marker == i) end
	arcPopup.noneBtn.sel:SetShown(DB.marker == 0)
	arcPopup.showSw:SetOn(DB.showOnReadyCheck)
	arcPopup.smartSw:SetOn(DB.smartOpen)
	arcPopup.announceSw:SetOn(DB.announceOnReadyCheck)
	arcPopup.alertSw:SetOn(DB.interruptAlert)
	if not arcPopup.msg:HasFocus() then arcPopup.msg:SetText(DB.message or DEFAULTS.message) end
	RefreshDragIconsFor(arcPopup)
end

function CreateArcPopup()
	if arcPopup then return arcPopup end
	local f = CreateFrame("Frame", "KickAssistArcFrame", UIParent, "BackdropTemplate")
	f:SetSize(320, 606); f:SetFrameStrata("DIALOG"); f:SetToplevel(true); f:SetClampedToScreen(true)
	f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); local pt,_,rp,x,y = self:GetPoint(); DB.point = { pt, rp, x, y } end)
	Skin(f, COL.bg, COL.line2)
	tinsert(UISpecialFrames, "KickAssistArcFrame")
	arcPopup = f

	local bar = CreateFrame("Frame", nil, f, "BackdropTemplate")
	bar:SetPoint("TOPLEFT", 1, -1); bar:SetPoint("TOPRIGHT", -1, -1); bar:SetHeight(30); Skin(bar, COL.panel)
	local t1 = bar:CreateFontString(nil, "OVERLAY"); t1:SetFont(STANDARD_TEXT_FONT, 14, ""); t1:SetPoint("LEFT", 12, 0)
	t1:SetText("|cff3fc9f2Kick|r|cffd5e2f2 Assist|r")
	local close = MakeCloseBox(bar, function() f:Hide() end); close:SetPoint("RIGHT", -4, 0)

	local instr = f:CreateFontString(nil, "OVERLAY"); instr:SetFont(STANDARD_TEXT_FONT, 11, ""); instr:SetPoint("TOP", 0, -40)
	instr:SetTextColor(COL.dim[1], COL.dim[2], COL.dim[3]); instr:SetText("Pick your kick marker")

	-- Marker grid (4x2) with cyan selection borders.
	f.markerBtns = {}
	for i = 1, 8 do
		local btn = CreateFrame("Button", nil, f); btn:SetSize(40, 40)
		local col = (i - 1) % 4; local row = math.floor((i - 1) / 4)
		btn:SetPoint("TOPLEFT", 62 + col * 50, -60 - row * 50)
		local icon = btn:CreateTexture(nil, "ARTWORK"); icon:SetAllPoints(); SetMarkerTexture(icon, i)
		btn.sel = ArcMakeSel(btn)
		btn:SetScript("OnClick", function() DB.marker = i; RefreshArcPopup(); SyncMacros(); Announce() end)
		btn:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(MARKER_NAMES[i]); GameTooltip:Show() end)
		btn:SetScript("OnLeave", GameTooltip_Hide)
		f.markerBtns[i] = btn
	end
	local none = MakeSmallButton(f, "No Marker", 100); none:SetPoint("TOP", 0, -164)
	none.sel = ArcMakeSel(none)
	none:SetScript("OnClick", function() DB.marker = 0; RefreshArcPopup(); SyncMacros() end)
	f.noneBtn = none

	-- Titled boxed section on the popup (matches the options window's boxed sections).
	local function popSection(titleText, topY, height)
		local t = f:CreateFontString(nil, "OVERLAY"); t:SetFont(STANDARD_TEXT_FONT, 11, "")
		t:SetPoint("TOPLEFT", 20, topY); t:SetTextColor(COL.arc[1], COL.arc[2], COL.arc[3]); t:SetText(titleText)
		local box = CreateFrame("Frame", nil, f, "BackdropTemplate")
		box:SetPoint("TOPLEFT", 16, topY - 16); box:SetPoint("TOPRIGHT", -16, topY - 16); box:SetHeight(height)
		Skin(box, COL.box, COL.line)
		return box
	end
	-- Toggle row inside a section box: label left, switch OR checkbox right (per toggleStyle).
	local function boxToggle(box, relY, label, get, set)
		local lbl = box:CreateFontString(nil, "OVERLAY"); lbl:SetFont(STANDARD_TEXT_FONT, 12, "")
		lbl:SetPoint("TOPLEFT", 10, relY); lbl:SetTextColor(COL.ink[1], COL.ink[2], COL.ink[3]); lbl:SetText(label)
		local sw = MakeSwitch(box); sw:SetPoint("LEFT", lbl, "RIGHT", 14, 0)
		local cb = MakeCheckbox(box); cb:SetPoint("LEFT", lbl, "RIGHT", 14, 0)
		local function refresh()
			local useCheck = (DB.toggleStyle == "checkbox")
			sw:SetShown(not useCheck); cb:SetShown(useCheck)
			sw:SetOn(get()); cb:SetOn(get())
		end
		local function flip()
			set(not get())
			PlaySound(get() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
			refresh()
		end
		sw:SetScript("OnClick", flip); cb:SetScript("OnClick", flip)
		sw:HookScript("OnEnter", function() sw:SetHover(true) end); sw:HookScript("OnLeave", function() sw:SetHover(false) end)
		cb:HookScript("OnEnter", function() cb:SetHover(true) end); cb:HookScript("OnLeave", function() cb:SetHover(false) end)
		refresh()
		return {
			SetOn = function() refresh() end,   -- proxy; RefreshArcPopup calls :SetOn to re-read state
			labelW = lbl:GetStringWidth(),
			alignTo = function(colX)
				sw:ClearAllPoints(); sw:SetPoint("LEFT", lbl, "LEFT", colX - 10, 0)
				cb:ClearAllPoints(); cb:SetPoint("LEFT", lbl, "LEFT", colX - 10, 0)
			end,
		}
	end

	-- Ready Check section (toggles column-aligned past the longest label)
	local rcBox = popSection("Ready Check", -190, 84)
	f.showSw     = boxToggle(rcBox, -6,  "Show on ready check", function() return DB.showOnReadyCheck end, function(v) DB.showOnReadyCheck = v end)
	f.smartSw    = boxToggle(rcBox, -30, "Smart open (marker clash)", function() return DB.smartOpen end, function(v) DB.smartOpen = v end)
	f.announceSw = boxToggle(rcBox, -54, "Announce on ready check", function() return DB.announceOnReadyCheck end, function(v) DB.announceOnReadyCheck = v end)
	local rcCol = math.max(f.showSw.labelW, f.smartSw.labelW, f.announceSw.labelW) + 26
	f.showSw.alignTo(rcCol); f.smartSw.alignTo(rcCol); f.announceSw.alignTo(rcCol)

	local msgLabel = f:CreateFontString(nil, "OVERLAY"); msgLabel:SetFont(STANDARD_TEXT_FONT, 10, ""); msgLabel:SetPoint("TOPLEFT", 22, -302)
	msgLabel:SetTextColor(COL.dim[1], COL.dim[2], COL.dim[3]); msgLabel:SetText("MESSAGE (%MARKER% = ICON)")
	local msg = CreateFrame("EditBox", nil, f, "BackdropTemplate"); msg:SetSize(276, 20); msg:SetPoint("TOPLEFT", 22, -318); Skin(msg, COL.well)
	msg:SetFont(STANDARD_TEXT_FONT, 11, ""); msg:SetTextInsets(6, 6, 0, 0); msg:SetTextColor(COL.ink[1], COL.ink[2], COL.ink[3]); msg:SetAutoFocus(false)
	msg:SetText(DB.message or DEFAULTS.message)
	msg:SetScript("OnEnterPressed", function() DB.message = msg:GetText(); msg:ClearFocus() end)
	msg:SetScript("OnEscapePressed", function() msg:SetText(DB.message or DEFAULTS.message); msg:ClearFocus() end)
	msg:SetScript("OnEditFocusLost", function() DB.message = msg:GetText() end)
	f.msg = msg

	local announce = MakeSmallButton(f, "Announce to Group", 180); announce:SetPoint("TOP", 0, -348)
	announce:SetScript("OnClick", function() DB.message = msg:GetText(); Announce() end)

	local macroBtn = MakeSmallButton(f, "Edit Macro", 132); macroBtn:SetPoint("TOPLEFT", 22, -378)
	-- the Arc window opens the Arc-styled Macros tab; the classic window keeps the
	-- old Blizzard editor, which matches the look you picked
	macroBtn:SetScript("OnClick", function() OpenKAOptions("Macros") end)
	local optBtn = MakeSmallButton(f, "Options", 132); optBtn:SetPoint("TOPRIGHT", -22, -378)
	optBtn:SetScript("OnClick", function() OpenKAOptions() end)

	-- Drag-to-bar macros.
	local dragHeader = f:CreateFontString(nil, "OVERLAY"); dragHeader:SetFont(STANDARD_TEXT_FONT, 10, ""); dragHeader:SetPoint("TOP", 0, -414)
	dragHeader:SetTextColor(COL.dim[1], COL.dim[2], COL.dim[3]); dragHeader:SetText("NEW? DRAG A MACRO TO YOUR BAR")
	f.dragIcons = {}
	local function arcDragBox(xOff, labelText, key, pickup)
		local box = CreateFrame("Button", nil, f, "BackdropTemplate"); box:SetSize(40, 40); box:SetPoint("TOP", xOff, -432)
		box:RegisterForDrag("LeftButton"); box:RegisterForClicks("LeftButtonUp"); Skin(box, COL.well, COL.arcDeep)
		local ic = box:CreateTexture(nil, "ARTWORK"); ic:SetPoint("TOPLEFT", 2, -2); ic:SetPoint("BOTTOMRIGHT", -2, 2)
		box:SetHighlightTexture(WHITE); box:GetHighlightTexture():SetVertexColor(COL.arc[1], COL.arc[2], COL.arc[3], 0.15)
		f.dragIcons[key] = ic
		box:SetScript("OnDragStart", pickup); box:SetScript("OnClick", pickup)
		box:SetScript("OnEnter", function(self)
			box:SetBackdropBorderColor(COL.arc[1], COL.arc[2], COL.arc[3], 1)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(labelText)
			GameTooltip:AddLine("Drag onto an action bar, or click then a bar slot.", 0.6, 0.6, 0.6, true); GameTooltip:Show()
		end)
		box:SetScript("OnLeave", function() box:SetBackdropBorderColor(COL.arcDeep[1], COL.arcDeep[2], COL.arcDeep[3], 1); GameTooltip_Hide() end)
		local lbl = f:CreateFontString(nil, "OVERLAY"); lbl:SetFont(STANDARD_TEXT_FONT, 10, ""); lbl:SetPoint("TOP", box, "BOTTOM", 0, -4)
		lbl:SetTextColor(COL.dim[1], COL.dim[2], COL.dim[3]); lbl:SetText(labelText)
	end
	arcDragBox(-84, "Focus + Kick", "kick", function() DB.macroEnabled = true; KAPickupSlot("macroName", DEFAULTS.macroName, UpdateManagedMacro) end)
	arcDragBox(0, "Set Focus", "focus", function() KAPickupSlot("setFocusName", DEFAULTS.setFocusName, UpdateSetFocusMacro) end)
	arcDragBox(84, "Tab Kick", "autotab", function() KAPickupSlot("autoTabName", DEFAULTS.autoTabName, UpdateAutoTabMacro) end)

	-- Interrupt Alert section
	local iaBox = popSection("Interrupt Alert", -494, 62)
	f.alertSw = boxToggle(iaBox, -6, "Play a sound when your focus casts", function() return DB.interruptAlert end, function(v) DB.interruptAlert = v; SyncInterruptAlert() end)
	f.alertSw.alignTo(f.alertSw.labelW + 26)
	local iaHint = iaBox:CreateFontString(nil, "OVERLAY"); iaHint:SetFont(STANDARD_TEXT_FONT, 10, "")
	iaHint:SetPoint("TOPLEFT", 10, -32); iaHint:SetPoint("TOPRIGHT", -10, -32); iaHint:SetJustifyH("LEFT")
	iaHint:SetTextColor(COL.dim[1], COL.dim[2], COL.dim[3])
	iaHint:SetText("Fires when your focus casts and your kick is ready. Pick the sound in Options.")

	local pnt = DB.point or DEFAULTS.point
	f:ClearAllPoints(); f:SetPoint(pnt[1], UIParent, pnt[2], pnt[3], pnt[4])
	f:Hide()
	return f
end

local function CreateSettingsPanel()
	if settingsCategory then return end
	local panel = CreateFrame("Frame", "KickAssistSettingsPanel")
	panel.name = "Kick Assist"

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("Kick Assist")

	local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	desc:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
	desc:SetJustifyH("LEFT")
	desc:SetText("Pick your interrupt raid marker, announce it to the group, and keep your kick macro's marker in sync.")

	local openBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	openBtn:SetSize(240, 26)
	openBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
	openBtn:SetText("Open Kick Assist Settings")
	openBtn:SetScript("OnClick", function() OpenKAOptions() end)

	local winBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	winBtn:SetSize(240, 26)
	winBtn:SetPoint("TOPLEFT", openBtn, "BOTTOMLEFT", 0, -8)
	winBtn:SetText("Open Kick Assist Window")
	winBtn:SetScript("OnClick", function() ShowUI() end)

	local category = Settings.RegisterCanvasLayoutCategory(panel, "Kick Assist")
	Settings.RegisterAddOnCategory(category)
	settingsCategory = category
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("READY_CHECK")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Smart Open: for a brief window after a ready check, watch party/raid chat; if someone
-- ELSE calls out your marker, open the picker so you can change your focus. Chat text is
-- non-secret, so this stays taint-safe in M+ (unlike reading raid markers off units).
local SMART_OPEN_WINDOW = 4  -- seconds to watch after a ready check
local SMART_CHAT_EVENTS = {
	"CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER", "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
}
local function DisarmSmartOpen()
	smartOpenExpire = 0
	for _, e in ipairs(SMART_CHAT_EVENTS) do ev:UnregisterEvent(e) end
end
local function ArmSmartOpen()
	smartOpenExpire = GetTime() + SMART_OPEN_WINDOW
	for _, e in ipairs(SMART_CHAT_EVENTS) do ev:RegisterEvent(e) end
	C_Timer.After(SMART_OPEN_WINDOW + 0.1, function()
		if GetTime() >= smartOpenExpire then DisarmSmartOpen() end
	end)
end

ev:SetScript("OnEvent", function(_, event, arg1, arg2)
	if event == "ADDON_LOADED" then
		if arg1 ~= ADDON then return end
		KickAssistDB = KickAssistDB or {}
		KickAssistAccountDB = KickAssistAccountDB or {}
		CDB = KickAssistDB
		ADB = KickAssistAccountDB
		FillDefaults(CDB)      -- per-character store always gets defaults
		ResolveActiveDB()      -- DB points at account or per-character store per the saved flag
		CreateMinimapButton()
		CreateSettingsPanel()
		SyncInterruptAlert()
		print(PREFIX .. "loaded. /ka to open.")
	elseif event == "READY_CHECK" then
		-- In an enabled instance type, announce your kick (Announce self-skips once the key
		-- locks chat). Then either open the picker now, or with Smart Open, arm a brief
		-- chat watch and only open if someone else calls your marker.
		if DB and ShouldTriggerHere() then
			if DB.showOnReadyCheck then
				if DB.smartOpen then ArmSmartOpen() else ShowUI(true) end
			end
			if DB.announceOnReadyCheck then Announce(true) end
		end
	elseif event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER"
		or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER"
		or event == "CHAT_MSG_INSTANCE_CHAT" or event == "CHAT_MSG_INSTANCE_CHAT_LEADER" then
		-- Smart Open watch window. arg1 = message text, arg2 = sender. Skip your own echo
		-- (sender matches your cached name), then if another player calls your marker, open.
		if GetTime() > smartOpenExpire then
			DisarmSmartOpen()
		elseif myName and arg2 and not issecretvalue(arg2)
			and arg2:match("^[^-]+") ~= myName and MessageCallsMyMarker(arg1) then
			DisarmSmartOpen()
			ShowUI(true)
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		-- Catch up any macro edits deferred from combat.
		SyncMacros()
	elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
		-- New spec may have a different interrupt; re-sync both macros.
		if arg1 == "player" then
			SyncMacros()
			if macroFrame and macroFrame:IsShown() then macroFrame.note:SetText(MacroNoteText()) end
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		RememberMyName()  -- cache our name out in the world (it is secret inside M+)
		SyncMacros()      -- account-wide macro follows the class you just logged into
	end
end)

--------------------------------------------------------------------------------
-- Slash
--------------------------------------------------------------------------------

SLASH_KICKASSIST1 = "/ka"
SLASH_KICKASSIST2 = "/kickassist"
SlashCmdList["KICKASSIST"] = function(msg)
	msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if msg == "hide" then
		if frame then frame:Hide() end
	elseif msg == "macro" then
		-- follows your look: the Arc Macros tab, or the old editor on the classic look
		if DB.classicLook then KickAssist_ShowMacroEditor() else OpenKAOptions("Macros") end
	elseif msg == "options" or msg == "config" then
		OpenSettings()
	elseif msg == "minimap" then
		DB.minimap.hide = not DB.minimap.hide
		UpdateMinimapShown()
	elseif msg == "" or msg == "show" then
		ShowUI()
	else
		print(PREFIX .. "commands: /ka (open), /ka macro, /ka options, /ka minimap, /ka hide")
	end
end
