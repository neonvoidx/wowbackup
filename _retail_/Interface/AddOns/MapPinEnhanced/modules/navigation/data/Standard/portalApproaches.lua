---@class MapPinEnhanced
local MapPinEnhanced = select(2, ...)
local Navigation = MapPinEnhanced:GetModule("Navigation")

-- Both sides use map 84 and the same subzone. These are the user's paired
-- outside/inside captures; the native exit waypoint identifies the interior.
---@type NavigationPortalApproach
local sanctum = {
    mapID = 84,
    x = 0.48772173576791,
    y = 0.88028819726641,
    exitX = 0.49052777886391,
    exitY = 0.87074440717697,
    instruction = "Enter the Wizard's Sanctum.",
}

-- Explicit authored portal identities, not a rectangle that also includes the
-- mountain above the room. Northern Stormwind portals remain ordinary targets.
Navigation.portalApproaches = {}
for _, pointID in ipairs({
    200283, 200284, 200285, 200286, 200287, 200288, 200289, 200290,
    200291, 200293, 200294, 200296, 200297, 200299,
}) do
    Navigation.portalApproaches[pointID] = sanctum
end

-- Only a matching native exit hint activates this reverse crossing. Keep the
-- onward target selected so approaching the exit cannot hide crossing evidence.
Navigation.portalExitApproaches = {
    [sanctum.mapID] = {
        mapID = sanctum.mapID,
        x = sanctum.exitX,
        y = sanctum.exitY,
        exitX = sanctum.x,
        exitY = sanctum.y,
        instruction = "Exit the Wizard's Sanctum.",
        isExit = true,
    },
}
