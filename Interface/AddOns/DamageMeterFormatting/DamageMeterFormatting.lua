-- DamageMeterFormatFix
-- Purpose:
--   - SessionWindow: show "Total (Per Second)" (e.g. Damage Done (DPS))
-- This is a UI hook; Blizzard does NOT provide an official API to change the display format.

local ADDON_TO_HOOK = "Blizzard_DamageMeter";

local hooked = false;
local DEBUG = false;

local function Print(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffd200DamageMeterFormatFix:|r " .. tostring(msg));
	end
end

local function AbbrevNumberOrZero(v)
	if v == nil then
		return nil;
	end

	-- AbbreviateLargeNumbers is a Blizzard global utility used by the default Damage Meter UI.
	local ok, text = pcall(AbbreviateLargeNumbers, v);
	if not ok then
		return nil;
	end
	return text;
end

local function ShouldOverrideValueText(entry)
	-- Only override when both fields exist (Blizzard doesn't display both).
	return entry ~= nil and entry.value ~= nil and entry.valuePerSecond ~= nil and type(entry.GetValue) == "function";
end

local function FindOwningSourceWindow(entry)
	-- Source page (spell breakdown) entries live under a SourceWindow container.
	-- We only need to detect it so we can avoid overriding Blizzard's own formatting on that page.
	local parent = entry and entry.GetParent and entry:GetParent() or nil;
	local maxHops = 20;
	while parent and maxHops > 0 do
		-- DamageMeterSourceWindowMixin-like shape.
		if type(parent.GetSourceGUID) == "function" and type(parent.GetScrollBox) == "function" then
			return parent;
		end

		parent = parent.GetParent and parent:GetParent() or nil;
		maxHops = maxHops - 1;
	end

	return nil;
end

local function IsSourcePageEntry(entry)
	-- Fast-path: spell entries always belong to the source (breakdown) page.
	if entry and (entry.spellID ~= nil or type(entry.GetSpellID) == "function") then
		return true;
	end

	return FindOwningSourceWindow(entry) ~= nil;
end

local function ApplyTotalPerSecondValueText(entry)
	if not entry or not entry.GetValue then
		if DEBUG then
			Print("no entry or no GetValue");
		end
		return;
	end

	if not ShouldOverrideValueText(entry) then
		return;
	end

	-- Do NOT touch the source page; Blizzard already formats it (including skill %).
	if IsSourcePageEntry(entry) then
		return;
	end

	local totalText = AbbrevNumberOrZero(entry.value);
	local perSecondText = AbbrevNumberOrZero(entry.valuePerSecond);
	if not totalText or not perSecondText then
		return;
	end

	-- Format: Total (PerSecond)
	-- Example: 1.2M (54.3K)
	entry:GetValue():SetText(string.format("%s (%s)", totalText, perSecondText));
end

local function ApplyValueText(entry)
	ApplyTotalPerSecondValueText(entry);
end

local function TryHookDamageMeter()
	if not DamageMeterEntryMixin or type(DamageMeterEntryMixin) ~= "table" then
		return;
	end

	if type(DamageMeterEntryMixin.UpdateValue) ~= "function" then
		return;
	end

	if hooked then
		return;
	end

	-- hooksecurefunc runs after the original function; we then overwrite the value text.
	-- Note: hooksecurefunc only supports:
	--   hooksecurefunc([table,] "function", hookfunc)
	hooksecurefunc(DamageMeterEntryMixin, "UpdateValue", function(entry)
		-- Never allow secret-value access to break the UI; if something errors, just keep Blizzard's original text.
		local ok, err = pcall(ApplyValueText, entry);
		if not ok and DEBUG then
			Print(err);
		end
	end);

	hooked = true;
	if DEBUG then
		Print("hooked DamageMeterEntryMixin.UpdateValue()");
	end
end

local function ApplyToVisibleDamageMeterEntries()
	-- IMPORTANT: Avoid calling SessionWindow:Refresh() from addon code.
	-- Refresh triggers BuildDataProvider() which compares secret GUID values and can error when called from addon context.
	if not DamageMeter or type(DamageMeter.ForEachSessionWindow) ~= "function" then
		return;
	end

	local function SafeApply(entry)
		local ok = pcall(ApplyValueText, entry);
		return ok;
	end

	DamageMeter:ForEachSessionWindow(function(sessionWindow)
		if not sessionWindow then
			return;
		end

		-- Entries in the scroll box.
		if type(sessionWindow.EnumerateEntryFrames) == "function" then
			for _index, entry in sessionWindow:EnumerateEntryFrames() do
				SafeApply(entry);
			end
		end

		-- Local player entry is outside the scroll box.
		if type(sessionWindow.GetLocalPlayerEntry) == "function" then
			local localEntry = sessionWindow:GetLocalPlayerEntry();
			SafeApply(localEntry);
		end
	end);
end

SLASH_DMFF1 = "/dmff";
SlashCmdList.DMFF = function(msg)
	msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "");

	if msg == "debug" then
		DEBUG = not DEBUG;
		Print("debug=" .. tostring(DEBUG));
		if IsAddOnLoaded and IsAddOnLoaded(ADDON_TO_HOOK) then
			TryHookDamageMeter();
		end
		return;
	end

	if msg == "hook" then
		TryHookDamageMeter();
		Print("hooked=" .. tostring(hooked));
		return;
	end

	Print("hooked=" .. tostring(hooked) .. "  (commands: /dmff hook, /dmff debug)");
end

local f = CreateFrame("Frame");
f:RegisterEvent("ADDON_LOADED");
f:RegisterEvent("PLAYER_LOGIN");
f:RegisterEvent("PLAYER_REGEN_ENABLED");
f:RegisterEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED");
f:RegisterEvent("DAMAGE_METER_CURRENT_SESSION_UPDATED");
f:RegisterEvent("DAMAGE_METER_RESET");
f:SetScript("OnEvent", function(self, event, addonName)
	if event == "ADDON_LOADED" then
		-- Try on every addon load; once Blizzard_DamageMeter is loaded the mixins will exist.
		TryHookDamageMeter();
	elseif event == "PLAYER_LOGIN" then
		-- If Blizzard_DamageMeter is already loaded by the time we log in, hook immediately.
		if IsAddOnLoaded and IsAddOnLoaded(ADDON_TO_HOOK) then
			TryHookDamageMeter();
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		-- Leaving combat: re-apply formatting to anything currently visible.
		if hooked then
			ApplyToVisibleDamageMeterEntries();
		end
	elseif event == "DAMAGE_METER_COMBAT_SESSION_UPDATED" or event == "DAMAGE_METER_CURRENT_SESSION_UPDATED" or event == "DAMAGE_METER_RESET" then
		-- Keep text updated without forcing a Refresh from addon code.
		if hooked then
			ApplyToVisibleDamageMeterEntries();
		end
	end
end);


