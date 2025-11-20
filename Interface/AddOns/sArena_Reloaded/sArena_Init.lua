sArenaMixin = {}
sArenaFrameMixin = {}

local gameVersion = select(1, GetBuildInfo())
sArenaMixin.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
sArenaMixin.isMidnight = gameVersion:match("^12")
sArenaMixin.isMoP = gameVersion:match("^5%.")
sArenaMixin.isTBC = gameVersion:match("^2%.")