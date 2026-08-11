local env = select(2, ...)
local Path = env.modules:Import("packages\\path")
local UIFont = env.modules:Import("packages\\ui-font")
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List, SecureButton, ModelScene = unpack(UIKit.UI.Frames)
local DialogFrame_Preload = env.modules:Import("@\\Dialog\\DialogFrame\\Preload")
local QuestObjective = env.modules:New("@\\Dialog\\DialogFrame\\Widgets\\QuestObjective")

local Mixin = Mixin

do -- Objective
    local ICON_SIZE = 12
    local GAP = 10
    local HEIGHT = UIKit.Define.Fit{ delta = 8 }
    local TEXT_WIDTH = UIKit.Define.Percentage{ value = 100, operator = "-", delta = ICON_SIZE + GAP }
    local ACTIVE_ALPHA = 1
    local COMPLETE_ALPHA = 0.5

    local ObjectiveMixin = {}

    function ObjectiveMixin:SetComplete(isComplete)
        self:SetAlpha(isComplete and COMPLETE_ALPHA or ACTIVE_ALPHA)
        self.Icon:SetShown(not isComplete)
    end

    QuestObjective.Objective = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                Frame(name .. ".Icon")
                    :id("Icon", id)
                    :point(UIKit.Enum.Point.Left)
                    :size(ICON_SIZE, ICON_SIZE)
                    :background(DialogFrame_Preload.UIDEF.Objective)
                    :backgroundColor(DialogFrame_Preload.TextColorPrimary)
                    :alpha(0.8),

                Text(name .. ".Label")
                    :id("Label", id)
                    :anchor(UIKit.NewGroupCaptureString("Icon", id))
                    :point(UIKit.Enum.Point.Left, UIKit.Enum.Point.Right)
                    :x(GAP)
                    :size(TEXT_WIDTH, UIKit.Define.Fit{})
                    :fontObject(UIFont.ParchmentText)
                    :textColor(DialogFrame_Preload.TextColorPrimary)
                    :textJustifyH("LEFT")
                    :textJustifyV("MIDDLE")
                    :textVerticalSpacing(1.5)
                    :alpha(0.8)
            })
            :size(UIKit.UI.P_FILL, HEIGHT)
            :alpha(0.75)

        frame.Icon = UIKit.GetElementById("Icon", id)
        frame.Label = UIKit.GetElementById("Label", id)

        Mixin(frame, ObjectiveMixin)

        return frame
    end)
end

do -- Group
    local INSET = 24
    local HEIGHT = UIKit.Define.Fit{ delta = INSET }
    local BACKGROUND_SIZE = UIKit.Define.Fill{ delta = -12 }
    local CONTENT_WIDTH = UIKit.Define.Percentage{ value = 100, operator = "-", delta = INSET }

    local GroupMixin = {}

    function GroupMixin:SetData(data)
        self.ObjectiveListFrame:SetData(data)
    end

    local function OnObjectiveUpdate(element, index, value)
        element:SetComplete(value.finished)
        element.Label:SetText(value.text)
    end

    QuestObjective.Group = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                Frame(name .. ".Background")
                    :id("Background", id)
                    :size(BACKGROUND_SIZE)
                    :background(DialogFrame_Preload.UIDEF.UIDetailsOptionSoftEdge)
                    :backgroundBlendMode(UIKit.Enum.BlendMode.Add)
                    :alpha(0.0525)
                    :_excludeFromCalculations(),

                LayoutVertical(name .. ".ContentFrame", {
                    List(name .. ".ObjectiveListFrame")
                        :id("ObjectiveListFrame", id)
                        :poolTemplate(QuestObjective.Objective)
                        :poolElementUpdate(OnObjectiveUpdate)
                })
                    :id("ContentFrame", id)
                    :point(UIKit.Enum.Point.Center)
                    :size(CONTENT_WIDTH, UIKit.Define.Fit{})
                    :layoutSpacing(6)
            })
            :size(UIKit.UI.P_FILL, HEIGHT)

        frame.Background = UIKit.GetElementById("Background", id)
        frame.ContentFrame = UIKit.GetElementById("ContentFrame", id)
        frame.ObjectiveListFrame = UIKit.GetElementById("ObjectiveListFrame", id)

        Mixin(frame, GroupMixin)

        return frame
    end)
end
