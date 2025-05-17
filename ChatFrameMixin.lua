---@class addonTableChatanator
local addonTable = select(2, ...)

---@class Frame
addonTable.ChatFrameMixin = {}

function addonTable.ChatFrameMixin:OnLoad()
  self:SetHyperlinkPropagateToParent(true)

  self.filterFunc = nil
  self.messages = {}
  self.filteredMessages = self.messages
  self.font = "ChatFontNormal"

  self.sizingFontString = self:CreateFontString(nil, "BACKGROUND", self.font)

  self.sizingFontString:SetText("00:00:00")
  self.inset = self.sizingFontString:GetUnboundedStringWidth() + 20

  self.sizingFontString:SetPoint("TOPLEFT", self.inset, 0)
  self.sizingFontString:SetPoint("TOPRIGHT", -10, 0)
  self.sizingFontString:Hide()

  self.ScrollBox = CreateFrame("Frame", nil, self, "WowScrollBoxList")
  local view = CreateScrollBoxListLinearView()
  view:SetElementExtentCalculator(function(index)
    return self.filteredMessages[index].height
  end)
  view:SetElementInitializer("Frame", function(frame, data)
    if not frame.initialized then
      frame.initialized = true
      frame:SetHyperlinkPropagateToParent(true)
      frame.DisplayString = frame:CreateFontString(nil, "ARTWORK", self.font)
      frame.DisplayString:SetPoint("TOPLEFT", self.inset, 0)
      frame.DisplayString:SetPoint("RIGHT", -10, 0)
      frame.DisplayString:SetJustifyH("LEFT")
      frame.Timestamp = frame:CreateFontString(nil, "ARTWORK", self.font)
      frame.Timestamp:SetPoint("TOPLEFT", 10, 0)
      frame.Timestamp:SetJustifyH("LEFT")
      frame.Timestamp:SetTextColor(0.5, 0.5, 0.5)
    end
    if data.font ~= self.font or data.width ~= self:GetWidth() then
      self.sizingFontString:SetText(data.text)
      data.height = self.sizingFontString:GetLineHeight() * self.sizingFontString:GetNumLines()
    end
    frame.Timestamp:SetText(date("%X", data.timestamp))
    frame.DisplayString:SetText(data.text)
    frame.DisplayString:SetTextColor(data.color.r, data.color.g, data.color.b)
  end)
  self.ScrollBox:SetAllPoints(self)
  self.ScrollBox:SetInterpolateScroll(true)
  self.ScrollBox:Init(view)
  self.ScrollBox:SetHyperlinkPropagateToParent(true)
  self.ScrollBox:GetScrollTarget():SetHyperlinkPropagateToParent(true)
  self.ScrollBox:GetScrollTarget():SetPropagateMouseClicks(true)
  self.ScrollBox:SetPanExtent(50)

  -- Preserve location when scrolling up
  hooksecurefunc(self.ScrollBox, "scrollInternal", function()
    self.scrolling = self.ScrollBox:GetScrollPercentage() ~= 1
  end)

  self:RegisterForChat()
  self:RepositionEditBox()

  self:SetScript("OnEvent", self.OnEvent)
end

function addonTable.ChatFrameMixin:RegisterForChat()
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterEvent("SETTINGS_LOADED")
  --self:RegisterEvent("UPDATE_CHAT_COLOR")
  self:RegisterEvent("UPDATE_CHAT_WINDOWS")
  self:RegisterEvent("CHANNEL_UI_UPDATE")
  self:RegisterEvent("CHANNEL_LEFT")
  self:RegisterEvent("CHAT_MSG_CHANNEL")
  self:RegisterEvent("CHAT_MSG_COMMUNITIES_CHANNEL")
  self:RegisterEvent("CLUB_REMOVED")
  self:RegisterEvent("UPDATE_INSTANCE_INFO")
  --self:RegisterEvent("UPDATE_CHAT_COLOR_NAME_BY_CLASS")
  self:RegisterEvent("CHAT_SERVER_DISCONNECTED")
  self:RegisterEvent("CHAT_SERVER_RECONNECTED")
  self:RegisterEvent("BN_CONNECTED")
  self:RegisterEvent("BN_DISCONNECTED")
  self:RegisterEvent("PLAYER_REPORT_SUBMITTED")
  self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
  self:RegisterEvent("ALTERNATIVE_DEFAULT_LANGUAGE_CHANGED")
  self:RegisterEvent("NEWCOMER_GRADUATION")
  self:RegisterEvent("CHAT_REGIONAL_STATUS_CHANGED")
  self:RegisterEvent("CHAT_REGIONAL_SEND_FAILED")
  self:RegisterEvent("NOTIFY_CHAT_SUPPRESSED")

  self.channels = {}
  self.pendingJoins = {}
  self.pendingLeaves = {}

  for type, values in pairs(ChatTypeGroup) do
    if type ~= "TRADESKILLS" then
      for _, event in ipairs(values) do
        self:RegisterEvent(event)
      end
    end
  end

  hooksecurefunc(C_ChatInfo, "UncensorChatLine", function(lineID)
    local found = false
    for _, message in ipairs(self.messages) do
      if message.id == lineID then
        found = true
        message.text = message.Formatter(C_ChatInfo.GetChatLineText(lineID))
        break
      end
    end
    if found then
      self:Render()
    end
  end)

  hooksecurefunc(DEFAULT_CHAT_FRAME, "AddMessage", function(_, ...)
    local fullTrace = debugstack()
    if fullTrace:find("ChatFrame_OnEvent") then
      return
    end
    local trace = debugstack(3, 1, 0)
    if trace:find("Interface/AddOns/Chatanator") then
      return
    end
    local isBlizzard = trace:find("Interface/AddOns/Blizzard_") ~= nil and trace:find("PrintHandler") == nil
    self:SetIncomingType({type = "RAW", source = isBlizzard and "SYSTEM" or "ADDON"})
    self:AddMessage(...)
  end)

  hooksecurefunc(SlashCmdList, "JOIN", function(msg)
    local name = gsub(msg, "%s*([^%s]+).*", "%1");
    local id, fullName = GetChannelName(name)
    table.insert(self.pendingJoins, {name = fullName or name, id = id, time = time()})
  end)

  hooksecurefunc(SlashCmdList, "LEAVE", function(msg)
    local name = strmatch(msg, "%s*([^%s]+)");
    local id, fullName = GetChannelName(name)
    table.insert(self.pendingLeaves, {name = fullName, id = id, time = time()})
  end)
end

function addonTable.ChatFrameMixin:UpdateChannels()
  self.channels = {} -- Used to generate channel messages in Blizzard handlers
  local channelDetails = {GetChannelList()}
  if #channelDetails > 0 then
    for i = 1, #channelDetails, 3 do
      local partialName = channelDetails[i + 1]
      local id, fullName = GetChannelName(partialName)
      table.insert(self.channels, {name = fullName, id = id})
    end
  end
end

function addonTable.ChatFrameMixin:OnEvent(eventType, ...)
  if #self.pendingJoins > 0 or #self.pendingLeaves > 0 then
    local currentTime = time()
    while self.pendingJoins[1] and currentTime - self.pendingJoins[1].time > 5 do
      table.remove(self.pendingJoins, 1)
    end
    while self.pendingLeaves[1] and currentTime - self.pendingLeaves[1].time > 5 do
      table.remove(self.pendingLeaves, 1)
    end
  end
  local currentTime = time()
  if ChatFrame_SystemEventHandler(eventType, ...) then
    return
  elseif eventType == "UPDATE_CHAT_WINDOWS" or eventType == "CHANNEL_UI_UPDATE" or eventType == "CHANNEL_LEFT" then
    self:UpdateChannels()
  elseif eventType == "PLAYER_ENTERING_WORLD" then
		self.defaultLanguage = GetDefaultLanguage()
		self.alternativeDefaultLanguage = GetAlternativeDefaultLanguage()
  elseif eventType == "NEUTRAL_FACTION_SELECT_RESULT" then
		self.defaultLanguage = GetDefaultLanguage()
		self.alternativeDefaultLanguage = GetAlternativeDefaultLanguage()
  elseif eventType == "ALTERNATIVE_DEFAULT_LANGUAGE_CHANGED" then
		self.alternativeDefaultLanguage = GetAlternativeDefaultLanguage()
  elseif eventType:sub(1, 8) == "CHAT_MSG" then
    addonTable.ProcessChatEvent(self, eventType, ...)
	elseif eventType == "VOICE_CHAT_CHANNEL_TRANSCRIBING_CHANGED" then
		local _, isNowTranscribing = ...
		if ( not self.isTranscribing and isNowTranscribing ) then
			ChatFrame_DisplaySystemMessage(self, SPEECH_TO_TEXT_STARTED)
		end
		self.isTranscribing = isNowTranscribing
  end
end

function addonTable.ChatFrameMixin:RepositionEditBox()
  ChatFrame1EditBox:ClearAllPoints()
  ChatFrame1EditBox:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
  ChatFrame1EditBox:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT")
end

function addonTable.ChatFrameMixin:SetFilter(func)
  self.filterFunc = func
end

function addonTable.ChatFrameMixin:SetIncomingType(eventType)
  self.incomingType = eventType
end

function addonTable.ChatFrameMixin:AddMessage(text, r, g, b, id, _, _, _, _, Formatter)
  local data = {
    text = text,
    color = CreateColor(r or 1, g or 1, b or 1),
    timestamp = time(),
    id = id,
    formatter = Formatter, -- Stored in case we have to uncensor a message
    typeInfo = self.incomingType or {type = "MANUAL", source = "UNKNOWN"},
  }
  self.incomingType = nil
  if data.font ~= self.font or data.width ~= self:GetWidth() then
    data.font = self.font
    data.width = self:GetWidth()
    self.sizingFontString:SetText(data.text)
    data.height = (self.sizingFontString:GetLineHeight() + self.sizingFontString:GetSpacing()) * self.sizingFontString:GetNumLines()
  end
  table.insert(self.messages, data)
  self:SetScript("OnUpdate", self.Render)
end

function addonTable.ChatFrameMixin:Render()
  self:SetScript("OnUpdate", nil)
  if self.filterFunc then
    self.filteredMessages = tFilter(self.messages, self.filterFunc, true)
  else
    self.filteredMessages = self.messages
  end
  self.ScrollBox:SetDataProvider(CreateDataProvider(self.filteredMessages), true)
  if not self.scrolling then
    self.ScrollBox:ScrollToEnd()
  end
end
