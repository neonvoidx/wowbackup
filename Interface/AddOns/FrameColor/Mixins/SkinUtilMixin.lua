local addonName, private = ...
local public = _G[addonName]
-- This mixin adds usefull helper functions to skins.

local SkinUtil = {}
private.mixins["SkinUtil"] = SkinUtil

---Helper to skin default Nine Sliced windows like PortraitFrameTemplate.
---@param frame table
---@param color table
---@param desaturation number
function SkinUtil:SkinNineSliced(frame, color, desaturation)
  for _, texture in pairs({
    frame.NineSlice.TopEdge,
    frame.NineSlice.BottomEdge,
    frame.NineSlice.TopRightCorner,
    frame.NineSlice.TopLeftCorner,
    frame.NineSlice.RightEdge,
    frame.NineSlice.LeftEdge,
    frame.NineSlice.BottomRightCorner,
    frame.NineSlice.BottomLeftCorner,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(color[1], color[2], color[3], color[4])
  end
end

---A typical default UI box.
---@param box table
---@param color table
---@param desaturation number
function SkinUtil:SkinBox(box, color, desaturation)
  for _, key in pairs({
    "Left",
    "Middle",
    "Right",
  }) do
    box[key]:SetDesaturation(desaturation)
    box[key]:SetVertexColor(color[1], color[2], color[3], color[4])
  end
end

function SkinUtil:SkinTabs(frame, color, desaturation)
  if frame.TabSystem then
    for _, tab in pairs({ frame.TabSystem:GetChildren() }) do
      for _, texture in pairs({
        tab.Left,
        tab.Middle,
        tab.Right,
      }) do
        texture:SetDesaturation(desaturation)
        texture:SetVertexColor(color[1], color[2], color[3], color[4])
      end
    end
  else
    for _, texture in pairs({
      frame.Left,
      frame.Middle,
      frame.Right,
    })
    do
      texture:SetDesaturation(desaturation)
      texture:SetVertexColor(color[1], color[2], color[3], color[4])
    end
  end
end

function SkinUtil:SkinScrollBarOf(frame, color, desaturation)
  for _, texture in pairs({
    frame.ScrollBar.Track.Thumb.Begin,
    frame.ScrollBar.Track.Thumb.Middle,
    frame.ScrollBar.Track.Thumb.End,
    frame.ScrollBar.Back.Texture,
    frame.ScrollBar.Forward.Texture,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(color[1], color[2], color[3], color[4])
  end
end

function SkinUtil:SkinBorderOf(frame, color, desaturation)
  local textures

  if type(frame) == "table" then
    if frame.Border then
      textures = {
        frame.Border.TopEdge,
        frame.Border.TopRightCorner,
        frame.Border.RightEdge,
        frame.Border.BottomRightCorner,
        frame.Border.BottomEdge,
        frame.Border.BottomLeftCorner,
        frame.Border.LeftEdge,
        frame.Border.TopLeftCorner,
      }
    elseif frame.BorderTopMiddle then
      textures = {
        frame.BorderTopMiddle,
        frame.BorderTopRight,
        frame.BorderRightMiddle,
        frame.BorderBottomRight,
        frame.BorderBottomMiddle,
        frame.BorderBottomLeft,
        frame.BorderLeftMiddle,
        frame.BorderTopLeft,
        frame.LeftBorder,
        frame.BottomLeftBorder,
        frame.BottomBorder,
        frame.BottomRightBorder,
        frame.RightBorder,
      }
    elseif frame.TopLeftTex then
      textures = {
        frame.TopLeftTex,
        frame.TopTex,
        frame.TopRightTex,
        frame.RightTex,
        frame.BottomRightTex,
        frame.BottomTex,
        frame.BottomLeftTex,
        frame.LeftTex,
      }
    elseif frame.LeftBorder then -- AutoComple e.g does not have top borders.
      textures = {
        frame.TopLeftBorder,
        frame.TopBorder,
        frame.TopRightBorder,
        frame.RightBorder,
        frame.BottomRightBorder,
        frame.BottomBorder,
        frame.BottomLeftBorder,
        frame.LeftBorder,
      }
    else
      textures = {
        frame.TopEdge,
        frame.TopRightCorner,
        frame.RightEdge,
        frame.BottomRightCorner,
        frame.BottomEdge,
        frame.BottomLeftCorner,
        frame.LeftEdge,
        frame.TopLeftCorner,
      }
    end
  else
    textures = {
      _G[frame .. "TopLeftTexture"],
      _G[frame .. "TopTexture"],
      _G[frame .. "TopRightTexture"],
      _G[frame .. "RightTexture"],
      _G[frame .. "BottomRightTexture"],
      _G[frame .. "BottomTexture"],
      _G[frame .. "BottomLeftTexture"],
      _G[frame .. "LeftTexture"],

      _G[frame .. "TopLeftCorner"],
      _G[frame .. "TopBorder"],
      _G[frame .. "TopRightCorner"],
      _G[frame .. "RightBorder"],
      _G[frame .. "BottomRightCorner"],
      _G[frame .. "BottomBorder"],
      _G[frame .. "BottomLeftCorner"],
      _G[frame .. "LeftBorder"],
    }
  end

  for _, texture in pairs(textures) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(color[1], color[2], color[3], color[4])
  end
end

---Get all regions of a frame and its child frames.
---@param frame table the frame to search in.
---@param objectTypes table a table of object types to filter by. If nil, all object types are included.
---@return table table table of regions that match the specified object types.
function SkinUtil:GetAllChildRegionsOf(frame, objectTypes)
  if not frame then
    return {}
  end

  objectTypes = objectTypes or setmetatable({}, {__index = function() return true end }) -- Default to all object types if none are provided.

  -- Helper function to collect direct regions of a frame
  local function collect_all_regions(frame, objectTypes)
    local regions = {}

    -- frame:GetRegions() can return nil if the frame is invalid or has no regions
    local directRegions = { frame:GetRegions() }
    if directRegions then
      for _, region in pairs(directRegions) do
        if type(region) == "table" and region.GetObjectType then
          local objectType = region:GetObjectType()
          if objectTypes[objectType] then
            table.insert(regions, region)
          end
        end
      end
    end

    return regions
  end

  -- Helper function to collect direct child frames of a frame
  local function collect_all_child_frames(frame)
    local childs = {}

    -- frame:GetChildren() can return nil
    local directChildren = { frame:GetChildren() }
    if directChildren then
      for _, child in pairs(directChildren) do
        -- Check if child is not nil and is a Frame object
        if type(child) == "table" and child.IsObjectType and child:IsObjectType("Frame") then
          table.insert(childs, child)
        end
      end
    end

    return childs
  end

  local regions = {} -- Table to store regions.
  local frames_to_process = {} -- Queue for frames to process.

  table.insert(frames_to_process, frame) -- Start with the initial frame.

  local i = 1
  while i <= #frames_to_process do
    local current_frame = frames_to_process[i]
    i = i + 1

    for _, region in pairs(collect_all_regions(current_frame, objectTypes)) do
      table.insert(regions, region)
    end

    for _, grandchild_frame in pairs(collect_all_child_frames(current_frame)) do
      table.insert(frames_to_process, grandchild_frame)
    end
  end

  return regions
end


-- [[ Unit Frames ]] --
local UnitExists = UnitExists
local UnitIsPlayer = UnitIsPlayer
local UnitReaction = UnitReaction

function SkinUtil:GetUnitColor(UnitId)
  -- Check if the unit exists.
  if not UnitExists(UnitId) then
    return {1, 1, 1, 1} -- Fallback if no unit exists.
  end

  local color = {}

  -- Check if the unit is a player.
  if UnitIsPlayer(UnitId) then
    local class = select(2, UnitClass(UnitId))
    color = public.db.global.ClassColors[class]
  else
    local reaction = UnitReaction("player", UnitId)
    color = public.db.global.ReactionColors[reaction] or public.db.global.ReactionColors[5] -- 5 = Friendly.
  end

  return color
end
