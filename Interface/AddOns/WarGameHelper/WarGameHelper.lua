local ADDON_NAME, namespace = ...
local L = namespace.L
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
local FRAME_TITLE = "QueueMaster 9000"

local IS_MAINLINE = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local IS_TBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local IS_CATA = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)

local function GetBrackets()
    if IS_MAINLINE then
        return {
            [1] = { name = ARENA_2V2, value = 2 },
            [2] = { name = ARENA_3V3, value = 3 },
            [3] = { name = ARENA_5V5, value = 5 },
            [4] = { name = BATTLEGROUND, value = 0 },
            [5] = { name = L["Solo Shuffle"], value = 0 },
            [6] = { name = L["Battleground Blitz"], value = 0 },
        }
    else
        return {
            [1] = { name = ARENA_2V2, value = 2 },
            [2] = { name = ARENA_3V3, value = 3 },
            [3] = { name = ARENA_5V5, value = 5 },
            [4] = { name = BATTLEGROUND, value = 0 },
        }
    end
end

local DEFAULT_MAPS = namespace.Maps

local function GetDefaultSettings()
    local maps = DEFAULT_MAPS
    if IS_MAINLINE then
        return {
            Mode = 2, -- MODE_SPECTATOR
            BNetPartyLeader1 = nil,
            BNetPartyLeader2 = nil,
            Bracket = 2,
            Map = 19,
            TournamentRules = true,
            MapData = maps,
            UseTarget = false,
        }
    else
        return {
            Mode = 2,
            BNetPartyLeader1 = nil,
            BNetPartyLeader2 = nil,
            Bracket = 4,
            Map = 1,
            TournamentRules = true,
            MapData = maps,
            UseTarget = false,
        }
    end
end

local BRACKETS = GetBrackets()
local DEFAULT_SETTINGS = GetDefaultSettings()

local MODE_NORMAL = 1
local MODE_SPECTATOR = 2

local Settings = {}

WarGameHelperMixin = {}

local function BNet_GetBNetIDAccountFromBattleTag(battleTag)
    local numFriends = BNGetNumFriends()
    for i = 1, numFriends do
        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo.battleTag and accountInfo.battleTag == battleTag then
            return accountInfo.bnetAccountID
        end
    end
end

function WarGameHelperMixin:RefreshPartyLeaderFrame(frame)
    local button = frame.info

    local accountInfo = C_BattleNet.GetAccountInfoByID(frame.bnetID)
    if not accountInfo then return end

    local nameText, nameColour, charNameColour, infoText
    local characterName = accountInfo.gameAccountInfo.characterName
    if accountInfo.accountName then
        nameText = accountInfo.accountName
        if accountInfo.gameAccountInfo.isOnline then
            characterName = BNet_GetValidatedCharacterName(characterName, accountInfo.battleTag, accountInfo.gameAccountInfo.clientProgram)
        end
    else
        nameText = UNKNOWN
    end
    frame.accountName = nameText

    if accountInfo.gameAccountInfo.isOnline then
        local class = accountInfo.gameAccountInfo.className
        for k,v in pairs(LOCALIZED_CLASS_NAMES_MALE) do if class == v then class = k end end
        for k,v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do if class == v then class = k end end

        if accountInfo.gameAccountInfo.characterLevel and accountInfo.gameAccountInfo.raceName ~= "" then
            characterName = characterName.." ("..accountInfo.gameAccountInfo.characterLevel.." "..accountInfo.gameAccountInfo.raceName..")"
        end

        button.background:SetColorTexture(FRIENDS_BNET_BACKGROUND_COLOR.r, FRIENDS_BNET_BACKGROUND_COLOR.g, FRIENDS_BNET_BACKGROUND_COLOR.b, FRIENDS_BNET_BACKGROUND_COLOR.a)
        if accountInfo.isAFK or accountInfo.gameAccountInfo.isGameAFK then
            button.status:SetTexture(FRIENDS_TEXTURE_AFK)
        elseif accountInfo.isDND or accountInfo.gameAccountInfo.isGameBusy then
            button.status:SetTexture(FRIENDS_TEXTURE_DND)
        else
            button.status:SetTexture(FRIENDS_TEXTURE_ONLINE)
        end
        if not accountInfo.gameAccountInfo.richPresence or accountInfo.gameAccountInfo.richPresence == "" then
            infoText = UNKNOWN
        else
            infoText = accountInfo.gameAccountInfo.richPresence
        end
        C_Texture.SetTitleIconTexture(button.gameIcon, accountInfo.gameAccountInfo.clientProgram, Enum.TitleIconVersion.Medium)
        button.gameIcon:Show()

        local fadeIcon = (accountInfo.gameAccountInfo.clientProgram == BNET_CLIENT_WOW) and (accountInfo.gameAccountInfo.wowProjectID ~= WOW_PROJECT_ID)
        if fadeIcon then
            button.gameIcon:SetAlpha(0.6)
        else
            button.gameIcon:SetAlpha(1)
        end

        nameColour = FRIENDS_BNET_NAME_COLOR
        charNameColour = FRIENDS_GRAY_COLOR
        if class and RAID_CLASS_COLORS[class] then
            charNameColour = RAID_CLASS_COLORS[class]
        end
    else
        button.background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a)
        button.status:SetTexture(FRIENDS_TEXTURE_OFFLINE)
        nameColour = FRIENDS_GRAY_COLOR
        charNameColour = FRIENDS_GRAY_COLOR
        button.gameIcon:Hide()
        local lastOnlineTime = accountInfo.lastOnlineTime
        if not lastOnlineTime or lastOnlineTime == 0 or HasTimePassed(lastOnlineTime, SECONDS_PER_YEAR) then
            infoText = FRIENDS_LIST_OFFLINE
        else
            infoText = string.format(BNET_LAST_ONLINE_TIME, FriendsFrame_GetLastOnline(lastOnlineTime))
        end
    end

    if nameText then
        button.name:SetText(nameText)
        button.name:SetTextColor(nameColour.r, nameColour.g, nameColour.b)
        button.charName:SetText(characterName)
        button.charName:SetTextColor(charNameColour.r, charNameColour.g, charNameColour.b)
        button.info:SetText(infoText)
        button:Show()
    else
        button:Hide()
    end
end

function WarGameHelperMixin:RefreshPartyLeaderFrames()
    if self.partyLeader1.bnetID ~= nil then
        self:RefreshPartyLeaderFrame(self.partyLeader1)
    end
    if self.partyLeader2.bnetID ~= nil then
        self:RefreshPartyLeaderFrame(self.partyLeader2)
    end
end

function WarGameHelperMixin:UpdatePartyLeaderFrame(frame)
    local selectedFriend = BNGetSelectedFriend()
    if selectedFriend > 0 then
        local accountInfo = C_BattleNet.GetFriendAccountInfo(selectedFriend)
        if frame == self.partyLeader1 then
            Settings.BNetPartyLeader1 = accountInfo.battleTag
        else
            Settings.BNetPartyLeader2 = accountInfo.battleTag
        end
        frame.bnetID = accountInfo.bnetAccountID
        self:RefreshPartyLeaderFrame(frame)
    end
end

function WarGameHelperMixin:UpdateTargetCheckButtonState()
    self.targetCheckButton:SetEnabled(Settings.Bracket ~= 5)
    if Settings.UseTarget and Settings.Bracket ~= 5 then
        self.partyLeader1.info:SetAlpha(0.5)
        self.partyLeader1.updateButton:Disable()
    else
        self.partyLeader1.info:SetAlpha(1)
        self.partyLeader1.updateButton:Enable()
    end
end

function WarGameHelperMixin:SetMode(mode)
    if mode == MODE_SPECTATOR then
        self:SetTitle(FRAME_TITLE.." [Spectator]")
        self.partyLeader1.title:SetText(PARTY_LEADER.." 1:")
        self.partyLeader2.title:SetText(PARTY_LEADER.." 2:")
        self.partyLeader2:Show()
        self:SetWidth(580)
        self.targetCheckButton:Hide()
        self.partyLeader1.info:SetAlpha(1)
        self.partyLeader1.updateButton:Enable()
    else
        self:SetTitle(FRAME_TITLE)
        self.partyLeader1.title:SetText(ENEMY.." "..PARTY_LEADER..":")
        self.partyLeader2:Hide()
        self:SetWidth(354)
        self.targetCheckButton:Show()
        self:UpdateTargetCheckButtonState()
    end
    Settings.Mode = mode
end

function WarGameHelperMixin:RefreshMapList()
    local maps = DEFAULT_MAPS
    local mapWords = {}
    local uniqueMapWords = {}

    for _, map in pairs(maps) do
        for word in map.name:gmatch("%S+") do
            word = word:lower()
            if mapWords[word] == nil then
                mapWords[word] = map.id
                uniqueMapWords[word] = map.id
            elseif uniqueMapWords[word] ~= nil then
                uniqueMapWords[word] = nil
            end
        end
        map.value = nil
    end

    -- StartWarGameByName() doesn't properly tokenize map names with spaces so we look for the longest unique word to use instead.
    for _, map in pairs(maps) do
        for k, v in pairs(uniqueMapWords) do
            if v == map.id and (map.value == nil or k:len() > map.value:len()) then
                map.value = k
            end
        end
        if map.value == nil then
            map.value = map.name
        end
    end

    if #maps > 0 then
        Settings.MapData = maps
        WarGameHelperMapDropdown_SetUp(self.mapDropdown)
    end
end

function WarGameHelperMixin:OnLoad()
    self:SetPortraitToAsset("Interface\\Icons\\Spell_magic_polymorphchicken")
    self:SetAttribute("UIPanelLayout-defined", true)
    self:SetAttribute("UIPanelLayout-area", "left")
    self:SetAttribute("UIPanelLayout-pushable", 5)
    self:SetAttribute("UIPanelLayout-whileDead", true)
    self:RegisterEvent("ADDON_LOADED")
end

function WarGameHelperMixin:OnEvent(event, ...)
    if event == "ADDON_LOADED" and ADDON_NAME == ... then
        if not WarGameHelperDB then
            WarGameHelperDB = CopyTable(DEFAULT_SETTINGS)
        end
        Settings = WarGameHelperDB
        if Settings.BNetPartyLeader1 ~= nil then
            self.partyLeader1.bnetID = BNet_GetBNetIDAccountFromBattleTag(Settings.BNetPartyLeader1)
        end
        if Settings.BNetPartyLeader2 ~= nil then
            self.partyLeader2.bnetID = BNet_GetBNetIDAccountFromBattleTag(Settings.BNetPartyLeader2)
        end
        self.bracketDropdown = LibDD:Create_UIDropDownMenu(self:GetName() .. "BracketDropdown", self)
        self.bracketDropdown:SetPoint("TOPRIGHT", -160, -28)
        self.mapDropdown = LibDD:Create_UIDropDownMenu(self:GetName() .. "MapDropdown", self)
        self.mapDropdown:SetPoint("TOPRIGHT", 10, -28)
        WarGameHelperBracketDropdown_SetUp(self.bracketDropdown)
        WarGameHelperMapDropdown_SetUp(self.mapDropdown)
        self:SetMode(Settings.Mode)
        self.targetCheckButton:SetChecked(Settings.UseTarget)
        self.tournamentRulesCheckButton:SetChecked(Settings.TournamentRules)
        self:RefreshPartyLeaderFrames()
        self:RefreshMapList()
    elseif event == "BN_FRIEND_INFO_CHANGED" then
        self:RefreshPartyLeaderFrames()
    end
end

function WarGameHelperMixin:OnShow()
    if Settings.Mode == MODE_NORMAL and self.partyLeader1.bnetID == nil then
        self:UpdatePartyLeaderFrame(self.partyLeader1)
    end
    self:RegisterEvent("BN_FRIEND_INFO_CHANGED")
end

function WarGameHelperMixin:OnHide()
    self:UnregisterEvent("BN_FRIEND_INFO_CHANGED")
end

function WarGameHelperMixin:ShowFrame(mode)
    if not FriendsFrame:IsShown() then
        ToggleFriendsFrame()
    end
    self:SetMode(mode)
    ShowUIPanel(self)
end

function WarGameHelperMixin:PrintChatMsg(msg)
    print("|TInterface\\Icons\\Spell_magic_polymorphchicken:0:0:0:0|t |cFF00FF00"..FRAME_TITLE.."|r: "..msg)
end

function WarGameHelperMixin:SendQueue()
    local bnetID1 = self.partyLeader1.bnetID
    local accountName1 = self.partyLeader1.accountName
    local bnetID2 = self.partyLeader2.bnetID
    local accountName2 = self.partyLeader2.accountName
    local maps = Settings.MapData
    if Settings.Mode == MODE_NORMAL then
        if Settings.UseTarget and Settings.Bracket ~= 5 then
            if UnitExists("target") then
                StartWarGame("target", maps[Settings.Map].name, Settings.TournamentRules)
                self:PrintChatMsg("War Game request sent to "..UnitName("target").."...")
            end
        elseif bnetID1 ~= nil then
            local tournamentRules = Settings.TournamentRules and "1" or "0"
            local cmdStr = accountName1.." "..maps[Settings.Map].value.." "..tournamentRules
            if Settings.Bracket == 5 then
                StartSoloShuffleWarGameByName(cmdStr)
            elseif Settings.Bracket == 6 then
                C_PvP.StartSoloRBGWarGameByName(cmdStr)
            else
                StartWarGameByName(cmdStr)
            end
            self:PrintChatMsg("War Game request sent to "..accountName1.."...")
        end
    elseif bnetID1 ~= nil and bnetID2 ~= nil then
        if Settings.Bracket == 5 then
            StartSpectatorSoloShuffleWarGame(bnetID1, bnetID2, maps[Settings.Map].name, Settings.TournamentRules)
        elseif Settings.Bracket == 6 then
            C_PvP.StartSpectatorSoloRBGWarGame(bnetID1, bnetID2, maps[Settings.Map].name, Settings.TournamentRules)
        else
            StartSpectatorWarGame(bnetID1, bnetID2, BRACKETS[Settings.Bracket].value, maps[Settings.Map].name, Settings.TournamentRules)
        end
        self:PrintChatMsg("[Spectator] War Game request sent to "..accountName1.." and "..accountName2.."...")
    end
end

function WarGameHelperTargetCheckButton_OnClick(self)
    if self:GetChecked() then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        WarGameHelper.partyLeader1.info:SetAlpha(0.5)
        WarGameHelper.partyLeader1.updateButton:Disable()
    else
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        WarGameHelper.partyLeader1.info:SetAlpha(1)
        WarGameHelper.partyLeader1.updateButton:Enable()
    end
    Settings.UseTarget = self:GetChecked()
end

function WarGameHelperTournamentRulesCheckButton_OnClick(self)
    if self:GetChecked() then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    else
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    end
    Settings.TournamentRules = self:GetChecked()
end

function WarGameHelperStartButton_GetErrorTooltip()
    if Settings.Mode == MODE_NORMAL then
        if not UnitIsGroupLeader("player") then
            return WARGAME_REQ_LEADER
        end
        if Settings.Bracket < 4 then
            local groupSize = GetNumGroupMembers()
            if groupSize ~= 2 and groupSize ~= 3 and groupSize ~= 5 then
                local name = Settings.MapData[Settings.Map].name
                return string.format(WARGAME_REQ_ARENA, name, RED_FONT_COLOR_CODE)..FONT_COLOR_CODE_CLOSE
            end
        end
        if Settings.UseTarget and Settings.Bracket ~= 5 then
            if not UnitLeadsAnyGroup("target") or UnitIsUnit("player", "target") then
                return WARGAME_REQ_TARGET
            end
        elseif Settings.BNetPartyLeader1 == nil then
            return "You must select an enemy party leader to start a War Game."
        end
    else
        if Settings.BNetPartyLeader1 == nil or Settings.BNetPartyLeader2 == nil then
            return "You must select two party leaders to start a spectated War Game."
        end
    end
    return nil
end

function WarGameHelperStartButton_OnEnter(self)
    local tooltip = WarGameHelperStartButton_GetErrorTooltip()
    if tooltip then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltip, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, 1, 1)
    end
end

function WarGameHelperStartButton_OnClick(self)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    WarGameHelper:SendQueue()
end

local function GetFirstArenaMapIndex()
    if IS_MAINLINE then return 19 end
    if IS_CATA then return 9 end
    return 5 -- TBC
end

function WarGameHelperBracketDropdownButton_OnClick(self)
    local id = self.value
    local oldBracket = Settings.Bracket
    LibDD:UIDropDownMenu_SetSelectedValue(WarGameHelper.bracketDropdown, id)
    Settings.Bracket = id
    if id == 4 and oldBracket ~= id then
        Settings.Map = 1
        WarGameHelperMapDropdown_SetUp(WarGameHelper.mapDropdown)
    elseif id == 6 and oldBracket ~= id then
        Settings.Map = 36
        WarGameHelperMapDropdown_SetUp(WarGameHelper.mapDropdown)
    elseif (id ~= 4 and id ~= 6) and (oldBracket == 4 or oldBracket == 6) then
        Settings.Map = GetFirstArenaMapIndex()
        WarGameHelperMapDropdown_SetUp(WarGameHelper.mapDropdown)
    end
    if WarGameHelper.targetCheckButton:IsShown() then
        WarGameHelper:UpdateTargetCheckButtonState()
    end
end

function WarGameHelperBracketDropdown_Initialize(self)
    local info = LibDD:UIDropDownMenu_CreateInfo()
    info.func = WarGameHelperBracketDropdownButton_OnClick
    for i = 1, #BRACKETS do
        local v = BRACKETS[i]
        info.text = v.name
        info.value = i
        info.checked = false
        LibDD:UIDropDownMenu_AddButton(info)
    end
end

function WarGameHelperBracketDropdown_SetUp(self)
    LibDD:UIDropDownMenu_SetWidth(self, 100)
    LibDD:UIDropDownMenu_Initialize(self, WarGameHelperBracketDropdown_Initialize)
    LibDD:UIDropDownMenu_SetSelectedValue(self, Settings.Bracket)
end

function WarGameHelperMapDropdownButton_OnClick(self)
    local id = self.value
    LibDD:UIDropDownMenu_SetSelectedValue(WarGameHelper.mapDropdown, id)
    Settings.Map = id
end

function WarGameHelperMapDropdown_Initialize(self)
    local info = LibDD:UIDropDownMenu_CreateInfo()
    local bracket = Settings.Bracket
    info.func = WarGameHelperMapDropdownButton_OnClick
    for i = 1, #Settings.MapData do
        local v = Settings.MapData[i]
        local isBG = bracket == 4 and v.pvpType == 3 and not v.isBlitz
        local isBlitz = bracket == 6 and v.pvpType == 3 and v.isBlitz
        local isArena = bracket ~= 4 and bracket ~= 6 and v.pvpType == 4
        if isBG or isBlitz or isArena then
            info.text = v.name
            info.value = i
            info.checked = false
            LibDD:UIDropDownMenu_AddButton(info)
        end
    end
end

function WarGameHelperMapDropdown_SetUp(self)
    LibDD:UIDropDownMenu_SetWidth(self, 150)
    LibDD:UIDropDownMenu_Initialize(self, WarGameHelperMapDropdown_Initialize)
    LibDD:UIDropDownMenu_SetSelectedValue(self, Settings.Map)
end

SLASH_WARGAMEHELPER1 = "/wg"
SLASH_WARGAMEHELPER2 = "/wargame"
SLASH_WARGAMEHELPER3 = SLASH_WARGAME1
SLASH_WARGAMEHELPER4 = SLASH_WARGAME2
SlashCmdList["WARGAMEHELPER"] = function(msg)
    if msg == "" then
        WarGameHelper:ShowFrame(MODE_NORMAL)
    else
        SlashCmdList["WARGAME"](msg)
    end
end

SLASH_WARGAMEHELPER_SPEC1 = "/wgs"
SLASH_WARGAMEHELPER_SPEC2 = "/wgspec"
SLASH_WARGAMEHELPER_SPEC3 = SLASH_SPECTATOR_WARGAME1
SLASH_WARGAMEHELPER_SPEC4 = SLASH_SPECTATOR_WARGAME2
SlashCmdList["WARGAMEHELPER_SPEC"] = function(msg)
    if msg == "" then
        WarGameHelper:ShowFrame(MODE_SPECTATOR)
    else
        SlashCmdList["SPECTATOR_WARGAME"](msg)
    end
end

SLASH_WARGAMEHELPER_TARGET1 = "/wgt"
SLASH_WARGAMEHELPER_TARGET2 = "/wgtarget"
SlashCmdList["WARGAMEHELPER_TARGET"] = function(msg)
    if not UnitLeadsAnyGroup("target") or UnitIsUnit("player", "target") then
        WarGameHelper:PrintChatMsg(WARGAME_REQ_TARGET)
    else
        StartWarGame("target", Settings.MapData[Settings.Map].name, Settings.TournamentRules)
        WarGameHelper:PrintChatMsg("War Game request sent to "..UnitName("target").."...")
    end
end
