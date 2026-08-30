local env = select(2, ...)
local Config = env.Config
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local LazyTimer = env.modules:Import("packages\\lazy-timer")
local WoWClient = env.modules:Import("packages\\wow-client")
local ControlCenter_Preload = env.modules:Import("@\\Dialog\\ControlCenter\\Preload")
local ControlCenter_DataProvider = env.modules:Import("@\\Dialog\\ControlCenter\\DataProvider")
local ControlCenter_Director = env.modules:New("@\\Dialog\\ControlCenter\\Director")

local function False() return false end

local CreateFrame = CreateFrame
local ForceGossip = C_GossipInfo.ForceGossip
local ClearInteraction = C_PlayerInteractionManager.ClearInteraction
local GetActiveQuests = C_GossipInfo.GetActiveQuests
local GetAvailableQuests = C_GossipInfo.GetAvailableQuests
local GetGossipOptions = C_GossipInfo.GetOptions
local GetNumActiveQuests = C_GossipInfo.GetNumActiveQuests
local GetNumAvailableQuests = C_GossipInfo.GetNumAvailableQuests
local QuestIsFromAreaTrigger = QuestIsFromAreaTrigger or False
local QuestGetAutoAccept = QuestGetAutoAccept or False
local SelectOptionByIndex = C_GossipInfo.SelectOptionByIndex
local ipairs = ipairs

ControlCenter_Director.isInSession = false
ControlCenter_Director.questSessionType = false
ControlCenter_Director.gossipSessionType = false
ControlCenter_Director.muteDefaultUI = true

local THROTTLE_DURATION = 0.016
local IMMEDIATE_SESSION_END_DELAY = 0.1
local GOSSIP_SESSION_END_DELAY = 0.5
local QUEST_SESSION_END_DELAY = 0.625
local FALLBACK_SESSION_END_DELAY = 0.125
local FINAL_INTERACTION_SCAN_DELAY = 0.4
local SESSION_OPEN_WATCHDOG_DELAY = 0.75

local EVENTS = {
    "QUEST_GREETING",
    "QUEST_DETAIL",
    "QUEST_PROGRESS",
    "QUEST_FINISHED",
    "QUEST_COMPLETE",
    "QUEST_TURNED_IN",
    "QUEST_AUTOCOMPLETE",
    "GOSSIP_SHOW",
    "GOSSIP_CLOSED",
    "GOSSIP_CONFIRM",
    "GOSSIP_CONFIRM_CANCEL"
}
if WoWClient.IS_RETAIL then
    EVENTS[#EVENTS + 1] = "GOSSIP_OPTIONS_REFRESHED"
end
local CUSTOM_GOSSIP_EVENTS = {
    "GOSSIP_SHOW",
    "GOSSIP_CLOSED"
}
local GOSSIP_EVENTS = {
    "GOSSIP_SHOW",
    "GOSSIP_CLOSED",
    "QUEST_LOG_UPDATE"
}
local QUEST_EVENTS = {
    "QUEST_GREETING",
    "QUEST_DETAIL",
    "QUEST_PROGRESS",
    "QUEST_COMPLETE",
    "QUEST_FINISHED",
    "QUEST_ITEM_UPDATE",
    "QUEST_LOG_UPDATE",
    "UNIT_PORTRAIT_UPDATE",
    "PORTRAITS_UPDATED"
}
local GOSSIP_SESSION_TYPE_LOOKUP = {
    GOSSIP_SHOW    = ControlCenter_Preload.Enum.SessionType.Gossip,
    QUEST_GREETING = ControlCenter_Preload.Enum.SessionType.GossipGreeting
}
local QUEST_SESSION_TYPE_LOOKUP = {
    QUEST_DETAIL   = ControlCenter_Preload.Enum.SessionType.Detail,
    QUEST_PROGRESS = ControlCenter_Preload.Enum.SessionType.Progress,
    QUEST_COMPLETE = ControlCenter_Preload.Enum.SessionType.Complete
}
local BEGIN_SESSION_EVENTS = {
    GOSSIP_SHOW    = true,
    QUEST_GREETING = true,
    QUEST_DETAIL   = true,
    QUEST_PROGRESS = true,
    QUEST_COMPLETE = true
}
local END_SESSION_EVENTS = {
    GOSSIP_CLOSED  = true,
    QUEST_FINISHED = true
}

local function IsFirstGossipOptionAutoSelectable()
    if Config.DBGlobal:GetVariable("ForceGossip") ~= false or ForceGossip() then
        return false
    end

    if not ControlCenter_DataProvider.IsInteractingWithGossipNpc() then
        return false
    end

    local gossipOptions = GetGossipOptions()
    if #gossipOptions ~= 1 or #GetAvailableQuests() > 0 or #GetActiveQuests() > 0 then
        return false
    end

    return gossipOptions[1].selectOptionWhenOnlyOption == true
end

local function TryAutoSelectFirstGossipOption()
    if not IsFirstGossipOptionAutoSelectable() then
        return false
    end

    SelectOptionByIndex(GetGossipOptions()[1].orderIndex)
    return true
end

--[[
    Callback Events:
        ControlCenter.SessionBegin
        ControlCenter.SessionClosing
        ControlCenter.SessionEnd
        ControlCenter.CinematicBegin
        ControlCenter.CinematicEnd
        ControlCenter.CombatBegin
        ControlCenter.CombatEnd
        ControlCenter.Update
        QUEST_GREETING
        QUEST_GREETING_CLOSED
        QUEST_DETAIL
        QUEST_PROGRESS
        QUEST_COMPLETE
        QUEST_TURNED_IN
        QUEST_AUTOCOMPLETE
        QUEST_FINISHED
        GOSSIP_SHOW
        GOSSIP_CLOSED
        GOSSIP_CONFIRM
        GOSSIP_CONFIRM_CANCEL
        GOSSIP_OPTIONS_REFRESHED
]]

local EventListener = CreateFrame("Frame")
do
    local throttlePool = {}
    local isSessionActive = false
    local isContinuingNPCInteraction = false
    local isGreeting = false
    local sessionEndDelay = 0
    local scanFinalInteraction = false

    local SessionTimer = LazyTimer.New()
    local UpdateTimer = LazyTimer.New()
    local SessionOpenWatchdogTimer = LazyTimer.New()

    local function ResetThrottle(event)
        local throttle = throttlePool[event]
        if throttle then
            throttle.active = false
        end
    end

    local function GetThrottle(event)
        local throttle = throttlePool[event]
        if throttle then
            return throttle
        end

        local timer = LazyTimer.New()
        timer:SetAction(function()
            ResetThrottle(event)
        end)

        throttle = {
            active = false,
            timer  = timer
        }
        throttlePool[event] = throttle

        return throttle
    end

    local function ThrottleEvent(event)
        local throttle = GetThrottle(event)
        if throttle.active then
            return false
        end

        throttle.active = true
        throttle.timer:Start(THROTTLE_DURATION)
        return true
    end

    local function ResetSession()
        isSessionActive = false
        isContinuingNPCInteraction = false
        isGreeting = false
        sessionEndDelay = 0
        scanFinalInteraction = false

        SessionTimer:Stop()
        UpdateTimer:Stop()
        SessionOpenWatchdogTimer:Stop()

        ControlCenter_Director.isInSession = false
        ControlCenter_Director.gossipSessionType = false
        ControlCenter_Director.questSessionType = false
    end

    local function UpdateSessionEndDelay()
        scanFinalInteraction = false

        if not isContinuingNPCInteraction then
            sessionEndDelay = IMMEDIATE_SESSION_END_DELAY
            scanFinalInteraction = true
            return
        end

        if ControlCenter_Director.gossipSessionType and (GetNumAvailableQuests() > 0 or GetNumActiveQuests() > 0) then
            sessionEndDelay = GOSSIP_SESSION_END_DELAY
            return
        end

        if ControlCenter_Director.questSessionType then
            sessionEndDelay = QUEST_SESSION_END_DELAY
            return
        end

        sessionEndDelay = FALLBACK_SESSION_END_DELAY
    end

    local function ProcessGossipEvent(event, continueInteraction)
        local sessionType = GOSSIP_SESSION_TYPE_LOOKUP[event]
        if sessionType then
            ControlCenter_Director.gossipSessionType = sessionType
            ControlCenter_Director.questSessionType = false
            return
        end

        if event ~= "GOSSIP_CLOSED" then
            return
        end

        ControlCenter_Director.gossipSessionType = false
        if continueInteraction then
            isContinuingNPCInteraction = true
        end
    end

    local function ProcessQuestEvent(event)
        local sessionType = QUEST_SESSION_TYPE_LOOKUP[event]
        if sessionType then
            ControlCenter_Director.gossipSessionType = false
            ControlCenter_Director.questSessionType = sessionType
            return
        end

        if event == "QUEST_FINISHED" then
            ControlCenter_Director.questSessionType = false
        end
    end

    local function RelayEvent(event, ...)
        if event == "QUEST_FINISHED" and isGreeting then
            CallbackRegistry.Trigger("QUEST_GREETING_CLOSED", ...)
            return
        end

        CallbackRegistry.Trigger(event, ...)
    end

    local function IsDialogInteractionType(interactionType)
        if not interactionType then return true end
        return interactionType == Enum.PlayerInteractionType.Gossip or interactionType == Enum.PlayerInteractionType.QuestGiver
    end

    local function BeginQuestSession()
        if QuestIsFromAreaTrigger() and QuestGetAutoAccept() then
            return
        end

        EventListener:BeginSession()
    end

    local function OnSessionBegin(event)
        isSessionActive = true

        if QUEST_SESSION_TYPE_LOOKUP[event] then
            BeginQuestSession()
            return
        end

        if TryAutoSelectFirstGossipOption() then
            return
        end

        EventListener:BeginSession()
    end

    local function OnSessionEnd()
        isSessionActive = false
        SessionTimer:Start(sessionEndDelay)
    end

    function EventListener:BeginSession()
        if ControlCenter_Director.isInSession then
            return
        end

        ControlCenter_Director.isInSession = true
        SessionOpenWatchdogTimer:Start(SESSION_OPEN_WATCHDOG_DELAY)
        CallbackRegistry.Trigger("ControlCenter.SessionBegin")
    end

    function EventListener:EndSession(clearInteraction)
        if not ControlCenter_Director.isInSession then
            return
        end

        if clearInteraction and not isContinuingNPCInteraction then
            ClearInteraction()
        end

        ResetSession()
        CallbackRegistry.Trigger("ControlCenter.SessionEnd")
    end

    function EventListener:Enable()
        for _, event in ipairs(EVENTS) do
            EventListener:RegisterEvent(event)
        end
    end

    function EventListener:Disable()
        SessionTimer:Stop()
        UpdateTimer:Stop()
        SessionOpenWatchdogTimer:Stop()
        EventListener:UnregisterAllEvents()
    end

    SessionTimer:SetAction(function()
        if isSessionActive then
            return
        end

        if scanFinalInteraction and ControlCenter_DataProvider.IsInteractingWithNpc() then
            SessionTimer:Start(FINAL_INTERACTION_SCAN_DELAY)
            return
        end

        EventListener:EndSession()
    end)

    UpdateTimer:SetAction(function()
        CallbackRegistry.Trigger("ControlCenter.Update")
    end)

    SessionOpenWatchdogTimer:SetAction(function()
        if not ControlCenter_Director.isInSession then return end
        if ControlCenter_DataProvider.IsInteractingWithNpc() then return end
        EventListener:EndSession(true)
    end)

    EventListener:SetScript("OnEvent", function(self, event, ...)
        if not ThrottleEvent(event) then
            return
        end

        if event == "QUEST_GREETING" then
            isGreeting = true
        end

        if BEGIN_SESSION_EVENTS[event] then
            OnSessionBegin(event)
        elseif END_SESSION_EVENTS[event] then
            OnSessionEnd()
        end

        if not ControlCenter_Director.isInSession then
            return
        end

        ProcessGossipEvent(event, ...)
        ProcessQuestEvent(event)
        UpdateSessionEndDelay()
        RelayEvent(event, ...)
    end)

    local f = CreateFrame("Frame")
    f:RegisterEvent("CINEMATIC_START")
    f:RegisterEvent("CINEMATIC_STOP")
    f:RegisterEvent("PLAY_MOVIE")
    f:RegisterEvent("STOP_MOVIE")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("QUEST_LOG_UPDATE")
    f:RegisterEvent("QUEST_ITEM_UPDATE")
    f:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
    f:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "CINEMATIC_STOP" or event == "STOP_MOVIE" then
            CallbackRegistry.Trigger("ControlCenter.CinematicEnd")
            return
        end

        if not ControlCenter_Director.isInSession then
            return
        end

        if event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
            local interactionType = ...
            if not IsDialogInteractionType(interactionType) then
                CallbackRegistry.Trigger("ControlCenter.SessionClosing")
                EventListener:EndSession()
            end
            return
        end

        if event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
            local interactionType = ...
            if IsDialogInteractionType(interactionType) then
                CallbackRegistry.Trigger("ControlCenter.SessionClosing")
                OnSessionEnd()
            end
            return
        end

        if event == "CINEMATIC_START" or event == "PLAY_MOVIE" then
            CallbackRegistry.Trigger("ControlCenter.CinematicBegin")
            EventListener:EndSession()
            return
        end

        if event == "PLAYER_REGEN_DISABLED" then
            CallbackRegistry.Trigger("ControlCenter.CombatBegin")
        elseif event == "PLAYER_REGEN_ENABLED" then
            CallbackRegistry.Trigger("ControlCenter.CombatEnd")
        end

        if event == "QUEST_LOG_UPDATE" then
            UpdateTimer:Start(0)
        elseif event == "QUEST_ITEM_UPDATE" then
            CallbackRegistry.Trigger("ControlCenter.Update")
        end
    end)
end

local function RegisterFrameEvents(frame, events)
    if not frame then
        return
    end

    for _, event in ipairs(events) do
        frame:RegisterEvent(event)
    end
end

local function UnregisterFrameEvents(frame, events)
    if not frame then
        return
    end

    for _, event in ipairs(events) do
        frame:UnregisterEvent(event)
    end
end

local function EnableBlizzardHandling()
    RegisterFrameEvents(CustomGossipFrameManager, CUSTOM_GOSSIP_EVENTS)
    RegisterFrameEvents(GossipFrame, GOSSIP_EVENTS)
    RegisterFrameEvents(QuestFrame, QUEST_EVENTS)
end

local function DisableBlizzardHandling()
    UnregisterFrameEvents(CustomGossipFrameManager, CUSTOM_GOSSIP_EVENTS)
    UnregisterFrameEvents(GossipFrame, GOSSIP_EVENTS)

    if QuestFrame then
        QuestFrame:UnregisterAllEvents()
    end
end

function ControlCenter_Director.Enable()
    if ControlCenter_Director.muteDefaultUI then
        DisableBlizzardHandling()
    end

    EventListener:Enable()
end

function ControlCenter_Director.Disable()
    if ControlCenter_Director.muteDefaultUI then
        EnableBlizzardHandling()
    end

    EventListener:Disable()
end

function ControlCenter_Director.EndSession(clearInteraction)
    EventListener:EndSession(clearInteraction)
end

ControlCenter_Director.Enable()
