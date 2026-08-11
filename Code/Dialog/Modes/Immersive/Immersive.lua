local env = select(2, ...)
local L = env.L
local Enum = env.Enum
local Config = env.Config
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local UIAnim = env.modules:Import("packages\\ui-anim")
local Utils_Blizzard = env.modules:Import("packages\\utils\\blizzard")
local Dialog_Preload = env.modules:Import("@\\Dialog\\Preload")
local ControlCenter = env.modules:Import("@\\Dialog\\ControlCenter")
local DialogFrame = env.modules:Import("@\\Dialog\\DialogFrame")
local Modes_ModeHandler = env.modules:Import("@\\Dialog\\Modes\\ModeHandler")
local ImmersiveMode_Preload = env.modules:Import("@\\Dialog\\Modes\\Immersive\\Preload")
local ImmersiveMode_CVars = env.modules:Import("@\\Dialog\\Modes\\Immersive\\CVars")
local ImmersiveMode = env.modules:New("@\\Dialog\\Modes\\Immersive")

local UIParent = UIParent
local WorldFrame = WorldFrame
local CreateFrame = CreateFrame
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local UnitIsGameObject = UnitIsGameObject
local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit
local UnitName = UnitName
local ResetCursor = ResetCursor
local SetCursor = SetCursor
local Mixin = Mixin
local strlenutf8 = strlenutf8
local gmatch = string.gmatch
local gsub = string.gsub
local byte = string.byte
local find = string.find
local format = string.format
local sub = string.sub
local floor = math.floor
local max = math.max
local min = math.min
local tonumber = tonumber
local type = type


ImmersiveMode.isActive = false


local TEXT_PLAYBACK_INTERVAL = 0.05
local TEXT_PLAYBACK_PAUSE_DURATION = 0.125

local TextPlaybackUtil = {}
do
    function TextPlaybackUtil.GetCharacterStartIndex(text, characterIndex)
        local byteIndex = 1
        local currentCharacterIndex = 0

        while byteIndex <= #text do
            local characterStartIndex = byteIndex
            local characterByte = byte(text, byteIndex)
            if characterByte <= 127 then
                byteIndex = byteIndex + 1
            elseif characterByte <= 223 then
                byteIndex = byteIndex + 2
            elseif characterByte <= 239 then
                byteIndex = byteIndex + 3
            elseif characterByte <= 247 then
                byteIndex = byteIndex + 4
            else
                byteIndex = byteIndex + 1
            end

            currentCharacterIndex = currentCharacterIndex + 1
            if currentCharacterIndex == characterIndex then return characterStartIndex end
        end
    end

    function TextPlaybackUtil.GetCharacterEndIndex(text, characterIndex)
        local startIndex = TextPlaybackUtil.GetCharacterStartIndex(text, characterIndex)
        if not startIndex then return end

        local characterByte = byte(text, startIndex)
        if characterByte <= 127 then return startIndex end
        if characterByte <= 223 then return startIndex + 1 end
        if characterByte <= 239 then return startIndex + 2 end
        if characterByte <= 247 then return startIndex + 3 end
    end

    function TextPlaybackUtil.GetSubstring(text, firstCharacter, lastCharacter)
        local startIndex = TextPlaybackUtil.GetCharacterStartIndex(text, firstCharacter)
        local endIndex = TextPlaybackUtil.GetCharacterEndIndex(text, lastCharacter)
        return startIndex and endIndex and sub(text, startIndex, endIndex) or ""
    end

    function TextPlaybackUtil.AdjustForEscapeSequences(text, characterCount)
        if characterCount >= strlenutf8(text) then return characterCount end

        local currentText = TextPlaybackUtil.GetSubstring(text, 1, characterCount)
        local textureStartIndex = find(currentText, "|T[^|]*$")
        if textureStartIndex then
            local textureEndIndex = find(text, "|t", textureStartIndex)
            if textureEndIndex then
                return strlenutf8(sub(text, 1, textureEndIndex + 1))
            end
        end

        local atlasStartIndex = find(currentText, "|A[^|]*$")
        if atlasStartIndex then
            local atlasEndIndex = find(text, "|a", atlasStartIndex)
            if atlasEndIndex then
                return strlenutf8(sub(text, 1, atlasEndIndex + 1))
            end
        end

        return characterCount
    end

    function TextPlaybackUtil.IsPauseCharacter(character)
        local pauseCharacters = L["PLAYBACK_PAUSE_CHARACTERS"]
        for index = 1, #pauseCharacters do
            if find(pauseCharacters[index], character, 1, true) then
                return true
            end
        end
        return false
    end
end


local ImmersiveModeUtil = {}
do
    function ImmersiveModeUtil.SplitText(text, splitParagraphs)
        if not text or type(text) ~= "string" then return end

        text = gsub(text, " %s+", " ")
        text = gsub(text, "|c%x%x%x%x%x%x%x%x", "")
        text = gsub(text, "|r", "")
        text = splitParagraphs and gsub(text, "\n+", "\n") or gsub(text, "([\\.|>|<|!|?|\n])%s+", "%1\n")

        local lines = {}
        for segment in gmatch(text, "[^\n]+") do
            segment = gsub(segment, "^%s*(.-)%s*$", "%1")
            if segment ~= "" then
                lines[#lines + 1] = segment
            end
        end

        return lines
    end

    function ImmersiveModeUtil.GetEmoteIndexes(messages)
        local results = {}
        local isInEmote = false

        for index = 1, #messages do
            local message = messages[index]
            local isEmote = isInEmote

            for delimiter in gmatch(message, "[<>]") do
                isEmote = true
                isInEmote = delimiter == "<"
            end

            if isEmote then
                results[index] = true
            end
        end

        return results
    end

    function ImmersiveModeUtil.GetInteractionUnit()
        return UnitExists("questnpc") and "questnpc" or "npc"
    end

    function ImmersiveModeUtil.IsMouseOverInteractionTarget()
        if not UnitExists("mouseover") then return false end
        return (UnitExists("npc") and UnitIsUnit("mouseover", "npc")) or (UnitExists("questnpc") and UnitIsUnit("mouseover", "questnpc"))
    end

    function ImmersiveModeUtil.IsUnitPlayer(unit)
        return UnitExists(unit) and UnitIsUnit(unit, "player")
    end

    function ImmersiveModeUtil.IsObjectDialog()
        local unit = ImmersiveModeUtil.GetInteractionUnit()
        local isGameObject = UnitIsGameObject(unit)
        local isPlayer = ImmersiveModeUtil.IsUnitPlayer(unit)
        local isItem = Utils_Blizzard.FindItemInInventory(UnitName(unit)) ~= nil

        return isGameObject or isPlayer or isItem
    end

    function ImmersiveModeUtil.HasGossipOptions()
        local options = ControlCenter.GetGossipOptions()
        if options and options[1] then return true end

        options = ControlCenter.GetGossipOptionsQuestQuestAvailable()
        if options and options[1] then return true end

        options = ControlCenter.GetGossipOptionsQuestQuestIncomplete()
        if options and options[1] then return true end

        options = ControlCenter.GetGossipOptionsQuestQuestComplete()
        return options and options[1] ~= nil
    end
end


local function CloseSession()
    ControlCenter.CloseSession()
    CallbackRegistry.Trigger("DialogFrame.CloseSession")
end

local ACTION_HANDLERS = {
    [DialogFrame.Enum.Action.Goodbye]    = CloseSession,
    [DialogFrame.Enum.Action.Cancel]     = function()
        if ControlCenter.IsGossipQuest() then
            ControlCenter.DeclineCurrentQuest()
        else
            CloseSession()
        end
    end,
    [DialogFrame.Enum.Action.Accept]     = ControlCenter.AcceptCurrentQuest,
    [DialogFrame.Enum.Action.AutoAccept] = CloseSession,
    [DialogFrame.Enum.Action.Continue]   = ControlCenter.ContinueCurrentQuest,
    [DialogFrame.Enum.Action.Complete]   = ControlCenter.CompleteCurrentQuest
}

function ImmersiveMode.Activate()
    ImmersiveMode.isActive = true
    LWDialogFrame:SetDefaultTextShown(false)

    if ControlCenter.IsInSession() then
        ImmersiveMode_CVars.Activate()
    end

    if ControlCenter.GetGossipSessionType() then
        ImmersiveMode.OnShowGossip()
    elseif ControlCenter.GetQuestSessionType() then
        ImmersiveMode.OnShowQuest()
    else
        LWDialogFrame:Close()
        LWImmersiveChatBubble:UpdateChatBubble(true)
    end
end

function ImmersiveMode.Deactivate()
    ImmersiveMode.isActive = false
    ImmersiveMode_CVars.Deactivate()
    LWDialogFrame:Close()
    LWImmersiveChatBubble:RestoreNameplate()
    LWImmersiveChatBubble:Close()
end

function ImmersiveMode.OnQuestRewardChoiceSelected()
    if not ImmersiveMode.isActive then return end
    LWDialogFrame:UpdateFooterButtons()
end

function ImmersiveMode.OnSessionBegin()
    if not ImmersiveMode.isActive then return end
    ImmersiveMode_CVars.Activate()
end

function ImmersiveMode.OnSessionClosing()
    if not ImmersiveMode.isActive then return end
    LWImmersiveChatBubble:CloseImmediately()
end

function ImmersiveMode.OnSessionEnd()
    if not ImmersiveMode.isActive then return end
    ImmersiveMode_CVars.Deactivate()
    LWImmersiveChatBubble:CloseImmediately()
    LWImmersiveChatBubble:RestoreNameplate()
    LWDialogFrame:HideQuestModelFrame()
    LWDialogFrame:Close()
end

function ImmersiveMode.OnCombatBegin()
    if not ImmersiveMode.isActive then return end
    ImmersiveMode_CVars.Deactivate()
end

function ImmersiveMode.OnShowGossip()
    if not ImmersiveMode.isActive then return end

    LWImmersiveChatBubble:UpdateChatBubble(true)
    LWDialogFrame:HideQuestModelFrame()
    LWDialogFrame:RefreshGossipFrame()
    LWDialogFrame:Open()
    LWDialogFrame.GossipFrame.ScrollContainer:SetVerticalScroll(0, true)
    LWDialogFrame.GossipFrame:_Render()
    LWDialogFrame:RefreshEdgeFade()
end

function ImmersiveMode.OnHideGossip()
    if not ImmersiveMode.isActive then return end
    LWImmersiveChatBubble:Close()
    LWDialogFrame:Close()
end

function ImmersiveMode.OnUpdateGossip()
    if not ImmersiveMode.isActive then return end
    LWImmersiveChatBubble:UpdateChatBubble()
    if not ControlCenter.IsGossipValidForUpdate() then return end
    LWDialogFrame:UpdateGossipQuestOptions()
end

function ImmersiveMode.OnShowQuest()
    if not ImmersiveMode.isActive then return end

    LWImmersiveChatBubble:UpdateChatBubble(true)
    LWDialogFrame:RefreshQuestFrame()
    LWDialogFrame:RefreshQuestModelFrame()
    LWDialogFrame:Open()
    LWDialogFrame.QuestFrame.ScrollContainer:SetVerticalScroll(0, true)
    LWDialogFrame.QuestFrame:_Render()
    LWDialogFrame:RefreshEdgeFade()
end

function ImmersiveMode.OnHideQuest()
    if not ImmersiveMode.isActive then return end
    LWImmersiveChatBubble:Close()
    LWDialogFrame:HideQuestModelFrame()
    LWDialogFrame:Close()
end

function ImmersiveMode.OnUpdateQuest()
    if not ImmersiveMode.isActive then return end
    LWImmersiveChatBubble:UpdateChatBubble()
    if not ControlCenter.GetQuestSessionType() then return end
    LWDialogFrame:RefreshQuestFrame()
    LWDialogFrame:RefreshQuestModelFrame()
    LWDialogFrame.QuestFrame:_Render()
end

function ImmersiveMode.OnPortraitUpdate()
    if not ImmersiveMode.isActive or not ControlCenter.GetQuestSessionType() then return end
    LWDialogFrame:RefreshQuestModelFrame()
end

function ImmersiveMode.OnCloseSessionRequested()
    if not ImmersiveMode.isActive then return end
    CloseSession()
end

function ImmersiveMode.OnActionRequested(_, action)
    if not ImmersiveMode.isActive then return end

    local handler = ACTION_HANDLERS[action]
    if handler then handler() end
end

function ImmersiveMode.OnGossipOptionSelectionRequested(_, optionType, optionKey)
    if not ImmersiveMode.isActive then return end
    ControlCenter.SelectGossipOption(optionType, optionKey)
end

function ImmersiveMode.OnQuestRewardSelectionRequested(_, rewardIndex)
    if not ImmersiveMode.isActive then return end
    ControlCenter.SelectQuestReward(rewardIndex)
end


local ChatBubbleMixin = {}

function ChatBubbleMixin:OnLoad()
    self.padding = 32
    self.maxWidth = 350
    self.isNameplateAnchored = false
    self.nameplate = nil
    self.nameplateAlpha = nil
    self.isLoaded = true
    self.messages = nil
    self.messageIndex = nil
    self.sourceText = nil
    self.appearance = nil
    self.registeredAppearances = {}
    self.allowTail = true
    self.isFinished = false
    self.currentMessageText = nil
    self.textPlaybackState = nil
    self.autoProgressTimer = nil
    self.isMouseOver = false
    self.isDragging = false

    self.ProgressFrame:Hide()
    self.ProgressFrame.PreviousButton:HookClick(function() self:PreviousDialog() end)
    self.ProgressFrame.NextButton:HookClick(function() self:NextDialog() end)

    self:SetScript("OnEnter", self.OnEnter)
    self:SetScript("OnLeave", self.OnLeave)
    self:SetScript("OnMouseDown", self.OnMouseDown)
    self:SetScript("OnMouseUp", self.OnMouseUp)
    self:SetScript("OnUpdate", self.OnUpdate)
    self:SetScript("OnDragStart", function()
        if self.isNameplateAnchored then return end

        self.isDragging = true

        SetCursor("Interface\\Cursor\\UI-Cursor-Move")
        self:StartMoving()
    end)
    self:SetScript("OnDragStop", function()
        self.isDragging = false

        ResetCursor()
        self:StopMovingOrSizing()
        if not self.isNameplateAnchored then self:SavePosition() end
        C_Timer.After(0, function() self.isDragging = false end)
    end)

    self:Hide()
end

function ChatBubbleMixin:OnEnter()
    self.isMouseOver = true
    self.AnimGroup_Hover:Play(self, "ENABLED")
end

function ChatBubbleMixin:OnLeave()
    self.isMouseOver = false
    self.AnimGroup_Hover:Play(self, "DISABLED")
end

function ChatBubbleMixin:OnMouseDown()

end

function ChatBubbleMixin:OnMouseUp(button)
    if self.isDragging then return end
    self:HandleDialogProgression(button)
end

function ChatBubbleMixin:OnUpdate(elapsed)
    if self.AnimGroup:IsPlaying(self, "HIDE") then return end

    local unit = ImmersiveModeUtil.GetInteractionUnit()
    local nameplate = GetNamePlateForUnit(unit)
    local isValidNameplate = self:IsValidNameplate(nameplate)

    if self.isNameplateAnchored ~= isValidNameplate or (isValidNameplate and self.nameplate ~= nameplate) then
        self:SetNameplate(unit)
    end

    self:OnTextPlaybackUpdate(elapsed)
end

function ChatBubbleMixin:UpdateChatBubble(restartDialog)
    if not ImmersiveMode.isActive or not self.isLoaded then return end

    local wasShown = self:IsShown()

    local text = nil
    if ControlCenter.GetGossipSessionType() then
        text = ControlCenter.GetGossipText()
    elseif ControlCenter.GetQuestSessionType() then
        text = ControlCenter.GetQuestText()
    end

    local hasMessage, messageChanged = self:SetMessage(text, restartDialog)
    if not hasMessage then
        self:Close()
        return
    end
    if self.isFinished and not restartDialog then return end

    self:SetNameplate(ImmersiveModeUtil.GetInteractionUnit())

    if restartDialog or not wasShown then
        self:Open()
    elseif messageChanged then
        self.AnimGroup:Stop()
        self.AnimGroup:Play(self, "NEW")
    end
end

function ChatBubbleMixin:IsPreviousDialogEnabled()
    local isDialogAvailable = self:IsShown() or self.isFinished
    return ImmersiveMode.isActive and ControlCenter.IsInSession() and isDialogAvailable and self:HasMessage()
end

function ChatBubbleMixin:PreviousDialog()
    if not self:IsPreviousDialogEnabled() then return false end
    if not self:IsShown() then self:SetNameplate(ImmersiveModeUtil.GetInteractionUnit()) end
    return self:ShowPreviousMessage()
end

function ChatBubbleMixin:NextDialog()
    if not ImmersiveMode.isActive or not self:IsShown() then return false end
    return self:ShowNextMessage()
end

function ChatBubbleMixin:SkipDialog()
    if not ImmersiveMode.isActive or not self:IsShown() then return false end
    return self:SkipMessage()
end

function ChatBubbleMixin:HandleDialogProgression(button)
    if button == "LeftButton" then
        self:NextDialog()
    elseif button == "RightButton" then
        self:PreviousDialog()
    end
end

function ChatBubbleMixin:RegisterAppearance(appearanceID, setEnabled)
    self.registeredAppearances[appearanceID] = setEnabled
    if self.appearance == appearanceID then setEnabled(true) end
    return true
end

function ChatBubbleMixin:SetAppearance(appearanceID)
    if self.appearance == appearanceID then return end

    local previousAppearance = self.registeredAppearances[self.appearance]
    if previousAppearance then previousAppearance(false) end

    self.appearance = appearanceID

    local appearance = self.registeredAppearances[appearanceID]
    if appearance then appearance(true) end
end

function ChatBubbleMixin:SetTail(showTail)
    self.Tail:SetShown(showTail)
    self.allowTail = showTail
end

function ChatBubbleMixin:HasMessage()
    return self.messages and self.messages[1] ~= nil
end

function ChatBubbleMixin:UpdateProgressFrame()
    local messages = self.messages
    if not messages or #messages < 2 or not self.messageIndex then
        self.ProgressFrame:Hide()
        return
    end

    self.ProgressFrame.ProgressText:SetText(format("%d/%d", self.messageIndex, #messages))
    self.ProgressFrame:Show()
end

function ChatBubbleMixin:IsValidNameplate(nameplate)
    local playerNameplate = GetNamePlateForUnit("player")
    local isGameObject = UnitIsGameObject("npc") or UnitIsGameObject("questnpc")

    return nameplate ~= nil and nameplate ~= playerNameplate and not isGameObject
end

function ChatBubbleMixin:RestorePosition()
    local bounds = Config.DBGlobal:GetVariable("immersiveChatBubbleBounds")
    if not bounds or not bounds.point or bounds.x == nil or bounds.y == nil then
        self:SetDefaultPosition()
        return
    end

    self:ClearAllPoints()
    self:SetPoint(bounds.point, UIParent, bounds.x, bounds.y)
end

function ChatBubbleMixin:SavePosition()
    local point, _, _, x, y = self:GetPoint()

    Config.DBGlobal:SetVariable({ "immersiveChatBubbleBounds", "point" }, point)
    Config.DBGlobal:SetVariable({ "immersiveChatBubbleBounds", "x" }, x)
    Config.DBGlobal:SetVariable({ "immersiveChatBubbleBounds", "y" }, y)
end

function ChatBubbleMixin:SetDefaultPosition()
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "TOP", 0, -UIParent:GetHeight() / 6)
end

function ChatBubbleMixin:RestoreNameplate()
    if self.nameplate and self.nameplateAlpha ~= nil then
        self.nameplate:SetAlpha(self.nameplateAlpha)
    end

    self.isNameplateAnchored = false
    self.nameplate = nil
    self.nameplateAlpha = nil
end

function ChatBubbleMixin:SetNameplate(unit)
    local nameplate = GetNamePlateForUnit(unit)
    if not self:IsValidNameplate(nameplate) then
        self:RestoreNameplate()
        self:SetParent(LWParent)
        self:SetIgnoreParentScale(true)
        self:ClearAllPoints()
        self:RestorePosition()
        self:SetMovable(true)
        if self.allowTail then self.Tail:Hide() end
        return
    end

    if self.nameplate ~= nameplate then
        self:RestoreNameplate()
        self.nameplate = nameplate
        self.nameplateAlpha = nameplate:GetAlpha()
    end

    self.isNameplateAnchored = true
    self:SetParent(WorldFrame)
    self:SetIgnoreParentScale(false)
    if self.allowTail then self.Tail:Show() end
    nameplate:SetAlpha(0)
    self:ClearAllPoints()
    self:SetPoint("BOTTOM", nameplate, 0, 6)
    self:SetMovable(false)
end

function ChatBubbleMixin:IsPlaybackEnabled()
    return Config.DBGlobal:GetVariable("Immersive_Playback")
end

function ChatBubbleMixin:CancelAutoProgress()
    if not self.autoProgressTimer then return end

    self.autoProgressTimer:Cancel()
    self.autoProgressTimer = nil
end

function ChatBubbleMixin:StopTextPlayback(showFullText)
    local playbackState = self.textPlaybackState

    self.textPlaybackState = nil

    if showFullText and playbackState then
        self.String:SetText(playbackState.text)
    end
end

function ChatBubbleMixin:GetTextPreviewHexColor()
    local previewAlpha = tonumber(Config.DBGlobal:GetVariable("Immersive_ContentPreviewAlpha")) or 0.5
    local previewModifier = 0.2 + min(max(previewAlpha, 0), 1) / 1.25
    local red, green, blue = self.String:GetTextColor()

    red = min(max(floor(red * previewModifier * 255), 0), 255)
    green = min(max(floor(green * previewModifier * 255), 0), 255)
    blue = min(max(floor(blue * previewModifier * 255), 0), 255)
    return format("%02x%02x%02x", red, green, blue)
end

function ChatBubbleMixin:ScheduleAutoProgress()
    self:CancelAutoProgress()
    if not self:IsPlaybackEnabled() then return end
    if not Config.DBGlobal:GetVariable("Immersive_PlaybackAutoProgress") then return end

    local delay = max(tonumber(Config.DBGlobal:GetVariable("Immersive_PlaybackAutoProgressDelay")) or 1, 0)
    local sourceText = self.sourceText
    local messageIndex = self.messageIndex

    self.autoProgressTimer = C_Timer.NewTimer(delay, function()
        self.autoProgressTimer = nil
        if not self:IsPlaybackEnabled() then return end
        if not ImmersiveMode.isActive or not self:IsShown() or self.isFinished then return end
        if self.sourceText ~= sourceText or self.messageIndex ~= messageIndex then return end

        self:ShowNextMessage(true)
    end)
end

function ChatBubbleMixin:OnTextPlaybackFinished()
    local playbackState = self.textPlaybackState
    if not playbackState then return end

    local shouldAutoProgress = playbackState.shouldAutoProgress

    self.String:SetText(playbackState.text)
    self:StopTextPlayback()

    if shouldAutoProgress then self:ScheduleAutoProgress() end
end

function ChatBubbleMixin:OnTextPlaybackUpdate(elapsed)
    local playbackState = self.textPlaybackState
    if not playbackState then return end

    if playbackState.pauseActive then
        playbackState.pauseElapsed = playbackState.pauseElapsed + elapsed
        if playbackState.pauseElapsed < TEXT_PLAYBACK_PAUSE_DURATION then return end

        playbackState.pauseActive = false
        playbackState.pauseElapsed = 0
    end

    playbackState.elapsed = playbackState.elapsed + elapsed

    local textLength = strlenutf8(playbackState.text)
    local characterCount = min(floor(playbackState.elapsed / playbackState.interval) + 1, textLength)
    characterCount = TextPlaybackUtil.AdjustForEscapeSequences(playbackState.text, characterCount)

    if playbackState.pauseEnabled and playbackState.lastPauseIndex ~= characterCount then
        local lastCharacter = TextPlaybackUtil.GetSubstring(playbackState.text, characterCount, characterCount)
        if TextPlaybackUtil.IsPauseCharacter(lastCharacter) then
            playbackState.lastPauseIndex = characterCount
            playbackState.pauseActive = true
        end
    end

    local currentText = TextPlaybackUtil.GetSubstring(playbackState.text, 1, characterCount)
    local remainingText = TextPlaybackUtil.GetSubstring(playbackState.text, characterCount + 1, textLength)

    if remainingText ~= "" and self.appearance ~= ImmersiveMode_Preload.Enum.Appearance.Emote then
        self.String:SetText(currentText .. "|cff" .. self:GetTextPreviewHexColor() .. remainingText .. "|r")
    else
        self.String:SetText(currentText .. remainingText)
    end

    if characterCount >= textLength then
        self:OnTextPlaybackFinished()
    end
end

function ChatBubbleMixin:StartTextPlayback(text, shouldAutoProgress)
    self:CancelAutoProgress()
    self:StopTextPlayback()

    local playbackSpeed = max(tonumber(Config.DBGlobal:GetVariable("Immersive_PlaybackSpeed")) or 1, 0.1)
    local playbackSpeedModifier = tonumber(L["PLAYBACK_SPEED_MODIFIER"]) or 1
    self.textPlaybackState = {
        text               = text,
        elapsed            = 0,
        interval           = TEXT_PLAYBACK_INTERVAL / (playbackSpeed * playbackSpeedModifier),
        pauseEnabled       = Config.DBGlobal:GetVariable("Immersive_PlaybackPunctuationPausing"),
        pauseActive        = false,
        pauseElapsed       = 0,
        lastPauseIndex     = nil,
        shouldAutoProgress = shouldAutoProgress == true
    }

    self:OnTextPlaybackUpdate(0)
end

function ChatBubbleMixin:SetMessageToIndex(index, skipPlayback, shouldAutoProgress)
    local message = self.messages and self.messages[index]
    if not message then return false end

    local playbackEnabled = self:IsPlaybackEnabled()
    local messageChanged = self.messageIndex ~= index
        or self.currentMessageText ~= message.text
        or self.appearance ~= message.appearance

    if not messageChanged then
        if skipPlayback or not playbackEnabled then
            self:CancelAutoProgress()
            self:StopTextPlayback(true)
        end
        return false
    end

    self:CancelAutoProgress()
    self:StopTextPlayback(skipPlayback)

    self.messageIndex = index
    self.currentMessageText = message.text
    self.String:SetText(message.text)
    self:SetAppearance(message.appearance)

    local textWidth = self.String:GetStringWidth()
    local textHeight = self.String:GetStringHeight()

    self:SetSize(min(textWidth + self.padding, self.maxWidth), textHeight + self.padding)
    self:UpdateProgressFrame()

    if playbackEnabled and not skipPlayback then
        self:StartTextPlayback(message.text, shouldAutoProgress)
    end

    return true
end

function ChatBubbleMixin:SetMessage(msg, restartDialog)
    local splitParagraphs = Config.DBGlobal:GetVariable("Immersive_SplitParagraphs")
    local messages = ImmersiveModeUtil.SplitText(msg, splitParagraphs)
    if not messages or not messages[1] then
        self.messages = nil
        self.messageIndex = nil
        self.sourceText = msg
        self.splitParagraphs = splitParagraphs
        self.isFinished = false
        self.currentMessageText = nil
        self:CancelAutoProgress()
        self:StopTextPlayback()
        self:SetAppearance(nil)
        self:UpdateProgressFrame()
        return false
    end

    if restartDialog or self.sourceText ~= msg or self.splitParagraphs ~= splitParagraphs then
        local emoteIndexes = ImmersiveModeUtil.GetEmoteIndexes(messages)
        local defaultAppearance = ImmersiveModeUtil.IsObjectDialog() and ImmersiveMode_Preload.Enum.Appearance.Object or ImmersiveMode_Preload.Enum.Appearance.Dialog
        local formattedMessages = {}

        for index = 1, #messages do
            formattedMessages[index] = {
                text       = gsub(gsub(messages[index], "[<>]", ""), "%.%.%.", "…"),
                appearance = emoteIndexes[index] and ImmersiveMode_Preload.Enum.Appearance.Emote or defaultAppearance
            }
        end

        self.messages = formattedMessages
        self.messageIndex = nil
        self.currentMessageText = nil
        self.sourceText = msg
        self.splitParagraphs = splitParagraphs
        self.isFinished = false

        self:SetMessageToIndex(1, false, true)
        return true, true
    end

    return true, self:SetMessageToIndex(self.messageIndex)
end

function ChatBubbleMixin:ShowPreviousMessage()
    if not self:HasMessage() then return false end

    local wasShown = self:IsShown() and not self.isFinished
    self.isFinished = false
    local messageChanged = self:SetMessageToIndex(max((self.messageIndex or 1) - (wasShown and 1 or 0), 1), true, false)

    if not wasShown then
        self:Open()
    elseif messageChanged then
        self.AnimGroup:Stop()
        self.AnimGroup:Play(self, "NEW")
    else
        self.AnimGroup:Stop()
        self.AnimGroup:Play(self, "INVALID")
    end

    return true
end

function ChatBubbleMixin:ShowNextMessage(continueAutoProgress)
    if not self:IsShown() or not self:HasMessage() then return false end

    if self.messageIndex >= #self.messages then
        self.isFinished = true
        self:CancelAutoProgress()
        self:StopTextPlayback(true)
        self:Close()

        local autoClose = Config.DBGlobal:GetVariable("Immersive_PlaybackAutoClose")
        if self:IsPlaybackEnabled() and autoClose and ControlCenter.GetGossipSessionType() and not ImmersiveModeUtil.HasGossipOptions() then
            CloseSession()
        end

        return true
    end

    self:SetMessageToIndex(self.messageIndex + 1, false, continueAutoProgress)
    self.AnimGroup:Stop()
    self.AnimGroup:Play(self, "NEW")
    return true
end

function ChatBubbleMixin:SkipMessage()
    if not self:IsShown() then return false end
    self.isFinished = true
    self:CancelAutoProgress()
    self:StopTextPlayback(true)
    self:Close()
    return true
end

function ChatBubbleMixin:Open()
    self:Show()
    self.AnimGroup:Stop()
    self.AnimGroup:Play(self, "SHOW")
end

function ChatBubbleMixin:Close()
    self:CancelAutoProgress()
    self:StopTextPlayback(true)
    if not self:IsShown() or self.AnimGroup:IsPlaying(self, "HIDE") then return end
    self.AnimGroup:Stop()
    self.AnimGroup:Play(self, "HIDE"):onFinish(function() self:Hide() end)
end

function ChatBubbleMixin:CloseImmediately()
    self:CancelAutoProgress()
    self:StopTextPlayback(true)
    self.AnimGroup:Stop()
    self:Hide()
end

ChatBubbleMixin.AnimGroup = UIAnim.New()
do
    local FadeIn = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.25):from(0):to(1)
    local FadeInContent = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.5):from(0):to(1)
    local ScaleIn = UIAnim.Animate():property(UIAnim.Enum.Property.Scale):easing(UIAnim.Enum.Easing.ExpoOut):duration(1):from(0.25):to(1)
    ChatBubbleMixin.AnimGroup:State("SHOW", function(frame)
        FadeIn:Play(frame)
        FadeInContent:Play(frame.String)
        if frame.appearance ~= ImmersiveMode_Preload.Enum.Appearance.Emote then
            ScaleIn:Play(frame.ContainerFrame)
        else
            frame.ContainerFrame:SetScale(1)
        end
    end)

    local ScaleInDialog = UIAnim.Animate():property(UIAnim.Enum.Property.Scale):easing(UIAnim.Enum.Easing.ExpoOut):duration(0.75):from(0.75):to(1)
    local ScaleInObject = UIAnim.Animate():property(UIAnim.Enum.Property.Scale):easing(UIAnim.Enum.Easing.ExpoOut):duration(0.5):from(0.75):to(1)
    ChatBubbleMixin.AnimGroup:State("NEW", function(frame)
        FadeIn:Play(frame)
        FadeInContent:Play(frame.String)
        if frame.appearance == ImmersiveMode_Preload.Enum.Appearance.Dialog then
            ScaleInDialog:Play(frame.ContainerFrame)
        elseif frame.appearance == ImmersiveMode_Preload.Enum.Appearance.Object then
            ScaleInObject:Play(frame.ContainerFrame)
        else
            frame.ContainerFrame:SetScale(1)
        end
    end)

    local ScaleInvalid = UIAnim.Animate():property(UIAnim.Enum.Property.Scale):easing(UIAnim.Enum.Easing.ExpoOut):duration(1):from(0.95):to(1)
    ChatBubbleMixin.AnimGroup:State("INVALID", function(frame)
        if frame.appearance ~= ImmersiveMode_Preload.Enum.Appearance.Emote then
            ScaleInvalid:Play(frame.ContainerFrame)
        end
    end)

    local FadeOut = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.125):to(0)
    local ScaleOut = UIAnim.Animate():property(UIAnim.Enum.Property.Scale):easing(UIAnim.Enum.Easing.ExpoOut):duration(0.25):to(0.925)
    ChatBubbleMixin.AnimGroup:State("HIDE", function(frame)
        FadeOut:Play(frame)
        if frame.appearance ~= ImmersiveMode_Preload.Enum.Appearance.Emote then
            ScaleOut:Play(frame.ContainerFrame)
        end
    end)
end

ChatBubbleMixin.AnimGroup_Hover = UIAnim.New()
do
    local Enabled = UIAnim.Animate()
        :property(UIAnim.Enum.Property.Alpha)
        :easing(UIAnim.Enum.Easing.QuartInOut)
        :duration(0.375)
        :to(0.75)
    local Disabled = UIAnim.Animate()
        :property(UIAnim.Enum.Property.Alpha)
        :easing(UIAnim.Enum.Easing.QuartInOut)
        :duration(0.375)
        :to(1)

    ChatBubbleMixin.AnimGroup_Hover:State("ENABLED", function(frame)
        Enabled:Play(frame.ContainerFrame)
    end)

    ChatBubbleMixin.AnimGroup_Hover:State("DISABLED", function(frame)
        Disabled:Play(frame.ContainerFrame)
    end)
end


Mixin(LWImmersiveChatBubble, ChatBubbleMixin)
CallbackRegistry.Add("Preload.AddonReady", function()
    LWImmersiveChatBubble:OnLoad()

    LWImmersiveChatBubble:RegisterAppearance(ImmersiveMode_Preload.Enum.Appearance.Dialog, function(enabled)
        LWImmersiveChatBubble.ObjectBackground:SetShown(false)
        LWImmersiveChatBubble.DialogBackground:SetShown(enabled)
        LWImmersiveChatBubble.String:textColor(Dialog_Preload.TextColorSay)
        LWImmersiveChatBubble:SetTail(enabled)
    end)

    LWImmersiveChatBubble:RegisterAppearance(ImmersiveMode_Preload.Enum.Appearance.Object, function(enabled)
        LWImmersiveChatBubble.ObjectBackground:SetShown(enabled)
        LWImmersiveChatBubble.DialogBackground:SetShown(false)
        LWImmersiveChatBubble.String:textColor(Dialog_Preload.TextColorSay)
        LWImmersiveChatBubble:SetTail(false)
    end)

    LWImmersiveChatBubble:RegisterAppearance(ImmersiveMode_Preload.Enum.Appearance.Emote, function(enabled)
        LWImmersiveChatBubble.ObjectBackground:SetShown(enabled)
        LWImmersiveChatBubble.DialogBackground:SetShown(false)
        LWImmersiveChatBubble.String:textColor(Dialog_Preload.TextColorEmote)
        LWImmersiveChatBubble:SetTail(false)
    end)

    LWImmersiveChatBubble:UpdateChatBubble()
end)

local MouseEventListener = CreateFrame("Frame")
MouseEventListener:RegisterEvent("GLOBAL_MOUSE_UP")
MouseEventListener:SetScript("OnEvent", function(_, _, button)
    if not ImmersiveMode.isActive or LWImmersiveChatBubble.isDragging then return end
    if LWImmersiveChatBubble:IsShown() and LWImmersiveChatBubble.isMouseOver then return end
    if not ImmersiveModeUtil.IsMouseOverInteractionTarget() then return end
    LWImmersiveChatBubble:HandleDialogProgression(button)
end)


CallbackRegistry.Add("ControlCenter.QuestRewardChoiceSelected", ImmersiveMode.OnQuestRewardChoiceSelected)
CallbackRegistry.Add("ControlCenter.SessionBegin", ImmersiveMode.OnSessionBegin)
CallbackRegistry.Add("ControlCenter.SessionClosing", ImmersiveMode.OnSessionClosing)
CallbackRegistry.Add("ControlCenter.SessionEnd", ImmersiveMode.OnSessionEnd)
CallbackRegistry.Add("ControlCenter.CombatBegin", ImmersiveMode.OnCombatBegin)
CallbackRegistry.Add("ControlCenter.ShowGossip", ImmersiveMode.OnShowGossip)
CallbackRegistry.Add("ControlCenter.HideGossip", ImmersiveMode.OnHideGossip)
CallbackRegistry.Add("ControlCenter.UpdateGossip", ImmersiveMode.OnUpdateGossip)
CallbackRegistry.Add("ControlCenter.ShowQuest", ImmersiveMode.OnShowQuest)
CallbackRegistry.Add("ControlCenter.HideQuest", ImmersiveMode.OnHideQuest)
CallbackRegistry.Add("ControlCenter.UpdateQuest", ImmersiveMode.OnUpdateQuest)
CallbackRegistry.Add("UNIT_PORTRAIT_UPDATE", ImmersiveMode.OnPortraitUpdate)
CallbackRegistry.Add("PORTRAITS_UPDATED", ImmersiveMode.OnPortraitUpdate)
CallbackRegistry.Add(DialogFrame.Events.CloseSessionRequested, ImmersiveMode.OnCloseSessionRequested)
CallbackRegistry.Add(DialogFrame.Events.ActionRequested, ImmersiveMode.OnActionRequested)
CallbackRegistry.Add(DialogFrame.Events.GossipOptionSelectionRequested, ImmersiveMode.OnGossipOptionSelectionRequested)
CallbackRegistry.Add(DialogFrame.Events.QuestRewardSelectionRequested, ImmersiveMode.OnQuestRewardSelectionRequested)


Modes_ModeHandler.RegisterMode(Enum.Mode.Immersive, ImmersiveMode)
