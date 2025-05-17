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
end

function addonTable.ChatFrameMixin:RegisterForChat()
  self:RegisterEvent("PLAYER_ENTERING_WORLD");
  self:RegisterEvent("SETTINGS_LOADED");
  --self:RegisterEvent("UPDATE_CHAT_COLOR");
  --self:RegisterEvent("UPDATE_CHAT_WINDOWS");
  self:RegisterEvent("CHAT_MSG_CHANNEL");
  self:RegisterEvent("CHAT_MSG_COMMUNITIES_CHANNEL");
  self:RegisterEvent("CLUB_REMOVED");
  self:RegisterEvent("UPDATE_INSTANCE_INFO");
  --self:RegisterEvent("UPDATE_CHAT_COLOR_NAME_BY_CLASS");
  self:RegisterEvent("CHAT_SERVER_DISCONNECTED");
  self:RegisterEvent("CHAT_SERVER_RECONNECTED");
  self:RegisterEvent("BN_CONNECTED");
  self:RegisterEvent("BN_DISCONNECTED");
  self:RegisterEvent("PLAYER_REPORT_SUBMITTED");
  self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT");
  self:RegisterEvent("ALTERNATIVE_DEFAULT_LANGUAGE_CHANGED");
  self:RegisterEvent("NEWCOMER_GRADUATION");
  self:RegisterEvent("CHAT_REGIONAL_STATUS_CHANGED");
  self:RegisterEvent("CHAT_REGIONAL_SEND_FAILED");
  self:RegisterEvent("NOTIFY_CHAT_SUPPRESSED");

  self.channelList = {}
  self.zoneChannelList = {}
  local channelDetails = {GetChannelList()}
  if #channelDetails > 0 then
    for i = 1, #channelDetails, 3 do
      local name = channelDetails[i + 1]
      table.insert(self.channelList, name)
      local category = select(7, GetChannelDisplayInfo(channelDetails[1]))
      if category == "CHANNEL_CATEGORY_WORLD" then
        table.insert(self.zoneChannelList, name)
      end
    end
  end

  for type, values in pairs(ChatTypeGroup) do
    if type ~= "TRADESKILLS" then
      for _, event in ipairs(values) do
        self:RegisterEvent(event)
      end
    end
  end

  hooksecurefunc(DEFAULT_CHAT_FRAME, "AddMessage", function(_, ...)
    if debugstack():find("ChatFrame_OnEvent") then
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

  local env = {GetChatTimestampFormat = function() return nil end, FCFManager_ShouldSuppressMessage = function() return false end}
  setmetatable(env, {__index = _G, __newindex = _G})
  setfenv(ChatFrame_MessageEventHandler, env)
  self:SetScript("OnEvent", function(_, eventType, ...)
    self:SetIncomingType({type = eventType, source = select(2, ...)})
    ChatFrame_OnEvent(self, eventType, ...)
  end)
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

function addonTable.ChatFrameMixin:AddMessage(text, r, g, b, id)
  local data = {
    text = text,
    color = CreateColor(r or 1, g or 1, b or 1),
    timestamp = time(),
    id = id,
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
