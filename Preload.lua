local env = select(2, ...)
local Sound = env.modules:Import("packages\\sound")
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local UIFont = env.modules:Import("packages\\ui-font")
local SavedVariables = env.modules:Import("packages\\saved-variables")
local Path = env.modules:Import("packages\\path")


env.NAME = "Lorewalker"
env.ICON = Path.Root .. "\\Art\\Icons\\Logo"
env.ICON_ALT = Path.Root .. "\\Art\\Icons\\Logo-White"
env.VERSION_STRING = "Beta 1"
env.VERSION_NUMBER = 000001
env.DEBUG_MODE = false


local L = {}; env.L = L


local Enum = {}; env.Enum = Enum
do
    Enum.Mode = {
        Classic   = 1,
        Immersive = 2,
        Story     = 3
    }
    Enum.CameraEffectsPreset = {
        None     = 1,
        Full     = 2,
        Balanced = 3,
        Custom   = 4
    }
end


local Config = {}; env.Config = Config
do
    Config.DBGlobal = nil
    Config.DBGlobalPersistent = nil
    Config.DBLocal = nil
    Config.DBLocalPersistent = nil

    local NAME_GLOBAL = "LorewalkerDB_Global"
    local NAME_GLOBAL_PERSISTENT = "LorewalkerDB_Global_Persistent"
    local NAME_LOCAL = "LorewalkerDB_Local"
    local NAME_LOCAL_PERSISTENT = "LorewalkerDB_Local_Persistent"

    ---@format disable
    local DB_GLOBAL_DEFAULTS            = {
        lastLoadedVersion = nil,
        fontPath = nil,
        dialogFrameBounds = {
            point = nil,
            x = nil,
            y = nil,
            width = nil,
            height = nil,
        },
        immersiveChatBubbleBounds = {
            point = nil,
            x = nil,
            y = nil,
        },
        userKeybinds = {},

        ActiveMode = Enum.Mode.Classic,

        DialogFontSizeOffset                               = 1, --100%
        ChatBubbleFontSizeOffset                           = 1, --100%

        HideUI                                             = false,
        CameraEffectsPreset                                = Enum.CameraEffectsPreset.None,
        CameraEffects_Zoom                                 = nil,
        CameraEffects_ShowVignette                         = nil,
        CameraEffects_PitchLimit                           = nil,
        CameraEffects_Fov                                  = nil,
        CameraEffects_ShoulderOffset                       = nil,
        CameraEffects_HeadMovementStrength                 = nil,
        CameraEffects_FocusInteractTarget                  = nil,
        CameraEffects_FocusInteractTargetPitchStrength     = nil,
        CameraEffects_FocusInteractTargetYawStrength       = nil,

        ForceGossip                           = false,
        EscapeDeclinesQuest                   = false,
        Immersive_SplitParagraphs             = true,
        Immersive_Playback                    = false,
        Immersive_PlaybackSpeed               = 1,
        Immersive_PlaybackAutoProgress        = true,
        Immersive_PlaybackAutoProgressDelay   = 1,
        Immersive_PlaybackPunctuationPausing  = true,
        Immersive_PlaybackAutoClose           = true,
        Immersive_ContentPreviewAlpha         = .5,

        AudioGlobal                           = true,
    }
    local DB_GLOBAL_PERSISTENT_DEFAULTS = {}
    local DB_LOCAL_DEFAULTS             = {}
    local DB_LOCAL_PERSISTENT_DEFAULTS  = {}
    ---@format enable

    local DB_GLOBAL_MIGRATION           = {}

    function Config.LoadDB()
        if LorewalkerDB_Global and LorewalkerDB_Global.lastLoadedVersion == env.VERSION_NUMBER then
            -- Same version, skip migration
            SavedVariables.RegisterDatabase(NAME_GLOBAL).defaults(DB_GLOBAL_DEFAULTS)
            SavedVariables.RegisterDatabase(NAME_GLOBAL_PERSISTENT).defaults(DB_GLOBAL_PERSISTENT_DEFAULTS)
        else
            -- Migrate if new version
            SavedVariables.RegisterDatabase(NAME_GLOBAL).defaults(DB_GLOBAL_DEFAULTS).migrationPlan(DB_GLOBAL_MIGRATION)
            SavedVariables.RegisterDatabase(NAME_GLOBAL_PERSISTENT).defaults(DB_GLOBAL_PERSISTENT_DEFAULTS)
        end

        SavedVariables.RegisterDatabase(NAME_LOCAL).defaults(DB_LOCAL_DEFAULTS)
        SavedVariables.RegisterDatabase(NAME_LOCAL_PERSISTENT).defaults(DB_LOCAL_PERSISTENT_DEFAULTS)

        Config.DBGlobal = SavedVariables.GetDatabase(NAME_GLOBAL)
        Config.DBGlobalPersistent = SavedVariables.GetDatabase(NAME_GLOBAL_PERSISTENT)
        Config.DBLocal = SavedVariables.GetDatabase(NAME_LOCAL)
        Config.DBLocalPersistent = SavedVariables.GetDatabase(NAME_LOCAL_PERSISTENT)

        CallbackRegistry.Trigger("Preload.DatabaseReady")
    end
end


local SoundHandler = {}
do
    local function UpdateMainSoundLayer()
        local Settings_AudioGlobal = Config.DBGlobal:GetVariable("AudioGlobal")

        if Settings_AudioGlobal == true then
            Sound.SetEnabled("Main", true)
        elseif Settings_AudioGlobal == false then
            Sound.SetEnabled("Main", false)
        end
    end

    SavedVariables.OnChange("LorewalkerDB_Global", "AudioGlobal", UpdateMainSoundLayer)

    function SoundHandler.Load()
        UpdateMainSoundLayer()
    end
end


local FontHandler = {}
do
    local function UpdateFontSizes()
        local dialogFontSizeOffset = Config.DBGlobal:GetVariable("DialogFontSizeOffset")
        local chatBubbleFontSizeOffset = Config.DBGlobal:GetVariable("ChatBubbleFontSizeOffset")

        UIFont.ImmersiveChatBubbleFont:SetFontHeight(UIFont.LWFontSizeDef.ImmersiveChatBubbleFont * chatBubbleFontSizeOffset)
        UIFont.ParchmentText:SetFontHeight(UIFont.LWFontSizeDef.ParchmentText * dialogFontSizeOffset)
        UIFont.ParchmentOptionText:SetFontHeight(UIFont.LWFontSizeDef.ParchmentOptionText * dialogFontSizeOffset)
        UIFont.ParchmentItemText:SetFontHeight(UIFont.LWFontSizeDef.ParchmentItemText * dialogFontSizeOffset)
        UIFont.ParchmentCategoryLabelText:SetFontHeight(UIFont.LWFontSizeDef.ParchmentCategoryLabelText * dialogFontSizeOffset)
        UIFont.ParchmentHeaderPrimaryText:SetFontHeight(UIFont.LWFontSizeDef.ParchmentHeaderPrimaryText * dialogFontSizeOffset)
        UIFont.ParchmentHeaderSecondaryText:SetFontHeight(UIFont.LWFontSizeDef.ParchmentHeaderSecondaryText * dialogFontSizeOffset)
    end

    local function UpdateFonts()
        UIFont.CustomFont:RefreshFontList()

        local fontPath = Config.DBGlobal:GetVariable("fontPath")
        if fontPath == nil or not UIFont.CustomFont.FontExists(fontPath) then
            fontPath = UIFont.CustomFont.GetFontPathForIndex(1)
        end

        UIFont.ImmersiveChatBubbleFont:SetFontFile(fontPath)
        UIFont.ParchmentText:SetFontFile(fontPath)
        UIFont.ParchmentOptionText:SetFontFile(fontPath)
        UIFont.ParchmentItemText:SetFontFile(fontPath)
        UIFont.ParchmentRewardTagText:SetFontFile(fontPath)
        UIFont.ParchmentCategoryLabelText:SetFontFile(fontPath)
        UIFont.ParchmentHeaderPrimaryText:SetFontFile(fontPath)
        UIFont.ParchmentHeaderSecondaryText:SetFontFile(fontPath)

        UIFont.SetNormalFont(fontPath)
        Config.DBGlobal:SetVariable("fontPath", fontPath)
    end

    SavedVariables.OnChange("LorewalkerDB_Global", "fontPath", UpdateFonts)
    SavedVariables.OnChange("LorewalkerDB_Global", "DialogFontSizeOffset", UpdateFontSizes)
    SavedVariables.OnChange("LorewalkerDB_Global", "ChatBubbleFontSizeOffset", UpdateFontSizes)

    function FontHandler.Load()
        UpdateFonts()
        UpdateFontSizes()
    end
end


local function LoadAddon()
    Config.LoadDB()
    SoundHandler.Load()

    Config.DBGlobal:SetVariable("lastLoadedVersion", env.VERSION_NUMBER)
    CallbackRegistry.Trigger("Preload.AddonReady")
end

CallbackRegistry.Add("WoWClient.OnAddonLoaded", LoadAddon)
CallbackRegistry.Add("WoWClient.OnPlayerLogin", FontHandler.Load)
