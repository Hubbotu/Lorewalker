local env = select(2, ...)
local GenericEnum = env.modules:Import("packages\\generic-enum")
local UIFont = env.modules:Import("packages\\ui-font")
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List, SecureButton, ModelScene = unpack(UIKit.UI.Frames)
local Dialog_Preload = env.modules:Import("@\\Dialog\\Preload")
local Dialog_UIWidgets = env.modules:Import("@\\Dialog\\UIWidgets")


do -- Chat Bubble
    local CONTENT_INSET = 8
    local CONTENT_SIZE = UIKit.Define.Fill{ delta = CONTENT_INSET * 2 }
    local TEXT_WIDTH = 318
    local PROGRESS_FRAME_WIDTH = 56
    local PROGRESS_FRAME_HEIGHT = 16
    local PROGRESS_FRAME_Y = 2
    local STEPPER_BUTTON_SIZE = 12

    local name = "LWImmersiveChatBubble"
    local id = "LWImmersiveChatBubble"

    local frame = Frame(name, {
            Frame(name .. ".ContainerFrame", {
                Frame(name .. ".ContentFrame", {
                    Frame(name .. ".StringFrame", {
                        Text(name .. ".String")
                            :id("String", id)
                            :point(UIKit.Enum.Point.Center)
                            :size(TEXT_WIDTH, UIKit.UI.FIT)
                            :fontObject(UIFont.ImmersiveChatBubbleFont)
                            :textColor(Dialog_Preload.TextColorSay)
                            :ignoreParentScale(true)
                            :frameLevel(2)
                    })
                        :id("StringFrame", id)
                        :size(UIKit.UI.FILL)
                        :clipsChildren(true)
                })
                    :id("ContentFrame", id)
                    :size(CONTENT_SIZE)
                    :clipsChildren(true)
            })
                :id("ContainerFrame", id)
                :point(UIKit.Enum.Point.Center),

            Frame(name .. ".ProgressFrame", {
                Dialog_UIWidgets.StepperButton(name .. ".ProgressFrame.PreviousButton")
                    :id("ProgressFrame.PreviousButton", id)
                    :point(UIKit.Enum.Point.Left)
                    :size(STEPPER_BUTTON_SIZE, STEPPER_BUTTON_SIZE),

                Text(name .. ".ProgressFrame.ProgressText")
                    :id("ProgressFrame.ProgressText", id)
                    :point(UIKit.Enum.Point.Center)
                    :size(UIKit.UI.FIT, UIKit.UI.FIT)
                    :fontObject(UIFont.UIFontObjectNormal12)
                    :textColor(GenericEnum.UIColorRGB.NORMAL_FONT_COLOR)
                    :textJustifyH("CENTER")
                    :textJustifyV("MIDDLE"),

                Dialog_UIWidgets.StepperButton(name .. ".ProgressFrame.NextButton")
                    :id("ProgressFrame.NextButton", id)
                    :point(UIKit.Enum.Point.Right)
                    :size(STEPPER_BUTTON_SIZE, STEPPER_BUTTON_SIZE)
            })
                :id("ProgressFrame", id)
                :anchor(UIKit.NewGroupCaptureString("ContainerFrame", id))
                :frameLevel(3)
                :point(UIKit.Enum.Point.Bottom, UIKit.Enum.Point.Top)
                :size(PROGRESS_FRAME_WIDTH, PROGRESS_FRAME_HEIGHT)
                :y(PROGRESS_FRAME_Y)
                :_excludeFromCalculations()
        })
        :parent(LWParent)
        :frameStrata(UIKit.Enum.FrameStrata.World)
        :clampedToScreen(true)
        :ignoreParentAlpha(true)
        :enableMouse(true)
        :registerForDrag(true)
        :_Render()

    frame.ContainerFrame = UIKit.GetElementById("ContainerFrame", id)

    Frame(name .. ".DialogBackground", nil, frame.ContainerFrame, "NineSlicePanelTemplate")
        :parent(frame.ContainerFrame)
        :id("DialogBackground", id)
        :size(UIKit.UI.FILL)
        :frameLevel(1)
        :_Render()

    Frame(name .. ".ObjectBackground", nil, frame.ContainerFrame)
        :parent(frame.ContainerFrame)
        :id("ObjectBackground", id)
        :size(UIKit.Define.Fill{ delta = -CONTENT_INSET * 2 })
        :frameLevel(1)
        :background(Dialog_Preload.UIDEF.IMChatBubbleShadow)
        :_Render()

    frame.DialogBackground = UIKit.GetElementById("DialogBackground", id)
    frame.ObjectBackground = UIKit.GetElementById("ObjectBackground", id)
    frame.ContentFrame = UIKit.GetElementById("ContentFrame", id)
    frame.StringFrame = UIKit.GetElementById("StringFrame", id)
    frame.String = UIKit.GetElementById("String", id)
    frame.ProgressFrame = UIKit.GetElementById("ProgressFrame", id)
    frame.ProgressFrame.PreviousButton = UIKit.GetElementById("ProgressFrame.PreviousButton", id)
    frame.ProgressFrame.ProgressText = UIKit.GetElementById("ProgressFrame.ProgressText", id)
    frame.ProgressFrame.NextButton = UIKit.GetElementById("ProgressFrame.NextButton", id)

    frame.ProgressFrame.PreviousButton:OnLoad(false, frame)
    frame.ProgressFrame.NextButton:OnLoad(true, frame)

    frame.Tail = frame.ContainerFrame:CreateTexture(nil, "ARTWORK", nil, 7)
    frame.Tail:SetAtlas("ChatBubble-Tail", true)
    frame.Tail:ClearAllPoints()
    frame.Tail:SetSize(16, 16)
    frame.Tail:SetPoint("TOP", frame.ContainerFrame, "BOTTOM", 0, 6)
    frame.String:SetNonSpaceWrap(true)
    frame.String:SetPoint("CENTER", frame.StringFrame, 0, 0)

    frame:SetScript("OnSizeChanged", function(self, width, height) frame.ContainerFrame:SetSize(width, height) end)

    frame.DialogBackground.layoutType = "ChatBubble"
    frame.DialogBackground.inset = 16
    frame.DialogBackground:OnLoad()

    LWImmersiveChatBubble = frame
end
