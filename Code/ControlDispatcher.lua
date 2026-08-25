local env = select(2, ...)
local Config = env.Config
local Enum = env.Enum
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local WoWClient = env.modules:Import("packages\\wow-client")
local InputUtil = env.modules:Import("@\\InputUtil")
local ControlCenter = env.modules:Import("@\\Dialog\\ControlCenter")
local DialogFrame = env.modules:Import("@\\Dialog\\DialogFrame")
local Modes_ModeHandler = env.modules:Import("@\\Dialog\\Modes\\ModeHandler")
local ControlDispatcher = env.modules:New("@\\ControlDispatcher")


local REPEAT_INITIAL_DELAY = 0.375
local REPEAT_INTERVAL = 0.125
local driverFrame = CreateFrame("Frame")


local function TryClick(button)
    if button and button:IsShown() and button:IsVisible() then
        button:OnClick()
        WoWClient.BlockKeyEvent()
        return true
    end
end

local function TryScrollDown(container)
    if container and container:IsVisible() and container:HasContentBelow() then
        container:ScrollDown()
        WoWClient.BlockKeyEvent()
        return true
    end
end

local function TryScrollUp(container)
    if container and container:IsVisible() and container:HasContentAbove() then
        container:ScrollUp()
        WoWClient.BlockKeyEvent()
        return true
    end
end

local function HandleSelectionResult(selected, deselected, allowScroll, scrollFunc, scrollContainer)
    if selected then
        WoWClient.BlockKeyEvent()
        return true
    end

    if deselected then
        if allowScroll and scrollFunc(scrollContainer) then
            return true
        end

        WoWClient.BlockKeyEvent()
        return false
    end
end

local function HandleConfirmAction()
    if LWDialogFrame:ConfirmGossipSelection() or LWDialogFrame:ConfirmQuestSelection() then
        WoWClient.BlockKeyEvent()
        return true
    end

    return TryClick(LWDialogFrame.Footer.PrimaryButton)
end

local function HandleCloseAction()
    if Config.DBGlobal:GetVariable("EscapeDeclinesQuest") == false then
        DialogFrame.RequestCloseSession()
        WoWClient.BlockKeyEvent()
        return true
    end

    return TryClick(LWDialogFrame.Footer.SecondaryButton)
end

local function HandleScrollDownAction()
    if LWDialogFrame.GossipFrame:IsShown() then
        local selected, deselected, allowScroll = LWDialogFrame:SelectNextGossipOption()
        local result = HandleSelectionResult(selected, deselected, allowScroll, TryScrollDown, LWDialogFrame.GossipFrame.ScrollContainer)
        if result ~= nil then return result end
    end
    if LWDialogFrame.QuestFrame:IsShown() then
        local selected, deselected, allowScroll = LWDialogFrame:SelectNextQuestReward()
        local result = HandleSelectionResult(selected, deselected, allowScroll, TryScrollDown, LWDialogFrame.QuestFrame.ScrollContainer)
        if result ~= nil then return result end
    end
    if TryScrollDown(LWDialogFrame.GossipFrame.ScrollContainer) then
        return true
    end
    if TryScrollDown(LWDialogFrame.QuestFrame.ScrollContainer) then
        return true
    end
end

local function HandleScrollUpAction()
    if LWDialogFrame.GossipFrame:IsShown() then
        local selected, deselected, allowScroll = LWDialogFrame:SelectPreviousGossipOption()
        local result = HandleSelectionResult(selected, deselected, allowScroll, TryScrollUp, LWDialogFrame.GossipFrame.ScrollContainer)
        if result ~= nil then return result end
    end
    if LWDialogFrame.QuestFrame:IsShown() then
        local selected, deselected, allowScroll = LWDialogFrame:SelectPreviousQuestReward()
        local result = HandleSelectionResult(selected, deselected, allowScroll, TryScrollUp, LWDialogFrame.QuestFrame.ScrollContainer)
        if result ~= nil then return result end
    end
    if TryScrollUp(LWDialogFrame.GossipFrame.ScrollContainer) then
        return true
    end
    if TryScrollUp(LWDialogFrame.QuestFrame.ScrollContainer) then
        return true
    end
end

local function HandleSelectDialogOptionAction(optionIndex)
    ControlDispatcher.pushedDialogOption = LWDialogFrame:SetDialogOptionPushed(optionIndex, true)

    if ControlCenter.SelectDialogOption(optionIndex) then return true end

    ControlDispatcher.ReleasePushedDialogOption()
    return false
end

local DIALOG_FRAME_ACTIONS = {
    [InputUtil.Enum.Actions.Confirm] = {
        handler = HandleConfirmAction,
    },
    [InputUtil.Enum.Actions.Close] = {
        handler = HandleCloseAction,
    },
    [InputUtil.Enum.Actions.ScrollDown] = {
        handler = HandleScrollDownAction,
        repeatable = true,
    },
    [InputUtil.Enum.Actions.ScrollUp] = {
        handler = HandleScrollUpAction,
        repeatable = true,
    },
    [InputUtil.Enum.Actions.SelectOption1] = {
        handler = function() return HandleSelectDialogOptionAction(1) end,
        block = true,
    },
    [InputUtil.Enum.Actions.SelectOption2] = {
        handler = function() return HandleSelectDialogOptionAction(2) end,
        block = true,
    },
    [InputUtil.Enum.Actions.SelectOption3] = {
        handler = function() return HandleSelectDialogOptionAction(3) end,
        block = true,
    },
    [InputUtil.Enum.Actions.SelectOption4] = {
        handler = function() return HandleSelectDialogOptionAction(4) end,
        block = true,
    },
    [InputUtil.Enum.Actions.SelectOption5] = {
        handler = function() return HandleSelectDialogOptionAction(5) end,
        block = true,
    },
    [InputUtil.Enum.Actions.SelectOption6] = {
        handler = function() return HandleSelectDialogOptionAction(6) end,
        block = true,
    },
    [InputUtil.Enum.Actions.SelectOption7] = {
        handler = function() return HandleSelectDialogOptionAction(7) end,
        block = true,
    },
    [InputUtil.Enum.Actions.SelectOption8] = {
        handler = function() return HandleSelectDialogOptionAction(8) end,
        block = true,
    },
    [InputUtil.Enum.Actions.SelectOption9] = {
        handler = function() return HandleSelectDialogOptionAction(9) end,
        block = true,
    },
}

local IMMERSIVE_ACTIONS = {
    [InputUtil.Enum.Actions.PreviousDialog]  = {
        handler = LWImmersiveChatBubble.PreviousDialog,
        block = true,
    },
    [InputUtil.Enum.Actions.NextDialog]  = {
        handler = LWImmersiveChatBubble.NextDialog,
        block = true,
    },
}

local function IsImmersiveModeActive()
    return Modes_ModeHandler.IsModeActive(Enum.Mode.Immersive)
end

local function IsDialogFrameShown()
    return LWDialogFrame:IsShown()
end

local function CanProcessKeyInput()
    return IsImmersiveModeActive() or IsDialogFrameShown()
end

local function GetActionForKey(key, actions)
    for action, actionData in pairs(actions) do
        if key == InputUtil.GetKeybind(action) then
            return actionData
        end
    end
end

local function HandleActionForKey(key)
    if IsImmersiveModeActive() then
        local action = GetActionForKey(key, IMMERSIVE_ACTIONS)
        if action and action.handler(LWImmersiveChatBubble) then
            return action, IsImmersiveModeActive
        end
    end

    if IsDialogFrameShown() then
        local action = GetActionForKey(key, DIALOG_FRAME_ACTIONS)
        if action and action.handler() then
            return action, IsDialogFrameShown
        end
    end
end


function ControlDispatcher.RepeatAction_OnUpdate(_, elapsed)
    if not ControlDispatcher.repeatAction or not ControlDispatcher.repeatActionIsActive() then
        ControlDispatcher.StopRepeatingAction()
        return
    end

    ControlDispatcher.repeatElapsed = ControlDispatcher.repeatElapsed + elapsed
    if ControlDispatcher.repeatElapsed < REPEAT_INTERVAL then
        return
    end

    ControlDispatcher.repeatElapsed = 0

    if not ControlDispatcher.repeatAction.handler() then
        ControlDispatcher.StopRepeatingAction()
    end
end

function ControlDispatcher.StartRepeatingAction(key, action, isActionActive)
    ControlDispatcher.repeatKey = key
    ControlDispatcher.repeatAction = action
    ControlDispatcher.repeatActionIsActive = isActionActive
    ControlDispatcher.repeatElapsed = -REPEAT_INITIAL_DELAY
    driverFrame:SetScript("OnUpdate", ControlDispatcher.RepeatAction_OnUpdate)
end

function ControlDispatcher.StopRepeatingAction()
    if not ControlDispatcher.repeatAction then
        return
    end

    driverFrame:SetScript("OnUpdate", nil)
    ControlDispatcher.repeatKey = nil
    ControlDispatcher.repeatAction = nil
    ControlDispatcher.repeatActionIsActive = nil
    ControlDispatcher.repeatElapsed = nil
end

function ControlDispatcher.ReleasePushedDialogOption()
    local optionElement = ControlDispatcher.pushedDialogOption
    ControlDispatcher.pushedDialogOption = nil
    ControlDispatcher.pushedDialogOptionKey = nil
    if not optionElement then return end

    optionElement:SetPushed(false)
    optionElement:UpdateButtonState()
end

function ControlDispatcher.OnKeyDown(key)
    if not CanProcessKeyInput() then
        ControlDispatcher.StopRepeatingAction()
        ControlDispatcher.ReleasePushedDialogOption()
        return
    end

    if key == ControlDispatcher.repeatKey or key == ControlDispatcher.pushedDialogOptionKey then
        WoWClient.BlockKeyEvent()
        return
    end

    ControlDispatcher.StopRepeatingAction()
    ControlDispatcher.ReleasePushedDialogOption()

    local action, isActionActive = HandleActionForKey(key)
    if not action then return end

    if ControlDispatcher.pushedDialogOption then
        ControlDispatcher.pushedDialogOptionKey = key
    end

    if action.block then
        WoWClient.BlockKeyEvent()
    end

    if action.repeatable then
        ControlDispatcher.StartRepeatingAction(key, action, isActionActive)
    end
end

function ControlDispatcher.OnKeyUp(key)
    if key == ControlDispatcher.repeatKey then
        ControlDispatcher.StopRepeatingAction()
    end

    if key == ControlDispatcher.pushedDialogOptionKey then
        ControlDispatcher.ReleasePushedDialogOption()
    end
end

CallbackRegistry.Add("WoWClient.OnKeyDown", function(_, key) ControlDispatcher.OnKeyDown(key) end)
CallbackRegistry.Add("WoWClient.OnKeyUp", function(_, key) ControlDispatcher.OnKeyUp(key) end)
CallbackRegistry.Add("ControlCenter.ModeChanged", ControlDispatcher.StopRepeatingAction)
