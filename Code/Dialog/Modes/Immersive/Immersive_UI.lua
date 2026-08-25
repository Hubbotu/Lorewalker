local env = select(2, ...)
local Path = env.modules:Import("packages\\path")
local GenericEnum = env.modules:Import("packages\\generic-enum")
local Sound = env.modules:Import("packages\\sound")
local UIFont = env.modules:Import("packages\\ui-font")
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List, SecureButton, ModelScene = unpack(UIKit.UI.Frames)
local UICSharedMixin = env.modules:Import("packages\\uic-sharedmixin")
local Dialog_Preload = env.modules:Import("@\\Dialog\\Preload")
local Dialog_UIWidgets = env.modules:Import("@\\Dialog\\UIWidgets")
local Immersive_UI = env.modules:New("@\\@\\Dialog\\Modes\\Immersive\\UI")


do -- Replay Button
    local ATLAS = UIKit.Define.Texture_Atlas{ path = Path.Root .. "\\Art\\Dialog\\Shared\\ReplayButton", inset = 0, scale = 1 }
    local UIDEF = {
        UIReplayButton        = ATLAS{ left = 0 / 64, right = 32 / 64, top = 0 / 32, bottom = 32 / 32 },
        UIReplayButton_Pushed = ATLAS{ left = 32 / 64, right = 64 / 64, top = 0 / 32, bottom = 32 / 32 }
    }
    local ICON_Y = 0
    local ICON_Y_PUSHED = -1

    local ReplayButtonMixin = CreateFromMixins(UICSharedMixin.ButtonMixin)

    function ReplayButtonMixin:UpdateAnimation()
        local buttonState = self:GetButtonState()

        self.Icon:ClearAllPoints()
        if buttonState == "PUSHED" then
            self.Icon:background(UIDEF.UIReplayButton_Pushed)
            self.Icon:SetPoint("CENTER", self, 0, ICON_Y_PUSHED)
        else
            self.Icon:background(UIDEF.UIReplayButton)
            self.Icon:SetPoint("CENTER", self, 0, ICON_Y)
        end
    end

    function ReplayButtonMixin:OnLoad()
        self:InitButton()

        self:RegisterMouseEvents()
        self:HookButtonStateChange(self.UpdateAnimation)
        self:HookEnableChange(self.UpdateAnimation)
        self:HookMouseUp(self.PlayInteractSound)
        self:UpdateAnimation()
    end

    function ReplayButtonMixin:PlayInteractSound()
        Sound.PlaySound("UI", SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end

    Immersive_UI.ReplayButton = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                Frame(name .. ".Icon")
                    :id("Icon", id)
                    :background(UIDEF.UIReplayButton)
                    :point(UIKit.Enum.Point.Center)
                    :size(UIKit.UI.P_FILL, UIKit.UI.P_FILL)
            })

        Mixin(frame, ReplayButtonMixin)

        frame.Icon = UIKit.GetElementById("Icon", id)
        frame:OnLoad()

        return frame
    end)
end

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
            Frame(name .. ".ReplayFrame", {
                Frame(name .. ".BackgroundFrame")
                    :id("ReplayFrame.BackgroundFrame", id)
                    :point(UIKit.Enum.Point.Center)
                    :size(48, 48)
                    :frameLevel(1)
                    :background(Dialog_Preload.UIDEF.IMChatBubbleShadow),

                Immersive_UI.ReplayButton(name .. ".ReplayButton")
                    :id("ReplayFrame.ReplayButton", id)
                    :point(UIKit.Enum.Point.Center)
                    :size(22, 22)
                    :frameLevel(2)
            })
                :id("ReplayFrame", id)
                :point(UIKit.Enum.Point.Center)
                :size(48, 48)
                :frameLevel(1),

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

    frame.ReplayFrame = UIKit.GetElementById("ReplayFrame", id)
    frame.ReplayFrame.BackgroundFrame = UIKit.GetElementById("ReplayFrame.BackgroundFrame", id)
    frame.ReplayFrame.ReplayButton = UIKit.GetElementById("ReplayFrame.ReplayButton", id)
    frame.DialogBackground = UIKit.GetElementById("DialogBackground", id)
    frame.ObjectBackground = UIKit.GetElementById("ObjectBackground", id)
    frame.ContainerFrame = UIKit.GetElementById("ContainerFrame", id)
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
