local env = select(2, ...)
local UIFont = env.modules:Import("packages\\ui-font")
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List, SecureButton, ModelScene = unpack(UIKit.UI.Frames)
local DialogFrame_Preload = env.modules:Import("@\\Dialog\\DialogFrame\\Preload")
local GossipOptionBase = env.modules:Import("@\\Dialog\\DialogFrame\\Widgets\\GossipOptionBase")
local GossipOption = env.modules:New("@\\Dialog\\DialogFrame\\Widgets\\GossipOption")

local Mixin = Mixin

do -- Option
    local OPTION_PADDING = 8
    local OPTION_ICON_SIZE = 18
    local BACKGROUND_SIZE = UIKit.Define.Fill{ delta = -6 }
    local WIDTH = UIKit.Define.Percentage{ value = 100 }
    local HEIGHT = UIKit.Define.Fit{ delta = OPTION_PADDING }
    local CONTENT_WIDTH = UIKit.Define.Percentage{ value = 100, operator = "-", delta = OPTION_PADDING }
    local CONTENT_ICON_SIZE = OPTION_ICON_SIZE
    local CONTENT_TEXT_WIDTH = UIKit.Define.Percentage{ value = 100, operator = "-", delta = OPTION_ICON_SIZE + OPTION_PADDING }
    local CONTENT_TEXT_X = OPTION_ICON_SIZE + 8

    GossipOption.Option = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                Frame(name .. ".Background")
                    :id("Background", id)
                    :frameLevel(1)
                    :size(BACKGROUND_SIZE)
                    :background(DialogFrame_Preload.UIDEF.UIDetailsOptionSoftEdge)
                    :backgroundBlendMode(UIKit.Enum.BlendMode.Add)
                    :alpha(0.075)
                    :_excludeFromCalculations(),

                Frame(name .. ".ContainerFrame", {
                    Frame(name .. ".Icon")
                        :id("Icon", id)
                        :frameLevel(2)
                        :point(UIKit.Enum.Point.Left)
                        :size(CONTENT_ICON_SIZE, CONTENT_ICON_SIZE)
                        :background(UIKit.UI.TEXTURE_NIL),

                    Text(name .. ".Label")
                        :id("Label", id)
                        :frameLevel(2)
                        :point(UIKit.Enum.Point.Left)
                        :x(CONTENT_TEXT_X)
                        :size(CONTENT_TEXT_WIDTH, UIKit.UI.FIT)
                        :textJustifyH("LEFT")
                        :textJustifyV("MIDDLE")
                        :fontObject(UIFont.ParchmentOptionText)
                        :textColor(DialogFrame_Preload.TextColorPrimary)
                        :textVerticalSpacing(1.5)
                        :alpha(0.79)
                })
                    :id("ContainerFrame", id)
                    :frameLevel(2)
                    :point(UIKit.Enum.Point.Center)
                    :size(CONTENT_WIDTH, UIKit.UI.FIT)

            })
            :size(WIDTH, HEIGHT)

        frame.Background = UIKit.GetElementById("Background", id)
        frame.ContainerFrame = UIKit.GetElementById("ContainerFrame", id)
        frame.Icon = UIKit.GetElementById("Icon", id)
        frame.IconTexture = frame.Icon:GetTextureFrame()
        frame.Label = UIKit.GetElementById("Label", id)

        Mixin(frame, GossipOptionBase.OptionMixin)
        frame:OnLoad()

        return frame
    end)
end

do -- Group
    GossipOption.Group = UIKit.Template(function(id, name, children, ...)
        local frame =
            LayoutVertical(name, {
                List(name .. ".OptionListFrame")
                    :id("OptionListFrame", id)
                    :poolTemplate(GossipOption.Option)
                    :poolElementUpdate(GossipOptionBase.OnOptionUpdate)
            })
            :size(UIKit.UI.P_FILL, UIKit.UI.FIT)

        frame.OptionListFrame = UIKit.GetElementById("OptionListFrame", id)

        Mixin(frame, GossipOptionBase.GroupMixin)

        return frame
    end)
end
