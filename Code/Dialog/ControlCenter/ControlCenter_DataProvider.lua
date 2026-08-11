local env = select(2, ...)
local Struct = env.modules:Import("packages\\struct")
local Pool = env.modules:Import("packages\\pool")
local WoWClient = env.modules:Import("packages\\wow-client")
local ControlCenter_Preload = env.modules:Import("@\\Dialog\\ControlCenter\\Preload")
local ControlCenter_ContextIcon = env.modules:Await("@\\Dialog\\ControlCenter\\ContextIcon")
local ControlCenter_Formatting = env.modules:Await("@\\Dialog\\ControlCenter\\Formatting")
local ControlCenter_DataProvider = env.modules:New("@\\Dialog\\ControlCenter\\DataProvider")
local ControlCenter = env.modules:Await("@\\Dialog\\ControlCenter")

local function Nil() return nil end
local function False() return false end
local function Zero() return 0 end

local GetQuestID = GetQuestID or Zero
local GetTitleForQuestID = C_QuestLog and (C_QuestLog.GetTitleForQuestID or C_QuestLog.GetQuestInfo) or Nil
local GetQuestText = GetQuestText or Nil
local GetProgressText = GetProgressText or Nil
local GetRewardText = GetRewardText or Nil
local GetObjectiveText = GetObjectiveText or Nil
local GetCriteriaSpell = GetCriteriaSpell or Nil
local GetQuestObjectivesByQuestID = (C_QuestLog and C_QuestLog.GetQuestObjectives) or GetQuestObjectives or Nil
local GetQuestTagInfoByQuestID = (C_QuestLog and C_QuestLog.GetQuestTagInfo) or GetQuestTagInfo or Nil
local GetQuestResetTime = GetQuestResetTime or Nil
local GetQuestTimeLeftSeconds = (C_TaskQuest and C_TaskQuest.GetQuestTimeLeftSeconds) or Nil
local IsQuestCompleteByQuestID = (C_QuestLog and C_QuestLog.IsComplete) or IsQuestComplete or False
local IsQuestFailedByQuestID = (C_QuestLog and (C_QuestLog.IsFailed or C_QuestLog.IsQuestFailed)) or False
local IsQuestTrivialByQuestID = (C_QuestLog and C_QuestLog.IsQuestTrivial) or False
local IsQuestRepeatableByQuestID = (C_QuestLog and C_QuestLog.IsRepeatableQuest) or False
local IsQuestImportantByQuestID = (C_QuestLog and C_QuestLog.IsImportantQuest) or False
local GetQuestClassificationByQuestID = (C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification) or Nil
local GetQuestLogIndexByQuestID = (C_QuestLog and C_QuestLog.GetLogIndexForQuestID) or GetQuestLogIndexByID or Zero
local GetQuestLogInfoByIndex = (C_QuestLog and C_QuestLog.GetInfo) or Nil
local GetQuestLogTitleByIndex = GetQuestLogTitle or Nil
local IsQuestFlaggedCompletedOnAccount = (C_QuestLog and C_QuestLog.IsQuestFlaggedCompletedOnAccount) or False
local QuestGetAutoAccept = QuestGetAutoAccept or False
local HasQuestSessionBonus = (C_QuestLog and C_QuestLog.QuestHasQuestSessionBonus) or False
local CanQuestHaveWarModeBonus = (C_QuestLog and C_QuestLog.QuestCanHaveWarModeBonus) or False
local IsAccountQuestByQuestID = (C_QuestLog and C_QuestLog.IsAccountQuest) or False
local GetCampaignIDByQuestID = (C_CampaignInfo and C_CampaignInfo.GetCampaignID) or Nil
local GetRewardXP = GetRewardXP or Nil
local GetRewardHonor = GetRewardHonor or Nil
local GetRewardMoney = GetRewardMoney or Nil
local GetRewardArtifactXP = GetRewardArtifactXP or Nil
local GetRewardSkillPoints = GetRewardSkillPoints or Nil
local GetNumQuestRewards = GetNumQuestRewards or Zero
local GetNumQuestChoices = GetNumQuestChoices or Zero
local GetNumQuestItems = GetNumQuestItems or Zero
local GetQuestItemInfo = GetQuestItemInfo or Nil
local GetQuestRewardSpellIDs = (C_QuestInfoSystem and C_QuestInfoSystem.GetQuestRewardSpells) or Nil
local GetQuestRewardCurrenciesByQuestID = (C_QuestInfoSystem and C_QuestInfoSystem.GetQuestRewardCurrencies) or Nil
local GetQuestRewardSpellInfo = (C_QuestInfoSystem and C_QuestInfoSystem.GetQuestRewardSpellInfo) or Nil
local GetNumQuestLogRewardCurrencies = GetNumQuestLogRewardCurrencies or Zero
local GetQuestLogRewardCurrencyInfo = GetQuestLogRewardCurrencyInfo or Nil
local GetQuestItemInfoLootType = GetQuestItemInfoLootType or Zero
local GetQuestOfferRewardCurrencyInfo = (C_QuestOffer and C_QuestOffer.GetQuestRewardCurrencyInfo) or Nil
local GetQuestOfferMajorFactionReputationRewards = (C_QuestOffer and C_QuestOffer.GetQuestOfferMajorFactionReputationRewards) or Nil
local GetGreetingText = GetGreetingText or Nil
local GetGossipText = (C_GossipInfo and C_GossipInfo.GetText) or GetGossipText or Nil
local GetCurrencyContainerInfo = (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyContainerInfo) or Nil
local GetGossipOptions = (C_GossipInfo and C_GossipInfo.GetOptions) or Nil
local GetGossipAvailableQuests = (C_GossipInfo and C_GossipInfo.GetAvailableQuests) or Nil
local GetGossipActiveQuests = (C_GossipInfo and C_GossipInfo.GetActiveQuests) or Nil
local GetAvailableTitle = GetAvailableTitle or Nil
local GetAvailableLevel = GetAvailableLevel or Nil
local GetAvailableQuestInfoByIndex = GetAvailableQuestInfo
local GetActiveTitle = GetActiveTitle or Nil
local GetActiveQuestID = GetActiveQuestID or Zero
local GetActiveLevel = GetActiveLevel or Nil
local GetNumAvailableQuests = GetNumAvailableQuests or Zero
local GetNumActiveQuests = GetNumActiveQuests or Zero
local GetQuestDetailsTheme = (C_QuestLog and C_QuestLog.GetQuestDetailsTheme) or Nil
local IsInteractingWithNpcOfType = (C_PlayerInteractionManager and C_PlayerInteractionManager.IsInteractingWithNpcOfType) or False
local IsActiveQuestTrivial = IsActiveQuestTrivial or False
local IsActiveQuestLegendary = IsActiveQuestLegendary or False
local IsCurrentQuestFailed = IsCurrentQuestFailed or False
local UnitClass = UnitClass
local UnitExists = UnitExists
local ipairs = ipairs
local pairs = pairs
local wipe = table.wipe
local tsort = table.sort

local TYPE_GOSSIP = Enum.PlayerInteractionType and Enum.PlayerInteractionType.Gossip
local TYPE_QUEST_GIVER = Enum.PlayerInteractionType and Enum.PlayerInteractionType.QuestGiver
local SCOUTING_MAP = ADVENTURE_MAP_TITLE or "Scouting Map"
local EMPTY_TABLE = {}
local QUEST_TAG_TO_TYPE_LOOKUP = {
    [ControlCenter_Preload.Enum.QuestTag.Group]        = ControlCenter_Preload.Enum.QuestType.Group,
    [ControlCenter_Preload.Enum.QuestTag.Dungeon]      = ControlCenter_Preload.Enum.QuestType.Dungeon,
    [ControlCenter_Preload.Enum.QuestTag.Heroic]       = ControlCenter_Preload.Enum.QuestType.Heroic,
    [ControlCenter_Preload.Enum.QuestTag.Raid]         = ControlCenter_Preload.Enum.QuestType.Raid,
    [ControlCenter_Preload.Enum.QuestTag.Raid10]       = ControlCenter_Preload.Enum.QuestType.Raid,
    [ControlCenter_Preload.Enum.QuestTag.Raid25]       = ControlCenter_Preload.Enum.QuestType.Raid,
    [ControlCenter_Preload.Enum.QuestTag.Pvp]          = ControlCenter_Preload.Enum.QuestType.Pvp,
    [ControlCenter_Preload.Enum.QuestTag.MetaQuest]    = ControlCenter_Preload.Enum.QuestType.Meta,
    [ControlCenter_Preload.Enum.QuestTag.Legendary]    = ControlCenter_Preload.Enum.QuestType.Legendary,
    [ControlCenter_Preload.Enum.QuestTag.Important]    = ControlCenter_Preload.Enum.QuestType.Important,
    [ControlCenter_Preload.Enum.QuestTag.CallingQuest] = ControlCenter_Preload.Enum.QuestType.Calling
}
local QUEST_CLASSIFICATION_TO_TYPE_LOOKUP = {}
if Enum.QuestClassification then
    QUEST_CLASSIFICATION_TO_TYPE_LOOKUP[Enum.QuestClassification.Campaign] = ControlCenter_Preload.Enum.QuestType.Campaign
    QUEST_CLASSIFICATION_TO_TYPE_LOOKUP[Enum.QuestClassification.Important] = ControlCenter_Preload.Enum.QuestType.Important
    QUEST_CLASSIFICATION_TO_TYPE_LOOKUP[Enum.QuestClassification.Legendary] = ControlCenter_Preload.Enum.QuestType.Legendary
    QUEST_CLASSIFICATION_TO_TYPE_LOOKUP[Enum.QuestClassification.Meta] = ControlCenter_Preload.Enum.QuestType.Meta
    QUEST_CLASSIFICATION_TO_TYPE_LOOKUP[Enum.QuestClassification.Normal] = ControlCenter_Preload.Enum.QuestType.Normal
    QUEST_CLASSIFICATION_TO_TYPE_LOOKUP[Enum.QuestClassification.Recurring] = ControlCenter_Preload.Enum.QuestType.Recurring
    QUEST_CLASSIFICATION_TO_TYPE_LOOKUP[Enum.QuestClassification.Calling] = ControlCenter_Preload.Enum.QuestType.Calling
end
local QUEST_OPTION_FREQUENCY_TO_TYPE_LOOKUP = {
    [LE_QUEST_FREQUENCY_DAILY or 2]  = ControlCenter_Preload.Enum.QuestType.Daily,
    [LE_QUEST_FREQUENCY_WEEKLY or 3] = ControlCenter_Preload.Enum.QuestType.Weekly
}
local QUEST_LOG_FREQUENCY_TO_TYPE_LOOKUP = {}
if Enum.QuestFrequency then
    QUEST_LOG_FREQUENCY_TO_TYPE_LOOKUP[Enum.QuestFrequency.Daily] = ControlCenter_Preload.Enum.QuestType.Daily
    QUEST_LOG_FREQUENCY_TO_TYPE_LOOKUP[Enum.QuestFrequency.Weekly] = ControlCenter_Preload.Enum.QuestType.Weekly
    if Enum.QuestFrequency.ResetByScheduler then
        QUEST_LOG_FREQUENCY_TO_TYPE_LOOKUP[Enum.QuestFrequency.ResetByScheduler] = ControlCenter_Preload.Enum.QuestType.Recurring
    end
end


local function WipeStruct(_, object)
    Struct.Wipe(object)
end

local Pools = {
    item     = Pool.New(function() return ControlCenter_Preload.QuestRewardInfo.ItemInfo{} end, WipeStruct),
    spell    = Pool.New(function() return ControlCenter_Preload.QuestRewardInfo.SpellInfo{} end, WipeStruct),
    currency = Pool.New(function() return ControlCenter_Preload.QuestRewardInfo.CurrencyInfo{} end, WipeStruct),
    option   = Pool.New(function() return ControlCenter_Preload.SessionInfo.OptionInfo{} end, WipeStruct),
    quest    = Pool.New(function() return ControlCenter_Preload.SessionInfo.QuestInfo{} end, WipeStruct),
    result   = Pool.New(function() return {} end, function(_, object) wipe(object) end)
}

function ControlCenter_DataProvider.ReleaseAllPools()
    for _, pool in pairs(Pools) do
        pool:ReleaseAll()
    end
end

local function AppendResults(target, source)
    for index = 1, #source do
        target[#target + 1] = source[index]
    end
end

local function GetQuestCompletionState(questID, isComplete)
    return isComplete == true or isComplete == 1 or IsQuestCompleteByQuestID(questID) or false
end

local function GetQuestTrivialState(questID, isTrivial)
    return isTrivial or IsQuestTrivialByQuestID(questID) or false
end

local function GetQuestLogFrequencyType(questID)
    local questLogIndex = GetQuestLogIndexByQuestID(questID)
    if not questLogIndex or questLogIndex <= 0 then return end

    local questLogInfo = GetQuestLogInfoByIndex(questLogIndex)
    if questLogInfo then return QUEST_LOG_FREQUENCY_TO_TYPE_LOOKUP[questLogInfo.frequency] end

    local frequency = select(7, GetQuestLogTitleByIndex(questLogIndex))
    return QUEST_OPTION_FREQUENCY_TO_TYPE_LOOKUP[frequency]
end

local function GetQuestFailedState(questID)
    if IsQuestFailedByQuestID(questID) then return true end

    local questLogIndex = GetQuestLogIndexByQuestID(questID)
    if not questLogIndex or questLogIndex <= 0 then return false end

    return select(6, GetQuestLogTitleByIndex(questLogIndex)) == -1
end

local function ShouldIncludeQuest(optionType, isComplete)
    if optionType == ControlCenter_Preload.Enum.OptionType.QuestAvailable then return true end

    return isComplete == (optionType == ControlCenter_Preload.Enum.OptionType.QuestComplete)
end

local function CreateQuestOption(optionType, optionKey, questInfo)
    local optionInfo = Pools.option:Acquire()
    optionInfo.optionType = optionType
    optionInfo.optionKey = optionKey
    optionInfo.questInfo = questInfo
    optionInfo.name = ControlCenter_Formatting.FormatQuestOption(questInfo.questName, questInfo.questIsTrivial)
    optionInfo.contextIcon = ControlCenter_ContextIcon.GetContextIconForGossipOption(optionInfo)
    return optionInfo
end

local function BuildPartialQuestInfo(questID, questName, isTrivial, isComplete, frequency, isRepeatable, isLegendary, isImportant)
    questID = questID or 0

    local questInfo = Pools.quest:Acquire()
    local questTagInfo = GetQuestTagInfoByQuestID(questID)

    questInfo.questID = questID
    questInfo.questName = questName or GetTitleForQuestID(questID) or ""
    questInfo.questType = ControlCenter_DataProvider.GetQuestType(questID, questTagInfo, frequency, isRepeatable, isLegendary, isImportant)
    questInfo.questTagID = questTagInfo and questTagInfo.tagID
    questInfo.questTagName = questTagInfo and questTagInfo.tagName
    questInfo.questCampaignID = GetCampaignIDByQuestID(questID)
    questInfo.questIsComplete = GetQuestCompletionState(questID, isComplete)
    questInfo.questIsCompleteWarband = IsQuestFlaggedCompletedOnAccount(questID)
    questInfo.questIsTrivial = GetQuestTrivialState(questID, isTrivial)
    questInfo.questIsAccount = IsAccountQuestByQuestID(questID)
    questInfo.questIsPartySync = HasQuestSessionBonus(questID)
    questInfo.questIsFailed = GetQuestFailedState(questID)
    questInfo.questObjectives = GetQuestObjectivesByQuestID(questID)
    questInfo.questTimeLeft = GetQuestTimeLeftSeconds(questID)
    questInfo.questRewardWarModeBonus = CanQuestHaveWarModeBonus(questID)

    return questInfo
end


do --Player Interaction
    function ControlCenter_DataProvider.GetInteractUnitID()
        return UnitExists("questnpc") and "questnpc" or "npc"
    end

    function ControlCenter_DataProvider.IsInteractingWithNpc()
        return IsInteractingWithNpcOfType(TYPE_GOSSIP) or IsInteractingWithNpcOfType(TYPE_QUEST_GIVER)
    end

    function ControlCenter_DataProvider.IsInteractingWithGossipNpc()
        return IsInteractingWithNpcOfType(TYPE_GOSSIP)
    end

    function ControlCenter_DataProvider.IsInteractingWithQuestNpc()
        return IsInteractingWithNpcOfType(TYPE_QUEST_GIVER)
    end

    function ControlCenter_DataProvider.IsInteractingWithScoutingMap()
        return UnitClass("npc") == SCOUTING_MAP
    end

    function ControlCenter_DataProvider.IsInteractingWithGameObject()
        return not UnitExists("npc") and not UnitExists("questnpc")
    end
end

do --Helpers
    function ControlCenter_DataProvider.GetQuestType(questID, tagInfo, frequency, isRepeatable, isLegendary, isImportant)
        local questType = QUEST_CLASSIFICATION_TO_TYPE_LOOKUP[GetQuestClassificationByQuestID(questID)]
        if questType then
            return questType
        end

        if isLegendary then
            return ControlCenter_Preload.Enum.QuestType.Legendary
        end

        if isImportant or IsQuestImportantByQuestID(questID) then
            return ControlCenter_Preload.Enum.QuestType.Important
        end

        local tagID = tagInfo and tagInfo.tagID
        questType = QUEST_TAG_TO_TYPE_LOOKUP[tagID] or QUEST_OPTION_FREQUENCY_TO_TYPE_LOOKUP[frequency] or GetQuestLogFrequencyType(questID)
        if questType then
            return questType
        end

        if isRepeatable or IsQuestRepeatableByQuestID(questID) then
            return ControlCenter_Preload.Enum.QuestType.Repeatable
        end

        return ControlCenter_Preload.Enum.QuestType.Normal
    end

    function ControlCenter_DataProvider.GetAvailableQuestInfo(index)
        local title = GetAvailableTitle(index) or ""
        local level = GetAvailableLevel(index) or -1

        if not GetAvailableQuestInfoByIndex then
            return title, level, false, 1, false, false, 0, false
        end

        return title, level, GetAvailableQuestInfoByIndex(index)
    end

    function ControlCenter_DataProvider.GetActiveQuestInfo(index)
        local title, isComplete = GetActiveTitle(index)
        return title or "", GetActiveLevel(index) or -1, IsActiveQuestTrivial(index) or false, isComplete, IsActiveQuestLegendary(index) or false, GetActiveQuestID(index) or 0
    end
end

do --Fetchers
    local function CreateItemInfo(questRewardType, index)
        local name, texture, count, quality, isUsable, itemID, flags = GetQuestItemInfo(questRewardType, index)
        local itemInfo = Pools.item:Acquire()
        itemInfo.rewardID = itemID
        itemInfo.name = name
        itemInfo.texture = texture
        itemInfo.count = count
        itemInfo.quality = quality
        itemInfo.isUsable = isUsable
        itemInfo.lootType = GetQuestItemInfoLootType(questRewardType, index)
        itemInfo.questRewardContextFlags = flags
        itemInfo.questRewardType = questRewardType
        itemInfo.questRewardIndex = index
        return itemInfo
    end

    local function CreateCurrencyInfo(questRewardType, index, currencyData, poolType)
        if not currencyData then
            return nil
        end

        local currencyInfo = Pools.currency:Acquire()
        currencyInfo.rewardID = currencyData.currencyID
        currencyInfo.name = currencyData.name
        currencyInfo.texture = currencyData.texture
        currencyInfo.quality = currencyData.quality
        currencyInfo.baseRewardAmount = currencyData.baseRewardAmount
        currencyInfo.bonusRewardAmount = currencyData.bonusRewardAmount
        currencyInfo.totalRewardAmount = currencyData.totalRewardAmount
        currencyInfo.questRewardContextFlags = currencyData.questRewardContextFlags
        currencyInfo.containerInfo = GetCurrencyContainerInfo(currencyData.currencyID, currencyData.totalRewardAmount)
        currencyInfo.questRewardType = questRewardType
        currencyInfo.questRewardIndex = index
        if poolType then
            currencyInfo.uk_poolElementType = poolType
        end
        return currencyInfo
    end

    function ControlCenter_DataProvider.FetchItemInfo(questRewardType, num)
        local result = Pools.result:Acquire()

        for index = 1, num or 0 do
            result[index] = CreateItemInfo(questRewardType, index)
        end

        return result
    end

    function ControlCenter_DataProvider.FetchChoiceInfo(num)
        local result = Pools.result:Acquire()

        for index = 1, num or 0 do
            local lootType = GetQuestItemInfoLootType("choice", index)
            if WoWClient.IS_RETAIL and lootType == ControlCenter_Preload.Enum.LootType.Currency then
                --mirrors Blizzard QuestInfo_ShowRewards, where choice rewards can be currencies
                result[index] = CreateCurrencyInfo("choice", index, GetQuestOfferRewardCurrencyInfo("choice", index), "Currency") or CreateItemInfo("choice", index)
            else
                result[index] = CreateItemInfo("choice", index)
            end
        end

        return result
    end

    function ControlCenter_DataProvider.FetchSpells(questRewardType, questID, spellIDList)
        local result = Pools.result:Acquire()

        for index, spellID in ipairs(spellIDList or EMPTY_TABLE) do
            local spellData = GetQuestRewardSpellInfo(questID, spellID)
            if spellData then
                local spellInfo = Pools.spell:Acquire()
                spellInfo.rewardID = spellID
                spellInfo.name = spellData.name
                spellInfo.texture = spellData.texture
                spellInfo.garrFollowerID = spellData.garrFollowerID
                spellInfo.isTradeskill = spellData.isTradeskill
                spellInfo.isSpellLearned = spellData.isSpellLearned
                spellInfo.hideSpellLearnText = spellData.hideSpellLearnText
                spellInfo.isBoostSpell = spellData.isBoostSpell
                spellInfo.genericUnlock = spellData.genericUnlock
                spellInfo.spellType = spellData.type
                spellInfo.questRewardType = questRewardType
                spellInfo.questRewardIndex = index
                result[#result + 1] = spellInfo
            end
        end

        return result
    end

    function ControlCenter_DataProvider.FetchCurrencies(questID)
        local result = Pools.result:Acquire()

        if WoWClient.IS_CLASSIC_ALL then
            for index = 1, GetNumQuestLogRewardCurrencies(questID) do
                local name, texture, amount, currencyID, quality = GetQuestLogRewardCurrencyInfo(index, questID)
                local currencyInfo = Pools.currency:Acquire()
                currencyInfo.rewardID = currencyID
                currencyInfo.name = name
                currencyInfo.texture = texture
                currencyInfo.quality = quality
                currencyInfo.baseRewardAmount = amount
                currencyInfo.totalRewardAmount = amount
                currencyInfo.containerInfo = GetCurrencyContainerInfo(currencyID, amount)
                currencyInfo.questRewardType = "reward"
                currencyInfo.questRewardIndex = index
                result[#result + 1] = currencyInfo
            end
        elseif WoWClient.IS_RETAIL then
            for index, currencyData in ipairs(GetQuestRewardCurrenciesByQuestID(questID) or EMPTY_TABLE) do
                result[#result + 1] = CreateCurrencyInfo("reward", index, currencyData)
            end
        end

        return result
    end

    function ControlCenter_DataProvider.FetchGossipOptions(gossipOptions)
        local result = Pools.result:Acquire()

        for _, gossipOption in ipairs(gossipOptions or EMPTY_TABLE) do
            local optionName = gossipOption.name or ""
            local optionInfo = Pools.option:Acquire()
            optionInfo.name = ControlCenter_Formatting.FormatOption(optionName, gossipOption.flags)
            optionInfo.icon = gossipOption.icon
            optionInfo.optionFlag = gossipOption.flags
            optionInfo.optionType = ControlCenter_Preload.Enum.OptionType.Gossip
            optionInfo.optionKey = gossipOption.orderIndex
            optionInfo.optionSelectWhenOnlyOption = gossipOption.selectOptionWhenOnlyOption
            optionInfo.alertType = ControlCenter_Formatting.GetOptionAlertTypeFromText(optionName)
            optionInfo.contextIcon = ControlCenter_ContextIcon.GetContextIconForGossipOption(optionInfo)
            result[#result + 1] = optionInfo
        end

        return result
    end

    function ControlCenter_DataProvider.FetchGossipQuests(optionType, questData)
        local result = Pools.result:Acquire()

        for _, gossipData in ipairs(questData or EMPTY_TABLE) do
            local questInfo = ControlCenter_DataProvider.BuildPartialQuestInfoFromGossipOption(gossipData)
            if questInfo and ShouldIncludeQuest(optionType, questInfo.questIsComplete) then
                result[#result + 1] = CreateQuestOption(optionType, questInfo.questID, questInfo)
            end
        end

        return result
    end

    function ControlCenter_DataProvider.FetchGreetingAvailableQuests(num)
        local result = Pools.result:Acquire()

        for index = 1, num or 0 do
            local title, level, isTrivial, frequency, isRepeatable, isLegendary, questID, isImportant = ControlCenter_DataProvider.GetAvailableQuestInfo(index)
            local questInfo = ControlCenter_DataProvider.BuildPartialQuestInfoFromGreetingOption(title, level, questID, isTrivial, false, isLegendary, frequency, isRepeatable, isImportant)
            result[#result + 1] = CreateQuestOption(ControlCenter_Preload.Enum.OptionType.QuestAvailable, index, questInfo)
        end

        return result
    end

    function ControlCenter_DataProvider.FetchGreetingActiveQuests(optionType, num)
        local result = Pools.result:Acquire()

        for index = 1, num or 0 do
            local title, level, isTrivial, isComplete, isLegendary, questID = ControlCenter_DataProvider.GetActiveQuestInfo(index)
            local questInfo = ControlCenter_DataProvider.BuildPartialQuestInfoFromGreetingOption(title, level, questID, isTrivial, isComplete, isLegendary)
            if ShouldIncludeQuest(optionType, questInfo.questIsComplete) then
                result[#result + 1] = CreateQuestOption(optionType, index, questInfo)
            end
        end

        return result
    end
end

do --Quest Info
    local QuestInfoBuffer = ControlCenter_Preload.SessionInfo.QuestInfo{}
    local SkillInfoBuffer = ControlCenter_Preload.QuestRewardInfo.SkillInfo{}
    local SpellObjectiveInfoBuffer = ControlCenter_Preload.QuestRewardInfo.SpellInfo{}
    local QuestLoreSources = { GetGreetingText, GetQuestText, GetProgressText, GetRewardText }

    local function GetQuestLore()
        for _, func in ipairs(QuestLoreSources) do
            local text = func()
            if text and #text > 1 then
                return text
            end
        end
        return ""
    end

    function ControlCenter_DataProvider.BuildFullQuestInfoFromCurrentQuest()
        local questID = GetQuestID()
        local questTagInfo = GetQuestTagInfoByQuestID(questID)
        local questRewardNumChoice = GetNumQuestChoices()
        local questRewardNumReceive = GetNumQuestRewards()
        local questRewardNumRequired = GetNumQuestItems()
        local questRewardChoices = ControlCenter_DataProvider.FetchChoiceInfo(questRewardNumChoice)
        local questRewardReceive = ControlCenter_DataProvider.FetchItemInfo("reward", questRewardNumReceive)
        local questRequired = ControlCenter_DataProvider.FetchItemInfo("required", questRewardNumRequired)
        local questRewardSpells = ControlCenter_DataProvider.FetchSpells("reward", questID, GetQuestRewardSpellIDs(questID))
        local questRewardCurrencies = ControlCenter_DataProvider.FetchCurrencies(questID)
        local objectiveSpellID, objectiveSpellName, objectiveSpellTexture = GetCriteriaSpell()
        local questSkillName, questSkillIcon, questSkillPoints = GetRewardSkillPoints()
        local questRewardArtifactXP, questRewardArtifactCategory = GetRewardArtifactXP()

        Struct.Wipe(SpellObjectiveInfoBuffer)
        SpellObjectiveInfoBuffer.rewardID = objectiveSpellID
        SpellObjectiveInfoBuffer.name = objectiveSpellName
        SpellObjectiveInfoBuffer.texture = objectiveSpellTexture

        Struct.Wipe(SkillInfoBuffer)
        SkillInfoBuffer.name = questSkillName
        SkillInfoBuffer.texture = questSkillIcon
        SkillInfoBuffer.points = questSkillPoints

        Struct.Wipe(QuestInfoBuffer)
        QuestInfoBuffer.questLore = GetQuestLore()
        QuestInfoBuffer.questName = GetTitleForQuestID(questID) or ""
        QuestInfoBuffer.questType = ControlCenter_DataProvider.GetQuestType(questID, questTagInfo)
        QuestInfoBuffer.questTagID = questTagInfo and questTagInfo.tagID
        QuestInfoBuffer.questTagName = questTagInfo and questTagInfo.tagName
        QuestInfoBuffer.questID = questID
        QuestInfoBuffer.questCampaignID = GetCampaignIDByQuestID(questID)
        QuestInfoBuffer.questIsComplete = GetQuestCompletionState(questID)
        QuestInfoBuffer.questIsCompleteWarband = IsQuestFlaggedCompletedOnAccount(questID)
        QuestInfoBuffer.questIsTrivial = GetQuestTrivialState(questID)
        QuestInfoBuffer.questIsAccount = IsAccountQuestByQuestID(questID)
        QuestInfoBuffer.questIsAutoAccept = QuestGetAutoAccept()
        QuestInfoBuffer.questIsPartySync = HasQuestSessionBonus(questID)
        QuestInfoBuffer.questIsFailed = GetQuestFailedState(questID) or IsCurrentQuestFailed()
        QuestInfoBuffer.questObjectives = GetQuestObjectivesByQuestID(questID)
        QuestInfoBuffer.questObjectiveText = GetObjectiveText()
        QuestInfoBuffer.questSpellObjective = objectiveSpellID and SpellObjectiveInfoBuffer
        QuestInfoBuffer.questTimeLeft = GetQuestTimeLeftSeconds(questID)
        QuestInfoBuffer.questResetTime = GetQuestResetTime()
        QuestInfoBuffer.questBackground = GetQuestDetailsTheme(questID)
        QuestInfoBuffer.questRequired = questRequired
        QuestInfoBuffer.questRewardReceive = questRewardReceive
        QuestInfoBuffer.questRewardChoices = questRewardChoices
        QuestInfoBuffer.questRewardSpells = questRewardSpells
        QuestInfoBuffer.questRewardsChoice = questRewardChoices
        QuestInfoBuffer.questRewardsSpell = questRewardSpells
        QuestInfoBuffer.questRewardSkill = SkillInfoBuffer
        QuestInfoBuffer.questRewardNumReceive = questRewardNumReceive
        QuestInfoBuffer.questRewardNumChoice = questRewardNumChoice
        QuestInfoBuffer.questRewardNumSpell = #questRewardSpells
        QuestInfoBuffer.questRewardNumRequired = questRewardNumRequired
        QuestInfoBuffer.questRewardNumCurrencies = #questRewardCurrencies
        QuestInfoBuffer.questRewardCurrencies = questRewardCurrencies
        QuestInfoBuffer.questRewardExperience = GetRewardXP()
        QuestInfoBuffer.questRewardHonor = GetRewardHonor()
        QuestInfoBuffer.questRewardMoney = GetRewardMoney()
        QuestInfoBuffer.questRewardArtifactXP = questRewardArtifactXP
        QuestInfoBuffer.questRewardArtifactCategory = questRewardArtifactCategory
        QuestInfoBuffer.questRewardWarModeBonus = CanQuestHaveWarModeBonus(questID)
        QuestInfoBuffer.questRewardMajorFactionReputationReward = GetQuestOfferMajorFactionReputationRewards()

        return QuestInfoBuffer
    end

    function ControlCenter_DataProvider.BuildPartialQuestInfoFromGossipOption(gossipData)
        local questID = gossipData.questID
        if not questID then
            return
        end

        return BuildPartialQuestInfo(questID, gossipData.title, gossipData.isTrivial, gossipData.isComplete, gossipData.frequency, gossipData.repeatable, gossipData.isLegendary, gossipData.isImportant)
    end

    function ControlCenter_DataProvider.BuildPartialQuestInfoFromGreetingOption(name, level, questID, isTrivial, isComplete, isLegendary, frequency, isRepeatable, isImportant)
        return BuildPartialQuestInfo(questID or 0, name, isTrivial, isComplete, frequency, isRepeatable, isLegendary, isImportant)
    end
end

do --Gossip Info
    local gossipInfoTemplate = ControlCenter_Preload.SessionInfo.GossipInfo{}
    local sortedQuests = {}

    local function SortByFlag(a, b)
        return a.optionFlag > b.optionFlag
    end

    function ControlCenter_DataProvider.BuildGossipInfo()
        local gossipSessionType = ControlCenter.GetGossipSessionType()
        local gossipOptions = EMPTY_TABLE
        local gossipAvailableQuests
        local gossipIncompleteQuests
        local gossipCompleteQuests
        local gossipLore

        if gossipSessionType == ControlCenter_Preload.Enum.SessionType.Gossip then
            gossipOptions = ControlCenter_DataProvider.FetchGossipOptions(GetGossipOptions())
            gossipLore = GetGossipText() or ""

            local activeQuests = GetGossipActiveQuests()
            gossipAvailableQuests = ControlCenter_DataProvider.FetchGossipQuests(ControlCenter_Preload.Enum.OptionType.QuestAvailable, GetGossipAvailableQuests())
            gossipIncompleteQuests = ControlCenter_DataProvider.FetchGossipQuests(ControlCenter_Preload.Enum.OptionType.QuestIncomplete, activeQuests)
            gossipCompleteQuests = ControlCenter_DataProvider.FetchGossipQuests(ControlCenter_Preload.Enum.OptionType.QuestComplete, activeQuests)
            tsort(gossipOptions, SortByFlag)
        elseif gossipSessionType == ControlCenter_Preload.Enum.SessionType.GossipGreeting then
            gossipLore = GetGreetingText() or ""

            local numAvailable = GetNumAvailableQuests()
            local numActive = GetNumActiveQuests()
            gossipAvailableQuests = ControlCenter_DataProvider.FetchGreetingAvailableQuests(numAvailable)
            gossipIncompleteQuests = ControlCenter_DataProvider.FetchGreetingActiveQuests(ControlCenter_Preload.Enum.OptionType.QuestIncomplete, numActive)
            gossipCompleteQuests = ControlCenter_DataProvider.FetchGreetingActiveQuests(ControlCenter_Preload.Enum.OptionType.QuestComplete, numActive)
        else
            return
        end

        wipe(sortedQuests)
        AppendResults(sortedQuests, gossipAvailableQuests)
        AppendResults(sortedQuests, gossipCompleteQuests)
        AppendResults(sortedQuests, gossipIncompleteQuests)

        gossipInfoTemplate.gossipLore = gossipLore
        gossipInfoTemplate.gossipOptions = gossipOptions
        gossipInfoTemplate.gossipQuests = sortedQuests
        gossipInfoTemplate.gossipAvailableQuests = gossipAvailableQuests
        gossipInfoTemplate.gossipCompleteQuests = gossipCompleteQuests
        gossipInfoTemplate.gossipIncompleteQuests = gossipIncompleteQuests

        return gossipInfoTemplate
    end
end
