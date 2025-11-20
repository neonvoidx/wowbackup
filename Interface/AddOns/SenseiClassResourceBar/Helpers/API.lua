local addonName, addonTable = ...

addonTable.updateBar = function(name)
    local bar = addonTable.barInstances[name]
    if not bar then return end

    bar:ApplyLayout()
end

addonTable.updateBars = function()
    for name, _ in pairs(addonTable.barInstances) do
        addonTable.updateBar(name)
    end
end

addonTable.prettyPrint = function(...)
  print("|cffb5a707"..addonName..":|r", ...)
end
