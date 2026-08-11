local env = select(2, ...)
local UIFont = env.modules:Import("packages\\ui-font")
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List, SecureButton, ModelScene = unpack(UIKit.UI.Frames)
local DialogFrame_Preload = env.modules:Import("@\\Dialog\\DialogFrame\\Preload")
local Label = env.modules:New("@\\Dialog\\DialogFrame\\Widgets\\Label")

do --Label
    Label.New = UIKit.Template(function(id, name, children, ...)
        return Text(name)
            :textJustifyH("LEFT")
            :textJustifyV("TOP")
            :fontObject(UIFont.ParchmentText)
            :textColor(DialogFrame_Preload.TextColorPrimary)
            :textVerticalSpacing(1.5)
            :alpha(0.8)
            :size(UIKit.UI.P_FILL, UIKit.UI.FIT)
    end)
end
