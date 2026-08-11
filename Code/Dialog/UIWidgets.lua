local env = select(2, ...)
local Path = env.modules:Import("packages\\path")
local GenericEnum = env.modules:Import("packages\\generic-enum")
local Sound = env.modules:Import("packages\\sound")
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local UIFont = env.modules:Import("packages\\ui-font")
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List, SecureButton, ModelScene = unpack(UIKit.UI.Frames)
local UIAnim = env.modules:Import("packages\\ui-anim")
local UICSharedMixin = env.modules:Import("packages\\uic-sharedmixin")
local UICCommon = env.modules:Import("packages\\uic-common")
local InputUtil = env.modules:Import("@\\InputUtil")
local Dialog_Preload = env.modules:Import("@\\Dialog\\Preload")
local Dialog_UIWidgets = env.modules:New("@\\Dialog\\UIWidgets")

local Mixin = Mixin
local CreateFromMixins = CreateFromMixins

do -- Quest NPC Model Scene
    local QUEST_FRAME_MODEL_SCENE_ID = 309
    local DEFAULT_MOUNT_ANIMATION = 91
    local DEFAULT_SPELL_VISUAL_KIT_ID = 0
    local PANNING_MODEL_SCENE_TEMPLATE = "PanningModelSceneMixinTemplate"

    local QuestNPCModelSceneMixin = {}

    function QuestNPCModelSceneMixin:SetPortrait(portraitDisplayID, mountPortraitDisplayID, modelSceneID)
        self.portraitDisplayID = portraitDisplayID
        self.mountPortraitDisplayID = mountPortraitDisplayID
        self.modelSceneID = modelSceneID
        self.nativeZoomDistance = nil
        self.nativeMaxZoomDistance = nil
        self.zoomDistanceScale = nil
        self.maxZoomDistanceScale = nil

        self:ClearScene()
        if not portraitDisplayID or portraitDisplayID == 0 then return end

        self:TransitionToModelSceneID(
            modelSceneID or QUEST_FRAME_MODEL_SCENE_ID,
            CAMERA_TRANSITION_TYPE_IMMEDIATE,
            CAMERA_MODIFICATION_TYPE_DISCARD,
            true
        )

        if portraitDisplayID == -1 then
            local actor = self:GetPlayerActor("player")
            if actor then actor:SetModelByUnit("player", false) end
            return
        end

        local mount
        local rider
        local riderTag = "rider"

        if mountPortraitDisplayID and mountPortraitDisplayID > 0 then
            mount = self:GetActorByTag("mount")
            if mount then mount:SetModelByCreatureDisplayID(mountPortraitDisplayID) end
        else
            riderTag = "mount"
        end

        if portraitDisplayID > 0 then
            rider = self:GetActorByTag(riderTag)
            if rider then rider:SetModelByCreatureDisplayID(portraitDisplayID) end
        end

        if mount and rider then
            mount:AttachToMount(rider, DEFAULT_MOUNT_ANIMATION, DEFAULT_SPELL_VISUAL_KIT_ID)
        end
    end

    function QuestNPCModelSceneMixin:GetPortrait()
        return self.portraitDisplayID, self.mountPortraitDisplayID, self.modelSceneID
    end

    function QuestNPCModelSceneMixin:SetCameraZoom(zoomDistanceScale, maxZoomDistanceScale)
        self.zoomDistanceScale = zoomDistanceScale or 1
        self.maxZoomDistanceScale = maxZoomDistanceScale or 1

        local camera = self:GetActiveCamera()
        if not camera or not camera.GetZoomDistance or not camera.GetMaxZoomDistance then return end

        self.nativeZoomDistance = self.nativeZoomDistance or camera:GetZoomDistance()
        self.nativeMaxZoomDistance = self.nativeMaxZoomDistance or camera:GetMaxZoomDistance()
        if not self.nativeZoomDistance or not self.nativeMaxZoomDistance then return end

        camera:SetMaxZoomDistance(self.nativeMaxZoomDistance * self.maxZoomDistanceScale)
        camera:SetZoomDistance(self.nativeZoomDistance * self.zoomDistanceScale)
        if camera.SnapToTargetInterpolationZoom then camera:SnapToTargetInterpolationZoom() end
        self:SynchronizeActiveCamera()
    end

    function QuestNPCModelSceneMixin:GetCameraZoom()
        return self.zoomDistanceScale, self.maxZoomDistanceScale
    end

    Dialog_UIWidgets.QuestNPCModelScene = UIKit.Template(function(id, name, children, ...)
        local frame =
            ModelScene(name, {
                unpack(children)
            }, PANNING_MODEL_SCENE_TEMPLATE)

        Mixin(frame, QuestNPCModelSceneMixin)

        return frame
    end)
end

do -- Hotkey Frame
    local HOTKEY_REPLACEMENT_MAP = {
        ESCAPE       = { text = "ESC" },
        SPACE        = { icon = Path.Root .. "\\Art\\Hotkeys\\Space", noFrame = false },
        PADLSHOULDER = { icon = Path.Root .. "\\Art\\Hotkeys\\LB", noFrame = true },
        PADRSHOULDER = { icon = Path.Root .. "\\Art\\Hotkeys\\RB", noFrame = true },
        PADLTRIGGER  = { icon = Path.Root .. "\\Art\\Hotkeys\\LT", noFrame = true },
        PADRTRIGGER  = { icon = Path.Root .. "\\Art\\Hotkeys\\RT", noFrame = true }
    }
    local HOTKEY_REPLACEMENT_MAP_XBOX = {
        PAD1 = { icon = Path.Root .. "\\Art\\Hotkeys\\XBOX-P1", noFrame = true },
        PAD2 = { icon = Path.Root .. "\\Art\\Hotkeys\\XBOX-P2", noFrame = true },
        PAD3 = { icon = Path.Root .. "\\Art\\Hotkeys\\XBOX-P3", noFrame = true },
        PAD4 = { icon = Path.Root .. "\\Art\\Hotkeys\\XBOX-P4", noFrame = true }
    }
    local HOTKEY_REPLACEMENT_MAP_PS = {
        PAD1 = { icon = Path.Root .. "\\Art\\Hotkeys\\PS-P1", noFrame = true },
        PAD2 = { icon = Path.Root .. "\\Art\\Hotkeys\\PS-P2", noFrame = true },
        PAD3 = { icon = Path.Root .. "\\Art\\Hotkeys\\PS-P3", noFrame = true },
        PAD4 = { icon = Path.Root .. "\\Art\\Hotkeys\\PS-P4", noFrame = true }
    }

    local TEXTURE = UIKit.Define.Texture_NineSlice{ path = Path.Root .. "\\Art\\Dialog\\Shared\\HotkeyFrame", inset = 32, scale = 0.25, sliceMode = Enum.UITextureSliceMode.Tiled }
    local SIZE = UIKit.Define.Fit{ delta = 10 }
    local SIZE_ICON_FRAME = UIKit.Define.Fit{ delta = 4 }

    local HotkeyFrameMixin = {}

    function HotkeyFrameMixin:OnLoad()
        self:WatchKeybind()
    end

    function HotkeyFrameMixin:WatchKeybind()
        CallbackRegistry.Add("InputUtil.SetKeybind", function(_, action, key) self:UpdateHotkey(action, key) end)
        CallbackRegistry.Add("InputUtil.SetInputDevice", function() self:UpdateHotkey() end)
        CallbackRegistry.Add("InputUtil.SetDisplayInputDevice", function() self:UpdateHotkey() end)
    end

    function HotkeyFrameMixin:UpdateHotkey(action, key)
        if (not action and not key) or (action == self.action and key ~= self.key) then
            self:SetHotkey(action or self.action)
        end
    end

    function HotkeyFrameMixin:SetHotkey(action)
        if not action then
            self:Hide()
            return
        end

        self.action = action
        self.key = InputUtil.GetKeybind(action)

        if self.key then
            local replacement = HOTKEY_REPLACEMENT_MAP[self.key]
            if InputUtil:GetDisplayInputDevice() == InputUtil.Enum.DisplayInputDevices.Xbox then
                replacement = HOTKEY_REPLACEMENT_MAP_XBOX[self.key] or replacement
            elseif InputUtil:GetDisplayInputDevice() == InputUtil.Enum.DisplayInputDevices.PS then
                replacement = HOTKEY_REPLACEMENT_MAP_PS[self.key] or replacement
            end

            local noFrame = replacement and replacement.noFrame or false
            local useIcon = replacement and replacement.icon

            if useIcon then
                local iconSize = noFrame and 22 or 16
                self.Icon:SetSize(iconSize, iconSize)
                self.Icon:SetAlpha(noFrame and 1 or 0.75)
                self.IconTexture:SetTexture(replacement.icon)
            else
                self.Text:SetText(replacement and replacement.text or self.key)
            end

            local frameSize = useIcon and SIZE_ICON_FRAME or SIZE
            self:size(frameSize, frameSize)
            self.Frame:SetShown(not noFrame)
            self.Text:SetShown(not useIcon)
            self.Icon:SetShown(useIcon)
            self:Show()
            self:_Render()
        end
    end

    Dialog_UIWidgets.HotkeyFrame = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                Frame(name .. ".Frame")
                    :id("Frame", id)
                    :size(UIKit.UI.FILL)
                    :background(TEXTURE)
                    :frameLevel(1)
                    :_excludeFromCalculations(),

                Text(name .. ".Text")
                    :id("Text", id)
                    :point(UIKit.Enum.Point.Center)
                    :size(UIKit.UI.FIT, UIKit.UI.FIT)
                    :fontObject(UIFont.UIFontObjectNormal10)
                    :alpha(0.75)
                    :frameLevel(2)
                    :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged),

                Frame(name .. ".Icon")
                    :id("Icon", id)
                    :point(UIKit.Enum.Point.Center)
                    :background(UIKit.UI.TEXTURE_NIL)
                    :alpha(0.75)
                    :frameLevel(2)
                    :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)
            })
            :size(SIZE, SIZE)
            :minWidth(10)
            :minHeight(10)
            :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)

        frame.Frame = UIKit.GetElementById("Frame", id)
        frame.Text = UIKit.GetElementById("Text", id)
        frame.Icon = UIKit.GetElementById("Icon", id)
        frame.IconTexture = frame.Icon:GetTextureFrame()

        Mixin(frame, HotkeyFrameMixin)
        frame:OnLoad()

        return frame
    end)
end

do -- Hotkey Button
    local TEXT_ENABLED_X = 5
    local TEXT_DISABLED_X = 25

    local HotkeyButtonMixin = {}

    function HotkeyButtonMixin:HotkeyButton_UpdateLayout(hasKeybind)
        if hasKeybind then
            self.Text
                :anchor(self.HotkeyFrame)
                :x(TEXT_ENABLED_X)
                :point(UIKit.Enum.Point.Left, UIKit.Enum.Point.Right)
                :textJustifyH("LEFT")
        else
            self.Text
                :anchor(self.Content)
                :x(TEXT_DISABLED_X)
                :point(UIKit.Enum.Point.Left)
                :textJustifyH("LEFT")
        end
        self.Text:_Render()
    end

    function HotkeyButtonMixin:SetHotkey(text)
        self.HotkeyFrame:SetHotkey(text)
        self:HotkeyButton_UpdateLayout(text ~= nil)
    end

    function HotkeyButtonMixin:SetHotkeyIcon(texture)
        self.HotkeyFrame:SetIcon(texture)
        self:HotkeyButton_UpdateLayout(texture ~= nil)
    end

    Dialog_UIWidgets.RedHotkeyButton = UIKit.Template(function(id, name, children, ...)
        local frame =
            UICCommon.RedTextButton(name, {
                Dialog_UIWidgets.HotkeyFrame()
                    :id("HotkeyFrame", id)
                    :point(UIKit.Enum.Point.Left)
                    :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)
            })

        frame.HotkeyFrame = UIKit.GetElementById("HotkeyFrame", id)

        frame.Text
            :anchor(frame.Content)
            :point(UIKit.Enum.Point.Center)
            :size(UIKit.UI.P_FILL, UIKit.UI.P_FILL)
            :textJustifyH("CENTER")

        Mixin(frame, HotkeyButtonMixin)

        return frame
    end)

    Dialog_UIWidgets.GrayHotkeyButton = UIKit.Template(function(id, name, children, ...)
        local frame =
            UICCommon.GrayTextButton(name, {
                Dialog_UIWidgets.HotkeyFrame()
                    :id("HotkeyFrame", id)
                    :point(UIKit.Enum.Point.Left)
                    :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)
            })

        frame.HotkeyFrame = UIKit.GetElementById("HotkeyFrame", id)
        frame.Text
            :anchor(frame.Content)
            :point(UIKit.Enum.Point.Center)
            :size(UIKit.UI.P_FILL, UIKit.UI.P_FILL)
            :textJustifyH("CENTER")

        Mixin(frame, HotkeyButtonMixin)

        return frame
    end)
end

do -- Settings Button
    local ATLAS = UIKit.Define.Texture_Atlas{ path = Path.Root .. "\\Art\\Dialog\\Shared\\SettingsButton", inset = 0, scale = 1 }
    local UIDEF = {
        UISettingsButton             = ATLAS{ left = 0 / 128, right = 32 / 128, top = 0 / 32, bottom = 32 / 32 },
        UISettingsButton_Highlighted = ATLAS{ left = 32 / 128, right = 64 / 128, top = 0 / 32, bottom = 32 / 32 },
        UISettingsButton_Pushed      = ATLAS{ left = 64 / 128, right = 96 / 128, top = 0 / 32, bottom = 32 / 32 },
        UISettingsButton_Disabled    = ATLAS{ left = 96 / 128, right = 128 / 128, top = 0 / 32, bottom = 32 / 32 }
    }
    local ICON_SIZE = UIKit.Define.Percentage{ value = 78 }
    local ICON_Y = 0
    local ICON_Y_HIGHLIGHTED = 0
    local ICON_Y_PUSHED = -1
    local ICON_ENABLED_ALPHA = 1
    local ICON_DISABLED_ALPHA = 0.5

    local SettingsButtonMixin = CreateFromMixins(UICSharedMixin.ButtonMixin)

    function SettingsButtonMixin:OnLoad()
        self:InitButton()
        self:RegisterMouseEvents()
        self:HookButtonStateChange(self.UpdateAnimation)
        self:HookEnableChange(self.UpdateAnimation)
        self:HookMouseUp(self.PlayInteractSound)
        self:UpdateAnimation()
    end

    function SettingsButtonMixin:UpdateAnimation()
        local enabled = self:IsEnabled()
        local buttonState = self:GetButtonState()

        if not enabled then
            self.Icon:background(UIDEF.UISettingsButton_Disabled)
            self.Icon:ClearAllPoints()
            self.Icon:SetPoint("CENTER", self, "CENTER", 0, ICON_Y)
        elseif buttonState == "NORMAL" then
            self.Icon:background(UIDEF.UISettingsButton)
            self.Icon:ClearAllPoints()
            self.Icon:SetPoint("CENTER", self, "CENTER", 0, ICON_Y)
        elseif buttonState == "HIGHLIGHTED" then
            self.Icon:background(UIDEF.UISettingsButton_Highlighted)
            self.Icon:ClearAllPoints()
            self.Icon:SetPoint("CENTER", self, "CENTER", -ICON_Y_HIGHLIGHTED, ICON_Y_HIGHLIGHTED)
        elseif buttonState == "PUSHED" then
            self.Icon:background(UIDEF.UISettingsButton_Pushed)
            self.Icon:ClearAllPoints()
            self.Icon:SetPoint("CENTER", self, "CENTER", -ICON_Y_PUSHED, ICON_Y_PUSHED)
        end

        self.Icon:SetAlpha(enabled and ICON_ENABLED_ALPHA or ICON_DISABLED_ALPHA)
    end

    function SettingsButtonMixin:PlayInteractSound()
        Sound.PlaySound("UI", SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end

    Dialog_UIWidgets.SettingsButton = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                Frame(name .. ".Icon")
                    :id("Icon", id)
                    :point(UIKit.Enum.Point.Center)
                    :size(ICON_SIZE, ICON_SIZE)
                    :background(UIDEF.UISettingsButton)
                    :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)
            })
            :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)

        frame.Icon = UIKit.GetElementById("Icon", id)

        Mixin(frame, SettingsButtonMixin)
        frame:OnLoad()

        return frame
    end)
end

do -- Stepper Button
    local ATLAS = UIKit.Define.Texture_Atlas{ path = Path.Root .. "\\Art\\Dialog\\Shared\\StepperButton" }
    local UIDEF = {
        UIStepperLeft          = ATLAS{ left = 0 / 64, right = 32 / 64, top = 0 / 32, bottom = 32 / 64 },
        UIStepperLeft_Pushed   = ATLAS{ left = 32 / 64, right = 64 / 64, top = 0 / 32, bottom = 32 / 64 },
        UIStepperRight         = ATLAS{ left = 0 / 64, right = 32 / 64, top = 32 / 64, bottom = 64 / 64 },
        UIStepperRightt_Pushed = ATLAS{ left = 32 / 64, right = 64 / 64, top = 32 / 64, bottom = 64 / 64 }
    }

    local StepperButtonMixin = CreateFromMixins(UICSharedMixin.ButtonMixin)

    function StepperButtonMixin:UpdateAnimation()
        local buttonState = self:GetButtonState()

        if buttonState == "PUSHED" then
            if self.isIncrease then
                self:background(UIDEF.UIStepperRightt_Pushed)
            else
                self:background(UIDEF.UIStepperLeft_Pushed)
            end
        else
            if self.isIncrease then
                self:background(UIDEF.UIStepperRight)
            else
                self:background(UIDEF.UIStepperLeft)
            end
        end
    end

    function StepperButtonMixin:OnLoad(isIncrease, parent)
        self:InitButton()
        self.isIncrease = isIncrease
        self.parent = parent

        self:RegisterMouseEvents()
        self:HookButtonStateChange(self.UpdateAnimation)
        self:HookEnableChange(self.UpdateAnimation)
        self:HookMouseUp(self.PlayInteractSound)
        self:UpdateAnimation()
    end

    function StepperButtonMixin:PlayInteractSound()
        Sound.PlaySound("UI", SOUNDKIT.SCROLLBAR_STEP or SOUNDKIT.U_CHAT_SCROLL_BUTTON)
    end

    Dialog_UIWidgets.StepperButton = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name)
            :background(UIKit.UI.TEXTURE_NIL)
            :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)

        Mixin(frame, StepperButtonMixin)

        return frame
    end)
end

do -- Item Slot
    local ATLAS = UIKit.Define.Texture_Atlas{ path = Path.Root .. "\\Art\\Dialog\\Shared\\ItemSlot" }
    local UIDEF = {
        ItemSlot  = ATLAS{ left = 0 / 128, right = 64 / 128, top = 0 / 64, bottom = 64 / 64 },
        SpellSlot = ATLAS{ left = 64 / 128, right = 128 / 128, top = 0 / 64, bottom = 64 / 64 },
        ItemMask  = UIKit.Define.Texture{ path = Path.Root .. "\\Art\\Dialog\\Shared\\Mask-ItemSlot" }
    }
    local BACKGROUND_SIZE = UIKit.Define.Fill{ delta = -12 }
    local ITEM_SIZE = UIKit.Define.Fill{ delta = 4 }

    local ItemSlotMixin = {}

    function ItemSlotMixin:OnLoad()
        self.isBackgroundSet = false
    end

    function ItemSlotMixin:SetItem(texture, rarity)
        self.ItemTexture:SetTexture(texture)
        if not self.isBackgroundSet then
            self.Background:background(UIDEF.ItemSlot)
            self.isBackgroundSet = true
        end
        self.Background:backgroundColor(GenericEnum.ItemRarityColor[rarity])
    end

    function ItemSlotMixin:SetSpell(texture)
        self.ItemTexture:SetTexture(texture)
        if not self.isBackgroundSet then
            self.Background:background(UIDEF.SpellSlot)
            self.Background:backgroundColor(GenericEnum.UIColorRGB.WHITE_FONT_COLOR)
            self.isBackgroundSet = true
        end
    end

    function ItemSlotMixin:SetAmount(amount)
        self.AmountText:SetShown(amount ~= nil)
        if amount then
            self.AmountText:SetText(amount)
        end
    end

    Dialog_UIWidgets.ItemSlot = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                Frame(name .. ".Background")
                    :id("Background", id)
                    :frameLevel(2)
                    :background(UIKit.UI.TEXTURE_NIL)
                    :size(BACKGROUND_SIZE),

                Frame(name .. ".Item")
                    :id("Item", id)
                    :frameLevel(1)
                    :size(ITEM_SIZE)
                    :background(UIKit.UI.TEXTURE_NIL)
                    :mask(UIDEF.ItemMask),

                Text(name .. ".AmountText")
                    :id("AmountText", id)
                    :frameLevel(3)
                    :point(UIKit.Enum.Point.BottomRight)
                    :position(-5, 6)
                    :size(50, 50)
                    :fontObject(UIFont.ParchmentRewardTagText)
                    :textColor(GenericEnum.UIColorRGB.WHITE_FONT_COLOR)
                    :textJustifyH("RIGHT")
                    :textJustifyV("BOTTOM")
            })


        frame.Background = UIKit.GetElementById("Background", id)
        frame.BackgroundTexture = frame.Background:GetTextureFrame()
        frame.Item = UIKit.GetElementById("Item", id)
        frame.ItemTexture = frame.Item:GetTextureFrame()
        frame.AmountText = UIKit.GetElementById("AmountText", id)

        Mixin(frame, ItemSlotMixin)
        frame.AmountText:Hide()

        return frame
    end)
end
