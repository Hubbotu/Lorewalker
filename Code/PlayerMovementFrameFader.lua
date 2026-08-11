local env = select(2, ...)
local PlayerMovementFrameFader = env.modules:New("@\\PlayerMovementFrameFader")

local FrameFaderDriver = nil
local fadingFrames = nil
local deferredFadingFrames = nil
local frameMinAlpha = setmetatable({}, { __mode = "k" })
local frameMaxAlpha = setmetatable({}, { __mode = "k" })
local frameFadePredicate = setmetatable({}, { __mode = "k" })
local trackedFrameHooks = setmetatable({}, { __mode = "k" })
local driverEventsRegistered = false
local DEFAULT_MIN_ALPHA = 0.5
local DEFAULT_MAX_ALPHA = 1

function PlayerMovementFrameFader.HasVisibleFrames(frameTable)
    for frame in pairs(frameTable) do
        if frame:IsVisible() then
            return true
        end
    end
    return false
end

function PlayerMovementFrameFader.RegisterDriverEvents()
    if driverEventsRegistered then return end

    FrameFaderDriver:RegisterEvent("PLAYER_STARTED_MOVING")
    FrameFaderDriver:RegisterEvent("PLAYER_STOPPED_MOVING")
    FrameFaderDriver:RegisterEvent("PLAYER_IS_GLIDING_CHANGED")
    FrameFaderDriver:RegisterEvent("PLAYER_IMPULSE_APPLIED")
    driverEventsRegistered = true
end

function PlayerMovementFrameFader.UnregisterDriverEvents()
    if not driverEventsRegistered then return end

    FrameFaderDriver:UnregisterAllEvents()
    driverEventsRegistered = false
end

function PlayerMovementFrameFader.UpdateDriverState()
    if not FrameFaderDriver then return end

    local hasVisibleFadingFrames = fadingFrames and PlayerMovementFrameFader.HasVisibleFrames(fadingFrames)
    local hasVisibleDeferredFrames = deferredFadingFrames and PlayerMovementFrameFader.HasVisibleFrames(deferredFadingFrames)

    FrameFaderDriver:SetScript("OnUpdate", hasVisibleFadingFrames and PlayerMovementFrameFader.OnUpdate or nil)

    if hasVisibleFadingFrames or hasVisibleDeferredFrames then
        PlayerMovementFrameFader.RegisterDriverEvents()
    else
        PlayerMovementFrameFader.UnregisterDriverEvents()
    end
end

function PlayerMovementFrameFader.OnFrameVisibilityChanged()
    if deferredFadingFrames and IsPlayerMoving() then
        PlayerMovementFrameFader.MergeDeferredEvents()
    end

    PlayerMovementFrameFader.UpdateDriverState()
end

function PlayerMovementFrameFader.OnUpdate(_, elapsed)
    local isMoving = IsPlayerMoving()
    for frame in pairs(fadingFrames) do
        local fadePredicate = frameFadePredicate[frame]
        local fadeOut = isMoving and (not fadePredicate or fadePredicate())
        local minAlpha = frameMinAlpha[frame] or DEFAULT_MIN_ALPHA
        local maxAlpha = frameMaxAlpha[frame] or DEFAULT_MAX_ALPHA
        frame:SetAlpha(DeltaLerp(frame:GetAlpha(), fadeOut and minAlpha or maxAlpha, .1, elapsed))
    end
end

function PlayerMovementFrameFader.MergeDeferredEvents()
    if deferredFadingFrames then
        for frame in pairs(deferredFadingFrames) do
            fadingFrames[frame] = true
        end
        deferredFadingFrames = nil
    end
end

function PlayerMovementFrameFader.OnEvent(_, event, ...)
    if event == "PLAYER_STARTED_MOVING"
        or event == "PLAYER_STOPPED_MOVING"
        or event == "PLAYER_IS_GLIDING_CHANGED"
        or event == "PLAYER_IMPULSE_APPLIED" then
        PlayerMovementFrameFader.MergeDeferredEvents()
        PlayerMovementFrameFader.UpdateDriverState()
    end
end

function PlayerMovementFrameFader.HookFrameVisibility(frame)
    if trackedFrameHooks[frame] then return end

    trackedFrameHooks[frame] = true
    frame:HookScript("OnShow", PlayerMovementFrameFader.OnFrameVisibilityChanged)
    frame:HookScript("OnHide", PlayerMovementFrameFader.OnFrameVisibilityChanged)
end

function PlayerMovementFrameFader.InitializeDriver()
    if not FrameFaderDriver then
        fadingFrames = {}

        FrameFaderDriver = CreateFrame("FRAME")
        FrameFaderDriver:SetScript("OnUpdate", PlayerMovementFrameFader.OnUpdate)
        FrameFaderDriver:SetScript("OnEvent", PlayerMovementFrameFader.OnEvent)
    end
end

local function RemoveFrameInternal(frame)
    if fadingFrames then fadingFrames[frame] = nil end
    if deferredFadingFrames then deferredFadingFrames[frame] = nil end

    frameMinAlpha[frame] = nil
    frameMaxAlpha[frame] = nil
    frameFadePredicate[frame] = nil
end

function PlayerMovementFrameFader.AddFrame(frame, minAlpha, maxAlpha, durationSec, fadePredicate)
    RemoveFrameInternal(frame)

    PlayerMovementFrameFader.InitializeDriver()
    PlayerMovementFrameFader.HookFrameVisibility(frame)
    frameMinAlpha[frame] = minAlpha or DEFAULT_MIN_ALPHA
    frameMaxAlpha[frame] = maxAlpha or DEFAULT_MAX_ALPHA
    frameFadePredicate[frame] = fadePredicate
    fadingFrames[frame] = true
    PlayerMovementFrameFader.UpdateDriverState()
end

function PlayerMovementFrameFader.AddDeferredFrame(frame, minAlpha, maxAlpha, durationSec, fadePredicate)
    PlayerMovementFrameFader.InitializeDriver()
    RemoveFrameInternal(frame)

    if not deferredFadingFrames then deferredFadingFrames = {} end

    PlayerMovementFrameFader.HookFrameVisibility(frame)
    frameMinAlpha[frame] = minAlpha or DEFAULT_MIN_ALPHA
    frameMaxAlpha[frame] = maxAlpha or DEFAULT_MAX_ALPHA
    frameFadePredicate[frame] = fadePredicate
    deferredFadingFrames[frame] = true
    PlayerMovementFrameFader.UpdateDriverState()
end

function PlayerMovementFrameFader.RemoveFrame(frame)
    local maxAlpha = frameMaxAlpha[frame]
    if maxAlpha then frame:SetAlpha(maxAlpha) end

    RemoveFrameInternal(frame)
    PlayerMovementFrameFader.UpdateDriverState()
end
