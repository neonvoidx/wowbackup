local _, addon = ...
if not (addon.variables and (addon.variables.isForever or addon.variables.isTBC)) then return end

local M = { ranks = {} }
addon.AutoRankUp = M
for _, family in pairs(addon.SpellRankFamilies or {}) do
 for rank, id in ipairs(family) do M.ranks[id] = { family = family, rank = rank } end
end

function M.IsID(id)
 return not (issecretvalue and issecretvalue(id)) and type(id) == "number" and id > 0 and id < math.huge and id % 1 == 0
end

function M:IsIgnored(id)
 local ignored = addon.db and addon.db.autoRankUpIgnored
 return type(ignored) == "table" and (ignored[id] == true or ignored[tostring(id)] == true)
end

function M:AddIgnore(value)
 local id = tonumber(value)
 if not self.IsID(id) or not self.ranks[id] or not addon.db then return false end
 addon.db.autoRankUpIgnored = addon.db.autoRankUpIgnored or {}
 addon.db.autoRankUpIgnored[id] = true
 return true
end

function M:RemoveIgnore(id)
 local ignored = addon.db and addon.db.autoRankUpIgnored
 if ignored then ignored[id], ignored[tostring(id)] = nil, nil end
 self:RequestUpdate()
end

function M:GetIgnoredIDs()
 local result, seen = {}, {}
 for key, enabled in pairs(addon.db and addon.db.autoRankUpIgnored or {}) do
  local id = tonumber(key)
  if enabled == true and self.IsID(id) and not seen[id] then result[#result + 1], seen[id] = id, true end
 end
 table.sort(result)
 return result
end

function M:GetCursorSpellID()
 local kind, _, _, id = GetCursorInfo()
 if kind == "spell" and self.IsID(id) then return id end
end

function M:UpgradeSlot(slot, oldID, newID)
 if InCombatLockdown() or GetCursorInfo() then return false end
 local kind, id = GetActionInfo(slot)
 if kind ~= "spell" or not self.IsID(id) or id ~= oldID or self:IsIgnored(id) then return false end
 C_Spell.PickupSpell(newID)
 if self:GetCursorSpellID() ~= newID then
  ClearCursor()
  return false
 end
 local ok, err = pcall(PlaceAction, slot)
 ClearCursor()
 if not ok then error(err) end
 return true
end

function M:SetRetryEvents(inCombat, cursorBusy)
 self.pending = (inCombat or cursorBusy) and true or nil
 if inCombat then self.events:RegisterEvent("PLAYER_REGEN_ENABLED") else self.events:UnregisterEvent("PLAYER_REGEN_ENABLED") end
 if cursorBusy then self.events:RegisterEvent("CURSOR_CHANGED") else self.events:UnregisterEvent("CURSOR_CHANGED") end
end

function M:Run()
 self.queued = nil
 if not addon.db or addon.db.autoRankUpEnabled ~= true then self:SetRetryEvents(false, false); return end
 local inCombat = InCombatLockdown()
 local cursorBusy = not inCombat and GetCursorInfo() ~= nil
 self:SetRetryEvents(inCombat, cursorBusy)
 if self.pending then return end
 self.running = true
 local ok, err = pcall(function()
  for _, family in pairs(addon.SpellRankFamilies or {}) do
   local highest
   for rank = #family, 1, -1 do
    if C_SpellBook.IsSpellKnown(family[rank], Enum.SpellBookSpellBank.Player) then highest = rank; break end
   end
   if highest then
    for rank = 1, highest - 1 do
     local id = family[rank]
     if not self:IsIgnored(id) then
      for _, slot in ipairs(C_ActionBar.FindSpellActionButtons(id) or {}) do self:UpgradeSlot(slot, id, family[highest]) end
     end
    end
   end
  end
 end)
 self.running = nil
 if not ok then geterrorhandler()(err) end
end

function M:RequestUpdate()
 if not addon.db or addon.db.autoRankUpEnabled ~= true then self:SetRetryEvents(false, false); return end
 if self.running or self.queued then return end
 self.queued = true
 C_Timer.After(0, function() M:Run() end)
end

M.events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "LEARNED_SPELL_IN_SKILL_LINE" }) do M.events:RegisterEvent(event) end
M.events:SetScript("OnEvent", function(_, event, spellID)
 if event == "LEARNED_SPELL_IN_SKILL_LINE" and (not M.IsID(spellID) or not M.ranks[spellID]) then return end
 if event == "CURSOR_CHANGED" and (not M.pending or GetCursorInfo()) then return end
 M:RequestUpdate()
end)
