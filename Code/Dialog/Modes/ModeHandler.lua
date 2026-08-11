local env = select(2, ...)
local Config = env.Config
local Enum = env.Enum
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local Modes_ModeHandler = env.modules:New("@\\Dialog\\Modes\\ModeHandler")


Modes_ModeHandler.modes = {}


local function RestoreMode(mode)
    if not mode then return end
    mode.Activate()
end

local function SwitchMode(modeID)
    local mode = Modes_ModeHandler.modes[modeID]
    if not mode then return false end

    local previousMode = Modes_ModeHandler.GetActiveMode()

    if previousMode and previousMode.Deactivate() == false then
        RestoreMode(previousMode)
        return false
    end

    if mode.Activate() == false then
        mode.Deactivate()
        RestoreMode(previousMode)
        return false
    end

    Config.DBGlobal:SetVariable("ActiveMode", modeID)
    CallbackRegistry.Trigger("ControlCenter.ModeChanged", modeID)
    return true
end


function Modes_ModeHandler.RegisterMode(modeID, mode)
    if Modes_ModeHandler.modes[modeID] then return end
    Modes_ModeHandler.modes[modeID] = mode
end

function Modes_ModeHandler.SetMode(modeID)
    if not Modes_ModeHandler.modes[modeID] then return false end
    if Modes_ModeHandler.IsModeActive(modeID) then return true end
    return SwitchMode(modeID)
end

function Modes_ModeHandler.GetMode()
    return Config.DBGlobal:GetVariable("ActiveMode")
end

function Modes_ModeHandler.GetActiveMode()
    local mode = Modes_ModeHandler.modes[Modes_ModeHandler.GetMode()]
    return mode and mode.isActive and mode or nil
end

function Modes_ModeHandler.IsModeActive(modeID)
    local mode = Modes_ModeHandler.modes[modeID]
    return Modes_ModeHandler.GetMode() == modeID and mode and mode.isActive or false
end


CallbackRegistry.Add("Preload.AddonReady", function()
    local modeID = Config.DBGlobal:GetVariable("ActiveMode")
    if not Modes_ModeHandler.modes[modeID] then modeID = Enum.Mode.Classic end
    Modes_ModeHandler.SetMode(modeID)
end)


do
    _G["Modes_ModeHandler"] = Modes_ModeHandler
end
