local env = select(2, ...)
local Config = env.Config
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local InputUtil = env.modules:New("@\\InputUtil")


InputUtil.Enum = {
    InputDevices        = {
        KBM     = 1,
        GamePad = 2
    },
    DisplayInputDevices = {
        KBM  = 1,
        Xbox = 2,
        PS   = 3
    },
    Actions             = {
        Confirm        = 1,
        Close          = 2,
        ScrollDown     = 3,
        ScrollUp       = 4,
        ScrollLeft     = 5,
        ScrollRight    = 6,
        PreviousDialog = 7,
        NextDialog     = 8,
        SelectOption1  = 9,
        SelectOption2  = 10,
        SelectOption3  = 11,
        SelectOption4  = 12,
        SelectOption5  = 13,
        SelectOption6  = 14,
        SelectOption7  = 15,
        SelectOption8  = 16,
        SelectOption9  = 17
    }
}

InputUtil.DefaultKeybindings = {
    [InputUtil.Enum.Actions.Confirm]        = {
        [InputUtil.Enum.InputDevices.KBM]     = "SPACE",
        [InputUtil.Enum.InputDevices.GamePad] = "PAD1"
    },
    [InputUtil.Enum.Actions.Close]          = {
        [InputUtil.Enum.InputDevices.KBM]     = "ESCAPE",
        [InputUtil.Enum.InputDevices.GamePad] = "PAD2"
    },
    [InputUtil.Enum.Actions.ScrollDown]     = {
        [InputUtil.Enum.InputDevices.KBM]     = "DOWN",
        [InputUtil.Enum.InputDevices.GamePad] = "PADDDOWN"
    },
    [InputUtil.Enum.Actions.ScrollUp]       = {
        [InputUtil.Enum.InputDevices.KBM]     = "UP",
        [InputUtil.Enum.InputDevices.GamePad] = "PADDUP"
    },
    [InputUtil.Enum.Actions.ScrollLeft]     = {
        [InputUtil.Enum.InputDevices.KBM]     = "LEFT",
        [InputUtil.Enum.InputDevices.GamePad] = "PADDLEFT"
    },
    [InputUtil.Enum.Actions.ScrollRight]    = {
        [InputUtil.Enum.InputDevices.KBM]     = "RIGHT",
        [InputUtil.Enum.InputDevices.GamePad] = "PADDRIGHT"
    },
    [InputUtil.Enum.Actions.PreviousDialog] = {
        [InputUtil.Enum.InputDevices.KBM]     = "Q",
        [InputUtil.Enum.InputDevices.GamePad] = "PADLSHOULDER"
    },
    [InputUtil.Enum.Actions.NextDialog]     = {
        [InputUtil.Enum.InputDevices.KBM]     = "E",
        [InputUtil.Enum.InputDevices.GamePad] = "PADRSHOULDER"
    },
    [InputUtil.Enum.Actions.SelectOption1]  = {
        [InputUtil.Enum.InputDevices.KBM] = "1"
    },
    [InputUtil.Enum.Actions.SelectOption2]  = {
        [InputUtil.Enum.InputDevices.KBM] = "2"
    },
    [InputUtil.Enum.Actions.SelectOption3]  = {
        [InputUtil.Enum.InputDevices.KBM] = "3"
    },
    [InputUtil.Enum.Actions.SelectOption4]  = {
        [InputUtil.Enum.InputDevices.KBM] = "4"
    },
    [InputUtil.Enum.Actions.SelectOption5]  = {
        [InputUtil.Enum.InputDevices.KBM] = "5"
    },
    [InputUtil.Enum.Actions.SelectOption6]  = {
        [InputUtil.Enum.InputDevices.KBM] = "6"
    },
    [InputUtil.Enum.Actions.SelectOption7]  = {
        [InputUtil.Enum.InputDevices.KBM] = "7"
    },
    [InputUtil.Enum.Actions.SelectOption8]  = {
        [InputUtil.Enum.InputDevices.KBM] = "8"
    },
    [InputUtil.Enum.Actions.SelectOption9]  = {
        [InputUtil.Enum.InputDevices.KBM] = "9"
    }
}
InputUtil.ActiveInputDevice = InputUtil.Enum.InputDevices.KBM
InputUtil.ActiveDisplayInputDevice = InputUtil.Enum.DisplayInputDevices.KBM


function InputUtil.GetInputDevice()
    return InputUtil.ActiveInputDevice
end

function InputUtil.GetDisplayInputDevice()
    return InputUtil.ActiveDisplayInputDevice
end

function InputUtil.SetInputDevice(device)
    if device == InputUtil.ActiveInputDevice then
        return
    end
    InputUtil.ActiveInputDevice = device
    CallbackRegistry.Trigger("InputUtil.SetInputDevice", device)
end

function InputUtil.SetDisplayInputDevice(device)
    if device == InputUtil.ActiveDisplayInputDevice then
        return
    end
    InputUtil.ActiveDisplayInputDevice = device
    CallbackRegistry.Trigger("InputUtil.SetDisplayInputDevice", device)
end

function InputUtil.GetDefaultKeybind(action)
    return InputUtil.DefaultKeybindings[action] and InputUtil.DefaultKeybindings[action][InputUtil.GetInputDevice()]
end

function InputUtil.GetKeybind(action)
    return InputUtil.GetUserKeybind(action) or InputUtil.GetDefaultKeybind(action)
end

function InputUtil.ClearUserKeybinds()
    Config.DBGlobal:SetVariable("userKeybinds", {})
end

function InputUtil.GetUserKeybind(action)
    local userKeybinds = Config.DBGlobal:GetVariable("userKeybinds")
    return userKeybinds and userKeybinds[action] and userKeybinds[action][InputUtil.GetInputDevice()]
end

function InputUtil.SetUserKeybind(action, key)
    local userKeybinds = Config.DBGlobal:GetVariable("userKeybinds") or {}
    userKeybinds[action] = userKeybinds[action] or {}
    userKeybinds[action][InputUtil.GetInputDevice()] = key
    Config.DBGlobal:SetVariable("userKeybinds", userKeybinds)

    CallbackRegistry.Trigger("InputUtil.SetKeybind", action, key)
end


local f = CreateFrame("Frame")
f:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")
f:SetScript("OnEvent", function(self, event, isActive)
    InputUtil.SetInputDevice(isActive and InputUtil.Enum.InputDevices.GamePad or InputUtil.Enum.InputDevices.KBM)
end)
