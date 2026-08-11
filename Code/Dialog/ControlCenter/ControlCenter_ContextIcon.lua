local env = select(2, ...)
local Path = env.modules:Import("packages\\path")
local UIKit = env.modules:Import("packages\\ui-kit")
local ControlCenter_Preload = env.modules:Import("@\\Dialog\\ControlCenter\\Preload")
local ControlCenter_ContextIcon = env.modules:New("@\\Dialog\\ControlCenter\\ContextIcon")

local band = bit.band

local PATH = Path.Root .. "\\Art\\Icons\\"
local QUEST_LABEL_PREPEND = Enum.GossipOptionRecFlags and Enum.GossipOptionRecFlags.QuestLabelPrepend

ControlCenter_ContextIcon.GossipIcon = 132053
ControlCenter_ContextIcon.TexDef = {
    AvailableCampaignQuest    = UIKit.Define.Texture{ path = PATH .. "AvailableCampaignQuest" },
    AvailableCallingQuest     = UIKit.Define.Texture{ path = PATH .. "AvailableCallingQuest" },
    AvailableImportantQuest   = UIKit.Define.Texture{ path = PATH .. "AvailableImportantQuest" },
    AvailableLegendaryQuest   = UIKit.Define.Texture{ path = PATH .. "AvailableLegendaryQuest" },
    AvailableMetaQuest        = UIKit.Define.Texture{ path = PATH .. "AvailableMetaQuest" },
    AvailableQuest            = UIKit.Define.Texture{ path = PATH .. "AvailableQuest" },
    AvailableRecurringQuest   = UIKit.Define.Texture{ path = PATH .. "AvailableRecurringQuest" },
    AvailableRepeatableQuest  = UIKit.Define.Texture{ path = PATH .. "AvailableRepeatableQuest" },
    AvailableWeeklyQuest      = UIKit.Define.Texture{ path = PATH .. "AvailableWeeklyQuest" },
    Blacksmith                = UIKit.Define.Texture{ path = PATH .. "Blacksmith" },
    CompleteCampaignQuest     = UIKit.Define.Texture{ path = PATH .. "CompleteCampaignQuest" },
    CompleteCallingQuest      = UIKit.Define.Texture{ path = PATH .. "CompleteCallingQuest" },
    CompleteImportantQuest    = UIKit.Define.Texture{ path = PATH .. "CompleteImportantQuest" },
    CompleteLegendaryQuest    = UIKit.Define.Texture{ path = PATH .. "CompleteLegendaryQuest" },
    CompleteMetaQuest         = UIKit.Define.Texture{ path = PATH .. "CompleteMetaQuest" },
    CompleteQuest             = UIKit.Define.Texture{ path = PATH .. "CompleteQuest" },
    CompleteRecurringQuest    = UIKit.Define.Texture{ path = PATH .. "CompleteRecurringQuest" },
    CompleteRepeatableQuest   = UIKit.Define.Texture{ path = PATH .. "CompleteRepeatableQuest" },
    CompleteWeeklyQuest       = UIKit.Define.Texture{ path = PATH .. "CompleteWeeklyQuest" },
    Copper                    = UIKit.Define.Texture{ path = PATH .. "Copper" },
    Directions                = UIKit.Define.Texture{ path = PATH .. "Directions" },
    Dungeon                   = UIKit.Define.Texture{ path = PATH .. "Dungeon" },
    Gold                      = UIKit.Define.Texture{ path = PATH .. "Gold" },
    Gossip                    = UIKit.Define.Texture{ path = PATH .. "Gossip" },
    GossipBlue                = UIKit.Define.Texture{ path = PATH .. "Gossip-Blue" },
    GossipDialog              = UIKit.Define.Texture{ path = PATH .. "Gossip-Dialog" },
    GossipQuest               = UIKit.Define.Texture{ path = PATH .. "Gossip-Quest" },
    GossipRed                 = UIKit.Define.Texture{ path = PATH .. "Gossip-Red" },
    Honor                     = UIKit.Define.Texture{ path = PATH .. "Honor" },
    IncompleteCampaignQuest   = UIKit.Define.Texture{ path = PATH .. "IncompleteCampaignQuest" },
    IncompleteCallingQuest    = UIKit.Define.Texture{ path = PATH .. "IncompleteCallingQuest" },
    IncompleteImportantQuest  = UIKit.Define.Texture{ path = PATH .. "IncompleteImportantQuest" },
    IncompleteLegendaryQuest  = UIKit.Define.Texture{ path = PATH .. "IncompleteLegendaryQuest" },
    IncompleteMetaQuest       = UIKit.Define.Texture{ path = PATH .. "IncompleteMetaQuest" },
    IncompleteQuest           = UIKit.Define.Texture{ path = PATH .. "IncompleteQuest" },
    IncompleteRecurringQuest  = UIKit.Define.Texture{ path = PATH .. "IncompleteRecurringQuest" },
    IncompleteRepeatableQuest = UIKit.Define.Texture{ path = PATH .. "IncompleteRepeatableQuest" },
    IncompleteWeeklyQuest     = UIKit.Define.Texture{ path = PATH .. "IncompleteWeeklyQuest" },
    Innkeeper                 = UIKit.Define.Texture{ path = PATH .. "Innkeeper" },
    Mail                      = UIKit.Define.Texture{ path = PATH .. "Mail" },
    Profession                = UIKit.Define.Texture{ path = PATH .. "Profession" },
    Raid                      = UIKit.Define.Texture{ path = PATH .. "Raid" },
    Repair                    = UIKit.Define.Texture{ path = PATH .. "Repair" },
    Silver                    = UIKit.Define.Texture{ path = PATH .. "Silver" },
    Taxi                      = UIKit.Define.Texture{ path = PATH .. "Taxi" },
    Transmog                  = UIKit.Define.Texture{ path = PATH .. "Transmog" },
    Vendor                    = UIKit.Define.Texture{ path = PATH .. "Vendor" },
    Warband                   = UIKit.Define.Texture{ path = PATH .. "Warband" },
    WarbandComplete           = UIKit.Define.Texture{ path = PATH .. "WarbandComplete" },
    XP                        = UIKit.Define.Texture{ path = PATH .. "XP" }
}

local QUEST_TITLE_TAG_ICON_LOOKUP = {
    [ControlCenter_Preload.Enum.QuestTag.Dungeon] = ControlCenter_ContextIcon.TexDef.Dungeon,
    [ControlCenter_Preload.Enum.QuestTag.Raid]    = ControlCenter_ContextIcon.TexDef.Raid,
    [ControlCenter_Preload.Enum.QuestTag.Raid10]  = ControlCenter_ContextIcon.TexDef.Raid,
    [ControlCenter_Preload.Enum.QuestTag.Raid25]  = ControlCenter_ContextIcon.TexDef.Raid
}
local QUEST_TITLE_TYPE_ICON_LOOKUP = {
    [ControlCenter_Preload.Enum.QuestType.Campaign]  = ControlCenter_ContextIcon.TexDef.AvailableCampaignQuest,
    [ControlCenter_Preload.Enum.QuestType.Calling]   = ControlCenter_ContextIcon.TexDef.AvailableCallingQuest,
    [ControlCenter_Preload.Enum.QuestType.Important] = ControlCenter_ContextIcon.TexDef.AvailableImportantQuest,
    [ControlCenter_Preload.Enum.QuestType.Legendary] = ControlCenter_ContextIcon.TexDef.AvailableLegendaryQuest,
    [ControlCenter_Preload.Enum.QuestType.Meta]      = ControlCenter_ContextIcon.TexDef.AvailableMetaQuest,
    [ControlCenter_Preload.Enum.QuestType.Recurring] = ControlCenter_ContextIcon.TexDef.AvailableRecurringQuest
}
local QUEST_TITLE_TYPE_TOOLTIP_LOOKUP = {
    [ControlCenter_Preload.Enum.QuestType.Campaign]  = QUEST_CLASSIFICATION_CAMPAIGN,
    [ControlCenter_Preload.Enum.QuestType.Calling]   = QUEST_CLASSIFICATION_CALLING,
    [ControlCenter_Preload.Enum.QuestType.Important] = QUEST_CLASSIFICATION_IMPORTANT,
    [ControlCenter_Preload.Enum.QuestType.Legendary] = QUEST_CLASSIFICATION_LEGENDARY,
    [ControlCenter_Preload.Enum.QuestType.Meta]      = QUEST_CLASSIFICATION_META,
    [ControlCenter_Preload.Enum.QuestType.Recurring] = QUEST_CLASSIFICATION_RECURRING
}
local QUEST_ICON_LOOKUP = {
    [ControlCenter_Preload.Enum.OptionType.QuestAvailable]  = {
        Normal     = PATH .. "AvailableQuest",
        Recurring  = PATH .. "AvailableRecurringQuest",
        Repeatable = PATH .. "AvailableRepeatableQuest",
        Daily      = PATH .. "AvailableRepeatableQuest",
        Weekly     = PATH .. "AvailableWeeklyQuest",
        Meta       = PATH .. "AvailableMetaQuest",
        Legendary  = PATH .. "AvailableLegendaryQuest",
        Campaign   = PATH .. "AvailableCampaignQuest",
        Important  = PATH .. "AvailableImportantQuest",
        Calling    = PATH .. "AvailableCallingQuest"
    },
    [ControlCenter_Preload.Enum.OptionType.QuestComplete]   = {
        Normal     = PATH .. "CompleteQuest",
        Recurring  = PATH .. "CompleteRecurringQuest",
        Repeatable = PATH .. "CompleteRepeatableQuest",
        Daily      = PATH .. "CompleteRepeatableQuest",
        Weekly     = PATH .. "CompleteWeeklyQuest",
        Meta       = PATH .. "CompleteMetaQuest",
        Legendary  = PATH .. "CompleteLegendaryQuest",
        Campaign   = PATH .. "CompleteCampaignQuest",
        Important  = PATH .. "CompleteImportantQuest",
        Calling    = PATH .. "CompleteCallingQuest"
    },
    [ControlCenter_Preload.Enum.OptionType.QuestIncomplete] = {
        Normal     = PATH .. "IncompleteQuest",
        Recurring  = PATH .. "IncompleteRecurringQuest",
        Repeatable = PATH .. "IncompleteRepeatableQuest",
        Daily      = PATH .. "IncompleteRepeatableQuest",
        Weekly     = PATH .. "IncompleteWeeklyQuest",
        Meta       = PATH .. "IncompleteMetaQuest",
        Legendary  = PATH .. "IncompleteLegendaryQuest",
        Campaign   = PATH .. "IncompleteCampaignQuest",
        Important  = PATH .. "IncompleteImportantQuest",
        Calling    = PATH .. "IncompleteCallingQuest"
    }
}
local ALERT_ICON_LOOKUP = {
    [ControlCenter_Preload.Enum.OptionAlertType.Red]  = PATH .. "Gossip-Red",
    [ControlCenter_Preload.Enum.OptionAlertType.Blue] = PATH .. "Gossip-Blue"
}
local ICON_REPLACEMENT_LOOKUP = { [ControlCenter_ContextIcon.GossipIcon] = PATH .. "Gossip" }


function ControlCenter_ContextIcon.GetContextIconForQuestTitle(questTagID, questTagName, questType, questTimeLeft)
    local tagIcon = QUEST_TITLE_TAG_ICON_LOOKUP[questTagID]
    if tagIcon then return tagIcon, questTagName end

    local typeIcon = QUEST_TITLE_TYPE_ICON_LOOKUP[questType]
    if not typeIcon then return end

    local tooltipBody = nil
    if questType == ControlCenter_Preload.Enum.QuestType.Recurring and questTimeLeft then tooltipBody = BONUS_OBJECTIVE_TIME_LEFT:format(QuestTimeRemainingFormatter:Format(questTimeLeft)) end

    return typeIcon, QUEST_TITLE_TYPE_TOOLTIP_LOOKUP[questType], tooltipBody
end

function ControlCenter_ContextIcon.GetContextIconForGossipOption(info)
    local optType = info.optionType

    if optType == ControlCenter_Preload.Enum.OptionType.Gossip then
        local flag = info.optionFlag or 0
        if QUEST_LABEL_PREPEND and band(flag, QUEST_LABEL_PREPEND) == QUEST_LABEL_PREPEND then
            return PATH .. "Gossip-Quest"
        end
        return ALERT_ICON_LOOKUP[info.alertType] or ICON_REPLACEMENT_LOOKUP[info.icon] or info.icon
    end

    local iconMap = QUEST_ICON_LOOKUP[optType]
    if iconMap and info.questInfo then
        return iconMap[info.questInfo.questType] or iconMap.Normal
    end
end
