local env = select(2, ...)
local L = env.L
local ControlCenter_Preload = env.modules:Import("@\\Dialog\\ControlCenter\\Preload")
local ControlCenter_Formatting = env.modules:New("@\\Dialog\\ControlCenter\\Formatting")

local format, gsub, find = string.format, string.gsub, string.find
local band = bit.band

local PLAY_MOVIE_LABEL_PREPEND = Enum.GossipOptionRecFlags and Enum.GossipOptionRecFlags.PlayMovieLabelPrepend
local MOVIE_PREFIX = PLAY_MOVIE_PREPEND and "|cFF002AC1" .. PLAY_MOVIE_PREPEND .. "|r "
local COLOR_MAP = {
    ["|cFFFF0000"]        = "|cFFB20300",
    ["|cnRED_FONT_COLOR"] = "|cFFB20300",
    ["|cFF00BFF3"]        = "|cFF002AC1"
}

local function ApplyColorReplacements(text)
    for alertColor, replaceColor in pairs(COLOR_MAP) do
        text = gsub(text, alertColor, replaceColor)
    end
    return text
end

function ControlCenter_Formatting.GetOptionAlertTypeFromText(text)
    if find(text, "|cFFFF0000") or find(text, "|cnRED_FONT_COLOR") then
        return ControlCenter_Preload.Enum.OptionAlertType.Red
    elseif find(text, "|cFF00BFF3") then
        return ControlCenter_Preload.Enum.OptionAlertType.Blue
    end

    return nil
end

function ControlCenter_Formatting.FormatOption(text, flag)
    text = ApplyColorReplacements(text)

    if MOVIE_PREFIX and PLAY_MOVIE_LABEL_PREPEND and band(flag or 0, PLAY_MOVIE_LABEL_PREPEND) == PLAY_MOVIE_LABEL_PREPEND then
        text = MOVIE_PREFIX .. text
    end

    return text
end

function ControlCenter_Formatting.FormatQuestOption(text, isTrivial)
    return isTrivial and format(TRIVIAL_QUEST_DISPLAY, text) or text
end
