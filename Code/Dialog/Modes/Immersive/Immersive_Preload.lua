local env = select(2, ...)
local ImmersiveMode_Preload = env.modules:New("@\\Dialog\\Modes\\Immersive\\Preload")


ImmersiveMode_Preload.Enum = {
    Appearance = {
        Dialog    = 1,
        Object    = 2,
        Emote     = 3
    }
}

ImmersiveMode_Preload.CVars = {
    NameplateShowFriendlyNPCs    = 1,
    NameplateShowFriends         = 1,
    NameplateShowAll             = 1,
    UnitNameNPC                  = 0,
    UnitNameFriendlyPlayerName   = 0,
    UnitNameEnemyPlayerName      = 0,
    ClampTargetNameplateToScreen = 0,
    NameplateOtherTopInset       = -1,
    NameplateOtherBottomInset    = -1,
    NameplateMotion              = 0,
    InstantQuestText             = 1
}
