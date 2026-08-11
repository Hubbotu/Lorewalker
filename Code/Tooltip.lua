local env = select(2, ...)
local Tooltip = env.modules:New("@\\Tooltip")

Tooltip.tooltips = {
    "GameTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "GarrisonFollowerTooltip"
}

function Tooltip.ModifyTooltip(tooltip)
    if not tooltip then return end
    tooltip:SetParent(LWParent)
    tooltip:SetFrameStrata("TOOLTIP")
end

function Tooltip.RestoreTooltip(tooltip)
    if not tooltip then return end
    tooltip:SetParent(UIParent)
    tooltip:SetFrameStrata("TOOLTIP")
end

function Tooltip.Modify()
    for _, tooltip in ipairs(Tooltip.tooltips) do
        Tooltip.ModifyTooltip(_G[tooltip])
    end
end

function Tooltip.Restore()
    for _, tooltip in ipairs(Tooltip.tooltips) do
        Tooltip.RestoreTooltip(_G[tooltip])
    end
end
