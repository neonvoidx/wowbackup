local addon = _G.EnhanceQoL
local CP = addon.Aura.CooldownPanels
local Editor = CP.SpellGroupsEditor
local SG = CP.SpellGroups
local Shared = addon.EntryPicker
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local Picker = Shared:Create("SpellGroups", {
 sourceKinds = { "SPELL", "ITEM", "CDM_AURA" }, idTypes = { "SPELL", "CDM_AURA", "ITEM" },
 categories = {
  {id="ALL",label=L["CooldownPanelPickerAll"]}, {id="SPELLS",label=Shared.GetTypeLabel("SPELL")},
  {id="AURAS",label=Shared.GetTypeLabel("CDM_AURA")}, {id="ITEMS",label=Shared.GetTypeLabel("ITEM")},
  {id="ID",label=L["CooldownPanelPickerByID"]},
 },
})
Editor.AddEntryPicker = Picker
function Picker:GetRowKey(row)
 if row.kind=="CDM_AURA" then return "aura:"..row.value end
 return row.key
end
function Picker:GetTarget(id) return SG:GetGroup(id) end
function Picker:CanEdit() return Editor:IsEditingAllowed() end
function Picker:IsAdded(row)
 local identity = Editor:GetMemberIdentity({type=row.kind,spellID=row.value,itemID=row.value})
 for _, member in ipairs(SG:GetMembers(self.targetId)) do if Editor:GetMemberIdentity(member)==identity then return true end end
 return false
end
function Picker:TryAdd(row)
 if row.kind=="SPELL" then return Editor:AddSpell(self.targetId,row.value,self.beforeKey)
 elseif row.kind=="CDM_AURA" then return Editor:AddAura(self.targetId,row.value,self.beforeKey)
 elseif row.kind=="ITEM" then return Editor:AddItem(self.targetId,row.value,self.beforeKey) end
 return false
end
function Picker:ExtendCatalog(append)
 -- Curated group members remain available even when browsing another class.
 for _, presetID in ipairs(SG.Presets and SG.Presets.order or {}) do
  local preset = SG.Presets.byID[presetID]
  for _, member in ipairs(preset and preset.members or {}) do
   local kind = member.type or "SPELL"
   local id = kind=="ITEM" and member.itemID or member.spellID
   if self.PlainID(id) then
    local tag
    if member.classID then
     if C_CreatureInfo and C_CreatureInfo.GetClassInfo then local info=C_CreatureInfo.GetClassInfo(member.classID);tag=info and info.classFile
     elseif GetClassInfo then local _,classTag=GetClassInfo(member.classID);tag=classTag end
    end
    append({key=(kind=="CDM_AURA" and "cdm-aura:" or kind:lower()..":")..id..(kind=="CDM_AURA" and ":player" or ""),kind=kind,value=id,
     category=kind=="ITEM" and "ITEMS" or kind=="CDM_AURA" and "AURAS" or "SPELLS",classTag=tag,
     name=Editor:GetMemberName(member),icon=Editor:GetMemberIcon(member),description=tostring(id)})
   end
  end
 end
end
function Editor:ShowMemberPicker(groupID,beforeKey)
 Picker.beforeKey = beforeKey
 return Picker:Open(groupID)
end
