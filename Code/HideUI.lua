local env = select(2, ...)
local Config = env.Config
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local SavedVariables = env.modules:Import("packages\\saved-variables")
local UIAnim = env.modules:Import("packages\\ui-anim")
local WoWClient = env.modules:Import("packages\\wow-client")
local Tooltip = env.modules:Import("@\\Tooltip")
local HideUI = env.modules:New("@\\HideUI")

local UIParent = UIParent
local WorldFrame = WorldFrame
local EventRegistry = EventRegistry
local UIModeUtil = UIModeUtil
local InCombatLockdown = InCombatLockdown


local UI_MODE_ROLESET_BLOCKLIST = {
    "unitFrames",
    "actionBars",
    "statusBars",
    "buffs",
    "cooldownViewers",
    "extraAbilities",
    "minimap",
    "objectives",
    "widgets",
    "chat",
    "bags",
    "microMenu",
    "arenaFrames",
    "encounterUI",
    "pvp"
}
if WoWClient.IS_RETAIL then
    UIModeUtil.RegisterMode("Lorewalker.HideUI", { rolesetBlocklist = UI_MODE_ROLESET_BLOCKLIST })
end


HideUI.Enabled = false
HideUI.fadeOutPlayback = false


function HideUI.LoadOptions()
    HideUI.Enabled = Config.DBGlobal:GetVariable("HideUI")
end

CallbackRegistry.Add("Preload.DatabaseReady", HideUI.LoadOptions)
SavedVariables.OnChange("LorewalkerDB_Global", "HideUI", HideUI.LoadOptions)


HideUI.AnimGroup = UIAnim.New()
do
    local FadeIn = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.2):from(0):to(1)
    HideUI.AnimGroup:State("FADE_IN", function(frame)
        FadeIn:Play(frame)
    end)

    local FadeOut = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.2):to(0)
    HideUI.AnimGroup:State("FADE_OUT", function(frame)
        FadeOut:Play(frame)
    end)
end

local function HideUIParent()
    if WoWClient.IS_RETAIL then
        UIModeUtil.SetModeActive("Lorewalker.HideUI", true)
        UIParent:SetAlpha(0)
    else
        UIParent:SetAlpha(1)
        UIParent:Hide()
    end
end

local function ShowUIParent(applyAlpha)
    if applyAlpha or applyAlpha == nil then
        UIParent:SetAlpha(1)
    end

    if WoWClient.IS_RETAIL then
        UIModeUtil.SetModeActive("Lorewalker.HideUI", false)
    else
        UIParent:Show()
    end
end

local function OnUIParentHidden()
    ShowUIParent()
end

if WoWClient.IS_RETAIL then
    EventRegistry:RegisterCallback("UI.TopLevelParentHidden", OnUIParentHidden, HideUI)
end

function HideUI.FadeOut(instant)
    HideUI.AnimGroup:Stop(UIParent)

    Tooltip.Modify()

    if instant then
        HideUIParent()
        HideUI.fadeOutPlayback = false
    else
        HideUI.fadeOutPlayback = true
        HideUI.AnimGroup:Play(UIParent, "FADE_OUT"):onFinish(function()
            HideUIParent()
            HideUI.fadeOutPlayback = false
        end)
    end
end

function HideUI.FadeIn(instant)
    if WoWClient.IS_CLASSIC_ALL and UIParent:IsShown() and not HideUI.fadeOutPlayback then
        instant = true
    end

    HideUI.AnimGroup:Stop(UIParent)
    HideUI.fadeOutPlayback = false

    ShowUIParent(instant)
    Tooltip.Restore()

    if not instant then
        UIParent:SetAlpha(0)
        HideUI.AnimGroup:Play(UIParent, "FADE_IN")
    end
end

local isSessionActive = false
local hideUIForSession = false
local hideUIForCinematic = false

function HideUI.OnSessionBegin()
    if isSessionActive then return end
    isSessionActive = true

    WorldFrame:SetAlpha(0)

    hideUIForSession = HideUI.Enabled and not InCombatLockdown()
    if hideUIForSession then
        HideUI.FadeOut()
    end
end

function HideUI.OnSessionEnd()
    if not isSessionActive then return end
    isSessionActive = false

    WorldFrame:SetAlpha(1)

    if hideUIForSession then
        hideUIForSession = false
        if not hideUIForCinematic then
            HideUI.FadeIn()
        end
    end
end

function HideUI.OnCinematicBegin()
    if not hideUIForSession then return end

    hideUIForCinematic = true
    HideUI.FadeOut(true)
    Tooltip.Restore()
end

function HideUI.OnCinematicEnd()
    if not hideUIForCinematic then return end
    hideUIForCinematic = false

    if not isSessionActive then
        HideUI.FadeIn()
    end
end

function HideUI.OnCombatBegin()
    if not isSessionActive then return end

    WorldFrame:SetAlpha(1)

    if hideUIForSession then
        HideUI.FadeIn(true)
    end
end

CallbackRegistry.Add("ControlCenter.SessionBegin", HideUI.OnSessionBegin)
CallbackRegistry.Add("ControlCenter.SessionEnd", HideUI.OnSessionEnd)
CallbackRegistry.Add("ControlCenter.CinematicBegin", HideUI.OnCinematicBegin)
CallbackRegistry.Add("ControlCenter.CinematicEnd", HideUI.OnCinematicEnd)
CallbackRegistry.Add("ControlCenter.CombatBegin", HideUI.OnCombatBegin)
