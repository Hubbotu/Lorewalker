local env = select(2, ...)
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local StaticPopup = env.modules:New("@\\StaticPopup")

StaticPopup.popups = {
    "StaticPopup1", "StaticPopup2"
}

function StaticPopup.ModifyPopup(popup)
    popup:SetParent(LWParent)
end

function StaticPopup.RestorePopup(popup)
    popup:SetParent(UIParent)
end

function StaticPopup.Modify()
    for _, popup in ipairs(StaticPopup.popups) do
        StaticPopup.ModifyPopup(_G[popup])
    end
end

function StaticPopup.Restore()
    for _, popup in ipairs(StaticPopup.popups) do
        StaticPopup.RestorePopup(_G[popup])
    end
end

CallbackRegistry.Add("GOSSIP_CONFIRM", StaticPopup.Modify)
CallbackRegistry.Add("GOSSIP_CONFIRM_CANCEL", StaticPopup.Restore)
CallbackRegistry.Add("ControlCenter.SessionEnd", StaticPopup.Restore)
