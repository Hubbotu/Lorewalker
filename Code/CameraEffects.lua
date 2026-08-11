local env = select(2, ...)
local Config = env.Config
local Path = env.modules:Import("packages\\path")
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local SavedVariables = env.modules:Import("packages\\saved-variables")
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List, SecureButton, ModelScene = unpack(UIKit.UI.Frames)
local CVarUtil = env.modules:Import("packages\\cvar-util")
local UIAnim = env.modules:Import("packages\\ui-anim")
local CameraEffects = env.modules:New("@\\CameraEffects")

local UIParent = UIParent
local GetCameraZoom = GetCameraZoom
local CameraZoomIn = CameraZoomIn
local CameraZoomOut = CameraZoomOut
local ConsoleExec = ConsoleExec
local InCombatLockdown = InCombatLockdown
local SetCVar = SetCVar
local GetCVar = GetCVar
local CreateFrame = CreateFrame
local pairs = pairs
local next = next
local wipe = wipe
local type = type
local min = math.min


do --Vignette
    LWVignette = Frame()
        :size(UIKit.UI.FILL)
        :frameStrata(UIKit.Enum.FrameStrata.Background)
        :background(UIKit.Define.Texture_NineSlice{ path = Path.Root .. "\\Art\\Dialog\\Shared\\Vignette", inset = 256, scale = 1, sliceMode = Enum.UITextureSliceMode.Stretched })
        :_Render()

    LWVignette:Hide()

    local function HideSelf()
        LWVignette:Hide()
    end

    function LWVignette:FadeIn()
        self:Show()
        self.AnimGroup:Play(self, "FADE_IN")
    end

    function LWVignette:FadeOut()
        self.AnimGroup:Play(self, "FADE_OUT"):onFinish(HideSelf)
    end

    LWVignette.AnimGroup = UIAnim.New()
    do
        local FadeIn = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(1):from(0):to(1)
        LWVignette.AnimGroup:State("FADE_IN", function(frame)
            FadeIn:Play(frame)
        end)

        local FadeOut = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(1):to(0)
        LWVignette.AnimGroup:State("FADE_OUT", function(frame)
            FadeOut:Play(frame)
        end)
    end
end



local MIN_TICK = 0.016
local SHOULDER_OFFSET_TICK = 0.1
local DEFAULT_SHOULDER_OFFSET_ZOOM = 39

local DefaultShoulderOffsetDef = {
    BeginDuration = 2.5,
    BeginEasing   = UIAnim.Enum.Easing.SineOut,
    EndDuration   = 1.5,
    EndEasing     = UIAnim.Enum.Easing.SineOut
}

CameraEffects.Enum = {
    Effects = {
        Zoom                             = 1,
        ShowVignette                     = 2,
        PitchLimit                       = "pitchlimit",

        Fov                              = "cameraFov",
        ShoulderOffset                   = "test_cameraOverShoulder",
        ShoulderOffsetDef                = {
            BeginDuration = 3,
            BeginEasing   = 4,
            EndDuration   = 5,
            EndEasing     = 6
        },
        CameraOverShoulderEasing         = "cameraOverShoulderEasing",
        HeadMovementStrength             = "test_cameraHeadMovementStrength",
        FocusInteractTarget              = "test_cameraTargetFocusInteractEnable",
        FocusInteractTargetPitchStrength = "test_cameraTargetFocusInteractStrengthPitch",
        FocusInteractTargetYawStrength   = "test_cameraTargetFocusInteractStrengthYaw",
        CameraKeepCharacterCentered      = "CameraKeepCharacterCentered",
        CameraReduceUnexpectedMovement   = "CameraReduceUnexpectedMovement"
    }
}

CameraEffects.Presets = {
    [env.Enum.CameraEffectsPreset.Full]     = {
        [CameraEffects.Enum.Effects.Zoom]                             = 5,
        [CameraEffects.Enum.Effects.ShowVignette]                     = true,
        [CameraEffects.Enum.Effects.PitchLimit]                       = 15,
        [CameraEffects.Enum.Effects.Fov]                              = 60,
        [CameraEffects.Enum.Effects.ShoulderOffset]                   = 1.5,
        [CameraEffects.Enum.Effects.ShoulderOffsetDef]                = {
            [CameraEffects.Enum.Effects.ShoulderOffsetDef.BeginDuration] = 2.5,
            [CameraEffects.Enum.Effects.ShoulderOffsetDef.BeginEasing]   = UIAnim.Enum.Easing.SineOut,
            [CameraEffects.Enum.Effects.ShoulderOffsetDef.EndDuration]   = 1.5,
            [CameraEffects.Enum.Effects.ShoulderOffsetDef.EndEasing]     = UIAnim.Enum.Easing.SineOut
        },
        [CameraEffects.Enum.Effects.HeadMovementStrength]             = nil,
        [CameraEffects.Enum.Effects.FocusInteractTarget]              = false,
        [CameraEffects.Enum.Effects.FocusInteractTargetPitchStrength] = nil,
        [CameraEffects.Enum.Effects.FocusInteractTargetYawStrength]   = nil
    },
    [env.Enum.CameraEffectsPreset.Balanced] = {
        [CameraEffects.Enum.Effects.Zoom]                             = nil,
        [CameraEffects.Enum.Effects.ShowVignette]                     = true,
        [CameraEffects.Enum.Effects.PitchLimit]                       = nil,
        [CameraEffects.Enum.Effects.Fov]                              = nil,
        [CameraEffects.Enum.Effects.ShoulderOffset]                   = 7,
        [CameraEffects.Enum.Effects.ShoulderOffsetDef]                = {
            [CameraEffects.Enum.Effects.ShoulderOffsetDef.BeginDuration] = 2.5,
            [CameraEffects.Enum.Effects.ShoulderOffsetDef.BeginEasing]   = UIAnim.Enum.Easing.ExpoOut,
            [CameraEffects.Enum.Effects.ShoulderOffsetDef.EndDuration]   = 2,
            [CameraEffects.Enum.Effects.ShoulderOffsetDef.EndEasing]     = UIAnim.Enum.Easing.ExpoOut
        },
        [CameraEffects.Enum.Effects.HeadMovementStrength]             = nil,
        [CameraEffects.Enum.Effects.FocusInteractTarget]              = nil,
        [CameraEffects.Enum.Effects.FocusInteractTargetPitchStrength] = nil,
        [CameraEffects.Enum.Effects.FocusInteractTargetYawStrength]   = nil
    }
}

CameraEffects.Enabled = false
CameraEffects.SessionOptions = {}


if GameEvent and GameEvent.UnregisterInternalEvent then GameEvent.UnregisterInternalEvent("EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED") end
CVarUtil.SetCVar(CameraEffects.Enum.Effects.CameraKeepCharacterCentered, false, CVarUtil.Enum.TemporaryType.UntilLogout)
CVarUtil.SetCVar(CameraEffects.Enum.Effects.CameraReduceUnexpectedMovement, false, CVarUtil.Enum.TemporaryType.UntilLogout)


function CameraEffects.LoadOptions()
    local preset = Config.DBGlobal:GetVariable("CameraEffectsPreset")
    CameraEffects.Enabled = preset ~= env.Enum.CameraEffectsPreset.None

    wipe(CameraEffects.SessionOptions)

    if preset == env.Enum.CameraEffectsPreset.Custom then
        for effectName, effect in pairs(CameraEffects.Enum.Effects) do
            CameraEffects.SessionOptions[effect] = Config.DBGlobal:GetVariable("CameraEffects_" .. effectName)
        end
        return
    end

    local options = CameraEffects.Presets[preset]
    if not options then return end

    for effect, value in pairs(options) do
        CameraEffects.SessionOptions[effect] = value
    end
end

CallbackRegistry.Add("Preload.DatabaseReady", CameraEffects.LoadOptions)
SavedVariables.OnChange("LorewalkerDB_Global", "CameraEffectsPreset", CameraEffects.LoadOptions)
for effectName in pairs(CameraEffects.Enum.Effects) do
    SavedVariables.OnChange("LorewalkerDB_Global", "CameraEffects_" .. effectName, CameraEffects.LoadOptions)
end


local CameraUtil = CreateFrame("Frame")
CameraUtil.Snapshot = {}
CameraUtil.Instances = {}
CameraUtil.isPlaying = false
CameraUtil.hasSnapshot = false
CameraUtil.isSkyriding = C_PlayerInfo.GetGlidingInfo()

function CameraUtil:CaptureSnapshot()
    if self.hasSnapshot then return end

    for _, cvar in pairs(CameraEffects.Enum.Effects) do
        if type(cvar) == "string" then
            local value = GetCVar(cvar)
            if value then
                self.Snapshot[cvar] = value
            end
        end
    end

    self.Snapshot[CameraEffects.Enum.Effects.Zoom] = GetCameraZoom()
    self.hasSnapshot = true

    CallbackRegistry.Trigger("CameraUtil.Snapshot")
end

function CameraUtil:RestoreFromSnapshot()
    if not self.hasSnapshot then return end

    for cvar, value in pairs(self.Snapshot) do
        if type(cvar) == "string" then
            SetCVar(cvar, value)
        end
    end

    if self.Snapshot[CameraEffects.Enum.Effects.Zoom] then
        self:Zoom(self.Snapshot[CameraEffects.Enum.Effects.Zoom])
    end
    self:RestorePitchLimit()
    self.hasSnapshot = false

    CallbackRegistry.Trigger("CameraUtil.RestoreFromSnapshot")
end

function CameraUtil:ReleaseSnapshotWhenIdle()
    if not next(self.Instances) then
        self.hasSnapshot = false
        return
    end

    self.shouldReleaseSnapshotWhenIdle = true
end

function CameraUtil:InterpolateCVar(cvar, startValue, endValue, duration, easing, onFinish)
    startValue = startValue or tonumber(GetCVar(cvar))

    if duration <= 0 then
        SetCVar(cvar, endValue)
        if onFinish then onFinish(cvar, endValue) end
        return
    end

    local animInstance = self.Instances[cvar]
    if not animInstance then
        animInstance = {}
        self.Instances[cvar] = animInstance
    end

    local easingFunction = type(easing) == "function" and easing or UIAnim.Easing[easing] or UIAnim.Easing.Linear

    animInstance.startValue = startValue
    animInstance.valueDelta = endValue - startValue
    animInstance.inverseDuration = 1 / duration
    animInstance.elapsed = 0
    animInstance.easing = easingFunction
    animInstance.onFinish = onFinish

    self.isPlaying = true
    self:SetScript("OnUpdate", self.OnUpdate)
end

function CameraUtil:IsPlaying()
    return self.isPlaying
end

function CameraUtil:CancelInstances(cvar)
    self.shouldReleaseSnapshotWhenIdle = nil

    if cvar then
        self.Instances[cvar] = nil
        if not next(self.Instances) then
            self.isPlaying = false
            self:SetScript("OnUpdate", nil)
        end
    else
        wipe(self.Instances)
        self.isPlaying = false
        self:SetScript("OnUpdate", nil)
    end
end

function CameraUtil:IsInterpolating(cvar)
    if cvar then
        return self.Instances[cvar] ~= nil
    end
    return next(self.Instances) ~= nil
end

function CameraUtil:Zoom(zoomLevel)
    local delta = GetCameraZoom() - zoomLevel
    if delta > 0 then
        CameraZoomIn(delta)
    else
        CameraZoomOut(-delta)
    end
end

function CameraUtil:RestorePitchLimit()
    ConsoleExec("pitchlimit 88")
end

function CameraUtil:RestoreFov()
    SetCVar(CameraEffects.Enum.Effects.Fov, CameraUtil.Snapshot[CameraEffects.Enum.Effects.Fov])
end

function CameraUtil:OnUpdate(elapsed)
    self.throttle = (self.throttle or 0) + elapsed
    if self.throttle < MIN_TICK then return end
    elapsed = self.throttle
    self.throttle = 0

    local instances = self.Instances

    for cvar, animInstance in pairs(instances) do
        animInstance.elapsed = animInstance.elapsed + elapsed
        local progress = min(animInstance.elapsed * animInstance.inverseDuration, 1)
        local value = animInstance.startValue + animInstance.valueDelta * animInstance.easing(progress)

        if cvar == CameraEffects.Enum.Effects.PitchLimit then
            ConsoleExec("pitchlimit " .. value)
        else
            SetCVar(cvar, value)
        end

        if progress >= 1 then
            instances[cvar] = nil
            if animInstance.onFinish then
                animInstance.onFinish(cvar, value)
            end
        end
    end

    if not next(instances) then
        self.isPlaying = false
        self:SetScript("OnUpdate", nil)

        if self.shouldReleaseSnapshotWhenIdle then
            self.shouldReleaseSnapshotWhenIdle = nil
            self.hasSnapshot = false
        end
    else
        self.isPlaying = true
    end
end

function CameraUtil:OnEvent(event, ...)
    if event == "PLAYER_IS_GLIDING_CHANGED" then
        self.isSkyriding = ...
        if self.isSkyriding then
            CameraEffects.OnSkyridingStarted()
        end
    end

    if event == "ADDONS_UNLOADING" then
        self:CancelInstances()
        self:RestoreFromSnapshot()
    end
end

CameraUtil:RegisterEvent("PLAYER_IS_GLIDING_CHANGED")
CameraUtil:RegisterEvent("ADDONS_UNLOADING")
CameraUtil:SetScript("OnEvent", CameraUtil.OnEvent)



local isSessionActive = false
local sessionID = 0
local ShoulderOffsetUtil = CreateFrame("Frame")

function ShoulderOffsetUtil:GetShoulderOffsetDefValue(key)
    local shoulderOffsetDef = CameraEffects.SessionOptions[CameraEffects.Enum.Effects.ShoulderOffsetDef]
    return shoulderOffsetDef and shoulderOffsetDef[CameraEffects.Enum.Effects.ShoulderOffsetDef[key]] or DefaultShoulderOffsetDef[key]
end

function ShoulderOffsetUtil:GetDialogFrameHorizontalDirection()
    return (LWDialogFrame:GetLeft() + LWDialogFrame:GetWidth() / 2 > GetScreenWidth() / 2) and 1 or -1
end

function ShoulderOffsetUtil:GetMountedShoulderOffsetScale()
    if IsMounted() then
        return 4.5
    end
    return 1.0
end

function ShoulderOffsetUtil:GetMountedShoulderOffsetDivisor()
    if IsMounted() then
        return 10
    end
    return 1
end

function ShoulderOffsetUtil:GetShoulderOffsetForZoom(zoom)
    local options = CameraEffects.SessionOptions
    local shoulderOffset = options[CameraEffects.Enum.Effects.ShoulderOffset]
    local baseZoom = options[CameraEffects.Enum.Effects.Zoom] or DEFAULT_SHOULDER_OFFSET_ZOOM

    if shoulderOffset == nil or baseZoom == nil or baseZoom == 0 then return nil end

    local target = ShoulderOffsetUtil:GetMountedShoulderOffsetScale() * self:GetDialogFrameHorizontalDirection() * shoulderOffset * (zoom / baseZoom)
    return target > 0 and target or target / ShoulderOffsetUtil:GetMountedShoulderOffsetDivisor()
end

function ShoulderOffsetUtil:OnUpdate(elapsed)
    if not isSessionActive or self.sessionID ~= sessionID then
        self:Stop()
        return
    end

    self.throttle = (self.throttle or 0) + elapsed
    if self.throttle < SHOULDER_OFFSET_TICK then return end
    self.throttle = 0

    local targetOffset = self:GetShoulderOffsetForZoom(GetCameraZoom())
    if targetOffset == nil then return end

    if self.lastTargetOffset == targetOffset then return end
    self.lastTargetOffset = targetOffset

    local duration = self:GetShoulderOffsetDefValue("BeginDuration")
    local easing = self:GetShoulderOffsetDefValue("BeginEasing")
    CameraUtil:InterpolateCVar(CameraEffects.Enum.Effects.ShoulderOffset, nil, targetOffset, duration, easing)
end

function ShoulderOffsetUtil:Start(activeSessionID)
    if not isSessionActive or activeSessionID ~= sessionID then return end

    self.sessionID = activeSessionID
    self.throttle = 0
    self.lastTargetOffset = nil
    self:Show()
end

function ShoulderOffsetUtil:Stop()
    self.sessionID = nil
    self.lastTargetOffset = nil
    self:Hide()
end

ShoulderOffsetUtil:SetScript("OnUpdate", ShoulderOffsetUtil.OnUpdate)
ShoulderOffsetUtil:Hide()



local E = CameraEffects.Enum.Effects
local Opts = CameraEffects.SessionOptions
local disableFov = false

function CameraEffects.OnSkyridingStarted()
    if not isSessionActive or disableFov or not Opts[E.Fov] then return end

    disableFov = true
    CameraUtil:CancelInstances(E.Fov)
    SetCVar(E.Fov, CameraUtil.Snapshot[E.Fov])
end

function CameraEffects.OnSessionBegin()
    if not CameraEffects.Enabled or isSessionActive or InCombatLockdown() then return end
    isSessionActive = true
    sessionID = sessionID + 1

    CameraUtil:CancelInstances()
    CameraUtil:CaptureSnapshot()
    disableFov = CameraUtil.isSkyriding

    if Opts[E.PitchLimit] then
        CameraUtil:InterpolateCVar(E.PitchLimit, 88, Opts[E.PitchLimit], 1.75, UIAnim.Enum.Easing.SineInOut, CameraUtil.RestorePitchLimit)
    end
    if Opts[E.ShowVignette] then
        LWVignette:FadeIn()
    end
    if Opts[E.FocusInteractTarget] then
        SetCVar(E.FocusInteractTarget, Opts[E.FocusInteractTarget])
        if Opts[E.FocusInteractTargetPitchStrength] then
            CameraUtil:InterpolateCVar(E.FocusInteractTargetPitchStrength, nil, Opts[E.FocusInteractTargetPitchStrength], 1, UIAnim.Enum.Easing.SineInOut)
        end
        if Opts[E.FocusInteractTargetYawStrength] then
            CameraUtil:InterpolateCVar(E.FocusInteractTargetYawStrength, nil, Opts[E.FocusInteractTargetYawStrength], 1, UIAnim.Enum.Easing.SineInOut)
        end
    end
    if Opts[E.ShoulderOffset] then
        local currentSessionID = sessionID
        C_Timer.After(0, function()
            if currentSessionID ~= sessionID or not isSessionActive or not CameraEffects.Enabled or InCombatLockdown() then return end
            local targetOffset = ShoulderOffsetUtil:GetShoulderOffsetForZoom(Opts[E.Zoom] or GetCameraZoom())
            local duration = ShoulderOffsetUtil:GetShoulderOffsetDefValue("BeginDuration")
            local easing = ShoulderOffsetUtil:GetShoulderOffsetDefValue("BeginEasing")
            CameraUtil:InterpolateCVar(E.ShoulderOffset, nil, targetOffset, duration, easing, function()
                ShoulderOffsetUtil:Start(currentSessionID)
            end)
        end)
    end
    if Opts[E.Fov] and not disableFov then
        CameraUtil:InterpolateCVar(E.Fov, nil, Opts[E.Fov], 2, UIAnim.Enum.Easing.SineInOut)
    end
    if Opts[E.HeadMovementStrength] then
        CameraUtil:InterpolateCVar(E.HeadMovementStrength, nil, Opts[E.HeadMovementStrength], 2, UIAnim.Enum.Easing.SineInOut)
    end
    if Opts[E.Zoom] then
        CameraUtil:Zoom(Opts[E.Zoom])
    end
end

function CameraEffects.OnSessionEnd()
    if not isSessionActive then return end
    isSessionActive = false
    sessionID = sessionID + 1

    ShoulderOffsetUtil:Stop()
    CameraUtil:CancelInstances()

    if Opts[E.FocusInteractTarget] then
        SetCVar(E.FocusInteractTarget, CameraUtil.Snapshot[E.FocusInteractTarget])
        if Opts[E.FocusInteractTargetPitchStrength] then
            CameraUtil:InterpolateCVar(E.FocusInteractTargetPitchStrength, nil, CameraUtil.Snapshot[E.FocusInteractTargetPitchStrength], 1.5, UIAnim.Enum.Easing.SineInOut)
        end
        if Opts[E.FocusInteractTargetYawStrength] then
            CameraUtil:InterpolateCVar(E.FocusInteractTargetYawStrength, nil, CameraUtil.Snapshot[E.FocusInteractTargetYawStrength], 1.5, UIAnim.Enum.Easing.SineInOut)
        end
    end
    if Opts[E.ShowVignette] then
        LWVignette:FadeOut()
    end
    if Opts[E.ShoulderOffset] then
        local restoreSessionID = sessionID
        local originalShoulderOffset = CameraUtil.Snapshot[E.ShoulderOffset]
        local duration = ShoulderOffsetUtil:GetShoulderOffsetDefValue("EndDuration")
        local easing = ShoulderOffsetUtil:GetShoulderOffsetDefValue("EndEasing")
        CameraUtil:InterpolateCVar(E.ShoulderOffset, nil, originalShoulderOffset, duration, easing, function(cvar)
            if isSessionActive or restoreSessionID ~= sessionID then return end
            SetCVar(cvar, originalShoulderOffset)
        end)
    end
    if Opts[E.Fov] and not disableFov then
        CameraUtil:InterpolateCVar(E.Fov, nil, CameraUtil.Snapshot[E.Fov], 1.5, UIAnim.Enum.Easing.SineInOut)
    end
    if Opts[E.HeadMovementStrength] then
        CameraUtil:InterpolateCVar(E.HeadMovementStrength, nil, CameraUtil.Snapshot[E.HeadMovementStrength], 1.5, UIAnim.Enum.Easing.SineInOut)
    end
    if Opts[E.Zoom] then
        CameraUtil:Zoom(CameraUtil.Snapshot[E.Zoom])
    end

    CameraUtil:RestorePitchLimit()
    CameraUtil:ReleaseSnapshotWhenIdle()
end

CallbackRegistry.Add("ControlCenter.SessionBegin", CameraEffects.OnSessionBegin)
CallbackRegistry.Add("ControlCenter.SessionEnd", CameraEffects.OnSessionEnd)
