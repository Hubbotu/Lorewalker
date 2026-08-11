local env = select(2, ...)
local CVarUtil = env.modules:Import("packages\\cvar-util")
local ImmersiveMode_Preload = env.modules:Import("@\\Dialog\\Modes\\Immersive\\Preload")
local ImmersiveMode_CVars = env.modules:New("@\\Dialog\\Modes\\Immersive\\CVars")

local InCombatLockdown = InCombatLockdown
local pairs = pairs


ImmersiveMode_CVars.isActive = false


function ImmersiveMode_CVars.Activate()
    if ImmersiveMode_CVars.isActive or InCombatLockdown() then return end
    ImmersiveMode_CVars.isActive = true

    for name, value in pairs(ImmersiveMode_Preload.CVars) do
        CVarUtil.SetCVar(name, value, CVarUtil.Enum.TemporaryType.UntilCombatOrLogout)
    end
end

function ImmersiveMode_CVars.Deactivate()
    if not ImmersiveMode_CVars.isActive then return end
    ImmersiveMode_CVars.isActive = false

    CVarUtil.WashList(CVarUtil.Enum.TemporaryType.UntilCombatOrLogout)
end

