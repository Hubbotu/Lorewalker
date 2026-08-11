local env = select(2, ...)
local ControlCenter_OptionFlags = env.modules:New("@\\Dialog\\ControlCenter\\OptionFlags")

local band = bit.band

function ControlCenter_OptionFlags.IsSet(bitMask, flagOrMask)
    return band(bitMask, flagOrMask) == flagOrMask
end

function ControlCenter_OptionFlags.IsAnySet(bitMask, mask)
    return band(bitMask, mask) ~= 0
end
