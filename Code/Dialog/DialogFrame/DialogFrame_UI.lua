local env = select(2, ...)
local L = env.L
local Path = env.modules:Import("packages\\path")
local UIFont = env.modules:Import("packages\\ui-font")
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List, SecureButton, ModelScene = unpack(UIKit.UI.Frames)
local GenericEnum = env.modules:Import("packages\\generic-enum")
local UICCommon = env.modules:Import("packages\\uic-common")
local Dialog_Preload = env.modules:Import("@\\Dialog\\Preload")
local Dialog_UIWidgets = env.modules:Import("@\\Dialog\\UIWidgets")
local DialogFrame_Preload = env.modules:Import("@\\Dialog\\DialogFrame\\Preload")
local DialogFrame_UI = env.modules:New("@\\Dialog\\DialogFrame\\UI")

local Label = env.modules:Import("@\\Dialog\\DialogFrame\\Widgets\\Label").New
local GossipOption = env.modules:Import("@\\Dialog\\DialogFrame\\Widgets\\GossipOption")
local GossipQuestOption = env.modules:Import("@\\Dialog\\DialogFrame\\Widgets\\GossipQuestOption")
local QuestTitleContainer = env.modules:Import("@\\Dialog\\DialogFrame\\Widgets\\QuestTitleContainer").New
local Spacer = env.modules:Import("@\\Dialog\\DialogFrame\\Widgets\\Spacer").New
local QuestCategoryLabel = env.modules:Import("@\\Dialog\\DialogFrame\\Widgets\\QuestCategoryLabel").New
local QuestObjective = env.modules:Import("@\\Dialog\\DialogFrame\\Widgets\\QuestObjective")
local QuestReward = env.modules:Import("@\\Dialog\\DialogFrame\\Widgets\\QuestReward")

do --QuestModelFrame
    local BACKGROUND_SIZE = UIKit.Define.Fill{ delta = -6 }
    local CONTENT_BACKGROUND_SIZE = UIKit.Define.Fill{ delta = 6 }
    local CONTENT_HEIGHT = UIKit.Define.Fit{ delta = 10 }
    local CONTENT_LABEL_WIDTH = UIKit.Define.Percentage{ value = 100, operator = "-", delta = 18 }

    local QuestModelFrameMixin = {}

    function QuestModelFrameMixin:SetPortrait(portraitDisplayID, text, name, mountPortraitDisplayID, modelSceneID)
        self.TargetModelScene:SetPortrait(portraitDisplayID, mountPortraitDisplayID, modelSceneID)
        self.NameplateLabel:SetText(name or "")
        self.ContentLabel:SetText(text or "")
    end

    function QuestModelFrameMixin:GetPortrait()
        local portraitDisplayID, mountPortraitDisplayID, modelSceneID = self.TargetModelScene:GetPortrait()
        return portraitDisplayID, self.ContentLabel:GetText(), self.NameplateLabel:GetText(), mountPortraitDisplayID, modelSceneID
    end

    function QuestModelFrameMixin:SetModelSceneZoom(zoomDistanceScale, maxZoomDistanceScale)
        self.TargetModelScene:SetCameraZoom(zoomDistanceScale, maxZoomDistanceScale)
    end

    function QuestModelFrameMixin:GetModelSceneZoom()
        return self.TargetModelScene:GetCameraZoom()
    end

    DialogFrame_UI.QuestModelFrame = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                Frame(name .. ".Background")
                    :id("Background", id)
                    :size(BACKGROUND_SIZE)
                    :background(DialogFrame_Preload.UIDEF.UIQuestModelFrameBackground)
                    :_excludeFromCalculations(true)
                    :frameLevel(1),

                LayoutVertical(name .. ".ContainerFrame", {
                    Frame(name .. ".TargetFrame", {
                        Frame(name .. ".Shadow")
                            :id("TargetFrameShadow", id)
                            :background(DialogFrame_Preload.UIDEF.UIQuestModelFrameShadow)
                            :point(UIKit.Enum.Point.Center)
                            :size(130, 130)
                            :y(-5)
                            :frameLevel(2),

                        Dialog_UIWidgets.QuestNPCModelScene(name .. ".TargetModelScene")
                            :id("TargetModelScene", id)
                            :point(UIKit.Enum.Point.Center)
                            :size(125, 125)
                            :y(-5)
                            :frameLevel(1)
                    })
                        :id("TargetFrame", id)
                        :size(140, 130)
                        :point(UIKit.Enum.Point.Top),

                    Frame(name .. ".Nameplate", {
                        Text(name .. ".NameplateLabel")
                            :id("NameplateLabel", id)
                            :point(UIKit.Enum.Point.Center)
                            :size(CONTENT_LABEL_WIDTH, UIKit.UI.P_FILL)
                            :fontObject(UIFont.UIFontObjectNormal12)
                            :textColor(GenericEnum.UIColorRGB.NORMAL_FONT_COLOR)
                            :textJustifyH("CENTER")
                            :textJustifyV("MIDDLE")
                            :wordWrap(false)
                    })
                        :id("Nameplate", id)
                        :background(DialogFrame_Preload.UIDEF.UIQuestModelFrameNameplate)
                        :size(UIKit.UI.P_FILL, 35)
                        :frameLevel(3),

                    Frame(name .. ".ContentFrame", {
                        Frame(name .. ".ContentFrame.Background")
                            :id("ContentFrame.Background", id)
                            :size(CONTENT_BACKGROUND_SIZE)
                            :background(DialogFrame_Preload.UIDEF.UIQuestModelFrameContent)
                            :_excludeFromCalculations(true),

                        Text(name .. ".ContentLabel")
                            :id("ContentLabel", id)
                            :size(CONTENT_LABEL_WIDTH, UIKit.UI.FIT)
                            :point(UIKit.Enum.Point.Top)
                            :textJustifyH("LEFT")
                            :textJustifyV("TOP")
                    })
                        :id("ContentFrame", id)
                        :size(UIKit.UI.P_FILL, CONTENT_HEIGHT)
                        :point(UIKit.Enum.Point.Center)
                        :frameLevel(2)
                })
                    :size(UIKit.UI.P_FILL, UIKit.UI.FIT)
                    :point(UIKit.Enum.Point.Center)
            })
            :size(140, UIKit.UI.FIT)

        frame.Background = UIKit.GetElementById("Background", id)
        frame.BackgroundTexture = frame.Background:GetTextureFrame()
        frame.TargetFrame = UIKit.GetElementById("TargetFrame", id)
        frame.TargetModelScene = UIKit.GetElementById("TargetModelScene", id)
        frame.Nameplate = UIKit.GetElementById("Nameplate", id)
        frame.NameplateLabel = UIKit.GetElementById("NameplateLabel", id)
        frame.ContentFrame = UIKit.GetElementById("ContentFrame", id)
        frame.ContentFrame.Background = UIKit.GetElementById("ContentFrame.Background", id)
        frame.ContentFrame.BackgroundTexture = frame.ContentFrame.Background:GetTextureFrame()
        frame.ContentLabel = UIKit.GetElementById("ContentLabel", id)

        Mixin(frame, QuestModelFrameMixin)
        frame:Hide()

        return frame
    end)
end

do -- DetailsFrame
    local INSET = 18
    local EDGE_OFFSET = 8
    local SCROLL_BOTTOM_PADDING = 75
    local SCROLL_INTERPOLATION = 10
    local SCROLL_STEP_SIZE = 58
    local SCROLL_CONTENT_HEIGHT = UIKit.Define.Fit{ delta = SCROLL_BOTTOM_PADDING }

    DialogFrame_UI.EdgeFade = UIKit.Template(function(id, name, children, ...)
        local frame =
            ScrollContainerEdge(name, {
                Frame(name .. ".EdgeFade")
                    :id("EdgeFade", id)
                    :background(DialogFrame_Preload.UIDEF.UIEdgeFade)
                    :backgroundColor(DialogFrame_Preload.TintColor)
                    :size(UIKit.Define.Percentage{ value = 100, operator = "-", delta = 25 }, 12)
                    :point(UIKit.Enum.Point.Bottom)
                    :y(5)
                    :frameLevel(10),

                Frame(name .. ".EdgeFadeGradient")
                    :id("EdgeFadeGradient", id)
                    :background(DialogFrame_Preload.UIDEF.UIEdgeFadeGradient)
                    :backgroundColor(DialogFrame_Preload.BackgroundColor)
                    :size(UIKit.UI.P_FILL, UIKit.UI.P_FILL)
                    :point(UIKit.Enum.Point.Bottom)
                    :y(-5)
                    :frameLevel(9)
            })
            :height(50)

        frame.EdgeFade = UIKit.GetElementById("EdgeFade", id)
        frame.EdgeFadeTexture = frame.EdgeFade:GetTextureFrame()
        frame.EdgeFadeGradient = UIKit.GetElementById("EdgeFadeGradient", id)
        frame.EdgeFadeGradientTexture = frame.EdgeFadeGradient:GetTextureFrame()

        return frame
    end)

    DialogFrame_UI.GossipFrame = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                ScrollContainer(name .. ".ScrollContainer", {
                    LayoutVertical{
                        Label(name .. ".GossipText")
                            :id("GossipText", id),

                        GossipQuestOption.Group(name .. ".GossipAvailableQuests")
                            :id("GossipAvailableQuests", id),

                        GossipQuestOption.Group(name .. ".GossipActiveQuests")
                            :id("GossipActiveQuests", id),

                        GossipOption.Group(name .. ".GossipOptions")
                            :id("GossipOptions", id)
                    }
                        :point(UIKit.Enum.Point.Top)
                        :size(UIKit.Define.Percentage{ value = 100, operator = "-", delta = EDGE_OFFSET * 2 }, UIKit.UI.FIT)
                        :layoutSpacing(22)
                        :layoutAlignmentH(UIKit.Enum.Direction.Justified)
                })
                    :id("ScrollContainer", id)
                    :point(UIKit.Enum.Point.Center)
                    :size(UIKit.Define.Percentage{ value = 100, operator = "+", delta = EDGE_OFFSET * 2 }, UIKit.UI.P_FILL)
                    :scrollInterpolation(SCROLL_INTERPOLATION)
                    :scrollStepSize(SCROLL_STEP_SIZE)
                    :scrollContainerContentWidth(UIKit.UI.P_FILL)
                    :scrollContainerContentHeight(SCROLL_CONTENT_HEIGHT)
            })

        frame.ScrollContainer = UIKit.GetElementById("ScrollContainer", id)
        frame.GossipText = UIKit.GetElementById("GossipText", id)
        frame.GossipAvailableQuests = UIKit.GetElementById("GossipAvailableQuests", id)
        frame.GossipActiveQuests = UIKit.GetElementById("GossipActiveQuests", id)
        frame.GossipOptions = UIKit.GetElementById("GossipOptions", id)

        return frame
    end)

    DialogFrame_UI.QuestFrame = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                QuestTitleContainer(name .. ".QuestTitleContainer")
                    :id("QuestTitleContainer", id)
                    :point(UIKit.Enum.Point.Top),

                ScrollContainer(name .. ".ScrollContainer", {
                    LayoutVertical{
                        Label(name .. ".QuestText")
                            :id("QuestText", id),

                        --Objectives
                        Spacer(name .. ".QuestObjectivesSpacer")
                            :id("QuestObjectivesSpacer", id),

                        QuestCategoryLabel(name .. ".QuestObjectivesHeader")
                            :id("QuestObjectivesHeader", id),

                        Label(name .. ".QuestObjectivesText")
                            :id("QuestObjectivesText", id),

                        QuestObjective.Group(name .. ".QuestObjectives")
                            :id("QuestObjectives", id),

                        --Spell Objective
                        Label(name .. ".QuestSpellObjectiveHeader")
                            :id("QuestSpellObjectiveHeader", id)
                            :alpha(0.5),

                        QuestReward.SpellRewardGroup(name .. ".QuestSpellObjective")
                            :id("QuestSpellObjective", id),

                        --Rewards
                        Spacer(name .. ".QuestRewardsSpacer")
                            :id("QuestRewardsSpacer", id),

                        QuestCategoryLabel(name .. ".QuestRewardsHeader")
                            :id("QuestRewardsHeader", id),

                        --Item Rewards
                        Label(name .. ".QuestItemRewardsHeader")
                            :id("QuestItemRewardsHeader", id),

                        QuestReward.ItemRewardButtonGroup(name .. ".QuestItemRewards")
                            :id("QuestItemRewards", id),

                        QuestReward.ItemChoiceRewardButtonGroup(name .. ".QuestItemChoiceRewards")
                            :id("QuestItemChoiceRewards", id),

                        Spacer(name .. ".QuestItemRewardsSpacer")
                            :id("QuestItemRewardsSpacer", id),

                        --Spell rewards
                        Label(name .. ".QuestSpellRewardsHeader")
                            :id("QuestSpellRewardsHeader", id),

                        QuestReward.SpellRewardGroup(name .. ".QuestSpellRewards")
                            :id("QuestSpellRewards", id),

                        Spacer(name .. ".QuestSpellRewardsSpacer")
                            :id("QuestSpellRewardsSpacer", id),

                        --You will receive
                        Label(name .. ".QuestReceiveRewardsHeader")
                            :id("QuestReceiveRewardsHeader", id),

                        QuestReward.ItemRewardButtonGroup(name .. ".QuestItemReceiveRewards")
                            :id("QuestItemReceiveRewards", id),

                        QuestReward.CurrencyRewardButtonGroup(name .. ".QuestCurrencyReceiveRewards")
                            :id("QuestCurrencyReceiveRewards", id),

                        QuestReward.SkillRewardButtonGroup(name .. ".QuestSkillReceiveRewards")
                            :id("QuestSkillReceiveRewards", id),

                        --Other
                        QuestReward.RewardText(name .. ".QuestRewardMoney")
                            :id("QuestRewardMoney", id),

                        QuestReward.RewardText(name .. ".QuestRewardHonor")
                            :id("QuestRewardHonor", id),

                        QuestReward.RewardText(name .. ".QuestRewardXP")
                            :id("QuestRewardXP", id)
                    }
                        :point(UIKit.Enum.Point.Top)
                        :y(-INSET)
                        :size(UIKit.Define.Percentage{ value = 100, operator = "-", delta = EDGE_OFFSET * 2 + INSET }, UIKit.UI.FIT)
                        :layoutSpacing(12)
                        :layoutAlignmentH(UIKit.Enum.Direction.Justified)
                })
                    :id("ScrollContainer", id)
                    :anchor(UIKit.NewGroupCaptureString("QuestTitleContainer", id))
                    :point(UIKit.Enum.Point.Top, UIKit.Enum.Point.Bottom)
                    :size(UIKit.Define.Percentage{ value = 100, operator = "+", delta = EDGE_OFFSET * 2 }, UIKit.Define.Percentage{ value = 100, operator = "-", delta = function() return UIKit.GetElementById("QuestTitleContainer", id):GetHeight() end })
                    :scrollInterpolation(SCROLL_INTERPOLATION)
                    :scrollStepSize(SCROLL_STEP_SIZE)
                    :scrollContainerContentWidth(UIKit.UI.P_FILL)
                    :scrollContainerContentHeight(SCROLL_CONTENT_HEIGHT)
            })

        frame.QuestTitleContainer = UIKit.GetElementById("QuestTitleContainer", id)
        frame.ScrollContainer = UIKit.GetElementById("ScrollContainer", id)
        frame.QuestText = UIKit.GetElementById("QuestText", id)
        frame.QuestObjectivesSpacer = UIKit.GetElementById("QuestObjectivesSpacer", id)
        frame.QuestObjectivesHeader = UIKit.GetElementById("QuestObjectivesHeader", id)
        frame.QuestObjectivesText = UIKit.GetElementById("QuestObjectivesText", id)
        frame.QuestObjectives = UIKit.GetElementById("QuestObjectives", id)
        frame.QuestSpellObjectiveHeader = UIKit.GetElementById("QuestSpellObjectiveHeader", id)
        frame.QuestSpellObjective = UIKit.GetElementById("QuestSpellObjective", id)
        frame.QuestRewardsSpacer = UIKit.GetElementById("QuestRewardsSpacer", id)
        frame.QuestRewardsHeader = UIKit.GetElementById("QuestRewardsHeader", id)
        frame.QuestItemRewardsHeader = UIKit.GetElementById("QuestItemRewardsHeader", id)
        frame.QuestItemRewards = UIKit.GetElementById("QuestItemRewards", id)
        frame.QuestItemChoiceRewards = UIKit.GetElementById("QuestItemChoiceRewards", id)
        frame.QuestItemRewardsSpacer = UIKit.GetElementById("QuestItemRewardsSpacer", id)
        frame.QuestSpellRewardsHeader = UIKit.GetElementById("QuestSpellRewardsHeader", id)
        frame.QuestSpellRewards = UIKit.GetElementById("QuestSpellRewards", id)
        frame.QuestSpellRewardsSpacer = UIKit.GetElementById("QuestSpellRewardsSpacer", id)
        frame.QuestReceiveRewardsHeader = UIKit.GetElementById("QuestReceiveRewardsHeader", id)
        frame.QuestItemReceiveRewards = UIKit.GetElementById("QuestItemReceiveRewards", id)
        frame.QuestCurrencyReceiveRewards = UIKit.GetElementById("QuestCurrencyReceiveRewards", id)
        frame.QuestSkillReceiveRewards = UIKit.GetElementById("QuestSkillReceiveRewards", id)
        frame.QuestRewardMoney = UIKit.GetElementById("QuestRewardMoney", id)
        frame.QuestRewardHonor = UIKit.GetElementById("QuestRewardHonor", id)
        frame.QuestRewardXP = UIKit.GetElementById("QuestRewardXP", id)

        frame.QuestObjectivesHeader:SetText(L["OBJECTIVES"])
        frame.QuestSpellObjectiveHeader:SetText(L["LEARN_SPELL_OBJECTIVE"])
        frame.QuestRewardsHeader:SetText(L["REWARDS"])
        frame.QuestRewardMoney:SetRewardIcon(Path.Root .. "\\Art\\Icons\\Gold")
        frame.QuestRewardHonor:SetRewardIcon(Path.Root .. "\\Art\\Icons\\Honor")
        frame.QuestRewardXP:SetRewardIcon(Path.Root .. "\\Art\\Icons\\XP")

        return frame
    end)
end

do -- Dialog Frame
    local CONTENT_DUMMY_TEXTURE = UIKit.Define.Texture_Atlas{ path = nil, inset = { 28, 118, 29, 142 }, left = 0 / 512, right = 366 / 512, top = 0 / 512, bottom = 466 / 512, sliceMode = Enum.UITextureSliceMode.Stretched }
    local CONTENT_INSET = 52
    local DETAILS_INSET = 12
    local TITLE_HEIGHT = 39
    local TITLE_SPACING = -1
    local FOOTER_HEIGHT = 37
    local FOOTER_INSET = 6
    local FOOTER_EDGE_FADE_HEIGHT = 8
    local TITLE_BTN_SIZE = 23
    local FOOTER_BTN_WIDTH = UIKit.Define.Percentage{ value = 39 }

    local name = "LWDialogFrame"
    local id = "LWDialogFrame"

    local frame = Frame(name, {
            HitRect(name .. ".HitRect")
                :id("HitRect", id)
                :size(UIKit.UI.FILL)
                :frameLevel(1000),

            HitRect(name .. ".ResizeHandle")
                :id("ResizeHandle", id)
                :point(UIKit.Enum.Point.BottomRight)
                :size(32, 32)
                :frameLevel(1000),

            Frame(name .. ".Selection", {
                Text(name .. ".Label")
                    :id("Selection.Label", id)
                    :size(UIKit.UI.FILL)
                    :fontObject(UIFont.UIFontObjectNormal16)
                    :text(L["DIALOG_FRAME"]),

                Frame(name .. ".Background")
                    :id("Selection.Background", id)
                    :background(Dialog_Preload.UIDEF.Selection)
                    :size(UIKit.UI.FILL)
            })
                :id("Selection", id)
                :size(UIKit.UI.FILL)
                :frameStrata(UIKit.Enum.FrameStrata.High)
                :ignoreParentAlpha(true),

            Frame(name .. ".ContainerFrame", {
                Frame(name .. ".TitleContainer", {
                    Frame(name .. ".TitleContainer.Portrait", {
                        Frame(name .. ".TitleContainer.Portrait.UnitPortrait")
                            :id("TitleContainer.Portrait.UnitPortrait", id)
                            :size(UIKit.Define.Fill{ delta = 12 })
                            :background(UIKit.UI.TEXTURE_NIL)
                            :mask(DialogFrame_Preload.UIDEF.UIPortraitMask)
                    })
                        :id("TitleContainer.Portrait", id)
                        :point(UIKit.Enum.Point.Left)
                        :size(45, 45)
                        :x(-5)
                        :background(DialogFrame_Preload.UIDEF.UIPortraitRing),

                    Text(name .. ".TitleContainer.Name")
                        :id("TitleContainer.Name", id)
                        :point(UIKit.Enum.Point.Center)
                        :size(UIKit.Define.Percentage{ value = 100, operator = "-", delta = 72 }, UIKit.UI.P_FILL)
                        :fontObject(UIFont.UIFontObjectNormal12)
                        :textColor(GenericEnum.UIColorRGB.NORMAL_FONT_COLOR),

                    LayoutHorizontal{
                        Dialog_UIWidgets.SettingsButton(name .. ".TitleContainer.SettingButton")
                            :id("TitleContainer.SettingButton", id)
                            :size(TITLE_BTN_SIZE, TITLE_BTN_SIZE),

                        UICCommon.RedCloseButton(name .. ".TitleContainer.CloseButton")
                            :id("TitleContainer.CloseButton", id)
                            :size(TITLE_BTN_SIZE, TITLE_BTN_SIZE)
                    }
                        :point(UIKit.Enum.Point.Right)
                        :x(-8)
                        :size(UIKit.UI.FIT, UIKit.UI.FIT)
                        :layoutSpacing(2)
                })
                    :id("TitleContainer", id)
                    :frameLevel(5)
                    :point(UIKit.Enum.Point.Top)
                    :size(UIKit.Define.Percentage{ value = 100, operator = "-", delta = 25 }, TITLE_HEIGHT)
                    :background(DialogFrame_Preload.UIDEF.UITitleContainer)
                    :registerForDrag(true),

                Frame(name .. ".ContentFrame", {
                    Frame(name .. ".ContentFrame.Background")
                        :id("ContentFrame.Background", id)
                        :frameLevel(2)
                        :background(CONTENT_DUMMY_TEXTURE)
                        :size(UIKit.Define.Fill{ delta = -12 }),

                    Frame{
                        Frame(name .. ".DetailsFrame", {
                            Frame(name .. ".DialogGlyph")
                                :id("DialogGlyph", id)
                                :point(UIKit.Enum.Point.Center)
                                :background(DialogFrame_Preload.UIDEF.DialogGlyph)
                                :backgroundColor(DialogFrame_Preload.TintColor)
                                :size(125, 125)
                                :alpha(0.25),

                            DialogFrame_UI.GossipFrame(name .. ".GossipFrame")
                                :id("GossipFrame", id)
                                :size(UIKit.UI.FILL),

                            DialogFrame_UI.QuestFrame(name .. ".QuestFrame")
                                :id("QuestFrame", id)
                                :size(UIKit.UI.FILL)
                        })
                            :id("DetailsFrame", id)
                            :point(UIKit.Enum.Point.Top)
                            :y(-DETAILS_INSET)
                            :size(UIKit.Define.Percentage{ value = 100, operator = "-", delta = DETAILS_INSET * 2 }, UIKit.Define.Percentage{ value = 100, operator = "-", delta = DETAILS_INSET * 2 + FOOTER_HEIGHT + FOOTER_EDGE_FADE_HEIGHT }),

                        DialogFrame_UI.EdgeFade(name .. ".EdgeFade")
                            :id("EdgeFade", id)
                            :anchor(UIKit.NewGroupCaptureString("DetailsFrame", id))
                            :point(UIKit.Enum.Point.Bottom, UIKit.Enum.Point.Bottom)
                            :width(UIKit.Define.Percentage{ value = 100, operator = "+", delta = 10 })
                            :y(-FOOTER_EDGE_FADE_HEIGHT - 5),

                        Frame(name .. ".Footer", {
                            Dialog_UIWidgets.RedHotkeyButton(name .. ".Footer.PrimaryButton")
                                :id("Footer.PrimaryButton", id)
                                :point(UIKit.Enum.Point.Left)
                                :size(FOOTER_BTN_WIDTH, UIKit.UI.P_FILL),

                            Dialog_UIWidgets.RedHotkeyButton(name .. ".Footer.SecondaryButton")
                                :id("Footer.SecondaryButton", id)
                                :point(UIKit.Enum.Point.Right)
                                :size(FOOTER_BTN_WIDTH, UIKit.UI.P_FILL)
                        })
                            :id("Footer", id)
                            :point(UIKit.Enum.Point.Bottom)
                            :y(FOOTER_INSET)
                            :size(UIKit.Define.Percentage{ value = 100, operator = "-", delta = FOOTER_INSET * 2 }, FOOTER_HEIGHT)
                    }
                        :id("ContentFrame", id)
                        :point(UIKit.Enum.Point.Center)
                        :size(UIKit.Define.Percentage{ value = 100, operator = "-", delta = CONTENT_INSET }, UIKit.Define.Percentage{ value = 100, operator = "-", delta = CONTENT_INSET - 9 })
                })
                    :id("Panel", id)
                    :frameLevel(3)
                    :point(UIKit.Enum.Point.Bottom)
                    :size(UIKit.UI.P_FILL, UIKit.Define.Percentage{ value = 100, operator = "-", delta = TITLE_SPACING + TITLE_HEIGHT }),

                DialogFrame_UI.QuestModelFrame(name .. ".QuestModelFrame")
                    :id("QuestModelFrame", id)
                    :anchor(UIKit.NewGroupCaptureString("Panel", id))
                    :point(UIKit.Enum.Point.TopLeft, UIKit.Enum.Point.TopRight)
                    :y(-15)
            })
                :id("ContainerFrame", id)
                :point(UIKit.Enum.Point.Center)
                :size(UIKit.UI.P_FILL, UIKit.UI.P_FILL)
        })
        :parent(LWParent)
        :frameStrata(UIKit.Enum.FrameStrata.Medium)
        :movable(true)
        :resizable(true)
        :dontSavePosition(true)
        :clampedToScreen(true)
        :enableMouse(true)
        :topLevel(true)
        :_Render()

    frame.HitRect = UIKit.GetElementById("HitRect", id)
    frame.ResizeHandle = UIKit.GetElementById("ResizeHandle", id)
    frame.Selection = UIKit.GetElementById("Selection", id)
    frame.Selection.Label = UIKit.GetElementById("Selection.Label", id)
    frame.Selection.Background = UIKit.GetElementById("Selection.Background", id)
    frame.ContainerFrame = UIKit.GetElementById("ContainerFrame", id)
    frame.TitleContainer = UIKit.GetElementById("TitleContainer", id)
    frame.TitleContainer.Portrait = UIKit.GetElementById("TitleContainer.Portrait", id)
    frame.TitleContainer.Portrait.UnitPortrait = UIKit.GetElementById("TitleContainer.Portrait.UnitPortrait", id)
    frame.TitleContainer.Name = UIKit.GetElementById("TitleContainer.Name", id)
    frame.TitleContainer.SettingButton = UIKit.GetElementById("TitleContainer.SettingButton", id)
    frame.TitleContainer.CloseButton = UIKit.GetElementById("TitleContainer.CloseButton", id)
    frame.ContentFrame = UIKit.GetElementById("ContentFrame", id)
    frame.ContentFrame.Background = UIKit.GetElementById("ContentFrame.Background", id)
    frame.ContentFrame.BackgroundTexture = frame.ContentFrame.Background:GetTextureFrame()
    frame.DialogGlyph = UIKit.GetElementById("DialogGlyph", id)
    frame.DetailsFrame = UIKit.GetElementById("DetailsFrame", id)
    frame.GossipFrame = UIKit.GetElementById("GossipFrame", id)
    frame.QuestFrame = UIKit.GetElementById("QuestFrame", id)
    frame.EdgeFade = UIKit.GetElementById("EdgeFade", id)
    frame.Footer = UIKit.GetElementById("Footer", id)
    frame.Footer.PrimaryButton = UIKit.GetElementById("Footer.PrimaryButton", id)
    frame.Footer.SecondaryButton = UIKit.GetElementById("Footer.SecondaryButton", id)
    frame.QuestModelFrame = UIKit.GetElementById("QuestModelFrame", id)
    LWDialogFrame = frame
end
