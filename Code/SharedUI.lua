local env = select(2, ...)
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List, SecureButton, ModelScene = unpack(UIKit.UI.Frames)
local UICCommon = env.modules:Import("packages\\uic-common")

LWParent = Frame("LWParent")
    :size(UIKit.UI.FILL)
    :_Render()

CallbackRegistry.Add("WoWClient.OnUIScaleChanged", function()
    LWParent:SetScale(UIParent:GetScale())
end)
