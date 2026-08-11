local env = select(2, ...)
local Enum = env.Enum
local Modes_ModeHandler = env.modules:Import("@\\Dialog\\Modes\\ModeHandler")
local StoryMode = env.modules:New("@\\Dialog\\Modes\\StoryMode")


StoryMode.isActive = false


function StoryMode.Activate()
    StoryMode.isActive = true
    LWDialogFrame:SetDefaultTextShown(false)
    LWDialogFrame:Close()
end

function StoryMode.Deactivate()
    StoryMode.isActive = false
    LWDialogFrame:Close()
end


Modes_ModeHandler.RegisterMode(Enum.Mode.Story, StoryMode)
