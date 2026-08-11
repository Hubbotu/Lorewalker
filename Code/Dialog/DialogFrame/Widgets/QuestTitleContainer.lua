local env = select(2, ...)
local UIFont = env.modules:Import("packages\\ui-font")
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List, SecureButton, ModelScene = unpack(UIKit.UI.Frames)
local DialogFrame_Preload = env.modules:Import("@\\Dialog\\DialogFrame\\Preload")
local QuestTitleContainer = env.modules:New("@\\Dialog\\DialogFrame\\Widgets\\QuestTitleContainer")

do -- Quest Header
    local HEIGHT = UIKit.Define.Fit{ delta = 22 }

    local QuestTitleContainerMixin = {}

    function QuestTitleContainerMixin:OnLoad()
        self.TitleIcon:SetScript("OnEnter", function() self:TitleIcon_OnEnter() end)
        self.TitleIcon:SetScript("OnLeave", function() self:TitleIcon_OnLeave() end)
        self.ContentSeperator:SetScript("OnEnter", function() self:ContentSeperator_OnEnter() end)
        self.ContentSeperator:SetScript("OnLeave", function() self:ContentSeperator_OnLeave() end)
    end

    function QuestTitleContainerMixin:TitleIcon_OnEnter()
        if not self.tooltipTitle then return end

        GameTooltip:SetOwner(self.TitleIcon, "ANCHOR_CURSOR_RIGHT")
        GameTooltip_SetTitle(GameTooltip, self.tooltipTitle)
        if self.tooltipBody then GameTooltip_AddNormalLine(GameTooltip, self.tooltipBody) end
        GameTooltip:Show()
    end

    function QuestTitleContainerMixin:TitleIcon_OnLeave()
        GameTooltip:Hide()
    end

    function QuestTitleContainerMixin:ContentSeperator_OnEnter()
        if not self.isQuestCompleteWarband then return end

        GameTooltip:SetOwner(self.ContentSeperator, "ANCHOR_RIGHT")
        GameTooltip_AddHighlightLine(GameTooltip, ACCOUNT_COMPLETED_QUEST_NOTICE)
        GameTooltip:Show()
    end

    function QuestTitleContainerMixin:ContentSeperator_OnLeave()
        GameTooltip:Hide()
    end

    function QuestTitleContainerMixin:SetText(title, campaign, icon, tooltipTitle, tooltipBody, isQuestCompleteWarband)
        local hasIcon = title and icon ~= nil

        self.TitleIcon:SetShown(hasIcon)
        self.TitleText:SetShown(title)
        self.TitleTextContainer:SetShown(title)
        self.CampaignText:SetShown(campaign)
        self.ContentSeperator:background(isQuestCompleteWarband and DialogFrame_Preload.UIDEF.UIQuestContentSeperatorWarbandComplete or DialogFrame_Preload.UIDEF.UIQuestContentSeperator)

        self.isQuestCompleteWarband = isQuestCompleteWarband
        self.tooltipTitle = tooltipTitle
        self.tooltipBody = tooltipBody
        if hasIcon then self.TitleIcon:background(icon) end
        if title then self.TitleText:SetText(title) end
        if campaign then self.CampaignText:SetText(campaign) end
    end

    QuestTitleContainer.New = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                LayoutVertical(name .. ".ContainerFrame", {
                    Text(name .. ".CampaignText")
                        :id("CampaignText", id)
                        :size(UIKit.UI.P_FILL, UIKit.UI.FIT)
                        :fontObject(UIFont.ParchmentHeaderSecondaryText)
                        :textColor(DialogFrame_Preload.TextColorPrimary)
                        :textJustifyH("LEFT")
                        :textJustifyV("MIDDLE")
                        :alpha(0.9),

                    LayoutHorizontal(name .. ".TitleTextContainer", {
                        Frame(name .. ".TitleIcon")
                            :id("TitleIcon", id)
                            :size(22, 22)
                            :background(UIKit.UI.TEXTURE_NIL)
                            :enableMouse(true),

                        Text(name .. ".TitleText")
                            :id("TitleText", id)
                            :size(UIKit.UI.P_FILL, UIKit.UI.FIT)
                            :fontObject(UIFont.ParchmentHeaderPrimaryText)
                            :textColor(DialogFrame_Preload.TextColorPrimary)
                            :textJustifyH("LEFT")
                            :textJustifyV("MIDDLE")
                    })
                        :id("TitleTextContainer", id)
                        :size(UIKit.UI.P_FILL, UIKit.UI.FIT)
                        :layoutSpacing(6)
                        :layoutAlignmentV(UIKit.Enum.Direction.Justified)
                })
                    :id("ContainerFrame", id)
                    :point(UIKit.Enum.Point.Top)
                    :size(UIKit.UI.P_FILL, UIKit.UI.FIT)
                    :layoutSpacing(8),

                Frame(name .. ".ContentSeperator")
                    :id("ContentSeperator", id)
                    :anchor(UIKit.NewGroupCaptureString("ContainerFrame", id))
                    :point(UIKit.Enum.Point.Top, UIKit.Enum.Point.Bottom)
                    :background(UIKit.UI.TEXTURE_NIL)
                    :backgroundColor(DialogFrame_Preload.TintColor)
                    :size(UIKit.UI.P_FILL, 25)
                    :enableMouse(true)
                    :y(6)
                    :_excludeFromCalculations()
            })
            :size(UIKit.UI.P_FILL, HEIGHT)

        frame.ContainerFrame = UIKit.GetElementById("ContainerFrame", id)
        frame.CampaignText = UIKit.GetElementById("CampaignText", id)
        frame.TitleTextContainer = UIKit.GetElementById("TitleTextContainer", id)
        frame.TitleIcon = UIKit.GetElementById("TitleIcon", id)
        frame.TitleText = UIKit.GetElementById("TitleText", id)
        frame.ContentSeperator = UIKit.GetElementById("ContentSeperator", id)

        Mixin(frame, QuestTitleContainerMixin)
        frame:OnLoad()

        return frame
    end)
end
