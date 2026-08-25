-- Azta'rec Helper, copyright 2026 Rothirr, all rights reserved.
-- Read it if you want. Copying any of it into another addon is theft, and
-- running it through an AI tool first does not change that. The timings and
-- coordinates were measured by hand. Nothing here is licensed to anyone.

local _, AZT = ...

-- Safe-spot tracking for the Azta'rec wave mechanic. While the boss channels,
-- a capture window opens per wave on the measured hit grid and the player
-- keys the quarter they run to. When the hidden echoes start right after the
-- channel, each cast start calls the recording back.

local Safe = {}
AZT.Safe = Safe

BINDING_HEADER_AZTARECHELPER = "Azta'rec Helper"
-- display names only. The MARK command ids stay, renaming those drops keybinds
BINDING_NAME_AZTARECHELPER_MARK_NORTH = "Azta'rec Helper: answer north"
BINDING_NAME_AZTARECHELPER_MARK_EAST = "Azta'rec Helper: answer east"
BINDING_NAME_AZTARECHELPER_MARK_SOUTH = "Azta'rec Helper: answer south"
BINDING_NAME_AZTARECHELPER_MARK_WEST = "Azta'rec Helper: answer west"

local seq = {} -- the route as quarters, which is what everything else reads
local steps = {} -- what the player actually answered, quarters or turns
local top = 0 -- highest wave the route knows of, answered or closed
local armed = false

-- capture state
local ticker
local winIdx = 0
local chanStartT = 0
-- per-difficulty cone hit grids (offsets after CHAN_START), measured via
-- deliberate deaths on the PTR. Both difficulties end the channel ~0.5s
-- after the last hit. Wave count grows per channel, so windows keep opening
-- until the channel actually stops.
local GRIDS = {
    [3508] = { first = 3.04, spacing = 3.5 }, -- "?"
    [3525] = { first = 2.50, spacing = 3.01 }, -- "??"
}
local grid = GRIDS[3508]
local MAX_WAVES = 10
local LOCK_DELAY = 0.8 -- the window closes this long after its hit
local chanUnit = nil -- unit token that ran the channel, its casts are the echoes
local capturing = false -- a channel is being recorded
local lastPull -- most recent recorded route, kept for review and replay
local practiceTicker -- non-nil while a practice sermon runs

local REPLAY_LEAD = 1.8 -- pause before a replay's first wave
local REPLAY_TAIL = 1.8 -- how long the last replay wave stays lit

-- what the wave countdown renders. One table, fields overwritten in place.
local wave = { phase = nil, idx = 0, total = nil, at = nil }
AZT.Wave = wave

local function setWave(phase, idx, total, at, startedAt, gap)
    wave.phase, wave.idx, wave.total, wave.at = phase, idx, total, at
    -- when the echo started and how long the last one ran. The encounter
    -- hides cast end times, so this pair is the only handle on when the
    -- next call is due.
    wave.startedAt, wave.gap = startedAt, gap
    if AZT.WaveSync then
        AZT.WaveSync()
    end
    if AZT.ArrowSync then
        AZT.ArrowSync()
    end
    if AZT.QuadClickSync then
        AZT.QuadClickSync()
    end
    if AZT.FollowSync then
        AZT.FollowSync()
    end
end

local function hitTime(i)
    return grid.first + grid.spacing * (i - 1)
end

-- echo state
local echoIdx = 0
local echoUntil = 0
local lastEchoAdvance = 0

-- cardinal quarters, each spanning the 90 degrees centered on its name
local QUADRANTS = { "N", "E", "S", "W" }

function Safe.GetSequence()
    return seq
end

local function seqText()
    return #seq > 0 and table.concat(seq, "  >  ") or "?"
end

local QUAD_INDEX = {}
for i, q in ipairs(QUADRANTS) do
    QUAD_INDEX[q] = i
end
local TURNS = { [0] = "stay", "left", "forward", "right" }

-- Where the safe quarter is from the player's view, assuming they are looking
-- at the boss in the middle. The far quarter is straight through him.
function Safe.TurnFromTo(from, to)
    local a, b = QUAD_INDEX[from], QUAD_INDEX[to]
    if not a or not b then
        return nil
    end
    return TURNS[(b - a) % 4]
end

local TURN_OFFSET = {}
for i, t in pairs(TURNS) do
    TURN_OFFSET[t] = i
end

-- and the way back, for routes answered as turns: the quarter that move
-- lands you in, again from the view of someone facing the middle
local function quadFromTurn(from, turn)
    local a, off = QUAD_INDEX[from], TURN_OFFSET[turn]
    if not a or not off then
        return nil
    end
    return QUADRANTS[(a - 1 + off) % 4 + 1]
end

--#region Facing

-- Where the player is looking. The delve stopped handing out coordinates in
-- 12.1, but the minimap still spins with the player when they have it set to
-- rotate, and the compass ring's own rotation reads back plain. Measured on
-- 2026-08-05: the ring sits at minus the facing with no offset, so undoing
-- the sign is the whole conversion.
local TAU = 2 * math.pi

local function plainNum(v)
    if type(v) ~= "number" then
        return nil
    end
    if not pcall(function()
        return v + 0
    end) then
        return nil
    end
    return v
end

-- A ring that never turns reads exactly like standing due north, which is
-- the one failure that would record a whole pull of wrong quarters instead
-- of admitting it knows nothing. So a reading counts only once the ring has
-- been seen moving. After that a still player is just a still player.
local RING_PROVE = 25 -- a ring that has not moved in this long has never moved
local ringRot, ringSince, ringLive, ringWarned

-- Minimap skins hide the compass ring, and a ring that is not visible stops
-- turning. Leatrix Plus hides the texture itself, EllesmereUI hides
-- MinimapBackdrop above it, which takes the ring with it however the texture's
-- own flag reads (measured 2026-08-19: shown true, parent hidden, rotation
-- frozen at 0, parent shown and it turned). In the delve the texture and
-- every hidden ancestor above it are kept shown but fully transparant while
-- the facing is wanted, and put back on the way out. A skin that reapplies
-- itself (EllesmereUI does after every fight) hides them again under the
-- lend, and a frozen ring would read as a player standing still, so the
-- lend is reasserted on every reading rather than trusted once
local lent = {} -- region -> the alpha it had, for every region shown on loan

-- SexyMap with its north tag off swaps the method on the texture itself,
-- MinimapCompassTexture.Show = MinimapCompassTexture.Hide, so calling
-- r:Show() through the object would hide the ring for it. Lent regions are
-- shown through the real method off the frame metatable, which an addon
-- can only shadow on the object, never replace underneath
local function show(r)
    local mt = getmetatable(r)
    local real = mt and type(mt.__index) == "table" and mt.__index.Show or r.Show
    real(r)
end

local function lendCompass()
    if not AZT.InDelve() then
        return
    end
    local r = MinimapCompassTexture
    while r and r ~= UIParent do
        if not r:IsShown() then
            if lent[r] == nil then
                lent[r] = r:GetAlpha()
                r:SetAlpha(0)
            end
            show(r)
        end
        r = r:GetParent()
    end
end

local function returnCompass()
    for r, alpha in pairs(lent) do
        r:Hide()
        r:SetAlpha(alpha)
    end
    wipe(lent)
end

local relentWarned
local rotateSeenOn -- rotation has been on during this visit, so off now means something flipped it

function Safe.RingFacing()
    if not MinimapCompassTexture then
        return nil
    end
    if GetCVar("rotateMinimap") == "1" then
        if AZT.InDelve() then
            rotateSeenOn = true
        end
    else
        -- a skin that writes its own rotation setting on every reapply
        -- (EllesmereUI at login and after each fight) turns the rotation
        -- back off under us, lent or the player's own. While the delve wants
        -- it rotating it goes back on whoever turned it off, and counts as
        -- lent so it is returned on the way out. Only once it has been seen
        -- on this visit though, so the entry sync gets to lend it first
        if not (rotateSeenOn and AZT.DelveRotate() and AZT.InDelve()) then
            return nil
        end
        C_CVar.SetCVar("rotateMinimap", "1")
        AztarecHelperDB.rotateLent = true
        if not relentWarned then
            relentWarned = true
            AZT.chat(
                "something keeps turning the minimap rotation off, a minimap addon most likely - it is back on for the delve"
            )
        end
    end
    lendCompass()
    local ok, rot = pcall(MinimapCompassTexture.GetRotation, MinimapCompassTexture)
    rot = ok and plainNum(rot) or nil
    if not rot then
        return nil
    end
    local now = GetTime()
    if ringRot == nil then
        ringRot, ringSince = rot, now
    elseif rot ~= ringRot then
        ringRot, ringSince = rot, now
        -- a ring that was given up on and turns after all takes its box
        -- down, the player fixed the minimap or spun to check
        if ringWarned and not ringLive then
            AZT.HideRingWarning()
            AZT.chat("the compass ring is turning, automatic recording can see your facing again")
        end
        ringLive = true
    elseif not ringLive and now - ringSince > RING_PROVE then
        -- said once, and never into a fight, the reader runs every frame
        -- and picks it up again when the fight is over
        if not ringWarned and AZT.InDelve() and not AZT.Fighting() then
            ringWarned = true
            AZT.chat("your minimap compass ring is not turning, so nothing here can tell which way you face")
            -- by hand only loses the turning room view, automatic loses the
            -- whole recording, so the box is for automatic
            if Safe.IsAuto() then
                AZT.ShowRingWarning(Safe.LoadedMinimapAddons())
            end
        end
        return nil
    end
    return -rot % TAU
end

-- the box's "I was idle" answer: the ring gets another RING_PROVE to show
-- it turns before the box comes back
function Safe.RearmRing()
    ringWarned = false
    ringSince = GetTime()
end

-- minimap addons known to touch the ring or the rotation, named in the
-- warning and the report so the player knows what to switch off
local MINIMAP_ADDONS = {
    "EllesmereUIMinimap",
    "EUIStandaloneMinimap",
    "Leatrix_Plus",
    "ElvUI",
    "SexyMap",
    "BetterMinimap",
    "BasicMinimap",
    "Chinchilla",
}

function Safe.LoadedMinimapAddons()
    local loaded = {}
    for _, name in ipairs(MINIMAP_ADDONS) do
        if C_AddOns.IsAddOnLoaded(name) then
            loaded[#loaded + 1] = name
        end
    end
    return loaded
end

-- /azt ring: what the facing reader sees, for reports of the room view
-- not turning. Every value here is the addon's own or a plain client
-- setting, safe to print in a fight
function Safe.RingReport()
    local tex = MinimapCompassTexture
    AZT.chat(
        ("ring report: recording %s, rotateMinimap=%s, in delve %s, rotation lent %s"):format(
            Safe.IsAuto() and "automatic" or "by hand",
            tostring(GetCVar("rotateMinimap")),
            tostring(AZT.InDelve()),
            tostring(AztarecHelperDB.rotateLent or false)
        )
    )
    if not tex then
        AZT.chat("ring: MinimapCompassTexture is missing on this client")
        return
    end
    local function deg(rad, none)
        return rad and ("%d deg"):format(math.floor(math.deg(rad) + 0.5)) or none
    end
    local ok, rot = pcall(tex.GetRotation, tex)
    AZT.chat(
        ("ring: shown %s, visible %s, alpha %.2f, rotation %s, seen moving %s, facing %s"):format(
            tostring(tex:IsShown()),
            tostring(tex:IsVisible()),
            tex:GetAlpha(),
            deg(ok and plainNum(rot), "unreadable"),
            tostring(ringLive or false),
            deg(Safe.RingFacing(), "none")
        )
    )
    local loaded = Safe.LoadedMinimapAddons()
    AZT.chat("minimap addons loaded: " .. (#loaded > 0 and table.concat(loaded, ", ") or "none of the known ones"))
end

-- The boss holds the middle through the whole channel and the player is
-- looking at him, so the quarter they stand in is the one behind them.
function Safe.RingQuadrant()
    local f = Safe.RingFacing()
    if not f then
        return nil
    end
    local behind = (180 - math.deg(f)) % 360
    return QUADRANTS[math.floor(((behind + 45) % 360) / 90) + 1]
end

-- by hand unless the player took the automatic offer. A practice drill is a
-- keys drill wherever it runs, so it reads as by hand too
function Safe.IsAuto()
    return not AztarecHelperDB.manualMode and not practiceTicker
end

function Safe.CanAuto()
    return Safe.RingFacing() ~= nil
end

-- Whether the minimap should rotate while the player is in the delve.
-- Automatic recording cannot read the facing without it, so it forces the
-- answer. By hand it is the player's setting, for a room view that turns
-- with them and an arrow that aims from where they stand
function AZT.DelveRotate()
    return Safe.IsAuto() or AztarecHelperDB.delveRotate or false
end

-- The rotation is the player's setting, so the addon only ever lends it: a
-- minimap it turned on for the delve goes back to still when they leave.
-- rotateLent lives in the saved variables so a reload or a crash inside the
-- delve still puts it back
function AZT.LendRotation()
    if GetCVar("rotateMinimap") ~= "1" then
        C_CVar.SetCVar("rotateMinimap", "1")
        AztarecHelperDB.rotateLent = true
        AZT.chat("minimap set to rotate while you are in the delve, it goes back when you leave")
    end
end

-- runs on every zone change and whenever the mode or the setting flips, so
-- the rotation follows the wish right away: lent on the way in and on a
-- flip to on, returned on the way out and on a flip to off
function Safe.RotateSync()
    if AZT.InDelve() and AZT.DelveRotate() then
        AZT.LendRotation()
        return
    end
    returnCompass()
    rotateSeenOn = false
    if AztarecHelperDB.rotateLent then
        AztarecHelperDB.rotateLent = nil
        C_CVar.SetCVar("rotateMinimap", "0")
        AZT.chat("minimap rotation put back the way it was")
    end
end

function AZT.SetDelveRotate(v)
    AztarecHelperDB.delveRotate = v and true or false
    Safe.RotateSync()
    if AZT.RefreshOptions then
        AZT.RefreshOptions()
    end
end

-- one owner for the switch, since the slash command, the options panel and
-- the offer box all flip it
function AZT.SetManualMode(v)
    AztarecHelperDB.manualMode = v and true or false
    -- an explicit choice either way, so the entry offer has nohting to ask
    AztarecHelperDB.autoAsked = true
    Safe.Reset()
    -- the board shows keys and click targets for hand recording only
    if AZT.QuadClickSync then
        AZT.QuadClickSync()
    end
    -- marking and calling ride the answer keys, which are idle in automatic,
    -- so they go off with it rather than sit on and silent
    if not v and (AztarecHelperDB.keysMark or AztarecHelperDB.callRoute) then
        AztarecHelperDB.keysMark = false
        if AztarecHelperDB.callRoute then
            AZT.SetCallRoute(false)
        end
        AZT.chat("marking and calling: OFF - they need the keys, which belong to recording by hand")
    end
    AZT.MarkKeysSync()
    if AZT.RefreshOptions then
        AZT.RefreshOptions()
    end
    -- automatic forces the rotation and by hand may not want it, so the
    -- minimap follows the mode right now
    Safe.RotateSync()
    if v then
        AZT.chat("recording by hand, press a quarter key at each wave")
    else
        AZT.chat("recording itself again")
        -- the picture page: which quarter gets written down. Every switch
        -- to automatic earns it, from the offer box this reads as page two
        AZT.ShowAutoHow()
    end
end

--#endregion

--#region Capture

local function stopTicker()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
end

-- Rebuild the quarters out of what was answered. A quarter answer stands on
-- its own, a turn only means something next to the wave before it, so the
-- whole route is walked again rather than patched at one index. That is what
-- lets a first wave answered late place every turn that was pressed behind it.
local function resolve()
    local prev
    for i = 1, top do
        local step = steps[i]
        local q
        if QUAD_INDEX[step] then
            q = step
        elseif step and prev then
            q = quadFromTurn(prev, step)
        end
        if q then
            seq[i] = q
        end
        prev = q
    end
end

local function clearRoute()
    wipe(seq)
    wipe(steps)
    top = 0
end

-- a wave the boss has moved past. Whatever is in it now is what it keeps
local function closeWindow(i)
    if seq[i] == nil then
        seq[i] = "?"
    end
    if i > top then
        top = i
    end
end

-- keep a copy of the route for review and replay, since the live table gets
-- wiped the moment the next channel starts. The copy also goes into the SV,
-- with later death details riding the same table, so review and replay
-- reach back past a reload or a disconnect
local function snapshotPull()
    if #seq == 0 then
        return
    end
    lastPull = { seq = {}, grid = grid, death = nil }
    for i, q in ipairs(seq) do
        lastPull.seq[i] = q
    end
    AztarecHelperDB.lastPull = lastPull
end

function Safe.RestorePull()
    lastPull = AztarecHelperDB.lastPull
end

-- every edit to the route fans out through here: the room view, except
-- during a drill where the drill itself drives it, and the route board,
-- which reads the real sequence drill or not
local function pushSeq(idx)
    if AZT.SetSafeQuads and not practiceTicker then
        AZT.SetSafeQuads(seq, idx)
    end
    if AZT.FollowSync then
        AZT.FollowSync()
    end
end

-- the window walk. The ticker advances the wave index for the countdown
-- display and closes windows the player never answered, every spot comes fromt
-- the quarter keys.
local function beginCapture(unit)
    stopTicker()
    clearRoute()
    chanUnit = unit
    chanStartT = GetTime()
    capturing = true
    winIdx = 1
    pushSeq()
    ticker = C_Timer.NewTicker(0.2, function()
        if winIdx > MAX_WAVES then
            return
        end
        local elapsed = GetTime() - chanStartT
        setWave("record", winIdx, nil, chanStartT + hitTime(winIdx))
        if elapsed >= hitTime(winIdx) + LOCK_DELAY then
            -- the window shuts a beat after its wave, which is where the
            -- player is standing when it lands and before they run for the
            -- next one
            if Safe.IsAuto() then
                seq[winIdx] = Safe.RingQuadrant() or "?"
                AZT.Log(("WINDOW %d locked %s"):format(winIdx, seq[winIdx]))
            elseif steps[winIdx] == nil then
                AZT.Log(("WINDOW %d closed with no input"):format(winIdx))
            end
            closeWindow(winIdx)
            winIdx = winIdx + 1
            pushSeq()
        end
    end)
    -- the moment it matters. A channel starting with no facing means this
    -- pull records nothing, and finding that out afterwards is too late
    if Safe.IsAuto() and not Safe.CanAuto() then
        AZT.chat("cannot see which way you face, so this channel will record as unknown")
    end
    AZT.Log(Safe.IsAuto() and "CAPTURE open - recording on its own" or "CAPTURE open - answer each wave")
end

local function finishCapture()
    capturing = false
    if not ticker then
        return
    end
    stopTicker()
    local elapsed = GetTime() - chanStartT
    if elapsed < 8 then
        -- real wave channels run 10.5s or longer. Something shorter slipped
        -- through the filters (or the boss died) - discard, don't replay
        AZT.Log(("CHANNEL discarded after %.1fs - not the wave mechanic"):format(elapsed))
        Safe.Reset()
        return
    end
    -- close out to the last hit that landed. The last wave's window is
    -- usually still open when the channel stops, so it gets read here.
    -- Anything with nothing behind it stays "?" and its echo shows as
    -- unknown rather than as a guess.
    while winIdx <= MAX_WAVES and hitTime(winIdx) <= elapsed + 0.6 do
        if Safe.IsAuto() then
            seq[winIdx] = Safe.RingQuadrant() or seq[winIdx]
        end
        closeWindow(winIdx)
        winIdx = winIdx + 1
    end
    AZT.Log(("CAPTURE closed after %.1fs: %s"):format(elapsed, seqText()))
    pushSeq()
    snapshotPull()
    setWave(nil, 0, nil, nil)
    echoIdx = 0
    echoUntil = GetTime() + 10 + 5 * #seq
    lastEchoAdvance = 0
    -- if the run goes stale (the boss stopped echoing short of the full
    -- route), clear the display rather than keep pointing at a wave that is
    -- never coming. A newer channel makes this timer a no-op.
    local window = echoUntil
    C_Timer.NewTimer(10 + 5 * #seq + 2, function()
        if not capturing and echoUntil == window and echoIdx < #seq then
            Safe.Reset()
        end
    end)
end

-- an answer, stored as it was given and read back as a quarter
local function fillSpot(i, step, caught)
    steps[i] = step
    if i > top then
        top = i
    end
    resolve()
    -- a turn with no answered wave behind it has no quarter yet, so it reads
    -- as unknown until one arrives
    local q = seq[i] or "?"
    AZT.Log(("SAFESPOT answered %d = %s -> %s%s"):format(i, step, q, caught and " (caught up)" or ""))
    AZT.chat(("safe spot %d: %s"):format(i, AZT.QuadName(q, 14)))
    pushSeq(echoIdx > 0 and echoIdx or nil)
    if AZT.FlashQuad then
        AZT.FlashQuad(q)
    end
end

-- Which wave an answer belongs to. Answers land in order: the earliest wave
-- still unanswered takes the press, and nothing can be answered before its
-- wave has happened, so missing one and tapping twice gets you level again
-- instead of shifting the whole route. A wave still blank when the echoes
-- start can be filled right up until its own echo plays. Nothing back means
-- there is no wave waiting for one.
local function answerIndex()
    -- how far the boss has actually got: the open window while the channel
    -- runs, the whole recorded route once it has stopped
    local limit = capturing and math.min(winIdx, MAX_WAVES) or top
    for i = 1, limit do
        if seq[i] == nil or seq[i] == "?" then
            return i, i < limit
        end
    end
    if capturing and limit >= 1 then
        -- level with the boss, so the press corrects the wave in front of you
        return limit, false
    end
end

-- Outside the pull an answer appends instead, for walking a route in by hand
-- between pulls. During the pull a press with nothing left to answer does
-- nothing at all.
local function place(step, i, caught)
    if not i then
        -- mid-pull a stray press must never grow the route, the gap between
        -- the channel and the first echo would happily take an append otherwise
        if armed or echoIdx > 0 then
            return
        end
        -- a turn cannot open a route, there is no wave behind it to turn from
        if top == 0 and not QUAD_INDEX[step] then
            return
        end
        if top >= MAX_WAVES then
            clearRoute()
        end
        i = top + 1
    end
    -- The safe spot never lands in the same quarter twice running, so an
    -- answer matching either neighbour is a slipped press rather than a route.
    -- Turns cannot express a repeat, this only ever catches a quarter, and
    -- the wave after only exists when an older hole is being backfilled
    if seq[i - 1] == step or seq[i + 1] == step then
        AZT.chat(("wave %d cannot repeat the quarter next to it, so that press was dropped"):format(i))
        return
    end
    fillSpot(i, step, caught)
end

local autoHinted = false

-- The keys are bound account wide and would happily walk a route in from
-- the middle of Dornogal, chatting about safe spots all the way. Answers
-- only count in the delve, or while a practice sermon runs anywhere. And
-- the route belongs to whichever mode is running: in automatic that is the
-- addon, so a press there means the player expected otherwise and is told
-- once rather than every wave.
local function answering()
    if practiceTicker then
        return true
    end
    if not AZT.InDelve() then
        return false
    end
    if Safe.IsAuto() then
        if not autoHinted and not capturing then
            autoHinted = true
            AZT.chat("recording itself right now, set Recording to By hand in the options to answer the waves yourself")
        end
        return false
    end
    return true
end

-- the player names the quarter outright, no position read anywhere
function Safe.CaptureQuadrant(q)
    if not QUAD_INDEX[q] or not answering() then
        return
    end
    place(q, answerIndex())
end

-- What each quarter key means once the keys answer relative turns. The room
-- is read north up, so the key that says north is the one that says straight
-- through the boss, and south would be staying put.
local KEY_TURN = { N = "forward", E = "right", S = "stay", W = "left" }

local DOUBLE_TAP = 1.2 -- a second press of the same key inside this is a slip
local lastKey, lastKeyAt

-- The keybinds, their slash shortcuts and the secure mark buttons all answer
-- through here. Room view clicks do not: a click lands on a quarter of the
-- room, so it names that quarter whatever the keys are set to mean.
function Safe.AnswerKey(q)
    if not QUAD_INDEX[q] or not answering() then
        return
    end
    local nowT = GetTime()
    -- waves sit 3s apart at the very tightest, so the same key twice inside a
    -- second is one fumbeld press. Left alone the second half of it spills
    -- into the next window and writes a wave the boss never called
    if q == lastKey and nowT - lastKeyAt < DOUBLE_TAP then
        AZT.Log("KEY " .. q .. " dropped, double tap")
        return
    end
    lastKey, lastKeyAt = q, nowT
    local i, caught = answerIndex()
    -- the opening wave has nothing behind it to turn from, so it names its
    -- quarter outright even while the rest of the route is answered as turns
    if AztarecHelperDB.relativeTurns and i and i > 1 then
        local turn = KEY_TURN[q]
        if turn == "stay" then
            AZT.chat("the safe spot never stays put, so south answers nothing after the first wave")
            return
        end
        place(turn, i, caught)
        return
    end
    place(q, i, caught)
end

-- globals for Bindings.xml, one per quarter
function AztarecHelper_MarkNorth()
    Safe.AnswerKey("N")
end

function AztarecHelper_MarkEast()
    Safe.AnswerKey("E")
end

function AztarecHelper_MarkSouth()
    Safe.AnswerKey("S")
end

function AztarecHelper_MarkWest()
    Safe.AnswerKey("W")
end

function Safe.Reset()
    stopTicker()
    Safe.StopReplay()
    -- a real pull starting mid-drill lands here too, the fight wins
    if practiceTicker then
        practiceTicker:Cancel()
        practiceTicker = nil
    end
    -- a room view the drill or replay opened goes back with it
    if AZT.ReleaseRoomView then
        AZT.ReleaseRoomView()
    end
    clearRoute()
    chanUnit = nil
    capturing = false
    winIdx = 0
    echoIdx = 0
    echoUntil = 0
    setWave(nil, 0, nil, nil)
    if AZT.SetSafeQuads then
        AZT.SetSafeQuads(seq)
    end
end

function Safe.IsArmed()
    return armed
end

--#endregion

--#region Review

function Safe.Review()
    if not lastPull then
        AZT.chat("nothing recorded yet - pull the boss once first")
        return
    end
    local parts, missed = {}, 0
    for i, q in ipairs(lastPull.seq) do
        parts[i] = AZT.QuadName(q, 14)
        if q == "?" then
            missed = missed + 1
        end
    end
    AZT.chat("last pull: " .. table.concat(parts, "  >  "))
    if missed > 0 then
        AZT.chat(("? = a wave you never answered, %d of them this pull"):format(missed))
    end
    local d = lastPull.death
    if not d then
        return
    end
    if d.phase == "echo" and d.safe == "?" then
        AZT.chat(("you died in echo %d, the one wave you never answered"):format(d.wave))
    elseif d.phase == "echo" and d.safe then
        AZT.chat(("you died in echo %d - safe was %s"):format(d.wave, AZT.QuadName(d.safe, 14)))
    elseif d.phase == "wave" then
        AZT.chat(("you died during wave %d of the channel"):format(d.wave))
    else
        AZT.chat("you died between the waves and the echoes")
    end
end

--#endregion

--#region Replay

local replayTicker

function Safe.StopReplay()
    if not replayTicker then
        return
    end
    replayTicker:Cancel()
    replayTicker = nil
    setWave(nil, 0, nil, nil)
    if AZT.SetSafeQuads then
        AZT.SetSafeQuads(seq)
    end
    if AZT.ReleaseRoomView then
        AZT.ReleaseRoomView()
    end
end

-- shared front door for both replay flavors: a second click stops the run
-- that is going, and nothing starts during the pull. Says whether the
-- caller may start a fresh run.
local function replayGate()
    if armed then
        AZT.chat("not during the pull")
        return false
    end
    if replayTicker then
        Safe.StopReplay()
        AZT.chat("replay stopped")
        return false
    end
    return true
end

-- walk a route across the room view on its real wave cadence. Display
-- only, the live capture state stays untouched.
local function runReplay(list, g)
    local startT = GetTime() + REPLAY_LEAD
    local shown = 0
    if AZT.EnsureRoomView then
        AZT.EnsureRoomView()
    end
    replayTicker = C_Timer.NewTicker(0.18, function()
        local nowT = GetTime()
        local due = 0
        if nowT >= startT then
            due = math.floor((nowT - startT) / g.spacing) + 1
        end
        if due > #list then
            if nowT >= startT + #list * g.spacing + REPLAY_TAIL then
                Safe.StopReplay()
                AZT.chat("replay done")
            end
            return
        end
        if due > shown then
            shown = due
            setWave("replay", due, #list, startT + due * g.spacing)
            if AZT.SetSafeQuads then
                AZT.SetSafeQuads(list, due)
            end
            if AZT.Cue then
                -- no landing time, so it speaks now as a real pull does
                AZT.Cue(list[due], nil, due > 1 and list[due - 1] or list[#list])
            end
        end
    end)
end

-- practice run between pulls, over what the last pull recorded
function Safe.Replay()
    if not replayGate() then
        return
    end
    if not lastPull or #lastPull.seq == 0 then
        AZT.chat("nothing recorded yet - pull the boss once first")
        return
    end
    AZT.chat(("replaying the last route (%d waves) - move along with it, or just watch"):format(#lastPull.seq))
    runReplay(lastPull.seq, lastPull.grid or grid)
end

--#endregion

--#region Practice

-- A pretend sermon, so the whole loop can be drilled without the boss. The
-- room view plays the ground's part, the safe quarter green and the other
-- three red, and the player answers with their keys or clicks like a real
-- pull. The echoes that follow are whatever they recorded. Input runs
-- through the real capture machinery, so relative turns and the press
-- guards behave exactly as they do in the fight.

local PRACTICE_WAVES = 7 -- the longest phase "??" reaches

local function randomRoute(n)
    local route = {}
    local at = math.random(4)
    for i = 1, n do
        route[i] = QUADRANTS[at]
        -- any quarter but the one just used, the boss never repeats
        at = (at - 1 + math.random(3)) % 4 + 1
    end
    return route
end

local function endPractice(route)
    practiceTicker:Cancel()
    practiceTicker = nil
    stopTicker()
    capturing = false
    local right = 0
    for i, q in ipairs(route) do
        if seq[i] == q then
            right = right + 1
        end
    end
    AZT.chat(("practice sermon over, %d of %d answered right - playing your recording back"):format(right, #route))
    snapshotPull()
    setWave(nil, 0, nil, nil)
    runReplay(lastPull.seq, grid)
end

local function startDrill()
    local route = randomRoute(PRACTICE_WAVES)
    beginCapture(nil)
    -- the capture repaints hold off while the drill runs, so the target
    -- colors only need painting when the wave moves on
    local shown = 0
    local function paint()
        shown = winIdx
        if AZT.SetSafeQuads then
            AZT.SetSafeQuads({ route[winIdx] }, 1)
        end
        if AZT.FlashQuad then
            AZT.FlashQuad(route[winIdx])
        end
    end
    practiceTicker = C_Timer.NewTicker(0.2, function()
        if winIdx > #route then
            endPractice(route)
            return
        end
        if winIdx > shown then
            paint()
        end
    end)
    paint()
end

local PRACTICE_LEAD = 3 -- countdown seconds, time to get hands on the keys

function Safe.Practice()
    if practiceTicker then
        Safe.Reset()
        AZT.chat("practice stopped")
        return
    end
    if not replayGate() then
        return
    end
    if AZT.EnsureRoomView then
        AZT.EnsureRoomView()
    end
    AZT.chat("practice sermon - green is safe, answer each wave like a real pull")
    if AztarecHelperDB.relativeTurns then
        AZT.chat("your keys answer relative turns, first wave excepted")
    else
        AZT.chat("your keys answer compass quarters")
    end
    AZT.chat(("starting in %d"):format(PRACTICE_LEAD))
    local left = PRACTICE_LEAD
    practiceTicker = C_Timer.NewTicker(1, function()
        left = left - 1
        if left > 0 then
            AZT.chat(tostring(left))
            return
        end
        practiceTicker:Cancel()
        startDrill()
    end)
end

--#endregion

--#region Events

local ENCOUNTER_IDS = { [3508] = "? (normal)", [3525] = "?? (hard)" }

-- Boss casts arrive on nameplateN units only when enemy nameplates are
-- enabled. BossN frames fire regardless, so both token kinds are accepted
-- (the seen-first token wins and the chanUnit filter drops the duplicate).
local function hostileUnit(unit)
    if type(unit) ~= "string" then
        return false
    end
    if unit:match("^boss%d$") then
        return true
    end
    if not unit:match("^nameplate%d+$") then
        return false
    end
    local ok, hostile = pcall(UnitCanAttack, "player", unit)
    if not ok or (issecretvalue and issecretvalue(hostile)) then
        return false
    end
    return hostile and true or false
end

local ef = CreateFrame("Frame")
ef:SetScript("OnEvent", function(_, event, ...)
    local ok, err = pcall(function(...)
        if event == "ENCOUNTER_START" then
            local id, name = ...
            if ENCOUNTER_IDS[id] or (type(name) == "string" and name:find("Azta")) then
                armed = true
                grid = GRIDS[id] or GRIDS[3508]
                Safe.Reset()
                ef:RegisterEvent("PLAYER_DEAD")
                AZT.chat(
                    ("Azta'rec pulled - encounter %s = %s"):format(
                        tostring(id),
                        ENCOUNTER_IDS[id] or "unknown difficulty"
                    )
                )
            end
        elseif event == "ENCOUNTER_END" then
            armed = false
            ef:UnregisterEvent("PLAYER_DEAD")
            -- the pull is over, wipe or kill, so clear the board rather than
            -- leave a dead run up. Review and replay keep their own copy,
            -- taken before this fires
            Safe.Reset()
        elseif event == "PLAYER_DEAD" then
            snapshotPull()
            if lastPull then
                local d = {}
                if capturing then
                    d.phase, d.wave = "wave", math.max(winIdx, 1)
                elseif echoIdx > 0 then
                    d.phase, d.wave = "echo", echoIdx
                end
                d.safe = d.wave and lastPull.seq[d.wave] or nil
                lastPull.death = d
                -- the boss never calls the same quarter twice running, so a
                -- doubled quarter in an automatic route means the facing
                -- read lied, and facing away from the boss is how. Said
                -- over the corpse, when the lesson lands best. The box
                -- counts its corpse showings and mutes itself on request
                if Safe.IsAuto() then
                    for i = 2, #lastPull.seq do
                        local q = lastPull.seq[i]
                        if q ~= "?" and q == lastPull.seq[i - 1] then
                            AZT.ShowMisreadWarning(true)
                            break
                        end
                    end
                end
            end
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
            local unit = ...
            if not armed or not hostileUnit(unit) then
                return
            end
            if capturing and chanUnit and unit ~= chanUnit then
                -- only the real boss channels, so the same channel arriving on
                -- a boss token is the same unit - adopt the sturdier token
                -- (boss frames never despawn mid-encounter but nameplates can)
                if unit:match("^boss%d$") and not chanUnit:match("^boss%d$") then
                    AZT.Log("CHANNELER token upgraded " .. chanUnit .. " -> " .. unit)
                    chanUnit = unit
                else
                    -- never wipe a capture in progress for another unit's channel
                    AZT.Log("CHANNEL from " .. unit .. " ignored - capture already running")
                end
                return
            end
            beginCapture(unit)
        elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            local unit = ...
            if armed and hostileUnit(unit) and (not chanUnit or unit == chanUnit) then
                finishCapture()
            end
        elseif event == "UNIT_SPELLCAST_START" then
            if not armed then
                return
            end
            local unit = ...
            if not hostileUnit(unit) then
                return
            end
            local nowT = GetTime()
            -- only the channeling unit's casts are echoes. The "??" clone's
            -- concurrent casts must not consume echo slots
            if chanUnit and unit ~= chanUnit then
                return
            end
            if #seq == 0 or echoIdx >= #seq or nowT > echoUntil then
                return
            end
            if nowT - lastEchoAdvance < 1 then
                return
            end
            local gap = lastEchoAdvance > 0 and (nowT - lastEchoAdvance) or nil
            lastEchoAdvance = nowT
            echoIdx = echoIdx + 1
            -- Reading the boss cast bar is the honest countdown source: each echo is
            -- one cast by the unit that ran the channel, and its end time is the
            -- tick where the wave really lands. When the client keeps the end time
            -- hidden the display falls back to nothing rather than guessing, so
            -- it can only ever go quiet, not wrong. The recorded route itself is
            -- read-only from here on, the cast bar feeds the countdown text and
            -- reaches nothing else.
            local at
            local okC, _, _, _, _, endMS = pcall(UnitCastingInfo, unit)
            if okC and endMS then
                local okT, t = pcall(function()
                    return endMS / 1000
                end)
                if okT and type(t) == "number" then
                    at = t
                end
            end
            setWave("echo", echoIdx, #seq, at, nowT, gap)
            if AZT.SetSafeQuads then
                AZT.SetSafeQuads(seq, echoIdx)
            end
            if AZT.Cue then
                AZT.Cue(seq[echoIdx], at, echoIdx > 1 and seq[echoIdx - 1] or seq[#seq])
            end
            if echoIdx >= #seq then
                -- clear the board just after the last wave actually lands:
                -- cast end plus a beat to see the outcome, or a spacing's
                -- worth when the end time was unreadable
                local delay
                local okD, d = pcall(function()
                    return at - GetTime()
                end)
                if okD and type(d) == "number" and d > 0 and d < 10 then
                    delay = d + 2
                else
                    delay = grid.spacing + 2
                end
                C_Timer.NewTimer(delay, function()
                    Safe.Reset()
                end)
            end
        end
    end, ...)
    if not ok then
        AZT.Log("SAFE_ERR " .. tostring(event) .. ": " .. tostring(err))
    end
end)

-- The encounter can only happen in the delve, so the cast and encounter
-- events only exist there. Outside it this file hears nothing at all,
-- spellcasts included, which otherwise fire on every mob around the player
local COMBAT_EVENTS = {
    "ENCOUNTER_START",
    "ENCOUNTER_END",
    "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_STOP",
    "UNIT_SPELLCAST_START",
}

function Safe.ZoneSync()
    Safe.RotateSync()
    if AZT.InDelve() then
        AZT.CueChannelWarn()
        for _, e in ipairs(COMBAT_EVENTS) do
            ef:RegisterEvent(e)
        end
    else
        for _, e in ipairs(COMBAT_EVENTS) do
            ef:UnregisterEvent(e)
        end
        -- PLAYER_DEAD rides the encounter and cannot outlive the delve
        ef:UnregisterEvent("PLAYER_DEAD")
    end
end

local zf = CreateFrame("Frame")
zf:RegisterEvent("PLAYER_ENTERING_WORLD")
zf:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zf:SetScript("OnEvent", function()
    Safe.ZoneSync()
end)

--#endregion
