local _, private = ...

-- Specify the options.
local options = {
  name = "_AceGUI-3.0",
  displayedName = "",
  order = 1,
  category = "AddonSkins",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["background"] = {
      order = 2,
      name = "",
      rgbaValues = private.colors.default.background,
    },
    ["borders"] = {
      order = 3,
      name = "",
      rgbaValues = private.colors.default.borders,
    },
    ["controls"] = {
      order = 4,
      name = "",
      rgbaValues = private.colors.default.controls,
    },
    ["tabs"] = {
      order = 5,
      name = "",
      rgbaValues = private.colors.default.tabs,
    },
  },
}

-- Register the Skin
local skin = {}

local origRegisterAsContainer
local origRegisterAsWidget
local origCreateTab_FromTabGroupContainer

function skin:OnEnable()
  if not origRegisterAsContainer or not origRegisterAsWidget then
    -- Silent to not rise an error if no addon uses AceGUI.
    local lib = LibStub("AceGUI-3.0", true)

    if not lib then
      return
    end

    -- Store the original functions.
    origRegisterAsContainer = lib.RegisterAsContainer
    origRegisterAsWidget = lib.RegisterAsWidget
  end

  self:Apply()
end

function skin:OnDisable()
  local lib = LibStub("AceGUI-3.0", true)

  if not lib then
    return
  end

  if origRegisterAsContainer then
    lib.RegisterAsContainer = origRegisterAsContainer
  end

  if origRegisterAsWidget then
    lib.RegisterAsWidget = origRegisterAsWidget
  end
end

function skin:Apply()
  local lib = LibStub("AceGUI-3.0", true)

  if not lib then
    return
  end

  local mainColor = self:GetColor("main")
  local backgroundColor = self:GetColor("background")
  local bordersColor = self:GetColor("borders")
  local controlsColor = self:GetColor("controls")
  local tabsColor = self:GetColor("tabs")

  -- Metatable for missing keys.
  local missingKeyMeta = {
    __index = function()
      return function() end -- No-op function for missing keys.
    end
  }

  -- Container callbacks.
  local containerCallbacks = {
    ["Frame"] = function(container)
      --container.frame:SetBackdropBorderColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
      container.statustext:GetParent():SetBackdropBorderColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])

      for _, v in pairs ({ container.frame:GetRegions() }) do
        if v:IsObjectType("Texture") then
          v:SetDesaturation(1)
          v:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
        end
      end
    end,

    ["TabGroup"] = function(container)
      container.border:SetBackdropBorderColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])

      if not origCreateTab_FromTabGroupContainer then
        origCreateTab_FromTabGroupContainer = container.CreateTab
      end

      container.CreateTab = function(self, id)
        local tab = origCreateTab_FromTabGroupContainer(self, id)

        for _, region in pairs ({
          "Left",
          "Middle",
          "Right",
          "LeftDisabled",
          "MiddleDisabled",
          "RightDisabled",
        }) do
          tab[region]:SetDesaturation(1)
          tab[region]:SetVertexColor(tabsColor[1], tabsColor[2], tabsColor[3], tabsColor[4])
        end

        return tab
      end
    end,

    ["TreeGroup"] = function(container)
      container.treeframe:SetBackdropBorderColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
      container.border:SetBackdropBorderColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
    end,

    ["InlineGroup"] = function(container)
      container.content:GetParent():SetBackdropBorderColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
    end,
  }

  setmetatable(containerCallbacks, missingKeyMeta)

  -- Hook the RegisterAsContainer
  lib.RegisterAsContainer = function(self, container)
    containerCallbacks[container.type](container)
    return origRegisterAsContainer(self, container)
  end

  -- Widget callbacks.
  local widgetCallbacks = {
    ["Dropdown"] = function(widget)
      for _, region in pairs ({
        "Left",
        "Middle",
        "Right"
      }) do
        widget.dropdown[region]:SetDesaturation(1)
        widget.dropdown[region]:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
      end
    end,

    ["Dropdown-Pullout"] = function(widget)
      widget.frame:SetBackdropBorderColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
    end,

    ["Slider"] = function(widget)
      widget.slider:SetBackdropBorderColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
    end,

    ["EditBox"] = function(widget)
      for _, region in pairs ({
        "Left",
        "Middle",
        "Right"
      }) do
        widget.editbox[region]:SetDesaturation(1)
        widget.editbox[region]:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
      end
    end,

    ["MultiLineEditBox"] = function(widget)
      widget.scrollBG:SetBackdropBorderColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
    end,

    ["Heading"] = function(widget)
      widget.left:SetDesaturation(1)
      widget.left:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
      widget.right:SetDesaturation(1)
      widget.right:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
    end,

    ["LSM30_Font"] = function(widget)
      for _, region in pairs ({
        "DLeft",
        "DMiddle",
        "DRight"
      }) do
        widget.frame[region]:SetDesaturation(1)
        widget.frame[region]:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
      end
    end,

    ["LSM30_Statusbar"] = function(widget)
      for _, region in pairs ({
        "DLeft",
        "DMiddle",
        "DRight"
      }) do
        widget.frame[region]:SetDesaturation(1)
        widget.frame[region]:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
      end
    end,

    ["LSM30_Border"] = function(widget)
      for _, region in pairs ({
        "DLeft",
        "DMiddle",
        "DRight"
      }) do
        widget.frame[region]:SetDesaturation(1)
        widget.frame[region]:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
      end
    end,

    ["LSM30_Background"] = function(widget)
      for _, region in pairs ({
        "DLeft",
        "DMiddle",
        "DRight"
      }) do
        widget.frame[region]:SetDesaturation(1)
        widget.frame[region]:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
      end
    end,

    ["SFX-Header"] = function(widget)
      widget.Left:SetDesaturation(1)
      widget.Left:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
      widget.Right:SetDesaturation(1)
      widget.Right:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
    end,

    ["SFX-Header-II"] = function(widget)
      widget.Border:SetDesaturation(1)
      widget.Border:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
    end,
  }

  setmetatable(widgetCallbacks, missingKeyMeta)

  -- Hook RegisterAsWidget
  lib.RegisterAsWidget = function(self, widget)
    widgetCallbacks[widget.type](widget)
    return origRegisterAsWidget(self, widget)
  end

  -- Update the pool
  -- @TODO improve.
  --[[
  local objPools = lib.objPools
  for _, callbackTable in pairs({
    containerCallbacks,
    widgetCallbacks
  }) do
    for type, _ in pairs(callbackTable) do
      local widgetPool = objPools[type] or {}
      for widget, _ in pairs(widgetPool) do
        callbackTable[type](widget)
      end
    end
  end
  --]]

  -- Skin the dropdown menu of AceGUISharedMediaWidgets
  local lib_AGSMW = LibStub("AceGUISharedMediaWidgets-1.0", true)
  if lib_AGSMW then
    local frame = lib_AGSMW:GetDropDownFrame()
    frame:SetBackdropBorderColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
    lib_AGSMW:ReturnDropDownFrame(frame)
  end
end

-- Register the Skin
FrameColor.API:RegisterSkin(skin, options)
