--[[
    Lorewalker API Documentation

    `LorewalkerAPI.OpenSettingsUI()`
]]

local env = select(2, ...)
LorewalkerAPI = LorewalkerAPI or {}

do -- @\\Settings
    local Settings = env.modules:Await("@\\Settings")
    LorewalkerAPI_OpenSettingsUI = Settings.OpenSettingsUI
    LorewalkerAPI.OpenSettingsUI = Settings.OpenSettingsUI
end
