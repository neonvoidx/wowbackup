-- Overachiever2: ContextMenu
-- Generic declarative wrapper around WoW 12.x MenuUtil.CreateContextMenu.
--
-- Item formats:
--   { text = "Label", onClick = function(context) end }          -- command
--   { text = "Label", children = { ... } }                       -- submenu
--   { separator = true }                                         -- divider
--   { title = "Header" }                                         -- title
--
-- Optional fields on any item (except separator):
--   visible  = function(context) return bool end   -- hide item when false
--   disabled = function(context) return bool end   -- gray out when true
--   tooltip  = "string"

Overachiever2.ContextMenu = {}

local function BuildMenu(description, items, context)
    for _, item in ipairs(items) do
        -- Skip items whose visible callback returns false
        if item.visible and not item.visible(context) then
            -- skip
        elseif item.separator then
            description:CreateDivider()
        elseif item.title then
            description:CreateTitle(item.title)
        elseif item.children then
            local submenu = description:CreateButton(item.text)
            BuildMenu(submenu, item.children, context)
        else
            local button = description:CreateButton(item.text, function()
                if item.onClick then
                    item.onClick(context)
                end
            end)
            if item.disabled and item.disabled(context) then
                button:SetEnabled(false)
            end
            if item.tooltip then
                button:SetTooltip(function(tooltip)
                    GameTooltip_SetTitle(tooltip, item.text)
                    GameTooltip_AddNormalLine(tooltip, item.tooltip)
                end)
            end
        end
    end
end

-- Show a context menu at the cursor position.
--   ownerFrame: the frame that owns the menu (for auto-close behavior)
--   items:      array of menu item definitions (see format above)
--   context:    arbitrary data passed to all callbacks
function Overachiever2.ContextMenu.Show(ownerFrame, items, context)
    MenuUtil.CreateContextMenu(ownerFrame, function(owner, rootDescription)
        BuildMenu(rootDescription, items, context)
    end)
end