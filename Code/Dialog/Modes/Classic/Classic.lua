local env = select(2, ...)
local Enum = env.Enum
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local ControlCenter = env.modules:Import("@\\Dialog\\ControlCenter")
local DialogFrame = env.modules:Import("@\\Dialog\\DialogFrame")
local Modes_ModeHandler = env.modules:Import("@\\Dialog\\Modes\\ModeHandler")
local ClassicMode = env.modules:New("@\\Dialog\\Modes\\Classic")


ClassicMode.isActive = false


local function CloseSession()
    ControlCenter.CloseSession()
    CallbackRegistry.Trigger("DialogFrame.CloseSession")
end

local ACTION_HANDLERS = {
    [DialogFrame.Enum.Action.Goodbye]    = CloseSession,
    [DialogFrame.Enum.Action.Cancel]     = function()
        if ControlCenter.IsGossipQuest() then
            ControlCenter.DeclineCurrentQuest()
        else
            CloseSession()
        end
    end,
    [DialogFrame.Enum.Action.Accept]     = ControlCenter.AcceptCurrentQuest,
    [DialogFrame.Enum.Action.AutoAccept] = CloseSession,
    [DialogFrame.Enum.Action.Continue]   = ControlCenter.ContinueCurrentQuest,
    [DialogFrame.Enum.Action.Complete]   = ControlCenter.CompleteCurrentQuest
}

function ClassicMode.Activate()
    ClassicMode.isActive = true
    LWDialogFrame:SetDefaultTextShown(true)

    if ControlCenter.GetGossipSessionType() then
        ClassicMode.OnShowGossip()
    elseif ControlCenter.GetQuestSessionType() then
        ClassicMode.OnShowQuest()
    else
        LWDialogFrame:HideQuestModelFrame()
        LWDialogFrame:Close()
    end
end

function ClassicMode.Deactivate()
    ClassicMode.isActive = false
    LWDialogFrame:HideQuestModelFrame()
    LWDialogFrame:Close()
end


function ClassicMode.OnQuestRewardChoiceSelected()
    if not ClassicMode.isActive then return end
    LWDialogFrame:UpdateFooterButtons()
end

function ClassicMode.OnSessionEnd()
    if not ClassicMode.isActive then return end
    LWDialogFrame:HideQuestModelFrame()
    LWDialogFrame:Close()
end

function ClassicMode.OnShowGossip()
    if not ClassicMode.isActive then return end

    LWDialogFrame:HideQuestModelFrame()
    LWDialogFrame:RefreshGossipFrame()
    LWDialogFrame:Open()
    LWDialogFrame.GossipFrame.ScrollContainer:SetVerticalScroll(0, true)
    LWDialogFrame.GossipFrame:_Render()
    LWDialogFrame:RefreshEdgeFade()
end

function ClassicMode.OnHideGossip(_, interactionIsContinuing)
    if not ClassicMode.isActive then return end
    LWDialogFrame:Close(interactionIsContinuing)
end

function ClassicMode.OnUpdateGossip()
    if not ClassicMode.isActive or not ControlCenter.IsGossipValidForUpdate() then return end
    LWDialogFrame:UpdateGossipQuestOptions()
end

function ClassicMode.OnShowQuest()
    if not ClassicMode.isActive then return end

    LWDialogFrame:RefreshQuestFrame()
    LWDialogFrame:RefreshQuestModelFrame()
    LWDialogFrame:Open()
    LWDialogFrame.QuestFrame.ScrollContainer:SetVerticalScroll(0, true)
    LWDialogFrame.QuestFrame:_Render()
    LWDialogFrame:RefreshEdgeFade()
end

function ClassicMode.OnHideQuest()
    if not ClassicMode.isActive then return end
    LWDialogFrame:HideQuestModelFrame()
    LWDialogFrame:Close()
end

function ClassicMode.OnUpdateQuest()
    if not ClassicMode.isActive or not ControlCenter.GetQuestSessionType() then return end

    LWDialogFrame:RefreshQuestFrame()
    LWDialogFrame:RefreshQuestModelFrame()
    LWDialogFrame.QuestFrame:_Render()
end

function ClassicMode.OnPortraitUpdate()
    if not ClassicMode.isActive or not ControlCenter.GetQuestSessionType() then return end
    LWDialogFrame:RefreshQuestModelFrame()
end


function ClassicMode.OnCloseSessionRequested()
    if not ClassicMode.isActive then return end
    CloseSession()
end

function ClassicMode.OnActionRequested(_, action)
    if not ClassicMode.isActive then return end

    local handler = ACTION_HANDLERS[action]
    if handler then handler() end
end

function ClassicMode.OnGossipOptionSelectionRequested(_, optionType, optionKey)
    if not ClassicMode.isActive then return end
    ControlCenter.SelectGossipOption(optionType, optionKey)
end

function ClassicMode.OnQuestRewardSelectionRequested(_, rewardIndex)
    if not ClassicMode.isActive then return end
    ControlCenter.SelectQuestReward(rewardIndex)
end


CallbackRegistry.Add("ControlCenter.QuestRewardChoiceSelected", ClassicMode.OnQuestRewardChoiceSelected)
CallbackRegistry.Add("ControlCenter.SessionEnd", ClassicMode.OnSessionEnd)
CallbackRegistry.Add("ControlCenter.ShowGossip", ClassicMode.OnShowGossip)
CallbackRegistry.Add("ControlCenter.HideGossip", ClassicMode.OnHideGossip)
CallbackRegistry.Add("ControlCenter.UpdateGossip", ClassicMode.OnUpdateGossip)
CallbackRegistry.Add("ControlCenter.ShowQuest", ClassicMode.OnShowQuest)
CallbackRegistry.Add("ControlCenter.HideQuest", ClassicMode.OnHideQuest)
CallbackRegistry.Add("ControlCenter.UpdateQuest", ClassicMode.OnUpdateQuest)
CallbackRegistry.Add("UNIT_PORTRAIT_UPDATE", ClassicMode.OnPortraitUpdate)
CallbackRegistry.Add("PORTRAITS_UPDATED", ClassicMode.OnPortraitUpdate)
CallbackRegistry.Add(DialogFrame.Events.CloseSessionRequested, ClassicMode.OnCloseSessionRequested)
CallbackRegistry.Add(DialogFrame.Events.ActionRequested, ClassicMode.OnActionRequested)
CallbackRegistry.Add(DialogFrame.Events.GossipOptionSelectionRequested, ClassicMode.OnGossipOptionSelectionRequested)
CallbackRegistry.Add(DialogFrame.Events.QuestRewardSelectionRequested, ClassicMode.OnQuestRewardSelectionRequested)


Modes_ModeHandler.RegisterMode(Enum.Mode.Classic, ClassicMode)
