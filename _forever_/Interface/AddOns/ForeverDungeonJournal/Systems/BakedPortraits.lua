-- Pre-rendered boss portraits.
-- Every creature portrait the journal shows was photographed once in-game
-- (black + white backgrounds, so the round edge keeps its exact alpha) and is
-- bundled here as Media\\Portraits\\<displayID>.tga. Bundled portraits appear
-- instantly instead of being rendered from the 3D model on first open.
-- Any display ID not in the list still goes through the live renderer.
local FDJ = _G.ForeverDungeonJournal_NS
if not FDJ then return end

local PATH = "Interface\\AddOns\\ForeverDungeonJournal\\Media\\Portraits\\"
FDJ.BAKED_PORTRAITS = {
    [414]=true, [517]=true, [522]=true, [523]=true, [524]=true, [556]=true, [559]=true, [571]=true, [825]=true, [1065]=true, [1131]=true, [1204]=true,
    [1267]=true, [1269]=true, [1305]=true, [1621]=true, [1693]=true, [1773]=true, [1816]=true, [1951]=true, [2007]=true, [2026]=true, [2029]=true, [2040]=true,
    [2041]=true, [2042]=true, [2043]=true, [2044]=true, [2142]=true, [2149]=true, [2172]=true, [2314]=true, [2316]=true, [2318]=true, [2347]=true, [2349]=true,
    [2352]=true, [2353]=true, [2438]=true, [2440]=true, [2447]=true, [2450]=true, [2605]=true, [2606]=true, [2837]=true, [3004]=true, [3222]=true, [3223]=true,
    [3224]=true, [3250]=true, [4088]=true, [4203]=true, [4211]=true, [4213]=true, [4214]=true, [4215]=true, [4256]=true, [4313]=true, [4642]=true, [4644]=true,
    [4652]=true, [4735]=true, [4939]=true, [4979]=true, [5027]=true, [5126]=true, [5230]=true, [5231]=true, [5266]=true, [5489]=true, [5497]=true, [5534]=true,
    [5710]=true, [5781]=true, [5945]=true, [5988]=true, [6059]=true, [6089]=true, [6097]=true, [6102]=true, [6110]=true, [6375]=true, [6434]=true, [6439]=true,
    [6441]=true, [6669]=true, [6708]=true, [6709]=true, [6774]=true, [6915]=true, [6980]=true, [7109]=true, [7113]=true, [7124]=true, [7125]=true, [7271]=true,
    [7353]=true, [7534]=true, [7550]=true, [7553]=true, [7555]=true, [7806]=true, [7845]=true, [7848]=true, [7856]=true, [7864]=true, [7873]=true, [7919]=true,
    [7970]=true, [7975]=true, [8053]=true, [8055]=true, [8177]=true, [8270]=true, [8271]=true, [8329]=true, [8652]=true, [8658]=true, [8667]=true, [8704]=true,
    [8705]=true, [8711]=true, [8756]=true, [8759]=true, [8760]=true, [8761]=true, [8762]=true, [8807]=true, [9014]=true, [9089]=true, [9212]=true, [9292]=true,
    [9293]=true, [9564]=true, [9567]=true, [9581]=true, [9584]=true, [9668]=true, [9686]=true, [9732]=true, [9733]=true, [9738]=true, [9755]=true, [9778]=true,
    [9783]=true, [9785]=true, [9786]=true, [9793]=true, [9806]=true, [9929]=true, [10115]=true, [10193]=true, [10222]=true, [10248]=true, [10433]=true, [10482]=true,
    [10544]=true, [10546]=true, [10669]=true, [10674]=true, [10691]=true, [10698]=true, [10728]=true, [10729]=true, [10771]=true, [10798]=true, [10901]=true, [11069]=true,
    [11070]=true, [11072]=true, [11073]=true, [11165]=true, [11172]=true, [11179]=true, [11250]=true, [11256]=true, [11270]=true, [11335]=true, [11382]=true, [11396]=true,
    [11429]=true, [11492]=true, [11537]=true, [11538]=true, [11545]=true, [11561]=true, [11564]=true, [11565]=true, [11574]=true, [11576]=true, [11578]=true, [11583]=true,
    [11611]=true, [11809]=true, [11835]=true, [12073]=true, [12162]=true, [12292]=true, [12293]=true, [12334]=true, [12350]=true, [12389]=true, [12818]=true, [12822]=true,
    [13589]=true, [14173]=true, [14308]=true, [14378]=true, [14383]=true, [14384]=true, [14403]=true, [14416]=true, [14556]=true,
}
local BAKED = FDJ.BAKED_PORTRAITS

function FDJ.SetBakedPortrait(texture, displayID)
    if not texture or type(displayID) ~= "number" or not BAKED[displayID] then return false end
    texture:SetTexture(PATH .. displayID)
    return true
end

local liveAcquire = FDJ.AcquirePortrait
FDJ.AcquirePortrait = function(host, displayID)
    if host and type(displayID) == "number" and BAKED[displayID] then
        if FDJ.ReleasePortrait then pcall(FDJ.ReleasePortrait, host) end
        host:SetTexture(PATH .. displayID)
        host:SetAlpha(1)
        return true
    end
    if liveAcquire then return liveAcquire(host, displayID) end
    return false
end

-- Portrait baking (1.9.4): /dj bake photographs the creature portraits that
-- are not bundled yet (Systems/BakedPortraits.lua), so they can be bundled as
-- Media\Portraits\<displayID>.tga and appear at once like the original
-- dungeons' bosses. A full-screen sheet shows every portrait at 64 x 64
-- screen pixels, once on black and once on white (the round edge's exact
-- alpha comes from the two), and the game saves a lossless screenshot of
-- each (Screenshots folder). Nothing else is changed; the sheet closes by
-- itself.
-- In this order on the sheet, left to right, top to bottom.
FDJ.BAKE_DISPLAY_IDS = {
    2317, 2460, 2462, 2499, 2514, 4973, 6124, 6374, 6687, 7971,
    8687, 9291, 12235, 14424, 129891, 129894, 129895, 129900, 129945, 129954,
    130061, 130102, 130235, 130427, 130432, 130436, 130440, 130447, 131644, 138667,
    139455, 140092, 140708, 141215, 141217, 141218, 141219, 141443, 142144, 142245,
    142322, 142826, 142837, 142840, 143673, 144023, 144170, 144175, 144188, 144189,
    144209, 144210, 144224, 144378, 144475, 144487, 145787, 145809,
}

local SIZE, PITCH, MARGIN = 64, 80, 16 -- screen pixels
local LOAD_WAIT, SHOT_WAIT = 6, 1.5    -- seconds

local function Say(text)
    print("|cffffd100Dungeon Journal|r " .. text)
end

local sheet
local function Sheet()
    if sheet then return sheet end
    sheet = CreateFrame("Frame", nil, UIParent)
    sheet:SetFrameStrata("TOOLTIP")
    sheet:SetFrameLevel(9000)
    sheet:EnableMouse(true)
    sheet.back = sheet:CreateTexture(nil, "BACKGROUND")
    sheet.back:SetAllPoints()
    sheet.marks = {}
    for i = 1, 2 do
        local mark = sheet:CreateTexture(nil, "ARTWORK")
        mark:SetColorTexture(1, 0, 0, 1)
        sheet.marks[i] = mark
    end
    sheet.cells = {}
    sheet:Hide()
    return sheet
end

-- Lay one page of portraits out on the sheet, one sheet unit = one screen
-- pixel. Returns how many fit on a page.
local function Layout(page, ids)
    local s = Sheet()
    local w, h = 1920, 1080
    if type(GetPhysicalScreenSize) == "function" then
        local okSize, pw, ph = pcall(GetPhysicalScreenSize)
        if okSize and tonumber(pw) and tonumber(ph) then w, h = pw, ph end
    end
    local parentScale = UIParent:GetEffectiveScale()
    s:SetScale((768 / h) / parentScale)
    s:ClearAllPoints()
    s:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    s:SetSize(w, h)
    -- Red 4 x 4 marks at (4, 4) and (w - 8, h - 8): where the sheet's
    -- corners are in the screenshot.
    s.marks[1]:SetSize(4, 4)
    s.marks[1]:ClearAllPoints()
    s.marks[1]:SetPoint("TOPLEFT", s, "TOPLEFT", 4, -4)
    s.marks[2]:SetSize(4, 4)
    s.marks[2]:ClearAllPoints()
    s.marks[2]:SetPoint("TOPLEFT", s, "TOPLEFT", w - 8, -(h - 8))
    local cols = math.max(1, math.floor((w - 2 * MARGIN) / PITCH))
    local rows = math.max(1, math.floor((h - 2 * MARGIN) / PITCH))
    local per = cols * rows
    for _, cell in ipairs(s.cells) do
        cell.tex:Hide()
        cell.label:Hide()
    end
    local first = (page - 1) * per
    for i = 1, per do
        local id = ids[first + i]
        if not id then break end
        local cell = s.cells[i]
        if not cell then
            cell = { tex = s:CreateTexture(nil, "ARTWORK"), label = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall") }
            cell.label:SetTextColor(0.5, 0.5, 0.5)
            s.cells[i] = cell
        end
        local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
        local x, y = MARGIN + col * PITCH, MARGIN + row * PITCH
        cell.tex:SetSize(SIZE, SIZE)
        cell.tex:ClearAllPoints()
        cell.tex:SetPoint("TOPLEFT", s, "TOPLEFT", x, -y)
        cell.tex:SetTexCoord(0, 1, 0, 1)
        cell.tex:SetTexture(nil)
        pcall(SetPortraitTextureFromCreatureDisplayID, cell.tex, id)
        cell.tex:Show()
        cell.label:ClearAllPoints()
        cell.label:SetPoint("TOP", cell.tex, "BOTTOM", 0, -1)
        cell.label:SetText(id)
        cell.label:Show()
    end
    return per
end

function FDJ.BakePortraits()
    if sheet and sheet:IsShown() then return end
    if type(Screenshot) ~= "function" or not (C_Timer and C_Timer.After) then
        Say("bake: this client cannot take screenshots from an addon.")
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        Say("bake: not in combat.")
        return
    end
    local ids = FDJ.BAKE_DISPLAY_IDS
    local oldFormat = GetCVar and GetCVar("screenshotFormat")
    pcall(SetCVar, "screenshotFormat", "tga")
    if GameTooltip then GameTooltip:Hide() end
    local s = Sheet()
    local page, pages = 1, 1
    local shots = 0
    local function Finish()
        s:Hide()
        if oldFormat then pcall(SetCVar, "screenshotFormat", oldFormat) end
        Say(string.format("bake: done, %d screenshots of %d portraits (Screenshots folder). Tell Claude.", shots, #ids))
    end
    local function Shot()
        local ok = pcall(Screenshot)
        if ok then shots = shots + 1 end
        return ok
    end
    local function Page()
        local per = Layout(page, ids)
        pages = math.ceil(#ids / per)
        s.back:SetColorTexture(0, 0, 0, 1)
        s:Show()
        C_Timer.After(LOAD_WAIT, function()
            if not Shot() then
                Say("bake: the game would not take the screenshot.")
                Finish()
                return
            end
            C_Timer.After(SHOT_WAIT, function()
                s.back:SetColorTexture(1, 1, 1, 1)
                C_Timer.After(SHOT_WAIT, function()
                    Shot()
                    C_Timer.After(SHOT_WAIT, function()
                        if page < pages then
                            page = page + 1
                            Page()
                        else
                            Finish()
                        end
                    end)
                end)
            end)
        end)
    end
    Say(string.format("bake: photographing %d portraits (about 15 seconds). Don't press any keys.", #ids))
    Page()
end
