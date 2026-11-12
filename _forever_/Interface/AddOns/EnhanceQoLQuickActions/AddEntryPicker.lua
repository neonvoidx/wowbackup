local addon = _G.EnhanceQoL
local QC = addon.QuickCast
local Editor = QC.Editor
local M = Editor.PickerAPI
local Shared = addon.EntryPicker
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local Picker = Shared:Create("QuickActions", {
 sourceKinds = {"SPELL","ITEM","MACRO"}, idTypes = {"SPELL","ITEM"},
 categories = {
  {id="ALL",label=L["CooldownPanelPickerAll"]}, {id="SPELLS",label=Shared.GetTypeLabel("SPELL")},
  {id="ITEMS",label=Shared.GetTypeLabel("ITEM")}, {id="MACROS",label=L["Macros"]},
  {id="MICRO",label=L["QuickCastMicroMenu"]}, {id="MENUS",label=L["QuickCastNestedMenu"]},
  {id="OUTFITS",label=L["QuickCastOutfits"]}, {id="PROFESSIONS",label=L["Professions"]},
  {id="SPECIAL",label=L["CooldownPanelPickerSpecial"]}, {id="ID",label=L["CooldownPanelPickerByID"]},
 },
})
Editor.AddEntryPicker = Picker
function Picker:GetTarget(id) return M.getMenu(id) end
function Picker:CanEdit() return M.isEditingAllowed() end
function Picker:SameAction(left, right)
 if not left or not right or left.kind ~= right.kind then return false end
 if left.kind=="macro" then
  if left.indexHint and right.indexHint then return left.indexHint==right.indexHint end
  return left.name==right.name
 end
 return left.id==right.id
end
function Picker:IsAdded(row)
 if row.kind=="SPELL" and row.overrides and row.overrides.trackPassiveSpell then return true end
 local menu = self:GetTarget(self.targetId)
 if not menu then return true end
 if row.managedSource then return menu.managedSources and menu.managedSources[row.managedSource]==true or false end
 if row.professionBatch then
  for _, profession in ipairs(row.professionBatch) do
   local found=false
   for _,action in ipairs(menu.actions or {}) do if action.kind=="spell" and action.id==profession.spellID then found=true;break end end
   if not found then return false end
  end
  return true
 end
 if row.markerKind then
  local existing={}
  for _, action in ipairs(menu.actions or {}) do if action.kind==row.markerKind then existing[action.id]=true end end
  for id=(row.markerKind=="worldmarker" and 0 or 1),8 do if not existing[id] then return false end end
  return true
 end
 if row.action then
  for _,action in ipairs(menu.actions or {}) do if self:SameAction(action,row.action) then return true end end
 elseif row.kind=="MACRO" then
  for _, action in ipairs(menu.actions or {}) do
   if action.kind=="macro" and (tonumber(action.indexHint)==row.value or not action.indexHint and action.name==row.name) then return true end
  end
 elseif row.kind=="SPELL" or row.kind=="ITEM" then
  local action = row.kind=="SPELL" and M.resolveSpellAction(row.value) or {kind="item",id=row.value}
  if action then
   for _, current in ipairs(menu.actions or {}) do if self:SameAction(current,action) then return true end end
  end
 end
 return false
end
function Picker:GetButtonText(row)
 return row.managedSource and self:IsAdded(row) and _G.REMOVE or (_G.ADD or _G.OKAY)
end
function Picker:TryAdd(row)
 if row.cursorAction then
  if not self:SameAction(M.resolveCursorAction(),row.action) then self:InvalidateCatalog();return false end
  return M.acceptCursorAction(self.targetId)
 end
 if row.kind=="SPELL" or row.kind=="ITEM" then return M.addActionByID(self.targetId,row.kind:lower(),row.value) end
 if row.add then return row.add(self.targetId) end
 if row.managedSource then return M.setManagedSource(self.targetId,row.managedSource,not self:IsAdded(row)) end
 local action = row.action
 if row.kind=="MACRO" then action={kind="macro",name=row.name,indexHint=row.value} end
 if not action or not QC:SetAction(self.targetId,nil,action) then return false end
 Editor.state.selectedMenuID=self.targetId
 M.refreshRuntime(false,self.targetId)
 return true
end
function Picker:ExtendCatalog(append)
 local function actionRow(key,category,action,name,icon,atlas)
  append({key=key,kind="ACTION",value=key,category=category,name=name or M.getActionName(action),
   icon=icon or select(2,M.getActionName(action)),atlas=atlas or select(4,M.getActionName(action)),action=action,description=M.getActionIdentity(action)})
 end
 local cursor = M.resolveCursorAction()
 if cursor then
  append({key="cursor",kind="ACTION",value="cursor",category="ALL",name=M.getActionName(cursor),icon=select(2,M.getActionName(cursor)),
   action=cursor,cursorAction=true,description=M.getActionIdentity(cursor)})
 end
 if QC.MicroMenu then
  for _,id in ipairs(QC.MicroMenu.order) do
   local name,icon,_,_,atlas=QC.MicroMenu:GetInfo(id)
   local available,reason=QC.MicroMenu:GetAvailability(id)
   append({key="micro:"..id,kind="ACTION",value=id,category="MICRO",name=name,icon=icon,atlas=atlas,
    action={kind="microMenu",id=id},tooltipDescription=not available and reason or nil,description=L["QuickCastMicroMenu"]})
  end
 end
 local config = QC:GetConfig()
 for _,id in ipairs(config.order or {}) do
  local menu=config.menus[id]
  if menu and menu.enabled~=false and not QC:WouldCreateMenuCycle(self.targetId,id) then
   actionRow("menu:"..id,"MENUS",{kind="menu",id=id},menu.name)
  end
 end
 for _,outfit in ipairs(M.getOutfitActions()) do
  local id=outfit.id
  append({key="outfit:"..id,kind="ACTION",value=id,category="OUTFITS",name=outfit.name,
   action=M.resolveOutfitAction(id),description=L["QuickCastOutfits"],add=function(target) return M.addOutfitAction(target,id) end})
 end
 local professions=M.getProfessionActions()
 if #professions>1 then
  append({key="professions:all",kind="ACTION",value="professions:all",category="PROFESSIONS",name=L["Professions"].." ("..(_G.ALL or L["CooldownPanelPickerAll"])..")",
   professionBatch=professions,add=function(target) return M.addProfessionActions(target,professions) end})
 end
 for _,sourceProfession in ipairs(professions) do
  local profession=sourceProfession
  append({key="spell:"..tostring(profession.spellID),kind="ACTION",value=profession.spellID,category="PROFESSIONS",name=profession.name,
   icon=select(2,M.getActionName({kind="spell",id=profession.spellID})),action={kind="spell",id=profession.spellID},description=L["Professions"],add=function(target) return M.addProfessionActions(target,{profession}) end})
 end
 for _,kind in ipairs({"worldmarker","raidtarget"}) do
  local markerKind=kind
  append({key="markers:"..kind,kind="ACTION",value=kind,category="SPECIAL",name=kind=="worldmarker" and L["WorldMarkers"] or L["RaidTargetIcon"],
   icon="Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",markerKind=kind,add=function(target) return M.addMarkerPreset(target,markerKind) end})
 end
 for _,id in ipairs({"auctionMount","hearthstone","randomMount","repairMount"}) do
  if QC.EQOL_ACTIONS[id] then
   local actionID=id
   local action={kind="eqol",id=id}
   append({key="eqol:"..id,kind="ACTION",value=id,category="SPECIAL",name=M.getEQOLActionName(id),icon=select(2,M.getActionName(action)),atlas=select(4,M.getActionName(action)),action=action,
    description=L["QuickCastEnhanceQoLActions"],add=function(target) return M.addEQOLAction(target,actionID) end})
  end
 end
 append({key="managed:"..QC.MANAGED_SOURCE_QUEST_ITEMS,kind="ACTION",value=QC.MANAGED_SOURCE_QUEST_ITEMS,category="SPECIAL",
  name=L["QuickCastQuestItems"],icon="Interface\\Icons\\INV_Misc_Bag_10",managedSource=QC.MANAGED_SOURCE_QUEST_ITEMS,keepVisible=true,
  description=L["QuickCastQuestItemsDescription"]})
 local teleportFunctions=addon.MythicPlus and addon.MythicPlus.functions
 if teleportFunctions and teleportFunctions.BuildCurrentSeasonTeleportSection then
  for _,source in ipairs({{QC.MANAGED_SOURCE_CURRENT_SEASON,"QuickCastCurrentSeasonMythicPlus"},{QC.MANAGED_SOURCE_TELEPORT_FAVORITES,"QuickCastTeleportFavorites"}}) do
   if source[1] and (source[2]~="QuickCastTeleportFavorites" or teleportFunctions.BuildTeleportCompendiumSections) then
    append({key="managed:"..source[1],kind="ACTION",value=source[1],category="SPECIAL",name=L[source[2]],managedSource=source[1],keepVisible=true,description=L["Teleports"]})
   end
  end
 end
end
