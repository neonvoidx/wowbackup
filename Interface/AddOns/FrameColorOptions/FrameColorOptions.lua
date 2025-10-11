-- The Module List Loader.
local _, private = ...

local L = FrameColor.API:GetLocale()
local ACD = LibStub("AceConfigDialog-3.0")
local AC = LibStub("AceConfig-3.0")

local profilesOptions = {
  name = "",
  type = "group",
  childGroups = "tab",
  args = {
    ImportExportPofile = {
      order = 2,
      name = L["share_profile_title"],
      type = "group",
      args = {
        Header = {
          order = 1,
          name = L["share_profile_header"],
          type = "header",
        },
        Desc = {
          order = 2,
          name = L["share_profile_desc_row1"] .. "\n" .. L["share_profile_desc_row2"],
          fontSize = "medium",
          type = "description",
        },
        Textfield = {
          order = 3,
          name = L["share_profile_input_name"],
          desc = L["share_profile_input_desc"],
          type = "input",
          multiline = 20,
          width = "full",
          confirm = function()
            return L["share_profile_input_desc"]
          end,
          get = function()
            return private:GetSerializedProfile()
          end,
          set = function(self, input)
            private:ImportProfile(input)
            ReloadUI()
          end,
        },
      },
    },
    Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(FrameColor.db)
  },
}

profilesOptions.args.Profiles.order = 1

AC:RegisterOptionsTable("FrameColor_Profiles", profilesOptions)

local rightInsetFrame = private:GetRightInsetFrame()

local function clearAceFrame()
  rightInsetFrame.aceScrollBox.frame:Hide() -- Hide the AceGUI frame.
  rightInsetFrame.aceScrollBox:ReleaseChildren() -- Release all children.
  rightInsetFrame.scrollBox:Show() -- Show the default frame again.
end

local content = {
  [1] = {
    order = 1,
    name = L["unit_frames"],
    showSearchBox = true,
    callback = function ()
      local moduleList = FrameColor:GetAllSkinsOfCategory("UnitFrames")
      private:PopulateRightInset_ModuleList(moduleList)
      clearAceFrame()
    end,
  },
  [2] = {
    order = 2,
    name = L["hud"],
    showSearchBox = true,
    callback = function ()
      local moduleList = FrameColor:GetAllSkinsOfCategory("HUD")
      private:PopulateRightInset_ModuleList(moduleList)
      clearAceFrame()
    end,
  },
  [3] = {
    order = 3,
    name = L["micro_menu"],
    showSearchBox = true,
    callback = function ()
      local moduleList = FrameColor:GetAllSkinsOfCategory("MicroMenu")
      private:PopulateRightInset_ModuleList(moduleList)
      clearAceFrame()
    end,
  },
  [4] = {
    order = 4,
    name = L["action_bars"],
    showSearchBox = true,
    callback = function()
      local moduleList = FrameColor:GetAllSkinsOfCategory("ActionBars")
      private:PopulateRightInset_ModuleList(moduleList)
      clearAceFrame()
    end,
  },
  [5] = {
    order = 5,
    name = L["windows"],
    showSearchBox = true,
    callback = function()
      local moduleList = FrameColor:GetAllSkinsOfCategory("Windows")
      private:PopulateRightInset_ModuleList(moduleList)
      clearAceFrame()
    end,
  },
  [6] = {
    order = 6,
    name = L["addon_skins"],
    showSearchBox = true,
    callback = function()
      local moduleList = FrameColor:GetAllSkinsOfCategory("AddonSkins")
      private:PopulateRightInset_ModuleList(moduleList)
      clearAceFrame()
    end,
  },
  [7] = {
    order = 7,
    name =  L["color_manager"],
    callback = function()
      private:PopulateRightInset_ColorManager()
      clearAceFrame()
    end,
  },
  [8] = {
    order = 8,
    name = L["profiles"],
    showSearchBox = false,
    callback = function()
      ACD:Open("FrameColor_Profiles", rightInsetFrame.aceScrollBox)
      rightInsetFrame.scrollBox:Hide()
      rightInsetFrame.aceScrollBox.frame:Show()
    end,
  }
}

private:PopulateLeftInset(content)


