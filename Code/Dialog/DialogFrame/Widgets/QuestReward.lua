local env = select(2, ...)
local Sound = env.modules:Import("packages\\sound")
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local UIFont = env.modules:Import("packages\\ui-font")
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List, SecureButton, ModelScene = unpack(UIKit.UI.Frames)
local UICSharedMixin = env.modules:Import("packages\\uic-sharedmixin")
local Dialog_UIWidgets = env.modules:Import("@\\Dialog\\UIWidgets")
local InputUtil = env.modules:Import("@\\InputUtil")
local ControlCenter_ContextIcon = env.modules:Import("@\\Dialog\\ControlCenter\\ContextIcon")
local ControlCenter_OptionFlags = env.modules:Import("@\\Dialog\\ControlCenter\\OptionFlags")
local ControlCenter = env.modules:Import("@\\Dialog\\ControlCenter")
local DialogFrame_Preload = env.modules:Import("@\\Dialog\\DialogFrame\\Preload")
local DialogFrame = env.modules:Await("@\\Dialog\\DialogFrame")
local Label = env.modules:Import("@\\Dialog\\DialogFrame\\Widgets\\Label").New
local QuestReward = env.modules:New("@\\Dialog\\DialogFrame\\Widgets\\QuestReward")

local function Nil() return nil end

local Mixin = Mixin
local CreateFromMixins = CreateFromMixins
local AbbreviateNumbers = AbbreviateNumbers
local Item = Item
local GetQuestItemInfo = GetQuestItemInfo
local GetFactionGrantedByCurrency = C_CurrencyInfo.GetFactionGrantedByCurrency or Nil
local FIRST_COMPLETION_BONUS = Enum.QuestRewardContextFlags and Enum.QuestRewardContextFlags.FirstCompletionBonus
local REPEAT_COMPLETION_BONUS = Enum.QuestRewardContextFlags and Enum.QuestRewardContextFlags.RepeatCompletionBonus

local function IsQuestRewardContextFlagSet(rewardInfo, flag)
    return flag and ControlCenter_OptionFlags.IsSet(rewardInfo.questRewardContextFlags or 0, flag)
end

local function GetBestItemRewardContextDescription(rewardInfo)
    if IsQuestRewardContextFlagSet(rewardInfo, FIRST_COMPLETION_BONUS) then
        return ACCOUNT_FIRST_TIME_QUEST_BONUS_TOOLTIP
    elseif IsQuestRewardContextFlagSet(rewardInfo, REPEAT_COMPLETION_BONUS) then
        return ACCOUNT_PREVIOUSLY_COMPLETED_QUEST_BONUS_TOOLTIP
    end
end

local function GetBestCurrencyRewardContextDescription(rewardInfo)
    local entireAmountIsBonus = rewardInfo.bonusRewardAmount == rewardInfo.totalRewardAmount
    local isReputationReward = GetFactionGrantedByCurrency(rewardInfo.rewardID) ~= nil

    if IsQuestRewardContextFlagSet(rewardInfo, FIRST_COMPLETION_BONUS) then
        if entireAmountIsBonus then
            return ACCOUNT_FIRST_TIME_QUEST_BONUS_TOOLTIP
        end

        local bonusString = isReputationReward and ACCOUNT_FIRST_TIME_QUEST_BONUS_REP_TOOLTIP or ACCOUNT_FIRST_TIME_QUEST_BONUS_CURRENCY_TOOLTIP
        return bonusString:format(rewardInfo.baseRewardAmount, rewardInfo.bonusRewardAmount)
    end

    if IsQuestRewardContextFlagSet(rewardInfo, REPEAT_COMPLETION_BONUS) then
        if entireAmountIsBonus then
            return ACCOUNT_PREVIOUSLY_COMPLETED_QUEST_BONUS_TOOLTIP
        end

        local bonusString = isReputationReward and ACCOUNT_PREVIOUSLY_COMPLETED_QUEST_REP_BONUS_TOOLTIP or ACCOUNT_PREVIOUSLY_COMPLETED_QUEST_CURRENCY_BONUS_TOOLTIP
        return bonusString:format(rewardInfo.baseRewardAmount, rewardInfo.bonusRewardAmount)
    end
end

local function GetBestQuestRewardContextDescription(rewardInfo, rewardButtonType)
    if not rewardInfo.questRewardContextFlags then
        return nil
    end

    if rewardButtonType == DialogFrame_Preload.Enum.RewardButtonType.Item then
        return GetBestItemRewardContextDescription(rewardInfo)
    elseif rewardButtonType == DialogFrame_Preload.Enum.RewardButtonType.Currency then
        return GetBestCurrencyRewardContextDescription(rewardInfo)
    end
end

local function GetRewardDisplayInfo(rewardButtonType, rewardInfo)
    local texture = rewardInfo.texture
    local quality = rewardInfo.quality or 0
    local name = rewardInfo.name
    local amount = rewardInfo.count or rewardInfo.totalRewardAmount or rewardInfo.points

    if rewardButtonType == DialogFrame_Preload.Enum.RewardButtonType.Skill then
        name = BONUS_SKILLPOINTS:format(name)
    end

    if rewardButtonType == DialogFrame_Preload.Enum.RewardButtonType.Currency then
        local containerInfo = rewardInfo.containerInfo
        if containerInfo then
            texture = containerInfo.icon
            quality = containerInfo.quality
            name = containerInfo.name
            amount = containerInfo.displayAmount or amount
        end
    end

    local amountText = nil
    if rewardButtonType == DialogFrame_Preload.Enum.RewardButtonType.Skill then
        amountText = amount
    else
        amountText = amount and amount > 1 and amount
    end
    
    if rewardButtonType == DialogFrame_Preload.Enum.RewardButtonType.Currency and amountText then
        amountText = AbbreviateNumbers(amountText)
    end

    return texture, quality, name, amountText
end

local function ApplyRewardDisplay(frame, rewardInfo, optionIndex)
    local texture, quality, name, amountText = GetRewardDisplayInfo(frame.rewardButtonType, rewardInfo)
    local hasWarbandRewardContext = IsQuestRewardContextFlagSet(rewardInfo, FIRST_COMPLETION_BONUS) or IsQuestRewardContextFlagSet(rewardInfo, REPEAT_COMPLETION_BONUS)

    if optionIndex and optionIndex <= 9 and InputUtil.GetInputDevice() == InputUtil.Enum.InputDevices.KBM then
        name = optionIndex .. ". " .. name
    end

    if frame.rewardButtonType == DialogFrame_Preload.Enum.RewardButtonType.Spell or frame.rewardButtonType == DialogFrame_Preload.Enum.RewardButtonType.Skill then
        frame.Item:SetSpell(texture)
    else
        frame.Item:SetItem(texture, quality)
    end

    frame.Item:SetAmount(amountText)
    if frame.WarbandIcon then
        frame.WarbandIcon:SetShown(hasWarbandRewardContext)
    end
    if frame.Count then
        frame.Count:Hide()
    end
    frame.Label:SetText(name)
end

local function ContinueOnItemLoad(frame, rewardInfo, optionIndex)
    if frame.rewardButtonType ~= DialogFrame_Preload.Enum.RewardButtonType.Item or not Item or not rewardInfo.rewardID then return end

    local itemID = rewardInfo.rewardID
    local item = Item:CreateFromItemID(itemID)
    if not item then return end

    item:ContinueOnItemLoad(function()
        if frame.rewardInfo ~= rewardInfo or rewardInfo.rewardID ~= itemID then return end

        local name, texture, count, quality, isUsable, currentItemID, flags = GetQuestItemInfo(rewardInfo.questRewardType, rewardInfo.questRewardIndex)
        if currentItemID ~= itemID then return end

        rewardInfo.name = name
        rewardInfo.texture = texture
        rewardInfo.count = count
        rewardInfo.quality = quality
        rewardInfo.isUsable = isUsable
        rewardInfo.questRewardContextFlags = flags

        frame:RewardButton_SetReward(rewardInfo)
        ApplyRewardDisplay(frame, rewardInfo, optionIndex)
    end)
end


local RewardButtonBaseMixin = CreateFromMixins(UICSharedMixin.ButtonMixin)

function RewardButtonBaseMixin:InitRewardButton(rewardButtonType)
    self.rewardInfo = nil
    self.rewardItemLink = nil
    self.rewardButtonType = rewardButtonType

    self:InitButton()
    self:RegisterMouseEvents()
    self:HookMouseEnter(self.RewardButton_OnEnter)
    self:HookMouseLeave(self.RewardButton_OnLeave)
    self:HookClick(self.RewardButton_OnClick)
end

function RewardButtonBaseMixin:RewardButton_SetReward(rewardInfo)
    self.rewardInfo = rewardInfo

    if self.rewardButtonType == DialogFrame_Preload.Enum.RewardButtonType.Item and rewardInfo.questRewardType and rewardInfo.questRewardIndex then
        self.rewardItemLink = GetQuestItemLink(rewardInfo.questRewardType, rewardInfo.questRewardIndex)
    else
        self.rewardItemLink = nil
    end
end

function RewardButtonBaseMixin:RewardButton_OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    if self.rewardButtonType == DialogFrame_Preload.Enum.RewardButtonType.Item then
        GameTooltip:SetQuestItem(self.rewardInfo.questRewardType, self.rewardInfo.questRewardIndex)
    elseif self.rewardButtonType == DialogFrame_Preload.Enum.RewardButtonType.Currency then
        GameTooltip:SetQuestCurrency(self.rewardInfo.questRewardType, self.rewardInfo.questRewardIndex)
    elseif self.rewardButtonType == DialogFrame_Preload.Enum.RewardButtonType.Spell then
        GameTooltip:SetSpellByID(self.rewardInfo.rewardID)
    elseif self.rewardButtonType == DialogFrame_Preload.Enum.RewardButtonType.Skill then
        local skillName = self.rewardInfo.name
        local skillPoints = self.rewardInfo.points
        if skillName and skillPoints then
            GameTooltip:SetText(BONUS_SKILLPOINTS_TOOLTIP:format(skillPoints, skillName))
        elseif skillName then
            GameTooltip:SetText(skillName)
        end
    end

    if self.rewardInfo.questRewardContextFlags then
        local rewardContextLine = GetBestQuestRewardContextDescription(self.rewardInfo, self.rewardButtonType)
        if rewardContextLine then
            GameTooltip_AddBlankLineToTooltip(GameTooltip)
            GameTooltip_AddColoredLine(GameTooltip, rewardContextLine, QUEST_REWARD_CONTEXT_FONT_COLOR)
        end
    end

    GameTooltip:Show()
end

function RewardButtonBaseMixin:RewardButton_OnLeave()
    GameTooltip:Hide()
end

function RewardButtonBaseMixin:RewardButton_OnClick()
    if not self.rewardItemLink then
        return false
    end

    if IsModifiedClick("CHATLINK") then
        local linkType = string.match(self.rewardItemLink, "|H([^:]+)")
        if linkType == "instancelock" then
            local guid = string.match(self.rewardItemLink, "|Hinstancelock:([^:]+)")
            if not string.find(UnitGUID("player"), guid) then
                return true
            end
        end

        if ChatFrameUtil.InsertLink(self.rewardItemLink) then
            return true
        end
    end

    if self.rewardButtonType == DialogFrame_Preload.Enum.RewardButtonType.Item and IsModifiedClick("DRESSUP") then
        return DressUpLink(self.rewardItemLink)
    end

    return false
end


do -- Reward Button
    local BACKGROUND_SIZE = UIKit.Define.Fill{ delta = -6 }
    local TAG_SIZE = UIKit.Define.Fit{ delta = 10 }
    local NAME_WIDTH = UIKit.Define.Percentage{ value = 100, operator = "-", delta = function(frame) return 35 + 8 + UIKit.GetElementById("Count", frame.templateID):GetWidth() + 8 end }
    local BACKGROUND_ALPHA = 0.04
    local BACKGROUND_ALPHA_HIGHLIGHTED = 0.1

    local RewardButtonMixin = CreateFromMixins(RewardButtonBaseMixin)

    function RewardButtonMixin:OnLoad(rewardButtonType)
        self:InitRewardButton(rewardButtonType)
        self:HookButtonStateChange(self.UpdateAnimation)
        self:HookClick(self.PlayInteractSound)
        self:UpdateAnimation()
    end

    function RewardButtonMixin:SetReward(rewardInfo)
        self:RewardButton_SetReward(rewardInfo)
        ApplyRewardDisplay(self, rewardInfo)
        ContinueOnItemLoad(self, rewardInfo)
    end

    function RewardButtonMixin:UpdateAnimation()
        local buttonState = self:GetButtonState()

        if buttonState == "NORMAL" then
            self.Background:SetAlpha(BACKGROUND_ALPHA)
        elseif buttonState == "HIGHLIGHTED" or buttonState == "PUSHED" then
            self.Background:SetAlpha(BACKGROUND_ALPHA_HIGHLIGHTED)
        end
    end

    function RewardButtonMixin:PlayInteractSound()
        Sound.PlaySound("UI", SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end

    QuestReward.RewardButton = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                Frame(name .. ".Background")
                    :id("Background", id)
                    :frameLevel(1)
                    :size(BACKGROUND_SIZE)
                    :background(DialogFrame_Preload.UIDEF.UIDetailsOptionSoftEdge)
                    :backgroundBlendMode(UIKit.Enum.BlendMode.Add)
                    :_excludeFromCalculations(),

                LayoutHorizontal(name .. ".ContentFrame", {
                    Dialog_UIWidgets.ItemSlot(name .. ".Item")
                        :id("Item", id)
                        :frameLevel(3)
                        :size(35, 35),

                    Frame(name .. ".WarbandIcon")
                        :id("WarbandIcon", id)
                        :size(16, 16)
                        :background(ControlCenter_ContextIcon.TexDef.Warband),

                    Frame(name .. ".Count", {
                        Text(name .. ".Count.Label")
                            :id("Count.Label", id)
                            :frameLevel(4)
                            :point(UIKit.Enum.Point.Center)
                            :size(UIKit.UI.FIT, UIKit.UI.FIT)
                            :fontObject(UIFont.ParchmentRewardTagText)
                            :textColor(DialogFrame_Preload.TextColorInversePrimary)
                    })
                        :id("Count", id)
                        :frameLevel(3)
                        :size(TAG_SIZE, TAG_SIZE)
                        :background(DialogFrame_Preload.UIDEF.UIDetailsOption)
                        :backgroundColor(DialogFrame_Preload.TintColor),

                    Text(name .. "Label")
                        :id("Label", id)
                        :frameLevel(3)
                        :size(NAME_WIDTH, UIKit.Define.Percentage{ value = 100 })
                        :textJustifyH("LEFT")
                        :fontObject(UIFont.ParchmentItemText)
                        :textColor(DialogFrame_Preload.TextColorPrimary)
                        :alpha(0.85)
                })
                    :id("ContentFrame", id)
                    :frameLevel(2)
                    :point(UIKit.Enum.Point.Center)
                    :size(UIKit.UI.P_FILL, UIKit.UI.P_FILL)
                    :layoutAlignmentV(UIKit.Enum.Direction.Justified)
                    :layoutSpacing(8)
            })
            :size(UIKit.UI.P_FILL, 30)

        frame.Background = UIKit.GetElementById("Background", id)
        frame.ContentFrame = UIKit.GetElementById("ContentFrame", id)
        frame.Item = UIKit.GetElementById("Item", id)
        frame.WarbandIcon = UIKit.GetElementById("WarbandIcon", id)
        frame.Count = UIKit.GetElementById("Count", id)
        frame.Count.Label = UIKit.GetElementById("Count.Label", id)
        frame.Label = UIKit.GetElementById("Label", id)
        frame.Label.templateID = id

        Mixin(frame, RewardButtonMixin)

        return frame
    end)
end

do -- Choice Reward Button
    local BACKGROUND_SIZE = UIKit.Define.Fill{ delta = -12 }
    local BORDER_SIZE = UIKit.Define.Fill{ delta = -12 }
    local NAME_WIDTH = UIKit.Define.Percentage{ value = 100, operator = "-", delta = 25 + 6 }
    local ALPHA_NORMAL = 1
    local ALPHA_OTHER = 0.25
    local BACKGROUND_ANIMATION_LOOKUP = {
        Normal   = {
            Background = {
                NORMAL      = 0.25,
                HIGHLIGHTED = 0.375,
                PUSHED      = 0.25
            },
            Border     = {
                NORMAL      = 0.25,
                HIGHLIGHTED = 0.375,
                PUSHED      = 0.25
            }
        },
        Selected = {
            Background = {
                NORMAL      = 0.25,
                HIGHLIGHTED = 0.375,
                PUSHED      = 0.25
            },
            Border     = {
                NORMAL      = 0.25,
                HIGHLIGHTED = 0.375,
                PUSHED      = 0.25
            }
        },
        Other    = {
            Background = {
                NORMAL      = 0,
                HIGHLIGHTED = 0,
                PUSHED      = 0
            },
            Border     = {
                NORMAL      = 0,
                HIGHLIGHTED = 1,
                PUSHED      = 0.75
            }
        }
    }

    local ChoiceRewardButtonMixin = CreateFromMixins(RewardButtonBaseMixin)

    function ChoiceRewardButtonMixin:OnLoad(rewardButtonType)
        self.rewardIndex = nil

        self:InitRewardButton(rewardButtonType)
        self:HookButtonStateChange(self.UpdateAnimation)
        self:HookClick(self.PlayInteractSound)
        self:HookClick(self.ChoiceRewardButton_OnClick)
        CallbackRegistry.Add("ControlCenter.QuestRewardChoiceSelected", function()
            self:UpdateAnimation()
        end)
        self:UpdateAnimation()
    end

    function ChoiceRewardButtonMixin:ChoiceRewardButton_OnClick()
        if not self.rewardIndex then
            return
        end

        DialogFrame.RequestQuestRewardSelection(self.rewardIndex)
    end

    function ChoiceRewardButtonMixin:SetReward(itemInfo, optionIndex)
        self.rewardIndex = itemInfo.questRewardIndex
        self:RewardButton_SetReward(itemInfo)
        ApplyRewardDisplay(self, itemInfo, optionIndex)
        ContinueOnItemLoad(self, itemInfo, optionIndex)
    end

    function ChoiceRewardButtonMixin:UpdateAnimation()
        local isAnyRewardSelected = ControlCenter.IsQuestRewardSelected()
        local isSelectedReward = self.rewardIndex == ControlCenter.GetQuestSelectedChoiceRewardIndex()
        local buttonState = self:GetButtonState()
        local stateKey = (not isAnyRewardSelected and "Normal") or (isSelectedReward and "Selected") or "Other"
        local state = BACKGROUND_ANIMATION_LOOKUP[stateKey]
        
        self.Background:SetAlpha(state.Background[buttonState])
        self.Border:SetAlpha(state.Border[buttonState])
        self:SetAlpha((stateKey == "Other" and ALPHA_OTHER) or ALPHA_NORMAL)
    end

    function ChoiceRewardButtonMixin:PlayInteractSound()
        Sound.PlaySound("UI", SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end

    QuestReward.ChoiceRewardButton = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                Frame(name .. ".Background")
                    :id("Background", id)
                    :frameLevel(1)
                    :size(BACKGROUND_SIZE)
                    :background(DialogFrame_Preload.UIDEF.UIDetailsOptionHighlight)
                    :backgroundBlendMode(UIKit.Enum.BlendMode.Add)
                    :_excludeFromCalculations(),

                Frame(name .. ".Border")
                    :id("Border", id)
                    :frameLevel(1)
                    :size(BORDER_SIZE)
                    :background(DialogFrame_Preload.UIDEF.UIDetailsOptionBorder)
                    :backgroundBlendMode(UIKit.Enum.BlendMode.Add)
                    :_excludeFromCalculations(),

                LayoutHorizontal(name .. ".ContentFrame", {
                    Dialog_UIWidgets.ItemSlot(name .. ".Item")
                        :id("Item", id)
                        :frameLevel(3)
                        :size(25, 25),

                    Text(name .. ".Label")
                        :id("Label", id)
                        :frameLevel(3)
                        :size(NAME_WIDTH, UIKit.UI.P_FILL)
                        :textJustifyH("LEFT")
                        :fontObject(UIFont.ParchmentOptionText)
                        :textColor(DialogFrame_Preload.TextColorPrimary)
                        :alpha(0.8)
                })
                    :id("ContentFrame", id)
                    :frameLevel(2)
                    :point(UIKit.Enum.Point.Center)
                    :size(UIKit.UI.P_FILL, UIKit.UI.P_FILL)
                    :layoutAlignmentV(UIKit.Enum.Direction.Justified)
                    :layoutSpacing(6)
            })
            :size(UIKit.UI.P_FILL, 25)

        frame.Background = UIKit.GetElementById("Background", id)
        frame.Border = UIKit.GetElementById("Border", id)
        frame.ContentFrame = UIKit.GetElementById("ContentFrame", id)
        frame.Item = UIKit.GetElementById("Item", id)
        frame.Label = UIKit.GetElementById("Label", id)
        frame.Label.templateID = id

        Mixin(frame, ChoiceRewardButtonMixin)

        return frame
    end)
end

do -- Reward Button
    QuestReward.ItemRewardButton = UIKit.Template(function(id, name, children, ...)
        local frame = QuestReward.RewardButton(name)
        frame:OnLoad(DialogFrame_Preload.Enum.RewardButtonType.Item)
        return frame
    end)

    QuestReward.ItemChoiceRewardButton = UIKit.Template(function(id, name, children, ...)
        local frame = QuestReward.ChoiceRewardButton(name)
        frame:OnLoad(DialogFrame_Preload.Enum.RewardButtonType.Item)
        return frame
    end)

    QuestReward.CurrencyRewardButton = UIKit.Template(function(id, name, children, ...)
        local frame = QuestReward.RewardButton(name)
        frame:OnLoad(DialogFrame_Preload.Enum.RewardButtonType.Currency)
        return frame
    end)

    QuestReward.CurrencyChoiceRewardButton = UIKit.Template(function(id, name, children, ...)
        local frame = QuestReward.ChoiceRewardButton(name)
        frame:OnLoad(DialogFrame_Preload.Enum.RewardButtonType.Currency)
        return frame
    end)

    QuestReward.SkillRewardButton = UIKit.Template(function(id, name, children, ...)
        local frame = QuestReward.RewardButton(name)
        frame:OnLoad(DialogFrame_Preload.Enum.RewardButtonType.Skill)
        return frame
    end)
end

do -- Reward Button Group
    local GAP = 8
    local CHOICE_SPACING = 12
    local ITEM_REWARD_SCHEMA = {
        Default  = QuestReward.ItemRewardButton,
        Currency = QuestReward.CurrencyRewardButton
    }
    local ITEM_CHOICE_REWARD_SCHEMA = {
        Default  = QuestReward.ItemChoiceRewardButton,
        Currency = QuestReward.CurrencyChoiceRewardButton
    }

    local RewardButtonGroupMixin = {}

    function RewardButtonGroupMixin:SetData(data)
        self.RewardListFrame:SetData(data)
    end

    local function OnRewardUpdate(element, index, value)
        element:SetReward(value, index)
        element:SetPushed(false)
        element:UpdateButtonState()
        element:UpdateAnimation()
    end

    QuestReward.RewardButtonGroupBase = UIKit.Template(function(id, name, children, ...)
        local frame =
            LayoutVertical(name, {
                List(name .. ".RewardListFrame")
                    :id("RewardListFrame", id)
                    :size(UIKit.UI.FILL)
                    :poolElementUpdate(OnRewardUpdate)
                    :_excludeFromCalculations()
            })
            :size(UIKit.UI.P_FILL, UIKit.UI.FIT)

        frame.RewardListFrame = UIKit.GetElementById("RewardListFrame", id)

        Mixin(frame, RewardButtonGroupMixin)

        return frame
    end)

    QuestReward.ItemRewardButtonGroup = UIKit.Template(function(id, name, children, ...)
        local frame =
            QuestReward.RewardButtonGroupBase(name)
            :layoutSpacing(GAP)

        frame.RewardListFrame:poolTemplate(ITEM_REWARD_SCHEMA)

        return frame
    end)

    QuestReward.ItemChoiceRewardButtonGroup = UIKit.Template(function(id, name, children, ...)
        local frame =
            QuestReward.RewardButtonGroupBase(name)
            :layoutSpacing(CHOICE_SPACING)

        frame.RewardListFrame:poolTemplate(ITEM_CHOICE_REWARD_SCHEMA)

        return frame
    end)

    QuestReward.CurrencyRewardButtonGroup = UIKit.Template(function(id, name, children, ...)
        local frame =
            QuestReward.RewardButtonGroupBase(name)
            :layoutSpacing(GAP)

        frame.RewardListFrame:poolTemplate(QuestReward.CurrencyRewardButton)

        return frame
    end)

    QuestReward.SkillRewardButtonGroup = UIKit.Template(function(id, name, children, ...)
        local frame =
            QuestReward.RewardButtonGroupBase(name)
            :layoutSpacing(GAP)

        frame.RewardListFrame:poolTemplate(QuestReward.SkillRewardButton)

        return frame
    end)
end

do -- Spell Reward Group
    do --SpellRewardHeader
        local HEIGHT_SECONDARY = UIKit.Define.Fit{ delta = 14 }

        local SpellRewardHeaderMixin = {}

        function SpellRewardHeaderMixin:SetPrimary(isPrimary)
            self:height(isPrimary and UIKit.UI.FIT or HEIGHT_SECONDARY)
        end

        QuestReward.SpellRewardHeader = UIKit.Template(function(id, name, children, ...)
            local frame =
                Label(name)
                :textJustifyV("BOTTOM")

            Mixin(frame, SpellRewardHeaderMixin)

            return frame
        end)
    end

    do --SpellRewardButton
        QuestReward.SpellRewardButton = UIKit.Template(function(id, name, children, ...)
            local frame = QuestReward.RewardButton(name)
            frame:OnLoad(DialogFrame_Preload.Enum.RewardButtonType.Spell)
            return frame
        end)
    end

    local LIST_SCHEMA = {
        Default = QuestReward.SpellRewardButton,
        HEADER  = QuestReward.SpellRewardHeader
    }

    local SpellRewardGroupMixin = {}

    function SpellRewardGroupMixin:SetData(data)
        self.SpellRewardListFrame:SetData(data)
    end

    local function OnSpellRewardUpdate(element, index, value)
        if value.uk_poolElementType == "HEADER" then
            element:SetText(value.text)
            element:SetPrimary(value.isPrimary)
        else
            element:SetReward(value)
        end
    end

    QuestReward.SpellRewardGroup = UIKit.Template(function(id, name, children, ...)
        local frame =
            LayoutVertical(name, {
                List(name .. ".SpellRewardListFrame")
                    :id("SpellRewardListFrame", id)
                    :size(UIKit.UI.FILL)
                    :poolTemplate(LIST_SCHEMA)
                    :poolElementUpdate(OnSpellRewardUpdate)
                    :_excludeFromCalculations()
            })
            :size(UIKit.UI.P_FILL, UIKit.UI.FIT)
            :layoutSpacing(12)

        frame.SpellRewardListFrame = UIKit.GetElementById("SpellRewardListFrame", id)

        Mixin(frame, SpellRewardGroupMixin)

        return frame
    end)
end

do -- Reward Text
    local GAP = 6
    local TEXT_WIDTH = UIKit.Define.Percentage{ value = 100, operator = "-", delta = 18 + GAP }

    local RewardTextMixin = {}

    function RewardTextMixin:SetRewardIcon(iconTexture)
        self.Icon:SetTexture(iconTexture)
    end

    function RewardTextMixin:SetRewardText(itemText)
        self.Label:SetText(itemText)
    end

    QuestReward.RewardText = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                Frame(name .. ".Icon")
                    :id("Icon", id)
                    :frameLevel(2)
                    :size(18, 18)
                    :point(UIKit.Enum.Point.Left)
                    :background(UIKit.UI.TEXTURE_NIL),

                Text(name .. ".Label")
                    :id("Label", id)
                    :frameLevel(2)
                    :size(TEXT_WIDTH, UIKit.UI.P_FILL)
                    :point(UIKit.Enum.Point.Left)
                    :x(18 + GAP)
                    :textJustifyH("LEFT")
                    :fontObject(UIFont.ParchmentItemText)
                    :textColor(DialogFrame_Preload.TextColorPrimary)
                    :textVerticalSpacing(1.5)
                    :alpha(0.8)
            })
            :size(UIKit.UI.P_FILL, UIKit.UI.FIT)

        frame.Icon = UIKit.GetElementById("Icon", id):GetTextureFrame()
        frame.Label = UIKit.GetElementById("Label", id)

        Mixin(frame, RewardTextMixin)

        return frame
    end)
end
