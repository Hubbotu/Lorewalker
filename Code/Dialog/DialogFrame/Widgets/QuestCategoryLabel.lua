local env = select(2, ...)
local UIFont = env.modules:Import("packages\\ui-font")
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List, SecureButton, ModelScene = unpack(UIKit.UI.Frames)
local DialogFrame_Preload = env.modules:Import("@\\Dialog\\DialogFrame\\Preload")
local QuestCategoryLabel = env.modules:New("@\\Dialog\\DialogFrame\\Widgets\\QuestCategoryLabel")

do -- Quest Category Label
    local QuestCategoryLabelMixin = {}

    function QuestCategoryLabelMixin:SetText(text)
        self.Label:SetText(text)
    end

    QuestCategoryLabel.New = UIKit.Template(function(id, name, children, ...)
        local frame = Frame(name, {
                Text(name .. ".Label")
                    :id("Label", id)
                    :point(UIKit.Enum.Point.Center)
                    :frameLevel(2)
                    :textJustifyH("LEFT")
                    :textJustifyV("MIDDLE")
                    :fontObject(UIFont.ParchmentCategoryLabelText)
                    :textColor(DialogFrame_Preload.TextColorPrimary)
                    :textVerticalSpacing(1)
                    :size(UIKit.UI.P_FILL, UIKit.UI.FIT)
            })
            :size(UIKit.UI.P_FILL, UIKit.UI.FIT)

        frame.Label = UIKit.GetElementById("Label", id)

        Mixin(frame, QuestCategoryLabelMixin)

        return frame
    end)
end
