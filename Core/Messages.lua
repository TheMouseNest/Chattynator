---@class addonTableChatanator
local addonTable = select(2, ...)

---@class MessagesMonitorMixin: Frame
addonTable.MessagesMonitorMixin ={}

function addonTable.MessagesMonitorMixin:OnLoad()
  self.font = "ChatFontNormal"
  self.widths = {}

  self.sizingFontString = self:CreateFontString(nil, "BACKGROUND", self.font)

  self.sizingFontString:SetNonSpaceWrap(true)
  self.sizingFontString:SetWordWrap(true)
  self.sizingFontString:Hide()

  self.sizingFontString:SetText("00:00:00")
  self.inset = self.sizingFontString:GetUnboundedStringWidth() + 10

  CHATANATOR_MESSAGE_LOG = CHATANATOR_MESSAGE_LOG or { current = {}, historical = {} }
  CHATANATOR_MESSAGE_LOG.cleanIndex = self:CleanStore(CHATANATOR_MESSAGE_LOG.current, CHATANATOR_MESSAGE_LOG.cleanIndex or 1)

  self.messages = CopyTable(CHATANATOR_MESSAGE_LOG.current)
  self.messageCount = #self.messages
  self.store = CHATANATOR_MESSAGE_LOG.current
  self.storeCount = #self.store

  self.pending = {}

  if DEFAULT_CHAT_FRAME:GetNumMessages() > 0 then
    for i = 1, DEFAULT_CHAT_FRAME:GetNumMessages() do
      self:SetIncomingType(nil)
      local text, r, g, b = DEFAULT_CHAT_FRAME:GetMessageInfo(i)
      self:AddMessage(text, r, g, b)
    end
  end

  self.heights = {}

  self:UpdateStores()

  self.editBox = ChatFrame1EditBox

  self:RegisterEvent("PLAYER_ENTERING_WORLD")

  self:RegisterEvent("UI_SCALE_CHANGED")

  self:RegisterEvent("SETTINGS_LOADED")
  --self:RegisterEvent("UPDATE_CHAT_COLOR");
  self:RegisterEvent("UPDATE_CHAT_WINDOWS")
  self:RegisterEvent("CHANNEL_UI_UPDATE")
  self:RegisterEvent("CHANNEL_LEFT")
  self:RegisterEvent("CHAT_MSG_CHANNEL")
  self:RegisterEvent("CHAT_MSG_COMMUNITIES_CHANNEL")
  self:RegisterEvent("CLUB_REMOVED")
  self:RegisterEvent("UPDATE_INSTANCE_INFO")
  --self:RegisterEvent("UPDATE_CHAT_COLOR_NAME_BY_CLASS");
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

  self.channelList = {}
  self.zoneChannelList = {}

  local ignoredGroups
  if addonTable.Config.Get(addonTable.Config.Options.ENABLE_COMBAT_MESSAGES) then
    ignoredGroups = {}
  else
    ignoredGroups = {
      ["TRADESKILLS"] = true,
      ["OPENING"] = true,
      ["PET_INFO"] = true,
      ["COMBAT_MISC_INFO"] = true,
      ["COMBAT_XP_GAIN"] = true,
    }
  end
  for event, group in pairs(ChatTypeGroupInverted) do
    if not ignoredGroups[group] then
      self:RegisterEvent(event)
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
      addonTable.CallbackRegistry:TriggerEvent("Render")
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

    local type
    if fullTrace:find("DevTools_Dump") then
      type = "DUMP"
    elseif trace:find("Interface/AddOns/Blizzard_") ~= nil and trace:find("PrintHandler") == nil then
      type = "SYSTEM"
    else
      type = "ADDON"
    end
    self:SetIncomingType({type = type, event = "NONE"})
    self:AddMessage(...)
  end)

  hooksecurefunc(SlashCmdList, "JOIN", function()
    local channel = DEFAULT_CHAT_FRAME.channelList[#DEFAULT_CHAT_FRAME.channelList]
    if tIndexOf(self.channelList, channel) == nil then
      table.insert(self.channelList, channel)
    end
  end)

  local env = {
    FlashTabIfNotShown = function() end,
    GetChatTimestampFormat = function() return nil end,
    FCFManager_ShouldSuppressMessage = function() return false end,
    ChatFrame_CheckAddChannel = function(_, _, channelID)
      return true or ChatFrame_AddChannel(self, C_ChatInfo.GetChannelShortcutForChannelID(channelID)) ~= nil
    end,
  }

  setmetatable(env, {__index = _G, __newindex = _G})
  setfenv(ChatFrame_MessageEventHandler, env)
  self:SetScript("OnEvent", self.OnEvent)
end

function addonTable.MessagesMonitorMixin:OnEvent(eventName, ...)
  if eventName == "UPDATE_CHAT_WINDOWS" or eventName == "CHANNEL_UI_UPDATE" or eventName == "CHANNEL_LEFT" then
    self:UpdateChannels()
  elseif eventName == "UI_SCALE_CHANGED" then
    self.sizingFontString:SetText("00:00:00")
    self.inset = self.sizingFontString:GetUnboundedStringWidth() + 10
    self.heights = {}
  else
    self:SetIncomingType({
      type = ChatTypeGroupInverted[eventName] or "NONE",
      event = eventName,
      source = select(2, ...),
      channel = self.channelMap[select(8, ...)],
    })
    ChatFrame_OnEvent(self, eventName, ...)
  end
end

function addonTable.MessagesMonitorMixin:CleanStore(store, index)
  if #store <= index then
    return
  end
  for i = index + 1, #store do
    local data = store[i]
    if data.text:find("|K.-|k") then
      data.text = data.text:gsub("|K.-|k", addonTable.Locales.UNKNOWN)
      data.text = data.text:gsub("|HBNplayer.-|h(.-)|h", "%1")
      if data.typeInfo.source then
        data.typeInfo.source = data.typeInfo.source:gsub("|K.-|k", addonTable.Locales.UNKNOWN)
      end
    end
  end
  return #store
end

function addonTable.MessagesMonitorMixin:RegisterWidth(width)
  width = math.floor(width)
  self.widths[width] = (self.widths[width] or 0) + 1
  if self.widths[width] == 1 then
    local key = self.font .. " " .. width
    for index, height in pairs(self.heights) do
      self.sizingFontString:SetWidth(width + 0.1)
      self.sizingFontString:SetText(self.messages[index].text)
      local basicHeight = (self.sizingFontString:GetLineHeight() + self.sizingFontString:GetSpacing()) * math.max(self.sizingFontString:GetNumLines(), 1)
      local stringHeight = self.sizingFontString:GetStringHeight()
      if not self.heights[index] then
        self.heights[index] = {}
      end
      height[key] = math.max(basicHeight, stringHeight)
    end
  end
end

function addonTable.MessagesMonitorMixin:UnregisterWidth(width)
  width = math.floor(width)
  self.widths[width] = (self.widths[width] or 0) - 1

  if self.widths[width] <= 0 then
    self.widths[width] = nil
    local tail = " " .. width .. "$"
    for index, height in pairs(self.heights) do
      for key in ipairs(height) do
        if key:match(tail) then
          height[key] = nil
        end
      end
      self.heights[index] = CopyTable(height) -- Optimisation to avoid lots of nils after resizing chat frame
    end
  end
end

function addonTable.MessagesMonitorMixin:GetMessage(reverseIndex)
  local index = self.messageCount - reverseIndex + 1
  return self.messages[index]
end

function addonTable.MessagesMonitorMixin:GetMessageHeight(reverseIndex)
  local index = self.messageCount - reverseIndex + 1
  if not self.heights[index] and self.messages[index] then
    local height = {}
    self.heights[index] = height
    for width in pairs(self.widths) do
      self.sizingFontString:SetWidth(width + 0.1)
      self.sizingFontString:SetText(self.messages[index].text)
      local basicHeight = (self.sizingFontString:GetLineHeight() + self.sizingFontString:GetSpacing()) * self.sizingFontString:GetNumLines()
      local stringHeight = self.sizingFontString:GetStringHeight()
      height[self.font .. " " .. width] = math.max(basicHeight, stringHeight)
    end
  end
  return self.heights[index]
end

function addonTable.MessagesMonitorMixin:UpdateStores()
  if self.storeCount < 10000 then
    return
  end

  local newStore = {}
  for i = 1, self.storeCount - 5001 do
    table.insert(newStore, CopyTable(self.store[i]))
  end
  if CHATANATOR_MESSAGE_LOG.cleanIndex <= #newStore then
    self:CleanStore(newStore, CHATANATOR_MESSAGE_LOG.cleanIndex)
  end
  local newCurrent = {}
  for i = self.messageCount - 5000, self.messageCount do
    table.insert(newCurrent, self.store[i])
  end
  table.insert(CHATANATOR_MESSAGE_LOG.historical, {
    startTimestamp = newStore[1].timestamp,
    endTimestamp = newStore[#newStore].timestamp,
    data = C_EncodingUtil.SerializeJSON(newStore)
  })
  CHATANATOR_MESSAGE_LOG.current = newCurrent
  self.store = newCurrent
  self.storeCount = #self.store
end

function addonTable.MessagesMonitorMixin:ReduceMessages()
  if self.messageCount < 10000 then
    return
  end

  local oldMessages = self.messages
  local oldHeights = self.heights
  self.messages = {}
  self.heights = {}
  for i = 1, self.messageCount - 5001 do
    table.insert(self.messages, oldMessages[i])
    self.heights[#self.messages] = oldHeights[i]
  end
  self.messageCount = #self.messages
end

function addonTable.MessagesMonitorMixin:UpdateChannels()
  self.channelList = {} -- Used to generate channel messages in Blizzard handlers
  self.zoneChannelList = {} -- Not used in anything relevant to us, so we don't fill it
  local channelDetails = {GetChannelList()}
  if #channelDetails > 0 then
    for i = 1, #channelDetails, 3 do
      local name = channelDetails[i + 1]
      local id, fullName = GetChannelName(name)
      table.insert(self.channelList, fullName)
      table.insert(self.zoneChannelList, id)
    end
  end

  self.channelMap = {}
  self.maxDisplay = 0
  for i = 1, GetNumDisplayChannels() do
    local name, isHeader, _, channelNumber = GetChannelDisplayInfo(i)
    if not isHeader and channelNumber then
      self.channelMap[channelNumber] = name
      self.maxDisplay = math.max(self.maxDisplay, channelNumber)
    end
  end
end

function addonTable.MessagesMonitorMixin:GetChannels()
  return self.channelMap, self.maxDisplay
end

function addonTable.MessagesMonitorMixin:SetIncomingType(eventType)
  self.incomingType = eventType
end

local ignore = {
  ["ADDON"] = true,
  ["SYSTEM"] = true,
  ["DUMP"] = true,
  ["BN_INLINE_TOAST_ALERT"] = true,
}

function addonTable.MessagesMonitorMixin:ShouldLog(data)
  return not ignore[data.typeInfo.type]
end

function addonTable.MessagesMonitorMixin:AddMessage(text, r, g, b, id, _, _, _, _, Formatter)
  local data = {
    text = text,
    color = {r = r or 1, g = g or 1, b = b or 1},
    timestamp = time(),
    id = id,
    formatter = Formatter, -- Stored in case we have to uncensor a message
    typeInfo = self.incomingType or {type = "ADDON", event = "NONE", source = "CHATANATOR"},
    recordedCharacter = addonTable.Data.CharacterName or "",
  }
  self.incomingType = nil
  table.insert(self.messages, data)
  if self:ShouldLog(data) then
    self.storeCount = self.storeCount + 1
    self.store[self.storeCount] = data
  end
  table.insert(self.pending, data)
  self.messageCount = self.messageCount + 1
  self:SetScript("OnUpdate", function()
    self:SetScript("OnUpdate", nil)
    self:ReduceMessages()
    local pending = self.pending
    self.pending = {}
    addonTable.CallbackRegistry:TriggerEvent("Render", pending)

    self:UpdateStores()
  end)
end
