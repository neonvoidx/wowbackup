-- Housing_StoragePanelExpert.lua
-- 目的：专家模式下强制保留 StoragePanel 显示（最小化增量改动）。
-- 原因：暴雪在 Expert 模式 OnShow 中触发 HouseStorageSetShown(false) 隐藏面板。
-- 方案：在隐藏动作后做一次“反向恢复”，并在专家模式显示时兜底。

local ADDON_NAME, ADT = ...
if not ADT then
    if DLAPI and DLAPI.DebugLog then
        DLAPI.DebugLog("ADT", "ADT: [StoragePanelExpert] 模块加载失败：ADT 为空")
    else
        print("ADT: [StoragePanelExpert] 模块加载失败：ADT 为空")
    end
    return
end

local function Debug(msg)
    local text = "[StoragePanelExpert] " .. tostring(msg)
    if ADT and ADT.DebugPrint then
        ADT.DebugPrint(text)
        return
    end
    if ADT and ADT.IsDebugEnabled and ADT.IsDebugEnabled() then
        if DLAPI and DLAPI.DebugLog then
            DLAPI.DebugLog("ADT", "ADT: " .. text)
        else
            print("ADT: " .. text)
        end
    end
end

-- 模块加载确认（仅在 DebugEnabled 时）
if ADT.IsDebugEnabled and ADT.IsDebugEnabled() then
    if DLAPI and DLAPI.DebugLog then
        DLAPI.DebugLog("ADT", "ADT: [StoragePanelExpert] 模块已加载")
    else
        print("ADT: [StoragePanelExpert] 模块已加载")
    end
end

local function IsExpertMode()
    if not (C_HouseEditor and C_HouseEditor.GetActiveHouseEditorMode) then return false end
    if not (Enum and Enum.HouseEditorMode and Enum.HouseEditorMode.ExpertDecor) then return false end
    return C_HouseEditor.GetActiveHouseEditorMode() == Enum.HouseEditorMode.ExpertDecor
end

local function DumpStorageState(tag)
    local hf = _G.HouseEditorFrame
    local sp = hf and hf.StoragePanel
    local sb = hf and hf.StorageButton
    if not (hf and sp and sb) then
        Debug(string.format("%s: hf=%s sp=%s sb=%s", tostring(tag), tostring(hf ~= nil), tostring(sp ~= nil), tostring(sb ~= nil)))
        return
    end
    local parent = sb.GetParent and sb:GetParent()
    local pname = parent and parent.GetName and parent:GetName() or "nil"
    local point, relTo, relPoint, xOfs, yOfs = sb:GetPoint(1)
    local relName = relTo and relTo.GetName and relTo:GetName() or "nil"
    Debug(string.format(
        "%s: sb shown=%s visible=%s alpha=%.2f scale=%.2f parent=%s point=%s rel=%s relPoint=%s x=%.1f y=%.1f",
        tostring(tag),
        tostring(sb:IsShown()),
        tostring(sb:IsVisible()),
        tonumber(sb:GetAlpha() or 0),
        tonumber(sb:GetScale() or 0),
        tostring(pname),
        tostring(point), tostring(relName), tostring(relPoint),
        tonumber(xOfs or 0), tonumber(yOfs or 0)
    ))
    Debug(string.format(
        "%s: sp shown=%s visible=%s collapsed=%s parent=%s",
        tostring(tag),
        tostring(sp:IsShown()),
        tostring(sp:IsVisible()),
        tostring(sp.collapsed),
        tostring(sp.GetParent and sp:GetParent() and sp:GetParent():GetName() or "nil")
    ))
end

local function ForceShowStorageNow()
    local hf = _G.HouseEditorFrame
    if not (hf and hf.StoragePanel and hf.StorageButton) then
        Debug("ForceShowStorageNow: StoragePanel/StorageButton 不可用")
        return
    end
    hf.StorageButton:Show()
    if hf.StoragePanel.UpdateCollapseState then
        hf.StoragePanel:UpdateCollapseState()
    else
        hf.StoragePanel:Show()
    end
    DumpStorageState("ForceShowStorageNow")
end

local function TryForceShowStorage()
    if not IsExpertMode() then
        Debug("TryForceShowStorage: 非专家模式，跳过")
        return
    end
    -- 下一帧执行，确保覆盖暴雪的隐藏动作
    Debug("TryForceShowStorage: 安排下一帧恢复显示")
    C_Timer.After(0, ForceShowStorageNow)
end

local function Install()
    if not _G.HouseEditorFrameMixin then
        Debug("Install: HouseEditorFrameMixin 未就绪")
        return false
    end
    if _G.HouseEditorFrameMixin._ADT_StorageKeepExpert then return end

    hooksecurefunc(_G.HouseEditorFrameMixin, "HouseStorageSetShown", function(self, shown)
        Debug("HouseStorageSetShown: shown=" .. tostring(shown))
        if shown == false and IsExpertMode() then
            TryForceShowStorage()
        end
    end)

    hooksecurefunc(_G.HouseEditorFrameMixin, "HideHouseStorage", function(self)
        Debug("HideHouseStorage called")
        if IsExpertMode() then
            TryForceShowStorage()
        end
    end)

    if _G.HouseEditorExpertDecorModeMixin then
        hooksecurefunc(_G.HouseEditorExpertDecorModeMixin, "OnShow", function()
            Debug("ExpertDecor OnShow")
            TryForceShowStorage()
        end)
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("HOUSE_EDITOR_MODE_CHANGED")
    eventFrame:SetScript("OnEvent", function(_, _, newMode)
        if not (Enum and Enum.HouseEditorMode) then return end
        if newMode == Enum.HouseEditorMode.ExpertDecor then
            Debug("Event: HOUSE_EDITOR_MODE_CHANGED -> ExpertDecor")
            TryForceShowStorage()
        end
    end)

    local hf = _G.HouseEditorFrame
    if hf and hf.StorageButton and not hf.StorageButton._ADT_StorageButtonHooked then
        hf.StorageButton:HookScript("OnShow", function() Debug("StorageButton OnShow") end)
        hf.StorageButton:HookScript("OnHide", function() Debug("StorageButton OnHide") end)
        hf.StorageButton._ADT_StorageButtonHooked = true
    end
    if hf and hf.StoragePanel and not hf.StoragePanel._ADT_StoragePanelHooked then
        hf.StoragePanel:HookScript("OnShow", function() Debug("StoragePanel OnShow") end)
        hf.StoragePanel:HookScript("OnHide", function() Debug("StoragePanel OnHide") end)
        hf.StoragePanel._ADT_StoragePanelHooked = true
    end

    _G.HouseEditorFrameMixin._ADT_StorageKeepExpert = true
    Debug("Install ok")
    return true
end

local function Boot(tryCount)
    local n = tonumber(tryCount or 0) + 1
    if Install() then return end
    if n >= 20 then
        Debug("Boot: 超时仍未安装")
        return
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, function() Boot(n) end)
    else
        local f = CreateFrame("Frame")
        f:SetScript("OnUpdate", function(self)
            self:Hide()
            Boot(n)
        end)
        f:Show()
    end
end

Boot(0)
