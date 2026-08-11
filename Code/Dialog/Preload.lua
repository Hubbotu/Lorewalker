local env = select(2, ...)
local Path = env.modules:Import("packages\\path")
local UIKit = env.modules:Import("packages\\ui-kit")
local React = env.modules:Import("packages\\react")
local Dialog_Preload = env.modules:New("@\\Dialog\\Preload")

local EDIT_MODE_ATLAS = UIKit.Define.Texture_Atlas{ path = Path.Root .. "\\Art\\EditMode\\EditMode" }
Dialog_Preload.UIDEF = {
    Selection          = EDIT_MODE_ATLAS{ inset = 7, left = 0 / 16, right = 16 / 16, top = 0 / 16, bottom = 16 / 16 },
    IMChatBubbleShadow = UIKit.Define.Texture_Atlas{ path = Path.Root .. "\\Art\\Dialog\\ImmersiveMode\\ChatBubbleShadow", inset = 31, left = 0 / 128, right = 128 / 128, top = 0 / 64, bottom = 64 / 64 }
}

Dialog_Preload.TextColorSay = React.New(nil)
Dialog_Preload.TextColorEmote = React.New(nil)

function Dialog_Preload:UpdateTextColor()
    local say = ChatTypeInfo["MONSTER_SAY"]
    Dialog_Preload.TextColorSay:Set(UIKit.Define.Color_RGBA{ r = say.r * 255, g = say.g * 255, b = say.b * 255, a = 1 })

    local emote = ChatTypeInfo["MONSTER_EMOTE"]
    Dialog_Preload.TextColorEmote:Set(UIKit.Define.Color_RGBA{ r = emote.r * 255, g = emote.g * 255, b = emote.b * 255, a = 1 })
end

local EL = CreateFrame("Frame")
EL:RegisterEvent("UPDATE_CHAT_COLOR")
EL:SetScript("OnEvent", function(_, _, chatType)
    if chatType == "MONSTER_SAY" or chatType == "MONSTER_EMOTE" then
        Dialog_Preload:UpdateTextColor()
    end
end)

Dialog_Preload:UpdateTextColor()
