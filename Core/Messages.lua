---@class addonTableChatanator
local addonTable = select(2, ...)

---@class MessagesMonitorMixin: Frame
addonTable.MessagesMonitorMixin ={}

local conversionThreshold = 10000

local function GetNewLog()
  return { current = {}, historical = {}, version = 1, cleanIndex = 0}
end

function addonTable.MessagesMonitorMixin:OnLoad()
  self.font = "ChatFontNormal"
  self.widths = {}

  self.sizingFontString = self:CreateFontString(nil, "BACKGROUND", self.font)

  self.sizingFontString:SetNonSpaceWrap(true)
  self.sizingFontString:SetWordWrap(true)
  self.sizingFontString:Hide()

  self.sizingFontString:SetText("00:00:00")
  self.inset = self.sizingFontString:GetUnboundedStringWidth() + 10
  self.spacing = addonTable.Config.Get(addonTable.Config.Options.MESSAGE_SPACING)
  self.timestampFormat = addonTable.Config.Get(addonTable.Config.Options.TIMESTAMP_FORMAT)

  CHATANATOR_MESSAGE_LOG = CHATANATOR_MESSAGE_LOG or GetNewLog()
  if CHATANATOR_MESSAGE_LOG.version ~= 1 then
    CHATANATOR_MESSAGE_LOG = GetNewLog()
  end
  CHATANATOR_MESSAGE_LOG.cleanIndex = CHATANATOR_MESSAGE_LOG.cleanIndex or 0
  CHATANATOR_MESSAGE_LOG.cleanIndex = self:CleanStore(CHATANATOR_MESSAGE_LOG.current, CHATANATOR_MESSAGE_LOG.cleanIndex)

  self.store = CHATANATOR_MESSAGE_LOG.current
  self.storeCount = #self.store

  self:UpdateStores()

  self.messages = CopyTable(CHATANATOR_MESSAGE_LOG.current)
  self.newMessageStartPoint = #self.messages + 1
  self.formatters = {}
  self.messageCount = #self.messages

  self.awaitingRecorderSet = {}
  self.pending = {}

  if DEFAULT_CHAT_FRAME:GetNumMessages() > 0 then
    for i = 1, DEFAULT_CHAT_FRAME:GetNumMessages() do
      self:SetIncomingType(nil)
      local text, r, g, b = DEFAULT_CHAT_FRAME:GetMessageInfo(i)
      self:AddMessage(text, r, g, b)
    end
  end

  self.heights = {}

  self.editBox = ChatFrame1EditBox
  local events = {
    "PLAYER_LOGIN",
    "UI_SCALE_CHANGED",

    "PLAYER_ENTERING_WORLD",
    "SETTINGS_LOADED",
    "UPDATE_CHAT_COLOR",
    "UPDATE_CHAT_WINDOWS",
    "CHANNEL_UI_UPDATE",
    "CHANNEL_LEFT",
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_COMMUNITIES_CHANNEL",
    "CLUB_REMOVED",
    "UPDATE_INSTANCE_INFO",
    --"UPDATE_CHAT_COLOR_NAME_BY_CLASS",
    "CHAT_SERVER_DISCONNECTED",
    "CHAT_SERVER_RECONNECTED",
    "BN_CONNECTED",
    "BN_DISCONNECTED",
    "PLAYER_REPORT_SUBMITTED",
    "NEUTRAL_FACTION_SELECT_RESULT",
    "ALTERNATIVE_DEFAULT_LANGUAGE_CHANGED",
    "NEWCOMER_GRADUATION",
    "CHAT_REGIONAL_STATUS_CHANGED",
    "CHAT_REGIONAL_SEND_FAILED",
    "NOTIFY_CHAT_SUPPRESSED",
  }
  for _, e in ipairs(events) do
    if C_EventUtils.IsEventValid(e) then
      self:RegisterEvent(e)
    end
  end

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
    for index, message in ipairs(self.messages) do
      local id = self.formatters[index].id
      if id == lineID then
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

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    local renderNeeded = false
    if settingName == addonTable.Config.Options.MESSAGE_SPACING then
      self.spacing = addonTable.Config.Get(addonTable.Config.Options.MESSAGE_SPACING)
      renderNeeded = true
    elseif settingName == addonTable.Config.Options.TIMESTAMP_FORMAT then
      error("haven't handled this yet")
    end
    if renderNeeded and self:GetScript("OnUpdate") == nil then
      self:SetScript("OnUpdate", function()
        addonTable.CallbackRegistry:TriggerEvent("Render")
      end)
    end
  end, self)
end

function addonTable.MessagesMonitorMixin:ShowGMOTD()
  local guildID = C_Club.GetGuildClubId()
  if not guildID then
    return
  end
  local motd = C_Club.GetClubInfo(guildID).broadcast
  if motd and motd ~= "" and motd ~= self.seenMOTD then
    self.seenMOTD = motd
    local info = ChatTypeInfo["GUILD"]
		local formatted = format(GUILD_MOTD_TEMPLATE, motd)
    self:SetIncomingType({type = "GUILD", event = "GUILD_MOTD"})
		self:AddMessage(formatted, info.r, info.g, info.b, info.id)
  end
end

function addonTable.MessagesMonitorMixin:OnEvent(eventName, ...)
  if eventName == "UPDATE_CHAT_WINDOWS" or eventName == "CHANNEL_UI_UPDATE" or eventName == "CHANNEL_LEFT" then
    self:UpdateChannels()

    if not self.seenMOTD then
      self:ShowGMOTD()
    end
  elseif eventName == "UPDATE_CHAT_COLOR" then
    local group, r, g, b = ...
    if group then
      group = string.upper(group)
      if self.messageCount >= self.newMessageStartPoint then
        for i = self.newMessageStartPoint, self.messageCount do
          local data = self.messages[i]
          if data.typeInfo.type == group then
            data.color = {r = r, g = g, b = b}
          end
        end
        if self:GetScript("OnUpdate") == nil then
          self:SetScript("OnUpdate", function()
            addonTable.CallbackRegistry:TriggerEvent("Render")
          end)
        end
      end
    end
  elseif eventName == "GUILD_MOTD" then
    self:ShowGMOTD()
  elseif eventName == "UI_SCALE_CHANGED" then
    self.sizingFontString:SetText("00:00:00")
    self.inset = self.sizingFontString:GetUnboundedStringWidth() + 10
    self.heights = {}
  elseif eventName == "PLAYER_LOGIN" then
    local name, realm = UnitFullName("player")
    addonTable.Data.CharacterName = name .. "-" .. realm
    for _, data in ipairs(self.awaitingRecorderSet) do
      data.recordedBy = addonTable.Data.CharacterName
    end

    addonTable.CallbackRegistry:TriggerEvent("Render")
  else
    local channelName = self.channelMap[select(8, ...)]
    self:SetIncomingType({
      type = ChatTypeGroupInverted[eventName] or "NONE",
      event = eventName,
      player = select(2, ...),
      channel = channelName and {name = channelName, isDefault = self.defaultChannels[channelName]} or nil,
    })
    ChatFrame_OnEvent(self, eventName, ...)
  end
end

function addonTable.MessagesMonitorMixin:CleanStore(store, index)
  if #store <= index then
    return index
  end
  for i = index + 1, #store do
    local data = store[i]
    if data.text:find("|K.-|k") then
      data.text = data.text:gsub("|K.-|k", "???")
      data.text = data.text:gsub("|HBNplayer.-|h(.-)|h", "%1")
      if data.typeInfo.player then
        data.typeInfo.player = data.typeInfo.player:gsub("|K.-|k", addonTable.Locales.UNKNOWN)
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
      height[key] = math.max(basicHeight, stringHeight, self.sizingFontString:GetLineHeight())
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
      height[self.font .. " " .. width] = math.max(basicHeight, stringHeight, self.sizingFontString:GetLineHeight())
    end
  end
  return self.heights[index]
end

function addonTable.MessagesMonitorMixin:UpdateStores()
  if self.storeCount < conversionThreshold then
    return
  end

  local newStore = {}
  for i = 1, self.storeCount - conversionThreshold / 2 - 1 do
    table.insert(newStore, CopyTable(self.store[i]))
  end
  if CHATANATOR_MESSAGE_LOG.cleanIndex <= #newStore then
    self:CleanStore(newStore, CHATANATOR_MESSAGE_LOG.cleanIndex)
  end
  local newCurrent = {}
  for i = self.messageCount - conversionThreshold / 2, self.messageCount do
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
  if self.messageCount < conversionThreshold then
    return
  end

  local oldMessages = self.messages
  local oldHeights = self.heights
  local oldFormatters = self.formatters
  self.messages = {}
  self.heights = {}
  self.formatters = {}
  for i = self.messageCount - conversionThreshold / 2, self.messageCount do
    table.insert(self.messages, oldMessages[i])
    self.heights[#self.messages] = oldHeights[i]
    self.formatters[#self.messages] = oldFormatters[i]
  end
  self.newMessageStartPoint = self.newMessageStartPoint - (#oldMessages - #self.messages)
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

  self.defaultChannels = {}

  self.channelMap = {}
  self.maxDisplay = 0
  for i = 1, GetNumDisplayChannels() do
    local name, isHeader, _, channelNumber, _, _, category = GetChannelDisplayInfo(i)
    if not isHeader then
      if channelNumber then
        self.channelMap[channelNumber] = name
        self.maxDisplay = math.max(self.maxDisplay, channelNumber)
      end

      if category ~= "CHANNEL_CATEGORY_CUSTOM" or select(4, GetChannelName(name)) then
        self.defaultChannels[name] = true
      end
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
    typeInfo = self.incomingType or {type = "ADDON", event = "NONE"},
    recordedBy = addonTable.Data.CharacterName or "",
  }
  if addonTable.Data.CharacterName == nil then
    table.insert(self.awaitingRecorderSet, data)
  end
  self.incomingType = nil
  table.insert(self.messages, data)
  self.formatters[self.messageCount + 1] = {
    formatter = Formatter,
    id = id,
  }
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
