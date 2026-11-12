-- /dj export: FDJ3 compressed snapshot. See Systems/CharacterSnapshot.lua.
local FDJ = _G.ForeverDungeonJournal_NS
if not FDJ then return end

-- FDJ2 added the race. The website still reads FDJ1 codes, which have no
-- race field, so an older export keeps working.

-- Export dialog strings in every supported locale.
do
    local strings = {
        enUS = {EXPORT_TITLE = "Dungeon Journal - character code", EXPORT_COPY = "Ctrl+A then Ctrl+C, and paste it on the website.", EXPORT_HINT = "%s - %d quests done. Paste this on the website.", EXPORT_ERROR = "Could not build the character code."},
        deDE = {EXPORT_TITLE = "Dungeon Journal - Charaktercode", EXPORT_COPY = "Strg+A, dann Strg+C; auf der Website einfügen.", EXPORT_HINT = "%s - %d Quests erledigt. Auf der Website einfügen.", EXPORT_ERROR = "Der Charaktercode konnte nicht erstellt werden."},
        frFR = {EXPORT_TITLE = "Dungeon Journal - code du personnage", EXPORT_COPY = "Ctrl+A puis Ctrl+C, et collez sur le site.", EXPORT_HINT = "%s - %d quêtes terminées. Collez sur le site.", EXPORT_ERROR = "Impossible de créer le code du personnage."},
        esES = {EXPORT_TITLE = "Dungeon Journal - código del personaje", EXPORT_COPY = "Ctrl+A y luego Ctrl+C; pégalo en el sitio web.", EXPORT_HINT = "%s - %d misiones completadas. Pégalo en el sitio web.", EXPORT_ERROR = "No se pudo crear el código del personaje."},
        itIT = {EXPORT_TITLE = "Dungeon Journal - codice personaggio", EXPORT_COPY = "Ctrl+A, poi Ctrl+C; incolla sul sito web.", EXPORT_HINT = "%s - %d missioni completate. Incolla sul sito web.", EXPORT_ERROR = "Impossibile creare il codice del personaggio."},
        ptBR = {EXPORT_TITLE = "Dungeon Journal - código do personagem", EXPORT_COPY = "Ctrl+A e depois Ctrl+C; cole no site.", EXPORT_HINT = "%s - %d missões concluídas. Cole no site.", EXPORT_ERROR = "Não foi possível criar o código do personagem."},
        ruRU = {EXPORT_TITLE = "Dungeon Journal - код персонажа", EXPORT_COPY = "Нажмите Ctrl+A, затем Ctrl+C и вставьте код на сайте.", EXPORT_HINT = "%s - выполнено заданий: %d. Вставьте код на сайте.", EXPORT_ERROR = "Не удалось создать код персонажа."},
        koKR = {EXPORT_TITLE = "Dungeon Journal - 캐릭터 코드", EXPORT_COPY = "Ctrl+A, Ctrl+C를 누른 후 웹사이트에 붙여넣으세요.", EXPORT_HINT = "%s - 완료한 퀘스트 %d개. 웹사이트에 붙여넣으세요.", EXPORT_ERROR = "캐릭터 코드를 만들 수 없습니다."},
        zhCN = {EXPORT_TITLE = "Dungeon Journal - 角色代码", EXPORT_COPY = "按 Ctrl+A，再按 Ctrl+C，然后粘贴到网站。", EXPORT_HINT = "%s - 已完成 %d 个任务。请粘贴到网站。", EXPORT_ERROR = "无法生成角色代码。"},
        zhTW = {EXPORT_TITLE = "Dungeon Journal - 角色代碼", EXPORT_COPY = "按 Ctrl+A，再按 Ctrl+C，然後貼到網站。", EXPORT_HINT = "%s - 已完成 %d 個任務。請貼到網站。", EXPORT_ERROR = "無法產生角色代碼。"},
        esMX = {EXPORT_TITLE = "Dungeon Journal - código del personaje", EXPORT_COPY = "Ctrl+A y luego Ctrl+C; pégalo en el sitio web.", EXPORT_HINT = "%s - %d misiones completadas. Pégalo en el sitio web.", EXPORT_ERROR = "No se pudo crear el código del personaje."},
    }
    for locale, values in pairs(strings) do
        if FDJ.Locales and FDJ.Locales[locale] then
            for key, value in pairs(values) do FDJ.Locales[locale][key] = value end
        end
    end
end
local function ExportText(key) return FDJ.L and FDJ.L(key) or key end


-- ------------------------------------------------------------------ encoding

local B36 = "0123456789abcdefghijklmnopqrstuvwxyz"

local function Base36(n)
    n = math.floor(tonumber(n) or 0)
    local sign = ""
    if n < 0 then
        sign, n = "-", -n
    end
    if n == 0 then return "0" end
    local out = ""
    while n > 0 do
        local d = n % 36
        out = B36:sub(d + 1, d + 1) .. out
        n = math.floor(n / 36)
    end
    return sign .. out
end

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

-- base64url, no padding. Arithmetic rather than the bit library, which is not
-- present on every client this addon runs on.
local function Base64Url(s)
    local out, n = {}, #s
    for i = 1, n, 3 do
        local b1 = s:byte(i)
        local b2 = s:byte(i + 1)
        local b3 = s:byte(i + 2)
        local v = b1 * 65536 + (b2 or 0) * 256 + (b3 or 0)
        local c1 = math.floor(v / 262144) % 64
        local c2 = math.floor(v / 4096) % 64
        local c3 = math.floor(v / 64) % 64
        local c4 = v % 64
        out[#out + 1] = B64:sub(c1 + 1, c1 + 1) .. B64:sub(c2 + 1, c2 + 1)
        if b2 then out[#out + 1] = B64:sub(c3 + 1, c3 + 1) end
        if b3 then out[#out + 1] = B64:sub(c4 + 1, c4 + 1) end
    end
    return table.concat(out)
end

-- Adler-32: catches a truncated or mistyped paste. Its running sums stay well
-- inside the range a double holds exactly, so there is no overflow to handle.
local function Checksum(s)
    local a, b = 1, 0
    for i = 1, #s do
        a = (a + s:byte(i)) % 65521
        b = (b + a) % 65521
    end
    return b * 65536 + a
end

-- FDJ3: raw DEFLATE JSON, base64url, Adler-32 of the UTF-8 JSON.
FDJ.BuildExportCode = function()
    local snapshot = FDJ.BuildCharacterSnapshot()
    local body = FDJ.ExportJSON(snapshot)
    local lib = (LibStub and LibStub:GetLibrary("LibDeflate", true)) or _G.FDJLibDeflate
    assert(lib, "LibDeflate unavailable")
    local code = "FDJ3." .. Base64Url(lib:CompressDeflate(body, {level = 5})) .. "." .. Base36(Checksum(body))
    return code, #snapshot.completed, snapshot.name
end

-- ------------------------------------------------------------------------ UI

local dialog

local function BuildDialog()
    local f = CreateFrame("Frame", "FDJExportFrame", UIParent, "BackdropTemplate")
    f:SetSize(520, 190)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(0.02, 0.02, 0.02, 0.95)
        f:SetBackdropBorderColor(0.34, 0.34, 0.34, 1)
    end

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -14)
    title:SetText(ExportText("EXPORT_TITLE"))

    f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.hint:SetPoint("TOP", title, "BOTTOM", 0, -6)

    -- A read-only looking box the player can select all of and copy.
    local box = CreateFrame("EditBox", nil, f)
    box:SetMultiLine(true)
    box:SetMaxLetters(0)
    box:SetFontObject("GameFontHighlightSmall")
    box:SetPoint("TOPLEFT", 18, -62)
    box:SetPoint("BOTTOMRIGHT", -18, 46)
    box:SetAutoFocus(false)
    box:SetTextInsets(6, 6, 4, 4)
    box:SetScript("OnEscapePressed", function() f:Hide() end)
    -- Typing into it would only corrupt the code, so put it straight back.
    box:SetScript("OnTextChanged", function(self, byUser)
        if byUser then
            self:SetText(f.code or "")
            self:HighlightText()
        end
    end)
    f.box = box

    local bg = CreateFrame("Frame", nil, f, "BackdropTemplate")
    bg:SetPoint("TOPLEFT", box, -6, 6)
    bg:SetPoint("BOTTOMRIGHT", box, 6, -6)
    bg:SetFrameLevel(box:GetFrameLevel() - 1)
    if bg.SetBackdrop then
        bg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        bg:SetBackdropColor(0, 0, 0, 0.6)
        bg:SetBackdropBorderColor(0.28, 0.28, 0.28, 1)
    end

    local foot = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    foot:SetPoint("BOTTOMLEFT", 18, 20)
    foot:SetText(ExportText("EXPORT_COPY"))

    local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    close:SetSize(80, 22)
    close:SetPoint("BOTTOMRIGHT", -16, 14)
    close:SetText(CLOSE or "Close")
    close:SetScript("OnClick", function() f:Hide() end)

    tinsert(UISpecialFrames, "FDJExportFrame")  -- Escape closes it
    return f
end

FDJ.ShowExportDialog = function()
    local ok, code, questCount, name = pcall(FDJ.BuildExportCode)
    if not ok or type(code) ~= "string" then
        print("|cffd8a83cDungeon Journal:|r " .. ExportText("EXPORT_ERROR"))
        return
    end
    dialog = dialog or BuildDialog()
    dialog.code = code
    dialog.hint:SetText(string.format(ExportText("EXPORT_HINT"),
        name or "?", questCount or 0))
    dialog.box:SetText(code)
    dialog:Show()
    dialog.box:SetFocus()
    dialog.box:HighlightText()
end

-- /dj export, chained onto the journal's own handler the way the other
-- Systems modules extend it.
local base = SlashCmdList and SlashCmdList.FOREVERDUNGEONJOURNAL
if base then
    SlashCmdList.FOREVERDUNGEONJOURNAL = function(msg, ...)
        local cmd = tostring(msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        if cmd == "export" then
            FDJ.ShowExportDialog()
            return
        end
        return base(msg, ...)
    end
end
