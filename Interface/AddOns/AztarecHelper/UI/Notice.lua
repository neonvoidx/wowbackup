-- Azta'rec Helper, copyright 2026 Rothirr, all rights reserved.
-- Read it if you want. Copying any of it into another addon is theft, and
-- running it through an AI tool first does not change that. The timings and
-- coordinates were measured by hand. Nothing here is licensed to anyone.

local _, AZT = ...

-- The reading box. One frame for the instructions behind the room view's
-- button and for the questions the addon asks on the way into the delve.

local box

-- taller reads scroll rather than grow the box past this
local MAX_BODY = 380

local INSTR_TITLE = "How to use it"
local INSTR = "|cffffd100The fight:|r during Sermon of Ula'tek the boss slams three quarters of the "
    .. "room at once and leaves one safe, a few waves in a row, the ground showing where. "
    .. "Then the echoes repeat the same order with nothing on the ground.\n\n"
    .. "|cffffd100Record the safe spots:|r while the ground shows them, press the safe quarter's key "
    .. "or click it on the room view, one answer per wave. A missed wave is caught up by "
    .. "your next press. Or set Recording to Automatic and the addon writes down where you "
    .. "stood for each wave, nothing to press. Automatic reads the quarter |cffff5a5abehind|r you, "
    .. "so face the boss the whole Sermon or it records the wrong spots.\n\n"
    .. "|cffffd100Dodge the echoes:|r the room view lights the safe quarter green and the one after "
    .. "it yellow, the arrow points your move and the voice calls it out loud. Go where "
    .. "they say.\n\n"
    .. "|cffffd100Practice:|r /azt practice runs a pretend sermon with no boss around. Every setting "
    .. "explains itself in its tooltip."

local function build()
    box = CreateFrame("Frame", "AztarecHelperNotice", UIParent, "BackdropTemplate")
    box:SetSize(480, 100)
    box:SetPoint("CENTER", 0, 140)
    -- above the settings panel, the boxes can open while it is up
    box:SetFrameStrata("FULLSCREEN_DIALOG")
    box:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    box:SetBackdropColor(0, 0, 0, 0.85)
    box:EnableMouse(true)
    box:SetMovable(true)
    box:RegisterForDrag("LeftButton")
    box:SetScript("OnDragStart", box.StartMoving)
    box:SetScript("OnDragStop", box.StopMovingOrSizing)

    local title = box:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    box.title = title

    -- room for a picture between the title and the text, the automatic
    -- explainer puts its screenshot there. Sized per show
    local pic = box:CreateTexture(nil, "ARTWORK")
    pic:SetPoint("TOP", 0, -38)
    box.pic = pic

    -- the body rides a scroll frame, so a long read, the collected release
    -- notes mostly, caps the box and rolls under the wheel instead of
    -- running off the screen
    local scroll = CreateFrame("ScrollFrame", nil, box)
    local content = CreateFrame("Frame", nil, scroll)
    scroll:SetScrollChild(content)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local v = self:GetVerticalScroll() - delta * 40
        self:SetVerticalScroll(math.min(math.max(v, 0), self:GetVerticalScrollRange()))
    end)
    local body = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOPLEFT")
    body:SetJustifyH("LEFT")
    body:SetSpacing(2)
    box.scroll, box.content, box.body = scroll, content, body

    -- a box can carry a link into the settings in its sentence. The links
    -- live in the body so its frame takes the clicks, and the box closes
    -- first so the settings do not open under it
    content:EnableMouse(true)
    content:SetHyperlinksEnabled(true)
    content:SetScript("OnHyperlinkClick", function(_, link)
        if link == "azt:options" then
            box:Hide()
            AZT.OpenOptions()
        end
    end)

    -- one button for reading, two when the box is asking something
    local right = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    right:SetSize(150, 22)
    right:SetPoint("BOTTOM", 0, 12)
    box.right = right

    local left = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    left:SetSize(150, 22)
    left:SetPoint("RIGHT", right, "LEFT", -8, 0)
    box.left = left

    -- a new frame starts shown, and the queue below reads shown as busy
    box:Hide()
    table.insert(UISpecialFrames, "AztarecHelperNotice")
end

-- text with one dismiss button, or a question with a choice on either side
-- One box, so asks that land together queue up behind it and take their
-- turn as it closes. Delve entry raises up to two at once, the automatic
-- offer and a party role ask.
local queue = {}
local show

local function showNext()
    local nxt = table.remove(queue, 1)
    if nxt then
        show(nxt.title, nxt.text, nxt.ask, nxt.pic)
    end
end

-- pic is { file, width, height }, shown between the title and the text
function show(title, text, ask, pic)
    if not box then
        build()
        box:SetScript("OnHide", showNext)
    end
    -- a different box waits its turn, but asking for the one already on
    -- screen just redraws it, else a mashed button stacks copies that each
    -- want their own Got it
    if box:IsShown() and box.title:GetText() ~= title then
        queue[#queue + 1] = { title = title, text = text, ask = ask, pic = pic }
        return
    end
    box.title:SetText(title)
    local picH = 0
    if pic then
        box.pic:SetTexture(pic[1])
        box.pic:SetSize(pic[2], pic[3])
        picH = pic[3] + 8
    end
    box.pic:SetShown(pic and true or false)
    box.body:SetWidth(box:GetWidth() - 36)
    box.body:SetText(text)
    local bodyH = box.body:GetStringHeight()
    box.content:SetSize(box:GetWidth() - 36, bodyH)
    local seen = math.min(bodyH, MAX_BODY)
    box.scroll:ClearAllPoints()
    box.scroll:SetPoint("TOPLEFT", 18, -38 - picH)
    box.scroll:SetPoint("TOPRIGHT", -18, -38 - picH)
    box.scroll:SetHeight(seen)
    box.scroll:SetVerticalScroll(0)
    box:SetHeight(38 + picH + seen + 48)
    box.left:SetShown(ask and true or false)
    box.right:ClearAllPoints()
    if ask then
        box.left:SetText(ask.leftText)
        box.left:SetScript("OnClick", function()
            box:Hide()
            ask.left()
        end)
        -- shifted right so the pair sits centred with the left button
        box.right:SetPoint("BOTTOM", 79, 12)
        box.right:SetText(ask.rightText)
        box.right:SetScript("OnClick", function()
            box:Hide()
            ask.right()
        end)
    else
        box.right:SetPoint("BOTTOM", 0, 12)
        box.right:SetText("Got it")
        box.right:SetScript("OnClick", function()
            box:Hide()
        end)
    end
    box:Show()
end

function AZT.ShowInstructions()
    show(INSTR_TITLE, INSTR)
end

-- What the News button on the room view opens, newest first. Add an entry
-- for every release with a feature to show, a sentence or two each,
-- internal fixes stay in the changelog. The box shows every entry the
-- player has not read yet, so a note is never missed by skipping versions,
-- and a bump without an entry relights nothing. The whole list stays,
-- an All notes button reads it back as the archive
local NEWS = {
    {
        v = "2.1.8",
        text = "The last pull survives reloads and disconnects now, so /azt review and /azt replay"
            .. " still know your route and your death after one.",
    },
    {
        v = "2.1.6",
        text = "Every window has a size slider of its own in the |Hazt:options|h|cff71d5ffoptions|r|h,"
            .. " and the slim room view got Info and News buttons in its corners.",
    },
}

local function unseenCount()
    local seen = AztarecHelperDB.newsSeen
    for i, n in ipairs(NEWS) do
        if n.v == seen then
            return i - 1
        end
    end
    return #NEWS
end

function AZT.NewsUnseen()
    return unseenCount() > 0
end

local function newsBody(count)
    local parts = {}
    for i = 1, count do
        parts[i] = "|cffffd100" .. NEWS[i].v .. "|r  " .. NEWS[i].text
    end
    return table.concat(parts, "\n\n")
end

local function showAllNews()
    show("Release notes", newsBody(#NEWS))
end

function AZT.ShowWhatsNew()
    -- nothing missed still reads as the latest note, the button always talks
    local count = math.max(unseenCount(), 1)
    AztarecHelperDB.newsSeen = NEWS[1].v
    if count == #NEWS then
        showAllNews()
        return
    end
    show("What's new", newsBody(count), {
        leftText = "All notes",
        left = showAllNews,
        rightText = "Got it",
        right = function() end,
    })
end

-- The compass arrow changes what the arrow points at, but the voice has no
-- compass mode, it keeps talking as if you face the boss. Said once when
-- the compass is first ticked, with the choice in hand, instead of
-- silently mixing the two readings. Anyone who ran the compass before this
-- ask existed is grandfathered by the bootstrap and keeps their cue toggle
-- as it stands.
local COMPASS_TITLE = "Compass arrow and the spoken cues"
local COMPASS_CUES = "With compass arrow, the arrow points the way the room view does "
    .. "but the voices still talk as if you are facing the boss. "
    .. "Disable Solo spoken cues in options if you want the arrow to be the only cue. "

function AZT.ShowCompassCueAsk()
    AztarecHelperDB.compassCueAsked = true
    show(COMPASS_TITLE, COMPASS_CUES, {
        leftText = "Turn cues off",
        left = function()
            AztarecHelperDB.cues = false
            AZT.chat("solo spoken cues: OFF")
        end,
        rightText = "Keep the cues",
        right = function() end,
    })
end

-- Party play, offered when the role calls for it: the leader hears about
-- calling, everyone else about following. Core/Follow.lua decides when to
-- show these, once per stint in a role, and the options keep both
-- changeable at any time.
local CALL_TITLE = "Call the route for your party?"
local CALL_TEXT = "You lead this group. With calling on, your answer keys also name each"
    .. " quarter in party chat as you record, by its marker number or as a direction if you"
    .. " switch that on, and party members running the addon see your route on the boss's"
    .. " timing. The calls ride the key presses themselves, so answer with your keys, a"
    .. " click on the room view answers for you alone and says nothing. The keys work"
    .. " as before otherwise. One ask for the group: keep party chat quiet during the"
    .. " fight, since stray lines land on the followers' boards as garbage. Declining"
    .. " keeps the semi automatic mode, where you record and answer for yourself only."
    .. " Either way you can change your mind under Party in the options."

function AZT.ShowCallAsk()
    show(CALL_TITLE, CALL_TEXT, {
        leftText = "Call the route",
        left = function()
            AZT.SetCallRoute(true)
            AZT.chat("route calling: ON while you lead")
        end,
        rightText = "Stay semi automatic",
        right = function() end,
    })
end

local FOLLOW_TITLE = "Follow the leader's calls?"
local FOLLOW_TEXT = "Someone else leads this group. With following on, their route calls show"
    .. " on a board of their own and on the wave countdown, timed by the boss like always."
    .. " A leader who calls directions rather than markers gets read out loud as well, which"
    .. " is its own tickbox under Party. The addon can show the calls but never read them, so"
    .. " the arrow and the solo cues lock off while you follow,"
    .. " and any party chat during the sermon lands on the board. Declining keeps the semi"
    .. " automatic mode, where you record and answer for yourself like when solo. Either way"
    .. " you can change your mind under Party in the options."

function AZT.ShowFollowAsk()
    show(FOLLOW_TITLE, FOLLOW_TEXT, {
        leftText = "Follow the calls",
        left = function()
            AZT.SetFollow(true)
            AZT.chat("following the leader: ON")
        end,
        rightText = "Stay semi automatic",
        right = function() end,
    })
end

-- Automatic recording is offered once, in the delve and out of combat,
-- rather than switched on behind the player's back. It needs the minimap
-- set to rotate, so saying yes turns that on too when it is off.
local AUTO_TITLE = "Record the route automatically?"
local AUTO = "The route can record itself while you dodge, nothing to press during the Sermon. "
    .. "It needs your minimap rotating with you: saying yes turns that on in the delve and "
    .. "puts it back when you leave.\n\n"
    .. "One rule: keep the boss in front of you. The quarter behind you is what each wave "
    .. "records as safe.\n\n"
    .. "|cffff5a5aAddon interference:|r minimap addons that square the map or hide its border get in the way of this, "
    .. "EllesmereUI and Leatrix Plus among them. If the route records nothing, turn their "
    .. "minimap module off.\n\n"
    .. "The quarter keys, marking and calling rest while it records. The Recording switch in "
    .. "the settings flips back any time."

function AZT.ShowAutoOffer()
    show(AUTO_TITLE, AUTO, {
        leftText = "Record automatically",
        left = function()
            -- lends the rotation on its own, automatic forces it
            AZT.SetManualMode(false)
        end,
        rightText = "Keep recording by hand",
        right = function()
            AztarecHelperDB.autoAsked = true
            -- the party role ask stood aside for this box, its turn now
            if AZT.Follow then
                AZT.Follow.Sync()
            end
        end,
    })
end

-- One picture worth of how automatic reads you, shown every time it gets
-- switched on, from the offer, the settings or /azt manual. The screenshot
-- has the south quarter glowing in a red box, which is the whole lesson
local HOW_TITLE = "The quarter behind you is what counts"
local HOW = "Face the boss while you dodge. The quarter at your back, the glowing one in the "
    .. "red box here, is what the wave writes down as the safe spot. Turn your back on him "
    .. "and the wrong quarter gets written, so keep him in front of you the whole Sermon."

local EXAMPLE = { "Interface\\AddOns\\AztarecHelper\\Media\\example.png", 293, 301 }

function AZT.ShowAutoHow()
    show(HOW_TITLE, HOW, nil, EXAMPLE)
end

-- Raised over the corpse when an automatic route holds the same quarter
-- twice in a row, which the boss never calls. That is the signature of
-- dodging with your back to him, so the lesson comes with the picture
local MISREAD_TITLE = "That route could not be right"
local MISREAD = "This recording had the same safe quarter twice in a row, and the boss never "
    .. "does that. It is the mark of dodging with your back to him: the addon writes down "
    .. "the quarter behind you, so facing the wrong way files you into the wrong quarter "
    .. "and the echoes send you somewhere false.\n\n"
    .. "Keep the boss in front of you for the whole Sermons every single wave."

-- The corpse showings are counted, and from the third one the box offers
-- to shut up for good, since by then the reader has either learned the
-- lesson or decided against it. The Recording problems button and
-- /azt badroute stay outside the count and keep working muted
function AZT.ShowMisreadWarning(fromDeath)
    if fromDeath then
        if AztarecHelperDB.misreadMuted then
            return
        end
        AztarecHelperDB.misreadSeen = (AztarecHelperDB.misreadSeen or 0) + 1
        if AztarecHelperDB.misreadSeen >= 3 then
            show(MISREAD_TITLE, MISREAD, {
                leftText = "Stop telling me",
                left = function()
                    AztarecHelperDB.misreadMuted = true
                    AZT.chat("the misrecorded route warning is muted - /azt badroute reads it any time")
                end,
                rightText = "Got it",
                right = function() end,
            }, EXAMPLE)
            return
        end
    end
    show(MISREAD_TITLE, MISREAD, nil, EXAMPLE)
end

-- The facing reader found the compass ring frozen: nothing turned it in 25
-- seconds of the player being in the delve, so automatic has nothing to
-- read. Shown once a session, with the minimap addons it can see loaded
-- named, since one of them hiding or replacing the ring is nearly always it
local RING_TITLE = "Automatic recording cannot see your facing"

function AZT.ShowRingWarning(loaded)
    local culprit
    if #loaded > 0 then
        culprit = "Loaded right now: " .. table.concat(loaded, ", ") .. ". "
    else
        culprit = "None of the ones this addon knows by name are loaded, but any minimap addon or skin counts. "
    end
    local text = "Your minimap's compass ring has not turned for a while, and that ring is the only "
        .. "place the addon can read which way you face in here. If you were standing still the "
        .. "whole time, that is all this is, spin once and it comes alive.\n\n"
        .. "If you were moving, a minimap addon that squares the map, hides its border or replaces "
        .. "the compass is the usual cause, Leatrix Plus, EllesmereUI's minimap module, SexyMap and "
        .. "the like. "
        .. culprit
        .. "Turn its minimap module off, reload, and set Recording to Automatic again.\n\n"
        .. "Or keep your minimap as it is and record by hand, a quarter key or a click per wave."
    show(RING_TITLE, text, {
        leftText = "Record by hand",
        left = function()
            AZT.SetManualMode(true)
        end,
        rightText = "I was idle, check again",
        right = function()
            AZT.Safe.RearmRing()
        end,
    })
end

-- the ring turned after all, so the box has nothing true left to say. Only
-- this box goes, the frame is shared with the instructions and the offers
function AZT.HideRingWarning()
    if box and box:IsShown() and box.title:GetText() == RING_TITLE then
        box:Hide()
    end
end

local ef = CreateFrame("Frame")
ef:RegisterEvent("PLAYER_ENTERING_WORLD")
ef:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ef:SetScript("OnEvent", function()
    if not AZT.InDelve() then
        return
    end
    -- the party role ask waits its turn behind this one, one box at a time
    if not AztarecHelperDB.autoAsked and not AZT.Safe.IsAuto() then
        AZT.ShowAutoOffer()
    end
end)
