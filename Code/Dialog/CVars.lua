local env = select(2, ...)
local CVarUtil = env.modules:Import("packages\\cvar-util")
local Dialog_CVars = env.modules:New("@\\Dialog\\CVars")

local InCombatLockdown = InCombatLockdown
local pairs = pairs


Dialog_CVars.Profiles = {
    ImmersiveMode = {
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
}

Dialog_CVars.activeProfile = nil

function Dialog_CVars.Activate(profile)
    if Dialog_CVars.activeProfile or not profile or InCombatLockdown() then return end
    Dialog_CVars.activeProfile = profile

    for name, value in pairs(profile) do
        CVarUtil.SetCVar(name, value, CVarUtil.Enum.TemporaryType.UntilCombatOrLogout)
    end
end

function Dialog_CVars.Deactivate(profile)
    if Dialog_CVars.activeProfile ~= profile then return end
    Dialog_CVars.activeProfile = nil

    CVarUtil.WashList(CVarUtil.Enum.TemporaryType.UntilCombatOrLogout)
end
