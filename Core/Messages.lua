---@class addonTableChatanator
local addonTable = select(2, ...)

---@class MessagesMonitorMixin: Frame
addonTable.MessagesMonitorMixin ={}

function addonTable.MessagesMonitorMixin:OnLoad()
  self.font = "ChatFontNormal"
  self.widths = {}

  self.sizingFontString = self:CreateFontString(nil, "BACKGROUND", self.font)

  self.sizingFontString:SetText("00:00:00")
  self.sizingFontString:SetNonSpaceWrap(true)
  self.sizingFontString:SetWordWrap(true)
  self.inset = self.sizingFontString:GetUnboundedStringWidth() + 20

  self.sizingFontString:Hide()

  self.messages = {}
  self.pending = {}

  self:RegisterEvent("PLAYER_ENTERING_WORLD")
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

  for event in pairs(ChatTypeGroupInverted) do
    self:RegisterEvent(event)
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

    local isBlizzard = trace:find("Interface/AddOns/Blizzard_") ~= nil and trace:find("PrintHandler") == nil
    self:SetIncomingType({type = isBlizzard and "SYSTEM" or "ADDON", event = "NONE"})
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
  self.editBox = ChatFrame1EditBox

  setmetatable(env, {__index = _G, __newindex = _G})
  setfenv(ChatFrame_MessageEventHandler, env)
  self:SetScript("OnEvent", function(_, eventType, ...)
    if eventType == "UPDATE_CHAT_WINDOWS" or eventType == "CHANNEL_UI_UPDATE" or eventType == "CHANNEL_LEFT" then
      self:UpdateChannels()
    else
      self:SetIncomingType({
        type = ChatTypeGroupInverted[eventType] or "NONE",
        event = eventType,
        source = select(2, ...),
        channel = self.channelMap[select(8, ...)],
      })
      ChatFrame_OnEvent(self, eventType, ...)
    end
  end)
end

function addonTable.MessagesMonitorMixin:RegisterWidth(width)
  width = math.floor(width)
  self.widths[width] = (self.widths[width] or 0) + 1
  if self.widths[width] == 1 then
    local key = self.font .. " " .. width
    for _, data in ipairs(self.messages) do
      self.sizingFontString:SetWidth(width)
      self.sizingFontString:SetText(data.text)
      local basicHeight = (self.sizingFontString:GetLineHeight() + self.sizingFontString:GetSpacing()) * self.sizingFontString:GetNumLines()
      local stringHeight = self.sizingFontString:GetStringHeight()
      data.height[key] = math.max(basicHeight, stringHeight)
    end
  end
end

function addonTable.MessagesMonitorMixin:UnregisterWidth(width)
  width = math.floor(width)
  self.widths[width] = (self.widths[width] or 0) - 1

  if self.widths[width] <= 0 then
    self.widths[width] = nil
    local tail = " " .. width .. "$"
    for _, data in ipairs(self.messages) do
      for key in ipairs(data.height) do
        if key:match(tail) then
          data.height[key] = nil
        end
      end
    end
  end
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
  for i = 1, GetNumDisplayChannels() do
    local name, isHeader, _, channelNumber = GetChannelDisplayInfo(i)
    if not isHeader and channelNumber then
      self.channelMap[channelNumber] = name
    end
  end
end

function addonTable.MessagesMonitorMixin:SetIncomingType(eventType)
  self.incomingType = eventType
end

function addonTable.MessagesMonitorMixin:AddMessage(text, r, g, b, id, _, _, _, _, Formatter)
  local data = {
    text = text,
    color = CreateColor(r or 1, g or 1, b or 1),
    timestamp = time(),
    id = id,
    formatter = Formatter, -- Stored in case we have to uncensor a message
    typeInfo = self.incomingType or {type = "ADDON", event = "NONE", source = "CHATANATOR"},
  }
  self.incomingType = nil
  data.height = {}
  for width in pairs(self.widths) do
    self.sizingFontString:SetWidth(width)
    self.sizingFontString:SetText(data.text)
    local basicHeight = (self.sizingFontString:GetLineHeight() + self.sizingFontString:GetSpacing()) * self.sizingFontString:GetNumLines()
    local stringHeight = self.sizingFontString:GetStringHeight()
    data.height[self.font .. " " .. width] = math.max(basicHeight, stringHeight)
  end
  table.insert(self.messages, data)
  table.insert(self.pending, data)
  self:SetScript("OnUpdate", function()
    self:SetScript("OnUpdate", nil)
    local pending = self.pending
    addonTable.CallbackRegistry:TriggerEvent("Render", pending)
  end)
end
