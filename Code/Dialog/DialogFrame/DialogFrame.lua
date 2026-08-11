local env = select(2, ...)
local L = env.L
local Config = env.Config
local Pool = env.modules:Import("packages\\pool")
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local UIKit = env.modules:Import("packages\\ui-kit")
local UIAnim = env.modules:Import("packages\\ui-anim")
local InputUtil = env.modules:Import("@\\InputUtil")
local Modes_ModeHandler = env.modules:Await("@\\Dialog\\Modes\\ModeHandler")
local Settings = env.modules:Await("@\\Settings")
local PlayerMovementFrameFader = env.modules:Import("@\\PlayerMovementFrameFader")
local ControlCenter_Preload = env.modules:Import("@\\Dialog\\ControlCenter\\Preload")
local ControlCenter_ContextIcon = env.modules:Import("@\\Dialog\\ControlCenter\\ContextIcon")
local ControlCenter = env.modules:Import("@\\Dialog\\ControlCenter")
local DialogFrame_Preload = env.modules:Import("@\\Dialog\\DialogFrame\\Preload")
local DialogFrame = env.modules:New("@\\Dialog\\DialogFrame")

DialogFrame.Events = {
    OpenRequested                  = "DialogFrame.OpenRequested",
    CloseRequested                 = "DialogFrame.CloseRequested",
    CloseSessionRequested          = "DialogFrame.CloseSessionRequested",
    ActionRequested                = "DialogFrame.ActionRequested",
    GossipOptionSelectionRequested = "DialogFrame.GossipOptionSelectionRequested",
    QuestRewardSelectionRequested  = "DialogFrame.QuestRewardSelectionRequested"
}
DialogFrame.Enum = {
    Action = {
        Goodbye    = 1,
        Cancel     = 2,
        Accept     = 3,
        AutoAccept = 4,
        Continue   = 5,
        Complete   = 6
    }
}
local GOSSIP_SELECTION_GROUPS = {
    { group = "GossipAvailableQuests", list = "OptionListFrame" },
    { group = "GossipActiveQuests",    list = "OptionListFrame" },
    { group = "GossipOptions",         list = "OptionListFrame" }
}
local QUEST_SELECTION_GROUPS = {
    { group = "QuestSpellObjective",         list = "SpellRewardListFrame" },
    { group = "QuestItemRewards",            list = "RewardListFrame" },
    { group = "QuestItemChoiceRewards",      list = "RewardListFrame" },
    { group = "QuestSpellRewards",           list = "SpellRewardListFrame" },
    { group = "QuestItemReceiveRewards",     list = "RewardListFrame" },
    { group = "QuestCurrencyReceiveRewards", list = "RewardListFrame" },
    { group = "QuestSkillReceiveRewards",    list = "RewardListFrame" }
}
local DEFAULT_POOL_ELEMENT_TYPE = "Default"
local MODEL_ZOOM_DISTANCE = 1.25
local MODEL_ZOOM_MAX_DISTANCE = 1.5


function DialogFrame.RequestOpen()
    CallbackRegistry.Trigger(DialogFrame.Events.OpenRequested)
end

function DialogFrame.RequestClose()
    CallbackRegistry.Trigger(DialogFrame.Events.CloseRequested)
end

function DialogFrame.RequestCloseSession()
    CallbackRegistry.Trigger(DialogFrame.Events.CloseSessionRequested)
end

function DialogFrame.RequestAction(action)
    CallbackRegistry.Trigger(DialogFrame.Events.ActionRequested, action)
end

function DialogFrame.RequestGossipOptionSelection(optionType, optionKey)
    CallbackRegistry.Trigger(DialogFrame.Events.GossipOptionSelectionRequested, optionType, optionKey)
end

function DialogFrame.RequestQuestRewardSelection(rewardIndex)
    CallbackRegistry.Trigger(DialogFrame.Events.QuestRewardSelectionRequested, rewardIndex)
end


local DialogFrameMixin = {}

local function SettingsMenu_IsModeSelected(modeID)
    return Modes_ModeHandler.GetMode() == modeID
end

local function SettingsMenu_SetMode(modeID)
    Modes_ModeHandler.SetMode(modeID)
end

local function SettingsMenu_OpenSettingsUI()
    ControlCenter.CloseSession()
    Settings.OpenSettingsUI()
end

local function CreateSettingsMenu(_, rootDescription)
    rootDescription:CreateButton(L["DIALOG_SETTINGS_OPEN"], SettingsMenu_OpenSettingsUI)

    local modeMenu = rootDescription:CreateButton(L["DIALOG_SETTINGS_MODE"])
    modeMenu:CreateRadio(L["CONFIG_DIALOGUE_MODE_CLASSIC"], SettingsMenu_IsModeSelected, SettingsMenu_SetMode, env.Enum.Mode.Classic)
    modeMenu:CreateRadio(L["CONFIG_DIALOGUE_MODE_IMMERSIVE"], SettingsMenu_IsModeSelected, SettingsMenu_SetMode, env.Enum.Mode.Immersive)
end

function DialogFrameMixin:OpenSettingsMenu()
    local menu = MenuUtil.CreateContextMenu(self.TitleContainer.SettingButton, CreateSettingsMenu)

    if not menu then return end
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", self.TitleContainer.SettingButton, "BOTTOMLEFT")
end

function DialogFrameMixin:OnLoad()
    self.showDefaultText = true
    self.forcedAspectRatio = 1.32
    self.minWidth = 378
    self.minHeight = self.minWidth * self.forcedAspectRatio
    self.maxWidth = 592
    self.maxHeight = self.maxWidth * self.forcedAspectRatio

    self.TitleContainer:SetScript("OnDragStart", function()
        SetCursor("Interface\\Cursor\\UI-Cursor-Move")
        self:StartMoving()
    end)

    self.TitleContainer:SetScript("OnDragStop", function()
        ResetCursor()
        self:StopMovingOrSizing()
        self:SavePositionAndDimensions()
    end)

    self.TitleContainer.CloseButton:HookClick(function()
        self:CloseSession()
    end)

    self.TitleContainer.SettingButton:HookClick(function()
        self:OpenSettingsMenu()
    end)

    CallbackRegistry.Add(DialogFrame.Events.OpenRequested, function() self:Open() end)
    CallbackRegistry.Add(DialogFrame.Events.CloseRequested, function() self:Close() end)

    self.ResizeHandle:AddOnMouseDown(function() self:StartResizing() end)
    self.ResizeHandle:AddOnMouseUp(function() self:StopResizing() end)
    self.ResizeHandle:AddOnEnter(function() SetCursor("UI_RESIZE_CURSOR") end)
    self.ResizeHandle:AddOnLeave(function() ResetCursor() end)

    --Stop resizing when the dialog frame closes
    CallbackRegistry.Add("DialogFrame.Close", function()
        if self.isResizing then
            self:StopResizing()
        end
    end)

    -- Re-render when the UI scale changes
    CallbackRegistry.Add("WoWClient.OnUIScaleChanged", function()
        if self:IsVisible() then
            self:_Render()
        end
    end)

    CallbackRegistry.Add("InputUtil.SetInputDevice", function()
        self:RefreshDialogOptionLabels()
    end)

    --Force aspect ratio
    self:HookScript("OnSizeChanged", function(_, width) self:SetHeight(width * self.forcedAspectRatio) end)

    self:resizeBounds(self.minWidth, self.minHeight, self.maxWidth, self.maxHeight)

    self:SetSize(self.minWidth, self.minHeight) --WIP
    C_Timer.After(1, function()
        self:RestorePositionAndDimensions()
    end)

    self.Selection:Hide()
    self:SetDialogGlyphVisibility(false)
    self:Close()

    DialogFrame_Preload:SetBackground(self.ContentFrame.BackgroundTexture)
    PlayerMovementFrameFader.AddDeferredFrame(self.ContainerFrame, 0.5, 1, 0.5, function() return not self:IsMouseOver() end)
end

function DialogFrameMixin:SetDialogGlyphVisibility(visibility)
    self.DialogGlyph:SetShown(visibility)
end

function DialogFrameMixin:UpdateDialogGlyph()
    local hasContent = nil
    if ControlCenter.GetGossipSessionType() then
        hasContent = self.GossipFrame.GossipText:IsShown() or self.GossipFrame.GossipAvailableQuests:IsShown() or self.GossipFrame.GossipActiveQuests:IsShown() or self.GossipFrame.GossipOptions:IsShown()
    elseif ControlCenter.GetQuestSessionType() then
        hasContent = self.QuestFrame.QuestTitleContainer.TitleText:IsShown() or self.QuestFrame.QuestTitleContainer.CampaignText:IsShown() or self.QuestFrame.QuestText:IsShown() or self.QuestFrame.QuestObjectivesHeader:IsShown() or self.QuestFrame.QuestRewardsHeader:IsShown()
    end

    self:SetDialogGlyphVisibility(not hasContent)
end

function DialogFrameMixin:SetSelectableGroupData(group, data)
    group:SetShown(#data > 0)
    if #data > 0 then
        group:SetData(data)
    end
end

local function RefreshListData(list)
    local data = list:GetData()
    if data then
        list:SetData(data)
    end
end

function DialogFrameMixin:RefreshDialogOptionLabels()
    if not self:IsShown() then return end

    if self.GossipFrame:IsShown() then
        RefreshListData(self.GossipFrame.GossipAvailableQuests.OptionListFrame)
        RefreshListData(self.GossipFrame.GossipActiveQuests.OptionListFrame)
        RefreshListData(self.GossipFrame.GossipOptions.OptionListFrame)
    elseif self.QuestFrame:IsShown() then
        RefreshListData(self.QuestFrame.QuestItemChoiceRewards.RewardListFrame)
    end

    self:_Render()
end

local function GetListElementPoolIndex(data, dataIndex, typeKey)
    local poolIndex = 0
    for index = 1, dataIndex do
        local value = data[index]
        if (value.uk_poolElementType or DEFAULT_POOL_ELEMENT_TYPE) == typeKey then
            poolIndex = poolIndex + 1
        end
    end
    return poolIndex
end

function DialogFrameMixin:ForEachSelectableList(list, reverse, func, allowOffscreen)
    local data = list:GetData()
    if not data then return end

    if reverse then
        for index = #data, 1, -1 do
            local value = data[index]
            local typeKey = value.uk_poolElementType or DEFAULT_POOL_ELEMENT_TYPE
            if typeKey ~= "HEADER" then
                local poolIndex = GetListElementPoolIndex(data, index, typeKey)
                local element = list:GetVisibleElement(poolIndex, typeKey) or (allowOffscreen and list:GetElement(poolIndex, typeKey))
                if element and func(element, value) then
                    return true
                end
            end
        end
    else
        for index = 1, #data do
            local value = data[index]
            local typeKey = value.uk_poolElementType or DEFAULT_POOL_ELEMENT_TYPE
            if typeKey ~= "HEADER" then
                local poolIndex = GetListElementPoolIndex(data, index, typeKey)
                local element = list:GetVisibleElement(poolIndex, typeKey) or (allowOffscreen and list:GetElement(poolIndex, typeKey))
                if element and func(element, value) then
                    return true
                end
            end
        end
    end
end

function DialogFrameMixin:ForEachSelectableGroup(frame, groups, reverse, func, allowOffscreen)
    if reverse then
        for index = #groups, 1, -1 do
            local group = frame[groups[index].group]
            if group and group:IsShown() and DialogFrameMixin:ForEachSelectableList(group[groups[index].list], true, function(element, value)
                    return func(element, value, groups[index].group)
                end, allowOffscreen) then
                return true
            end
        end
    else
        for index = 1, #groups do
            local group = frame[groups[index].group]
            if group and group:IsShown() and DialogFrameMixin:ForEachSelectableList(group[groups[index].list], false, function(element, value)
                    return func(element, value, groups[index].group)
                end, allowOffscreen) then
                return true
            end
        end
    end
end

function DialogFrameMixin:GetDialogOptionElement(optionIndex)
    if self.GossipFrame:IsShown() then
        local optionElement = nil
        DialogFrameMixin:ForEachSelectableGroup(self.GossipFrame, GOSSIP_SELECTION_GROUPS, false, function(element, optionInfo)
            if optionInfo.dialogOptionIndex == optionIndex then
                optionElement = element
                return true
            end
        end, true)
        return optionElement
    end

    if self.QuestFrame:IsShown() and self.QuestFrame.QuestItemChoiceRewards:IsShown() then
        local list = self.QuestFrame.QuestItemChoiceRewards.RewardListFrame
        local data = list:GetData()
        local rewardInfo = data and data[optionIndex]
        if not rewardInfo then return end

        local typeKey = rewardInfo.uk_poolElementType or DEFAULT_POOL_ELEMENT_TYPE
        local poolIndex = GetListElementPoolIndex(data, optionIndex, typeKey)
        return list:GetVisibleElement(poolIndex, typeKey) or list:GetElement(poolIndex, typeKey)
    end
end

function DialogFrameMixin:SetDialogOptionPushed(optionIndex, pushed)
    local optionElement = self:GetDialogOptionElement(optionIndex)
    if not optionElement then return end

    optionElement:SetPushed(pushed)
    optionElement:UpdateButtonState()
    return optionElement
end

function DialogFrameMixin:GetSelectableElementViewportState(scrollContainer, element)
    if not scrollContainer or not element or not element:IsShown() then return end

    local scrollFrame = scrollContainer:GetScrollFrame()
    local frameTop = scrollFrame and scrollFrame:GetTop()
    local frameBottom = scrollFrame and scrollFrame:GetBottom()
    local elementTop = element:GetTop()
    local elementBottom = element:GetBottom()
    if not frameTop or not frameBottom or not elementTop or not elementBottom then return end

    if elementBottom > frameTop then
        return DialogFrame_Preload.Enum.SelectableViewportState.Above
    elseif elementTop < frameBottom then
        return DialogFrame_Preload.Enum.SelectableViewportState.Below
    end
    return DialogFrame_Preload.Enum.SelectableViewportState.Visible
end

function DialogFrameMixin:EnsureSelectableElementVisible(scrollContainer, element)
    if not scrollContainer or not element or not element:IsShown() then return end

    local contentFrame = scrollContainer:GetContentFrame()
    local scrollFrame = scrollContainer:GetScrollFrame()
    local contentTop = contentFrame and contentFrame:GetTop()
    local elementTop = element:GetTop()
    local elementBottom = element:GetBottom()
    if not contentTop or not elementTop or not elementBottom then return end

    local scroll = scrollContainer:GetVerticalScroll()
    local top = contentTop - elementTop
    local bottom = contentTop - elementBottom
    local nextScroll = nil

    if top < scroll then
        nextScroll = top
    elseif bottom > scroll + scrollFrame:GetHeight() then
        nextScroll = bottom - scrollFrame:GetHeight()
    end

    if nextScroll then
        scrollContainer:SetVerticalScroll(nextScroll)
    end
end

function DialogFrameMixin:UpdateSelectableElementState(previousElement, nextElement)
    if previousElement == nextElement then return end
    if previousElement then previousElement:OnLeave() end
    if nextElement then nextElement:OnEnter() end
end

function DialogFrameMixin:RestorePositionAndDimensions()
    local bounds = Config.DBGlobal:GetVariable("dialogFrameBounds")

    if bounds and bounds.width and bounds.height then
        self:SetSize(bounds.width, bounds.height)
    end

    if not bounds or not bounds.point or not bounds.x or not bounds.y then
        self:SetDefaultPosition()
    else
        self:ClearAllPoints()
        self:SetPoint(bounds.point, UIParent, bounds.x, bounds.y)
    end

    self:_Render()
end

function DialogFrameMixin:SavePositionAndDimensions()
    local point, _, _, x, y = self:GetPoint()
    local width, height = self:GetSize()

    Config.DBGlobal:SetVariable({ "dialogFrameBounds", "point" }, point)
    Config.DBGlobal:SetVariable({ "dialogFrameBounds", "x" }, x)
    Config.DBGlobal:SetVariable({ "dialogFrameBounds", "y" }, y)
    Config.DBGlobal:SetVariable({ "dialogFrameBounds", "width" }, width)
    Config.DBGlobal:SetVariable({ "dialogFrameBounds", "height" }, height)
end

function DialogFrameMixin:SetDefaultPosition()
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()
    local defaultX = (screenWidth / 4) - (LWDialogFrame:GetWidth() / 2)
    local defaultY = (screenHeight / 2) - (LWDialogFrame:GetHeight() / 2)

    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", UIParent, defaultX, -defaultY)
end

function DialogFrameMixin:ShowSelectionHighlight()
    self.Selection:Show()
    self:SetAlpha(0)
end

function DialogFrameMixin:HideSelectionHighlight()
    self.Selection:Hide()
    self:SetAlpha(1)
end

function DialogFrameMixin:StartResizing()
    self:ShowSelectionHighlight()

    self.isResizing = true
    self:StartSizing()
end

function DialogFrameMixin:StopResizing()
    self:HideSelectionHighlight()
    self:RefreshEdgeFade()

    self.isResizing = false
    self:StopMovingOrSizing()
    self:SavePositionAndDimensions()

    if self:IsShown() then
        self:_Render()
    end
end

function DialogFrameMixin:Open()
    self:Show()
    self.AnimGroup:Play(self, "INSTANT")
    self.AnimGroup:Play(self, "CONTENT_INTRO")

    self:UpdateTitle()
    self:UpdateBackground()
    self:UpdateDetailsState()
    self:UpdateFooterButtons()
    self:UpdateDialogGlyph()

    CallbackRegistry.Trigger("DialogFrame.Open")
end

function DialogFrameMixin:Close()
    self:ResetGossipSelection()
    self:ResetQuestSelection()
    self:SetDialogGlyphVisibility(false)
    self:Hide()
    CallbackRegistry.Trigger("DialogFrame.Close")
end

function DialogFrameMixin:CloseSession()
    DialogFrame.RequestCloseSession()
end

function DialogFrameMixin:SetDefaultTextShown(shown)
    self.showDefaultText = shown
    if not shown then
        self.GossipFrame.GossipText:Hide()
        self.QuestFrame.QuestText:Hide()
    end
end

function DialogFrameMixin:UpdateTitle()
    local npcName = ControlCenter.GetNPCName()
    self.TitleContainer.Name:SetText(npcName)
    ControlCenter.SetUnitPortrait(self.TitleContainer.Portrait.UnitPortrait:GetTextureFrame():GetTextureObject())
end

function DialogFrameMixin:UpdateBackground()
    DialogFrame_Preload:SetBackground(self.ContentFrame.BackgroundTexture)
end

function DialogFrameMixin:UpdateDetailsState()
    self.GossipFrame:SetShown(ControlCenter.GetGossipSessionType())
    self.QuestFrame:SetShown(ControlCenter.GetQuestSessionType())
end

do --Gossip
    function DialogFrameMixin:UpdateGossipOptionIndices()
        local optionIndex = 1
        local gossipQuests = ControlCenter.GetGossipOptionsQuestQuest()
        local gossipOptions = ControlCenter.GetGossipOptions()

        for _, optionInfo in ipairs(gossipQuests) do
            optionInfo.dialogOptionIndex = optionIndex <= 9 and optionIndex or nil
            optionIndex = optionIndex + 1
        end

        for _, optionInfo in ipairs(gossipOptions) do
            optionInfo.dialogOptionIndex = optionIndex <= 9 and optionIndex or nil
            optionIndex = optionIndex + 1
        end
    end

    function DialogFrameMixin:RefreshGossipFrame()
        self:UpdateGossipText()
        self:UpdateGossipQuestOptions()
    end

    function DialogFrameMixin:UpdateGossipText()
        local gossipText = ControlCenter.GetGossipText()
        local isValidGossipText = gossipText and #gossipText >= 2

        self.GossipFrame.GossipText:SetShown(self.showDefaultText and isValidGossipText)
        if self.showDefaultText and isValidGossipText then
            self.GossipFrame.GossipText:SetText(gossipText)
        end
    end

    function DialogFrameMixin:UpdateGossipOptions()
        DialogFrameMixin:SetSelectableGroupData(self.GossipFrame.GossipOptions, ControlCenter.GetGossipOptions())
    end

    function DialogFrameMixin:UpdateGossipQuestOptions()
        self:UpdateGossipOptionIndices()

        local availableQuests = ControlCenter.GetGossipOptionsQuestQuestAvailable()
        local incompleteQuests = ControlCenter.GetGossipOptionsQuestQuestIncomplete()
        local completeQuests = ControlCenter.GetGossipOptionsQuestQuestComplete()

        --available quests
        DialogFrameMixin:SetSelectableGroupData(self.GossipFrame.GossipAvailableQuests, availableQuests)

        --completed and incompleted quests
        if not self.combinedQuests then self.combinedQuests = {} end
        wipe(self.combinedQuests)
        for _, quest in ipairs(completeQuests) do
            tinsert(self.combinedQuests, quest)
        end
        for _, quest in ipairs(incompleteQuests) do
            tinsert(self.combinedQuests, quest)
        end

        DialogFrameMixin:SetSelectableGroupData(self.GossipFrame.GossipActiveQuests, self.combinedQuests)
        self:UpdateGossipOptions()

        self:RefreshGossipSelection()
        self:UpdateDialogGlyph()
    end

    function DialogFrameMixin:ResetGossipSelection(boundary, allowBoundaryScroll)
        DialogFrameMixin:UpdateSelectableElementState(self.gossipSelectedElement, nil)
        self.gossipSelectedElement = nil
        self.gossipSelectedType = nil
        self.gossipSelectedKey = nil
        self.gossipSelectionBoundary = boundary
        self.gossipSelectionBoundaryAllowScroll = allowBoundaryScroll
    end

    function DialogFrameMixin:RefreshGossipSelection()
        local optionType = self.gossipSelectedType
        local optionKey = self.gossipSelectedKey
        if not optionKey then return end

        if DialogFrameMixin:ForEachSelectableGroup(self.GossipFrame, GOSSIP_SELECTION_GROUPS, false, function(element, option)
                if option.optionType == optionType and option.optionKey == optionKey then
                    return self:SetGossipSelection(element, option)
                end
            end, true) then
            return
        end

        self:ResetGossipSelection()
    end

    function DialogFrameMixin:SetGossipSelection(element, option)
        DialogFrameMixin:UpdateSelectableElementState(self.gossipSelectedElement, element)
        self.gossipSelectedElement = element
        self.gossipSelectedType = option.optionType
        self.gossipSelectedKey = option.optionKey
        self.gossipSelectionBoundary = nil
        self.gossipSelectionBoundaryAllowScroll = nil
        DialogFrameMixin:EnsureSelectableElementVisible(self.GossipFrame.ScrollContainer, element)
        return true
    end

    function DialogFrameMixin:SelectNextGossipOption()
        if self.gossipSelectionBoundary == DialogFrame_Preload.Enum.OptionBoundaryType.AfterLast then
            return false, true, self.gossipSelectionBoundaryAllowScroll
        end

        local optionType = self.gossipSelectedType
        local optionKey = self.gossipSelectedKey
        local seenSelected = not optionKey
        local targetIsBelow = nil

        if DialogFrameMixin:ForEachSelectableGroup(self.GossipFrame, GOSSIP_SELECTION_GROUPS, false, function(element, option)
                if seenSelected then
                    local viewportState = DialogFrameMixin:GetSelectableElementViewportState(self.GossipFrame.ScrollContainer, element)
                    if viewportState == DialogFrame_Preload.Enum.SelectableViewportState.Below then
                        targetIsBelow = true
                        return true
                    elseif viewportState ~= DialogFrame_Preload.Enum.SelectableViewportState.Visible then
                        return
                    end
                    return self:SetGossipSelection(element, option)
                elseif option.optionType == optionType and option.optionKey == optionKey then
                    seenSelected = true
                end
            end, true) then
            if targetIsBelow then
                return false, true, self.GossipFrame.ScrollContainer:HasContentBelow()
            end
            return true
        end

        if optionKey and seenSelected then
            local allowScroll = self.GossipFrame.ScrollContainer:HasContentBelow()
            self:ResetGossipSelection(DialogFrame_Preload.Enum.OptionBoundaryType.AfterLast, allowScroll)
            return false, true, allowScroll
        end
    end

    function DialogFrameMixin:SelectPreviousGossipOption()
        if self.gossipSelectionBoundary == DialogFrame_Preload.Enum.OptionBoundaryType.BeforeFirst then
            return false, true, self.gossipSelectionBoundaryAllowScroll
        end

        local optionType = self.gossipSelectedType
        local optionKey = self.gossipSelectedKey
        local seenSelected = not optionKey
        local targetIsAbove = nil

        if DialogFrameMixin:ForEachSelectableGroup(self.GossipFrame, GOSSIP_SELECTION_GROUPS, true, function(element, option)
                if seenSelected then
                    local viewportState = DialogFrameMixin:GetSelectableElementViewportState(self.GossipFrame.ScrollContainer, element)
                    if viewportState == DialogFrame_Preload.Enum.SelectableViewportState.Above then
                        targetIsAbove = true
                        return true
                    elseif viewportState ~= DialogFrame_Preload.Enum.SelectableViewportState.Visible then
                        return
                    end
                    return self:SetGossipSelection(element, option)
                elseif option.optionType == optionType and option.optionKey == optionKey then
                    seenSelected = true
                end
            end, true) then
            if targetIsAbove then
                return false, true, self.GossipFrame.ScrollContainer:HasContentAbove()
            end
            return true
        end

        if optionKey and seenSelected then
            local allowScroll = self.GossipFrame.ScrollContainer:HasContentAbove()
            self:ResetGossipSelection(DialogFrame_Preload.Enum.OptionBoundaryType.BeforeFirst, allowScroll)
            return false, true, allowScroll
        end
    end

    function DialogFrameMixin:ConfirmGossipSelection()
        if self.GossipFrame:IsShown() and self.gossipSelectedElement then
            self.gossipSelectedElement:OnClick()
            return true
        end
    end
end

do --Quest
    do --Spell Reward
        local QUEST_SPELL_TYPE_PRIORITY = {
            [Enum.QuestCompleteSpellType.LegacyBehavior]      = 0,
            [Enum.QuestCompleteSpellType.Follower]            = 1,
            [Enum.QuestCompleteSpellType.Companion]           = 2,
            [Enum.QuestCompleteSpellType.Tradeskill]          = 3,
            [Enum.QuestCompleteSpellType.Ability]             = 4,
            [Enum.QuestCompleteSpellType.Aura]                = 5,
            [Enum.QuestCompleteSpellType.Spell]               = 6,
            [Enum.QuestCompleteSpellType.Unlock]              = 7,
            [Enum.QuestCompleteSpellType.QuestlineUnlock]     = 8,
            [Enum.QuestCompleteSpellType.QuestlineReward]     = 9,
            [Enum.QuestCompleteSpellType.QuestlineUnlockPart] = 10,
            [Enum.QuestCompleteSpellType.PossibleReward]      = 11
        }

        local QUEST_SPELL_TYPE_HEADER_LOOKUP = {
            [Enum.QuestCompleteSpellType.LegacyBehavior]      = REWARD_AURA,
            [Enum.QuestCompleteSpellType.Follower]            = REWARD_FOLLOWER,
            [Enum.QuestCompleteSpellType.Companion]           = REWARD_COMPANION,
            [Enum.QuestCompleteSpellType.Tradeskill]          = REWARD_TRADESKILL_SPELL,
            [Enum.QuestCompleteSpellType.Ability]             = REWARD_ABILITY,
            [Enum.QuestCompleteSpellType.Aura]                = REWARD_AURA,
            [Enum.QuestCompleteSpellType.Spell]               = REWARD_SPELL,
            [Enum.QuestCompleteSpellType.Unlock]              = REWARD_UNLOCK,
            [Enum.QuestCompleteSpellType.QuestlineUnlock]     = REWARD_QUESTLINE_UNLOCK,
            [Enum.QuestCompleteSpellType.QuestlineReward]     = REWARD_QUESTLINE_REWARD,
            [Enum.QuestCompleteSpellType.QuestlineUnlockPart] = REWARD_QUESTLINE_UNLOCK_PART,
            [Enum.QuestCompleteSpellType.PossibleReward]      = REWARD_POSSIBLE_QUEST_REWARD
        }

        local SpellHeaderPool = Pool.New(function(pool) return { uk_poolElementType = "HEADER", text = nil, isPrimary = false } end)

        local function SortSpellRewards(a, b)
            return QUEST_SPELL_TYPE_PRIORITY[a.spellType] < QUEST_SPELL_TYPE_PRIORITY[b.spellType]
        end

        function DialogFrameMixin:FormatSpellRewards(spellRewards)
            SpellHeaderPool:ReleaseAll()

            local formattedSpellRewards = {}
            for _, spellInfo in ipairs(spellRewards) do
                tinsert(formattedSpellRewards, spellInfo)
            end
            table.sort(formattedSpellRewards, SortSpellRewards)

            local currentType, numHeaders = nil, 0
            for index, spellInfo in ipairs(formattedSpellRewards) do
                if spellInfo.spellType ~= currentType then
                    local header = QUEST_SPELL_TYPE_HEADER_LOOKUP[spellInfo.spellType]
                    if header then
                        local spellHeaderObject = SpellHeaderPool:Acquire()
                        spellHeaderObject.uk_poolElementType = "HEADER"
                        spellHeaderObject.text, spellHeaderObject.isPrimary = header, numHeaders == 0
                        tinsert(formattedSpellRewards, index, spellHeaderObject)
                        numHeaders = numHeaders + 1
                    end
                    currentType = spellInfo.spellType
                end
            end

            return formattedSpellRewards
        end
    end

    function DialogFrameMixin:RefreshQuestModelFrame()
        local portraitDisplayID, text, name, mountPortraitDisplayID, modelSceneID = ControlCenter.GetQuestPortrait()
        if not portraitDisplayID or portraitDisplayID == 0 then
            self:HideQuestModelFrame()
            return
        end

        self.QuestModelFrame:Show()
        self.QuestModelFrame:SetPortrait(portraitDisplayID, text, name, mountPortraitDisplayID, modelSceneID)
        self.QuestModelFrame:SetModelSceneZoom(MODEL_ZOOM_DISTANCE, MODEL_ZOOM_MAX_DISTANCE)
        self.QuestModelFrame:_Render()
    end

    function DialogFrameMixin:HideQuestModelFrame()
        self.QuestModelFrame:SetPortrait()
        self.QuestModelFrame:Hide()
    end

    function DialogFrameMixin:RefreshQuestFrame()
        self:UpdateQuestTitle()
        self:UpdateQuestText()
        if ControlCenter.GetQuestSessionType() == ControlCenter_Preload.Enum.SessionType.Progress then
            if ControlCenter.IsQuestComplete() then
                self:UpdateQuestObjectives(false)
            else
                self:UpdateQuestObjectives(true)
            end
            self:UpdateQuestRewards(false)
        elseif ControlCenter.GetQuestSessionType() == ControlCenter_Preload.Enum.SessionType.Complete then
            self:UpdateQuestObjectives(false)
            self:UpdateQuestRewards(true)
        elseif ControlCenter.GetQuestSessionType() == ControlCenter_Preload.Enum.SessionType.Detail then
            self:UpdateQuestObjectives(true)
            self:UpdateQuestRewards(true)
        end
        self:UpdateDialogGlyph()
    end

    function DialogFrameMixin:UpdateQuestTitle()
        local campaignName = ControlCenter.GetQuestCampaignName()
        local questName = ControlCenter.GetQuestName()
        local questTagID = ControlCenter.GetQuestTagID()
        local questTagName = ControlCenter.GetQuestTagName()
        local questType = ControlCenter.GetQuestType()
        local questTimeLeft = ControlCenter.GetQuestTimeLeft()
        local isQuestCompleteWarband = ControlCenter.IsQuestCompleteWarband()
        local questIcon, tooltipTitle, tooltipBody = ControlCenter_ContextIcon.GetContextIconForQuestTitle(questTagID, questTagName, questType, questTimeLeft)
        self.QuestFrame.QuestTitleContainer:SetText(questName, campaignName, questIcon, tooltipTitle, tooltipBody, isQuestCompleteWarband)
    end

    function DialogFrameMixin:UpdateQuestText()
        local questText = ControlCenter.GetQuestText()
        local isValidQuestText = #questText >= 2

        self.QuestFrame.QuestText:SetShown(self.showDefaultText and isValidQuestText)
        if self.showDefaultText and isValidQuestText then
            self.QuestFrame.QuestText:SetText(questText)
        end
    end

    function DialogFrameMixin:UpdateQuestObjectives(show)
        local questSessionType = ControlCenter.GetQuestSessionType()
        local showGroup, showText, showSpellObjective = nil, nil, nil

        if show then
            if questSessionType == ControlCenter_Preload.Enum.SessionType.Progress then
                local objectives = ControlCenter.GetQuestObjectives()
                showGroup = objectives and #objectives > 0
                if showGroup then
                    self.QuestFrame.QuestObjectives:SetData(objectives)
                end
            else
                local objectiveText = ControlCenter.GetQuestObjectiveText()
                showText = objectiveText and #objectiveText >= 2
                if showText then
                    self.QuestFrame.QuestObjectivesText:SetText(objectiveText)
                end
            end

            local spellObjective = ControlCenter.GetQuestSpellObjective()
            showSpellObjective = spellObjective and spellObjective.rewardID ~= nil
            if showSpellObjective then
                self.QuestFrame.QuestSpellObjective:SetData({ spellObjective })
            end
        end

        local showCategory = showGroup or showText
        self.QuestFrame.QuestObjectivesSpacer:SetShown(self.QuestFrame.QuestText:IsShown() and (showCategory or showSpellObjective))
        self.QuestFrame.QuestObjectivesHeader:SetShown(showCategory)
        self.QuestFrame.QuestObjectivesText:SetShown(showText)
        self.QuestFrame.QuestObjectives:SetShown(showGroup)
        self.QuestFrame.QuestSpellObjectiveHeader:SetShown(showSpellObjective)
        self.QuestFrame.QuestSpellObjective:SetShown(showSpellObjective)
    end

    function DialogFrameMixin:UpdateQuestRewards(show)
        local isQuestComplete = ControlCenter.IsQuestComplete()
        local showCategory, showChoice, showSpell, showReceiveHeader, showReceiveItem, showReceiveCurrency, showReceiveSkill, showOtherExperience, showOtherMoney, showOtherHonor

        if show then
            local choice = ControlCenter.GetQuestRewardChoice()
            local spell = ControlCenter.GetQuestRewardSpell()
            local items = ControlCenter.GetQuestRewardReceive()
            local currency = ControlCenter.GetQuestRewardCurrencies()
            local skill = ControlCenter.GetQuestRewardSkill()
            local xp, xpPercentage = ControlCenter.GetQuestRewardXP()
            local money = ControlCenter.GetQuestRewardMoneyFormatted()
            local honor = ControlCenter.GetQuestRewardHonor()

            showChoice = choice and #choice > 0
            showSpell = spell and #spell > 0
            showReceiveItem = items and #items > 0
            showReceiveCurrency = currency and #currency > 0
            showReceiveSkill = skill and skill.points ~= nil
            showOtherExperience = xp and xp > 0
            showOtherMoney = money ~= nil
            showOtherHonor = honor and honor > 0
            showReceiveHeader = showReceiveItem or showReceiveCurrency or showReceiveSkill or showOtherMoney or showOtherHonor
            showCategory = showChoice or showSpell or showReceiveItem or showReceiveCurrency or showReceiveSkill or showOtherExperience or showOtherMoney or showOtherHonor

            if showChoice then
                self.QuestFrame.QuestItemRewardsHeader:SetText(isQuestComplete and REWARD_CHOOSE or REWARD_CHOICES)
                if isQuestComplete then
                    self.QuestFrame.QuestItemChoiceRewards:SetData(choice)
                else
                    self.QuestFrame.QuestItemRewards:SetData(choice)
                end
            end
            if showSpell then
                self.QuestFrame.QuestSpellRewards:SetData(self:FormatSpellRewards(spell))
            end
            if showReceiveSkill then
                self.QuestFrame.QuestSkillReceiveRewards:SetData({ skill })
            end
            if showCategory then
                self.QuestFrame.QuestReceiveRewardsHeader:SetText((showChoice or showSpell) and REWARD_ITEMS or REWARD_ITEMS_ONLY)
            end
            if showReceiveItem then
                self.QuestFrame.QuestItemReceiveRewards:SetData(items)
            end
            if showReceiveCurrency then
                self.QuestFrame.QuestCurrencyReceiveRewards:SetData(currency)
            end
            if showOtherExperience then
                self.QuestFrame.QuestRewardXP:SetRewardText(BreakUpLargeNumbers(xp) .. (xpPercentage and " (" .. xpPercentage .. "%)" or ""))
            end
            if showOtherMoney then
                self.QuestFrame.QuestRewardMoney:SetRewardText(money)
            end
            if showOtherHonor then
                self.QuestFrame.QuestRewardHonor:SetRewardText(BreakUpLargeNumbers(honor))
            end
        end

        self.QuestFrame.QuestRewardsSpacer:SetShown((self.QuestFrame.QuestText:IsShown() or self.QuestFrame.QuestObjectivesHeader:IsShown()) and showCategory)
        self.QuestFrame.QuestRewardsHeader:SetShown(showCategory)
        self.QuestFrame.QuestItemRewardsHeader:SetShown(showChoice)
        self.QuestFrame.QuestItemChoiceRewards:SetShown(isQuestComplete and showChoice)
        self.QuestFrame.QuestItemRewards:SetShown(not isQuestComplete and showChoice)
        self.QuestFrame.QuestItemRewardsSpacer:SetShown(showChoice)
        self.QuestFrame.QuestSpellRewardsHeader:SetShown(showSpell)
        self.QuestFrame.QuestSpellRewards:SetShown(showSpell)
        self.QuestFrame.QuestSpellRewardsSpacer:SetShown(showSpell)
        self.QuestFrame.QuestSkillReceiveRewards:SetShown(showReceiveSkill)
        self.QuestFrame.QuestReceiveRewardsHeader:SetShown(showReceiveHeader)
        self.QuestFrame.QuestItemReceiveRewards:SetShown(showReceiveItem)
        self.QuestFrame.QuestCurrencyReceiveRewards:SetShown(showReceiveCurrency)
        self.QuestFrame.QuestRewardXP:SetShown(showOtherExperience)
        self.QuestFrame.QuestRewardMoney:SetShown(showOtherMoney)
        self.QuestFrame.QuestRewardHonor:SetShown(showOtherHonor)

        self:RefreshQuestSelection()
    end

    function DialogFrameMixin:ResetQuestSelection(boundary, allowBoundaryScroll)
        DialogFrameMixin:UpdateSelectableElementState(self.questSelectedElement, nil)
        self.questSelectedElement = nil
        self.questSelectedGroup = nil
        self.questSelectedRewardID = nil
        self.questSelectedRewardType = nil
        self.questSelectedRewardIndex = nil
        self.questSelectionBoundary = boundary
        self.questSelectionBoundaryAllowScroll = allowBoundaryScroll
    end

    function DialogFrameMixin:SetQuestSelection(element, groupKey, rewardInfo)
        DialogFrameMixin:UpdateSelectableElementState(self.questSelectedElement, element)
        self.questSelectedElement = element
        self.questSelectedGroup = groupKey
        self.questSelectedRewardID = rewardInfo.rewardID
        self.questSelectedRewardType = rewardInfo.questRewardType
        self.questSelectedRewardIndex = rewardInfo.questRewardIndex
        self.questSelectionBoundary = nil
        self.questSelectionBoundaryAllowScroll = nil
        DialogFrameMixin:EnsureSelectableElementVisible(self.QuestFrame.ScrollContainer, element)
        return true
    end

    function DialogFrameMixin:RefreshQuestSelection()
        local groupKey = self.questSelectedGroup
        local rewardID = self.questSelectedRewardID
        local rewardType = self.questSelectedRewardType
        local rewardIndex = self.questSelectedRewardIndex
        if not groupKey then return end

        if DialogFrameMixin:ForEachSelectableGroup(self.QuestFrame, QUEST_SELECTION_GROUPS, false, function(element, rewardInfo, currentGroupKey)
                if currentGroupKey == groupKey and rewardInfo.rewardID == rewardID and rewardInfo.questRewardType == rewardType and rewardInfo.questRewardIndex == rewardIndex then
                    return self:SetQuestSelection(element, currentGroupKey, rewardInfo)
                end
            end, true) then
            return
        end

        self:ResetQuestSelection()
    end

    function DialogFrameMixin:SelectNextQuestReward()
        if self.questSelectionBoundary == DialogFrame_Preload.Enum.OptionBoundaryType.AfterLast then
            return false, true, self.questSelectionBoundaryAllowScroll
        end

        local groupKey = self.questSelectedGroup
        local rewardID = self.questSelectedRewardID
        local rewardType = self.questSelectedRewardType
        local rewardIndex = self.questSelectedRewardIndex
        local seenSelected = not groupKey
        local targetIsBelow = nil

        if DialogFrameMixin:ForEachSelectableGroup(self.QuestFrame, QUEST_SELECTION_GROUPS, false, function(element, rewardInfo, currentGroupKey)
                if seenSelected then
                    local viewportState = DialogFrameMixin:GetSelectableElementViewportState(self.QuestFrame.ScrollContainer, element)
                    if viewportState == DialogFrame_Preload.Enum.SelectableViewportState.Below then
                        targetIsBelow = true
                        return true
                    elseif viewportState ~= DialogFrame_Preload.Enum.SelectableViewportState.Visible then
                        return
                    end
                    return self:SetQuestSelection(element, currentGroupKey, rewardInfo)
                elseif currentGroupKey == groupKey and rewardInfo.rewardID == rewardID and rewardInfo.questRewardType == rewardType and rewardInfo.questRewardIndex == rewardIndex then
                    seenSelected = true
                end
            end, true) then
            if targetIsBelow then
                return false, true, self.QuestFrame.ScrollContainer:HasContentBelow()
            end
            return true
        end

        if groupKey and seenSelected then
            local allowScroll = self.QuestFrame.ScrollContainer:HasContentBelow()
            self:ResetQuestSelection(DialogFrame_Preload.Enum.OptionBoundaryType.AfterLast, allowScroll)
            return false, true, allowScroll
        end
    end

    function DialogFrameMixin:SelectPreviousQuestReward()
        if self.questSelectionBoundary == DialogFrame_Preload.Enum.OptionBoundaryType.BeforeFirst then
            return false, true, self.questSelectionBoundaryAllowScroll
        end

        local groupKey = self.questSelectedGroup
        local rewardID = self.questSelectedRewardID
        local rewardType = self.questSelectedRewardType
        local rewardIndex = self.questSelectedRewardIndex
        local seenSelected = not groupKey
        local targetIsAbove = nil

        if DialogFrameMixin:ForEachSelectableGroup(self.QuestFrame, QUEST_SELECTION_GROUPS, true, function(element, rewardInfo, currentGroupKey)
                if seenSelected then
                    local viewportState = DialogFrameMixin:GetSelectableElementViewportState(self.QuestFrame.ScrollContainer, element)
                    if viewportState == DialogFrame_Preload.Enum.SelectableViewportState.Above then
                        targetIsAbove = true
                        return true
                    elseif viewportState ~= DialogFrame_Preload.Enum.SelectableViewportState.Visible then
                        return
                    end
                    return self:SetQuestSelection(element, currentGroupKey, rewardInfo)
                elseif currentGroupKey == groupKey and rewardInfo.rewardID == rewardID and rewardInfo.questRewardType == rewardType and rewardInfo.questRewardIndex == rewardIndex then
                    seenSelected = true
                end
            end, true) then
            if targetIsAbove then
                return false, true, self.QuestFrame.ScrollContainer:HasContentAbove()
            end
            return true
        end

        if groupKey and seenSelected then
            local allowScroll = self.QuestFrame.ScrollContainer:HasContentAbove()
            self:ResetQuestSelection(DialogFrame_Preload.Enum.OptionBoundaryType.BeforeFirst, allowScroll)
            return false, true, allowScroll
        end
    end

    function DialogFrameMixin:ConfirmQuestSelection()
        if self.QuestFrame:IsShown() and self.questSelectedElement and self.questSelectedElement.rewardIndex and self.questSelectedElement.rewardIndex ~= ControlCenter.GetQuestSelectedChoiceRewardIndex() then
            self.questSelectedElement:OnClick()
            return true
        end
    end
end

do --Footer
    local function GoodbyeButton_OnClick()
        DialogFrame.RequestAction(DialogFrame.Enum.Action.Goodbye)
    end

    local function CancelButton_OnClick()
        DialogFrame.RequestAction(DialogFrame.Enum.Action.Cancel)
    end

    local function AcceptButton_OnClick()
        DialogFrame.RequestAction(DialogFrame.Enum.Action.Accept)
    end

    local function AutoAcceptButton_OnClick()
        DialogFrame.RequestAction(DialogFrame.Enum.Action.AutoAccept)
    end

    local function ContinueButton_OnClick()
        DialogFrame.RequestAction(DialogFrame.Enum.Action.Continue)
    end

    local function CompleteButton_OnClick()
        DialogFrame.RequestAction(DialogFrame.Enum.Action.Complete)
    end

    local function SetupButton(button, info, enabled)
        button:SetHotkey(enabled and info.keybind or nil)
        button:SetText(info.text)
        button:SetOnClick(info.onClick)
        button:SetEnabled(enabled)
    end

    local BUTTON_TYPES = {
        Goodbye    = { text = L["GOODBYE"], onClick = GoodbyeButton_OnClick, keybind = InputUtil.Enum.Actions.Close },
        Cancel     = { text = L["CANCEL"], onClick = CancelButton_OnClick, keybind = InputUtil.Enum.Actions.Close },
        Accept     = { text = L["ACCEPT"], onClick = AcceptButton_OnClick, keybind = InputUtil.Enum.Actions.Confirm },
        AutoAccept = { text = L["AUTO_ACCEPT"], onClick = AutoAcceptButton_OnClick, keybind = InputUtil.Enum.Actions.Confirm },
        Decline    = { text = L["DECLINE"], onClick = CancelButton_OnClick, keybind = InputUtil.Enum.Actions.Close },
        Continue   = { text = L["CONTINUE"], onClick = ContinueButton_OnClick, keybind = InputUtil.Enum.Actions.Confirm },
        Complete   = { text = L["COMPLETE"], onClick = CompleteButton_OnClick, keybind = InputUtil.Enum.Actions.Confirm }
    }

    local LAYOUTS = {
        Gossip                  = {
            secondary = { buttonType = BUTTON_TYPES.Goodbye, enabled = true }
        },
        QuestAvailable          = {
            primary   = { buttonType = BUTTON_TYPES.Accept, enabled = true },
            secondary = { buttonType = BUTTON_TYPES.Decline, enabled = true }
        },
        QuestAutoAccept         = {
            primary = { buttonType = BUTTON_TYPES.AutoAccept, enabled = true }
        },
        QuestIncomplete         = {
            primary   = { buttonType = BUTTON_TYPES.Continue, enabled = false },
            secondary = { buttonType = BUTTON_TYPES.Cancel, enabled = true }
        },
        QuestIncompleteContinue = {
            primary   = { buttonType = BUTTON_TYPES.Continue, enabled = true },
            secondary = { buttonType = BUTTON_TYPES.Cancel, enabled = true }
        },
        QuestCompleteInvalid    = {
            primary   = { buttonType = BUTTON_TYPES.Complete, enabled = false },
            secondary = { buttonType = BUTTON_TYPES.Cancel, enabled = true }
        },
        QuestCompleteValid      = {
            primary   = { buttonType = BUTTON_TYPES.Complete, enabled = true },
            secondary = { buttonType = BUTTON_TYPES.Cancel, enabled = true }
        }
    }

    local function ApplyLayout(layout)
        LWDialogFrame.Footer.PrimaryButton:SetShown(layout.primary ~= nil)
        LWDialogFrame.Footer.SecondaryButton:SetShown(layout.secondary ~= nil)

        if layout.primary then
            SetupButton(LWDialogFrame.Footer.PrimaryButton, layout.primary.buttonType, layout.primary.enabled)
        end

        if layout.secondary then
            SetupButton(LWDialogFrame.Footer.SecondaryButton, layout.secondary.buttonType, layout.secondary.enabled)
        end
    end

    function DialogFrameMixin:UpdateFooterButtons()
        if not ControlCenter.IsInSession() then return end

        local gossipSessionType = ControlCenter.GetGossipSessionType()
        local questSessionType = ControlCenter.GetQuestSessionType()
        local isAutoAccept = ControlCenter.IsQuestAutoAccept()

        if gossipSessionType then
            ApplyLayout(LAYOUTS.Gossip)
        elseif questSessionType then
            if questSessionType == ControlCenter_Preload.Enum.SessionType.Detail then
                if isAutoAccept then
                    ApplyLayout(LAYOUTS.QuestAutoAccept)
                else
                    ApplyLayout(LAYOUTS.QuestAvailable)
                end
            elseif questSessionType == ControlCenter_Preload.Enum.SessionType.Progress then
                if ControlCenter.IsQuestComplete() then
                    ApplyLayout(LAYOUTS.QuestIncompleteContinue)
                else
                    ApplyLayout(LAYOUTS.QuestIncomplete)
                end
            elseif questSessionType == ControlCenter_Preload.Enum.SessionType.Complete then
                if ControlCenter.IsQuestRewardSelected() then
                    ApplyLayout(LAYOUTS.QuestCompleteValid)
                else
                    ApplyLayout(LAYOUTS.QuestCompleteInvalid)
                end
            end
        end
    end
end

do --EdgeFade
    function DialogFrameMixin:RefreshEdgeFade()
        self:UpdateEdgeFadeToActiveFrame()
    end

    function DialogFrameMixin:UpdateEdgeFadeToActiveFrame()
        local frame = ControlCenter.GetGossipSessionType() and self.GossipFrame or ControlCenter.GetQuestSessionType() and self.QuestFrame
        if not frame then return end

        self.EdgeFade:scrollEdgeLinkedScrollContainer(frame.ScrollContainer)
        self.EdgeFade:scrollEdgeDirection(UIKit.Enum.ScrollEdgeDirection.Trailing)
        self.EdgeFade:scrollEdgeMin(0)
        self.EdgeFade:scrollEdgeMax(50)
        C_Timer.After(0, function() self.EdgeFade:UpdateAlpha() end)
    end
end

DialogFrameMixin.AnimGroup = UIAnim.New()
do
    local function ApplyDefaultState(frame)
        frame:SetAlpha(1)
    end

    DialogFrameMixin.AnimGroup:State("INSTANT", function(frame)
        ApplyDefaultState(frame)
    end)

    local FadeIn = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.125):to(1)
    DialogFrameMixin.AnimGroup:State("FADE_IN", function(frame)
        FadeIn:Play(frame)
    end)

    local FadeOut = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.125):to(0.5)
    DialogFrameMixin.AnimGroup:State("FADE_OUT", function(frame)
        FadeOut:Play(frame)
    end)

    local FadeInDetails = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.25):from(0):to(1)
    DialogFrameMixin.AnimGroup:Animation("CONTENT_INTRO", function(frame)
        FadeInDetails:Play(frame.DetailsFrame)
    end)
end

Mixin(LWDialogFrame, DialogFrameMixin)
CallbackRegistry.Add("Preload.AddonReady", function()
    LWDialogFrame:OnLoad()
end)
