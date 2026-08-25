local env = select(2, ...)
local Config = env.Config
local Path = env.modules:Import("packages\\path")
local UIKit = env.modules:Import("packages\\ui-kit")
local React = env.modules:Import("packages\\react")
local Utils_Texture = env.modules:Import("packages\\utils\\texture")
local ControlCenter = env.modules:Import("@\\Dialog\\ControlCenter")
local DialogFrame_Preload = env.modules:New("@\\Dialog\\DialogFrame\\Preload")


local ATLAS = UIKit.Define.Texture_Atlas{ path = Path.Root .. "\\Art\\Dialog\\DialogFrame\\DialogFrame" }
Utils_Texture.Preload(Path.Root .. "\\Art\\Dialog\\DialogFrame\\DialogFrame")
DialogFrame_Preload.UIDEF = {
    UIPortraitRing                         = ATLAS{ left = 6 / 512, right = 82 / 512, top = 6 / 512, bottom = 82 / 512 },
    UIPortraitMask                         = UIKit.Define.Texture{ path = Path.Root .. "\\Art\\Dialog\\DialogFrame\\Mask-UnitPortrait" },
    UITitleContainer                       = ATLAS{ inset = 14, scale = 0.82, left = 86 / 512, right = 186 / 512, top = 6 / 512, bottom = 50 / 512 },
    UIDetailsOptionSoftEdge                = ATLAS{ inset = 16, left = 212 / 512, right = 258 / 512, top = 51 / 512, bottom = 97 / 512 },
    UIDetailsOption                        = ATLAS{ inset = 6, scale = 0.7, left = 88 / 512, right = 124 / 512, top = 56 / 512, bottom = 92 / 512 },
    UIDetailsOptionBorder                  = ATLAS{ inset = 13, scale = 0.67, left = 130 / 512, right = 166 / 512, top = 56 / 512, bottom = 92 / 512 },
    UIDetailsOptionHighlight               = ATLAS{ inset = 13, scale = 0.67, left = 172 / 512, right = 208 / 512, top = 56 / 512, bottom = 92 / 512 },
    UIQuestOption                          = ATLAS{ inset = 32, scale = 1, left = 128 / 768, right = 192 / 768, top = 52 / 768, bottom = 116 / 768 },
    UIEdgeFade                             = ATLAS{ left = 5 / 512, right = 318 / 512, top = 95 / 512, bottom = 110 / 512 },
    UIEdgeFadeGradient                     = ATLAS{ left = 5 / 512, right = 320 / 512, top = 116 / 512, bottom = 168 / 512 },
    UIQuestModelFrameBackground            = ATLAS{ inset = 12, left = 5 / 512, right = 75 / 512, top = 266 / 512, bottom = 336 / 512 },
    UIQuestModelFrameNameplate             = ATLAS{ left = 8 / 512, right = 152 / 512, top = 173 / 512, bottom = 209 / 512 },
    UIQuestModelFrameContent               = ATLAS{ inset = 3, left = 8 / 512, right = 152 / 512, top = 217 / 512, bottom = 262 / 512 },
    UIQuestModelFrameShadow                = ATLAS{ inset = 5, left = 80 / 512, right = 140 / 512, top = 269 / 512, bottom = 329 / 512 },
    UIQuestContentSeperator                = ATLAS{ left = 182 / 512, right = 504 / 512, top = 439 / 512, bottom = 467 / 512 },
    UIQuestContentSeperatorWarbandComplete = ATLAS{ left = 182 / 512, right = 504 / 512, top = 476 / 512, bottom = 504 / 512 },
    UIDialogFrameShadow                    = ATLAS{ inset = 47, scale = 2, left = 262 / 512, right = 358 / 512, top = 0 / 512, bottom = 96 / 512 },
    DialogGlyph                            = ATLAS{ inset = 0, left = 7 / 512, right = 101 / 512, top = 341 / 512, bottom = 435 / 512 },
    Objective                              = UIKit.Define.Texture{ path = Path.Root .. "\\Art\\Dialog\\Shared\\Objective" }
}

DialogFrame_Preload.Enum = {
    RewardButtonType        = {
        Item     = 1,
        Currency = 2,
        Spell    = 3,
        Skill    = 4
    },
    OptionBoundaryType      = {
        BeforeFirst = 1,
        AfterLast   = 2
    },
    SelectableViewportState = {
        Above   = 1,
        Below   = 2,
        Visible = 3
    }
}

local TEXT_COLOR_LIGHT = UIKit.Define.Color_RGBA{ r = 15, g = 15, b = 15, a = 1 }
local TEXT_COLOR_DARK = UIKit.Define.Color_RGBA{ r = 245, g = 245, b = 245, a = 1 }
DialogFrame_Preload.TextColorPrimary = React.New(TEXT_COLOR_LIGHT)
DialogFrame_Preload.TextColorInversePrimary = React.New(UIKit.Define.Color_RGBA{ r = 255, g = 255, b = 255, a = 1 })
DialogFrame_Preload.TintColor = React.New(UIKit.Define.Color_RGBA{ r = 15, g = 15, b = 15, a = 1 })
DialogFrame_Preload.BackgroundColor = React.New(UIKit.Define.Color_RGBA{ r = 255, g = 255, b = 255, a = 1 })

local QUEST_BACKGROUND_PATH = Path.Root .. "\\Art\\Dialog\\DialogFrame\\"
local BACKGROUND_LOOKUP = {
    ["Classic"]     = {
        texture   = QUEST_BACKGROUND_PATH .. "QuestBackgroundClassic",
        color     = UIKit.Define.Color_RGBA{ r = 214, g = 168, b = 114, a = 1 },
        tintColor = UIKit.Define.Color_RGBA{ r = 121, g = 72, b = 5, a = 1 },
        textColor = TEXT_COLOR_LIGHT
    },
    ["Dark"]        = {
        texture   = QUEST_BACKGROUND_PATH .. "QuestBackgroundDark",
        color     = UIKit.Define.Color_RGBA{ r = 33, g = 33, b = 33, a = 1 },
        tintColor = UIKit.Define.Color_RGBA{ r = 179, g = 179, b = 179, a = 1 },
        textColor = TEXT_COLOR_DARK
    },
    ["QuestBG-Sky"] = {
        texture   = QUEST_BACKGROUND_PATH .. "QuestBackgroundMidnightSky",
        color     = UIKit.Define.Color_RGBA{ r = 216, g = 179, b = 158, a = 1 },
        tintColor = UIKit.Define.Color_RGBA{ r = 142, g = 98, b = 80, a = 1 },
        textColor = TEXT_COLOR_LIGHT
    }
}

function DialogFrame_Preload:SetBackground(backgroundTextureObject)
    local background = BACKGROUND_LOOKUP[Config.DBGlobal:GetVariable("Theme") == env.Enum.Theme.Dark and "Dark" or "Classic"]
    local questBackground = ControlCenter.GetQuestSessionType() and ControlCenter.GetQuestBackground()
    if questBackground then
        background = BACKGROUND_LOOKUP[questBackground.background] or background
    end
    backgroundTextureObject:SetTexture(background.texture)
    DialogFrame_Preload.TextColorPrimary:Set(background.textColor)
    DialogFrame_Preload.TintColor:Set(background.tintColor)
    DialogFrame_Preload.BackgroundColor:Set(background.color)
end
