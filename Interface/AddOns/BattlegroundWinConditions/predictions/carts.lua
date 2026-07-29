local _, NS = ...

local CreateFrame = CreateFrame
local pairs = pairs

local GetDoubleStateIconRowVisualizationInfo = C_UIWidgetManager.GetDoubleStateIconRowVisualizationInfo
local GetCaptureBarWidgetVisualizationInfo = C_UIWidgetManager.GetCaptureBarWidgetVisualizationInfo

local CartPrediction = {}
NS.CartPrediction = CartPrediction

local CartFrame = CreateFrame("Frame", "CartFrame")
CartFrame:SetScript("OnEvent", function(_, event, ...)
  if CartPrediction[event] then
    CartPrediction[event](CartPrediction, ...)
  end
end)

do
  local allyCarts, hordeCarts = 0, 0
  local curMap = {
    id = 0,
    maxCarts = 0,
    tickRate = 0,
    cartResources = {},
    cartTimers = {},
  }

  function CartPrediction:CaptureBarTracker(widgetID)
    -- widgetType == 1
    -- 521 -- all bases random eots
    -- 732 -- lava cart
    -- 794 -- top cart
    -- 795 -- mid cart
    if widgetID == 521 or widgetID == 723 or widgetID == 794 or widgetID == 795 then
      local captureInfo = GetCaptureBarWidgetVisualizationInfo(widgetID)

      if not captureInfo or not captureInfo.barMaxValue then
        return
      end

      -- local barMinValue = captureInfo.barMinValue -- 100 (friendly)
      -- local barMaxValue = captureInfo.barMaxValue -- 0 (enemy)
      local barValue = captureInfo.barValue -- (starts at 50)
      local isVisible = captureInfo.shownState -- 1 (shown) or 0 (not)
      local neutralZoneCenter = captureInfo.neutralZoneCenter -- 50
      local neutralZoneSize = captureInfo.neutralZoneSize -- 40/4 (40 on random eots/4 on carts)
      -- so that means your team wins with 71+ (50+(40/2))=70
      -- 50 being middle and 40 point buffer (20 each side)
      -- 100 being fully controlled, 0 being enemy controlled
      -- so positive progression = taking it, negative = losing it
      NS.Debug("barValue", widgetID, barValue, isVisible == 1, neutralZoneCenter, neutralZoneSize)
    end
  end

  do
    function CartPrediction:GetObjectivesByMapID(mapID)
      -- mapID == Zone ID in-game
      -- SSM = 423
      if mapID == 423 then
        -- Silvershard Mines
        allyCarts, hordeCarts = 0, 0

        local baseInfo = GetDoubleStateIconRowVisualizationInfo(1700)

        if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
          return
        end

        for _, v in pairs(baseInfo.leftIcons) do
          if v.iconState == Enum.IconState.ShowState1 then
            allyCarts = allyCarts + 1
          end
        end
        for _, v in pairs(baseInfo.rightIcons) do
          if v.iconState == Enum.IconState.ShowState1 then
            hordeCarts = hordeCarts + 1
          end
        end
      end
    end

    function CartPrediction:ObjectiveTracker(widgetID)
      -- widgetType == 14
      -- 1700 = SSM
      if widgetID == 1700 then
        -- Silvershard Mines
        allyCarts, hordeCarts = 0, 0

        local baseInfo = GetDoubleStateIconRowVisualizationInfo(widgetID)

        if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
          return
        end

        for _, v in pairs(baseInfo.leftIcons) do
          if v.iconState == Enum.IconState.ShowState1 then
            allyCarts = allyCarts + 1
          end
        end
        for _, v in pairs(baseInfo.rightIcons) do
          if v.iconState == Enum.IconState.ShowState1 then
            hordeCarts = hordeCarts + 1
          end
        end
      end
    end

    function CartPrediction:UPDATE_UI_WIDGET(widgetInfo)
      if widgetInfo then
        local widgetID = widgetInfo.widgetID
        -- local widgetSetID = widgetInfo.widgetSetID
        -- local widgetType = widgetInfo.widgetType
        -- local unitToken = widgetInfo.unitToken
        -- local typeInfo = UIWidgetManager:GetWidgetTypeInfo(widgetType)
        -- local visInfo = typeInfo.visInfoDataFunction(widgetID)

        CartPrediction:ObjectiveTracker(widgetID)
        CartPrediction:CaptureBarTracker(widgetID)
      end
    end

    function CartPrediction:StartInfoTracker(mapInfo)
      -- local
      -- global
      curMap = mapInfo
      allyCarts, hordeCarts = 0, 0

      self:GetObjectivesByMapID(curMap.id)

      CartFrame:RegisterEvent("UPDATE_UI_WIDGET")
    end
  end
end

function CartPrediction:StopInfoTracker()
  CartFrame:UnregisterEvent("UPDATE_UI_WIDGET")
end
