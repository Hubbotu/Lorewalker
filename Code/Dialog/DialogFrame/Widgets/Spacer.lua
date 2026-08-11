local env = select(2, ...)
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame = unpack(UIKit.UI.Frames)
local Spacer = env.modules:New("@\\Dialog\\DialogFrame\\Widgets\\Spacer")

do -- Spacer
    Spacer.New = UIKit.Template(function(id, name, children, ...)
        return Frame(name)
            :size(UIKit.UI.P_FILL, 2)
    end)
end
