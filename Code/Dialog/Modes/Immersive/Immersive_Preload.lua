local env = select(2, ...)
local ImmersiveMode_Preload = env.modules:New("@\\Dialog\\Modes\\Immersive\\Preload")


ImmersiveMode_Preload.Enum = {
    Appearance = {
        Dialog    = 1,
        Object    = 2,
        Emote     = 3
    }
}
