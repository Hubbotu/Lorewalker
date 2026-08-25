--[[
    widgetName:                         string
    widgetDecsription:                  Settings_Define.Descriptor
    widgetType:                         Settings_Enum.WidgetType
    widgetTransparent:                  boolean

    Shared:
        key:                            string
        set:                            function

    Tab:
        widgetTab_isFooter:             boolean

    Title:
        widgetTitle_info:               Settings_Define.TitleInfo

    Container:
        widgetContainer_isNested:       boolean

    Text:

    Range:
        widgetRange_min:                number|function
        widgetRange_max:                number|function
        widgetRange_step:               number|function
        widgetRange_textFormatting      string (%s: value)
        widgetRange_textFormattingFunc: function

    Button:
        widgetButton_text:              string
        widgetButton_refreshOnClick:    boolean

    CheckButton:

    SelectionMenu:
        widgetSelectionMenu_data:       table|function
        widgetSelectionMenu_get:        function
        widgetSelectionMenu_set:        function

    Color Input:

    Input:
        widgetInput_placeholder:        string|function

    disableWhen:                        function
    showWhen:                           function
    indent:                             number
    children:                           table
]]

local env = select(2, ...)
local Config = env.Config
local L = env.L
local UIFont = env.modules:Import("packages\\ui-font")
local Modes_ModeHandler = env.modules:Import("@\\Dialog\\Modes\\ModeHandler")
local Settings_Define = env.modules:Import("@\\Settings\\Define")
local Settings_Enum = env.modules:Import("@\\Settings\\Enum")
local Settings_Preload = env.modules:Import("@\\Settings\\Preload")
local Settings_Schema = env.modules:New("@\\Settings\\Schema")

local SettingsPrompt = _G[Settings_Preload.FRAME_NAME].Prompt

local function HandleAccept()
    Config.DBGlobal:Wipe()
    ReloadUI()
end

local RESET_PROMPT = {
    text         = L["CONFIG_GENERAL_OTHER_RESETPROMPT"],
    options      = {
        {
            text     = L["CONFIG_GENERAL_OTHER_RESETPROMPT_YES"],
            callback = HandleAccept
        },
        {
            text     = L["CONFIG_GENERAL_OTHER_RESETPROMPT_NO"],
            callback = nil
        }
    },
    hideOnEscape = true,
    timeout      = 10
}

do -- Schema
    local function FormatPercentage(value) return string.format("%0.0f", value * 100) .. "%" end

    Settings_Schema.SCHEMA = {
        {
            widgetName = L["CONFIG_GENERAL"],
            widgetType = Settings_Enum.WidgetType.Tab,
            children   = {
                {
                    widgetName = L["CONFIG_GENERAL_PREFERENCES"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    children   = {
                        {
                            widgetName               = L["CONFIG_GENERAL_PREFERENCES_FONT"],
                            widgetType               = Settings_Enum.WidgetType.SelectionMenu,
                            widgetSelectionMenu_data = function()
                                UIFont.CustomFont:RefreshFontList()
                                return UIFont.CustomFont:GetFontNames()
                            end,
                            widgetSelectionMenu_get  = function(value)
                                return UIFont.CustomFont.GetFontIndexForPath(value)
                            end,
                            widgetSelectionMenu_set  = function(index)
                                return UIFont.CustomFont.GetFontPathForIndex(index)
                            end,
                            key                      = "fontPath"
                        }
                    }
                },
                {
                    widgetName = L["CONFIG_GENERAL_OTHER"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    children   = {
                        {
                            widgetName        = nil,
                            widgetType        = Settings_Enum.WidgetType.Button,
                            widgetButton_text = L["CONFIG_GENERAL_OTHER_RESETBUTTON"],
                            set               = function() SettingsPrompt:Open(RESET_PROMPT) end
                        }
                    }
                }
            }
        },
        {
            widgetName = L["CONFIG_DIALOGUE"],
            widgetType = Settings_Enum.WidgetType.Tab,
            children   = {
                {
                    widgetType               = Settings_Enum.WidgetType.SelectionMenu,
                    widgetTransparent        = true,
                    widgetSelectionMenu_data = {
                        L["CONFIG_DIALOGUE_MODE_CLASSIC"],
                        L["CONFIG_DIALOGUE_MODE_IMMERSIVE"]
                    },
                    widgetSelectionMenu_set  = function(index)
                        Modes_ModeHandler.SetMode(index)
                        return Modes_ModeHandler.GetMode()
                    end,
                    key                      = "ActiveMode"
                },
                {
                    widgetName = L["CONFIG_DIALOGUE_FRAME"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    children   = {
                        {
                            widgetName               = L["CONFIG_DIALOGUE_THEME"],
                            widgetType               = Settings_Enum.WidgetType.SelectionMenu,
                            widgetSelectionMenu_data = {
                                L["CONFIG_DIALOGUE_THEME_LIGHT"],
                                L["CONFIG_DIALOGUE_THEME_DARK"]
                            },
                            key                      = "Theme"
                        },
                        {
                            widgetName = L["CONFIG_DIALOGUE_RIGHTCLICKTOCLOSE"],
                            widgetType = Settings_Enum.WidgetType.CheckButton,
                            key        = "RightClickToClose"
                        }
                    }
                }
            }
        },
        {
            widgetName = L["CONFIG_EFFECTS"],
            widgetType = Settings_Enum.WidgetType.Tab,
            children   = {
                {
                    widgetName = L["CONFIG_EFFECTS"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    children   = {
                        {
                            widgetName = L["CONFIG_EFFECTS_HIDEUI"],
                            widgetType = Settings_Enum.WidgetType.CheckButton,
                            key        = "HideUI"
                        },
                        {
                            widgetName               = L["CONFIG_EFFECTS_CAMERA"],
                            widgetType               = Settings_Enum.WidgetType.SelectionMenu,
                            widgetSelectionMenu_data = {
                                L["CONFIG_EFFECTS_CAMERA_NONE"],
                                L["CONFIG_EFFECTS_CAMERA_FULL"],
                                L["CONFIG_EFFECTS_CAMERA_BALANCED"]
                            },
                            key                      = "CameraEffectsPreset"
                        }
                    }
                }
            }
        },
        {
            widgetName = L["CONFIG_TTS"],
            widgetType = Settings_Enum.WidgetType.Tab,
            children   = {
                {
                    widgetName = L["WIP"],
                    widgetType = Settings_Enum.WidgetType.Text
                }
            }
        },
        {
            widgetName = L["CONFIG_KEYBINDINGS"],
            widgetType = Settings_Enum.WidgetType.Tab,
            children   = {
                {
                    widgetName = L["WIP"],
                    widgetType = Settings_Enum.WidgetType.Text
                }
            }
        },
        {
            widgetName = L["CONFIG_APPEARANCE"],
            widgetType = Settings_Enum.WidgetType.Tab,
            children   = {
                {
                    widgetName = L["CONFIG_APPEARANCE_DIALOG"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    children   = {
                        {
                            widgetName                     = L["CONFIG_APPEARANCE_DIALOG_FONTSIZE"],
                            widgetType                     = Settings_Enum.WidgetType.Range,
                            widgetRange_min                = 0.8,
                            widgetRange_max                = 1.2,
                            widgetRange_step               = 0.1,
                            widgetRange_textFormattingFunc = FormatPercentage,
                            key                            = "DialogFontSizeOffset"
                        }
                    }
                },
                {
                    widgetName = L["CONFIG_APPEARANCE_IMMERSIVE"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    showWhen   = function() return Config.DBGlobal:GetVariable("ActiveMode") == env.Enum.Mode.Immersive end,
                    children   = {
                        {
                            widgetName                     = L["CONFIG_APPEARANCE_IMMERSIVE_FONTSIZE"],
                            widgetType                     = Settings_Enum.WidgetType.Range,
                            widgetRange_min                = 0.8,
                            widgetRange_max                = 1.2,
                            widgetRange_step               = 0.1,
                            widgetRange_textFormattingFunc = FormatPercentage,
                            key                            = "ChatBubbleFontSizeOffset"
                        }
                    }
                }
            }
        },
        {
            widgetName = L["CONFIG_AUDIO"],
            widgetType = Settings_Enum.WidgetType.Tab,
            children   = {
                {
                    widgetName = L["CONFIG_AUDIO_GENERAL"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    children   = {
                        {
                            widgetName = L["CONFIG_AUDIO_GENERAL_ENABLEGLOBALAUDIO"],
                            widgetType = Settings_Enum.WidgetType.CheckButton,
                            key        = "AudioGlobal"
                        }
                    }
                }
            }
        },
        {
            widgetName         = L["CONFIG_ABOUT"],
            widgetType         = Settings_Enum.WidgetType.Tab,
            widgetTab_isFooter = true,
            children           = {
                {
                    widgetName       = L["CONFIG_ABOUT"],
                    widgetType       = Settings_Enum.WidgetType.Title,
                    widgetTitle_info = Settings_Define.TitleInfo{ imagePath = env.ICON_ALT, text = env.NAME, subtext = env.VERSION_STRING }
                },
                {
                    widgetName        = L["CONFIG_ABOUT_DEVELOPER"],
                    widgetType        = Settings_Enum.WidgetType.Container,
                    widgetTransparent = true,
                    children          = {
                        {
                            widgetName        = L["CONFIG_ABOUT_DEVELOPER_ADAPTIVEX"],
                            widgetType        = Settings_Enum.WidgetType.Text,
                            widgetTransparent = true
                        }
                    }
                }
            }
        }
    }
end
