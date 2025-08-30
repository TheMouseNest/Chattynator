---@class addonTableChattynator
local addonTable = select(2, ...)

---@class MessagesMonitorMixin: Frame
addonTable.MessagesMonitorMixin ={}

local conversionThreshold = 5000

local function GetNewLog()
  return { current = {}, historical = {}, version = 1, cleanIndex = 0}
end

local ChatTypeGroupInverted = {}

for group, values in pairs(ChatTypeGroup) do
  for _, value in pairs(values) do
    if ChatTypeGroupInverted[value] == nil then
      ChatTypeGroupInverted[value] = group
    end
  end
end

local function ConvertFormat()
  if not addonTable.Config.Get(addonTable.Config.Options.APPLIED_MESSAGE_IDS) then
    local idRoot = #CHATTYNATOR_MESSAGE_LOG.historical + 1
    for index, entry in ipairs(CHATTYNATOR_MESSAGE_LOG.current) do
      if entry.id == nil then
        entry.id = "r" .. idRoot .. "_" .. index
      end
    end
    local frame = CreateFrame("Frame")
    local historicalIndex = 1
    frame:SetScript("OnUpdate", function()
      if CHATTYNATOR_MESSAGE_LOG.historical[historicalIndex] then
        if type(CHATTYNATOR_MESSAGE_LOG.historical[historicalIndex].data) == "string" and C_EncodingUtil then
          local resolved = C_EncodingUtil.DeserializeJSON(CHATTYNATOR_MESSAGE_LOG.historical[historicalIndex].data)
          for index, entry in ipairs(resolved) do
            if entry.id == nil then
              entry.id = "r" .. historicalIndex .. "_" .. index
            end
          end
          CHATTYNATOR_MESSAGE_LOG.historical[historicalIndex].data = C_EncodingUtil.SerializeJSON(resolved)
        end
        historicalIndex = historicalIndex + 1
      else
        addonTable.Config.Set(addonTable.Config.Options.APPLIED_MESSAGE_IDS, true)
        frame:SetScript("OnUpdate", nil)
      end
    end)
  end
  if not addonTable.Config.Get(addonTable.Config.Options.APPLIED_PLAYER_TABLE) then
    for _, entry in ipairs(CHATTYNATOR_MESSAGE_LOG.current) do
      if type(entry.typeInfo.player) == "string" then
        entry.typeInfo.player = {name = entry.typeInfo.player, class = entry.typeInfo.playerClass}
        entry.player = nil
      elseif type(entry.typeInfo.player) == "table" and next(entry.typeInfo.player) == nil then
        entry.typeInfo.player = nil
      end
    end
    local frame = CreateFrame("Frame")
    local historicalIndex = 1
    frame:SetScript("OnUpdate", function()
      if CHATTYNATOR_MESSAGE_LOG.historical[historicalIndex] then
        if type(CHATTYNATOR_MESSAGE_LOG.historical[historicalIndex].data) == "string" and C_EncodingUtil then
          local resolved = C_EncodingUtil.DeserializeJSON(CHATTYNATOR_MESSAGE_LOG.historical[historicalIndex].data)
          for _, entry in ipairs(resolved) do
            if type(entry.typeInfo.player) == "string" then
              entry.typeInfo.player = {name = entry.typeInfo.player, class = entry.typeInfo.playerClass}
              entry.player = nil
            elseif type(entry.typeInfo.player) == "table" and next(entry.typeInfo.player) == nil then
              entry.typeInfo.player = nil
            end
          end
          CHATTYNATOR_MESSAGE_LOG.historical[historicalIndex].data = C_EncodingUtil.SerializeJSON(resolved)
        end
        historicalIndex = historicalIndex + 1
      else
        addonTable.Config.Set(addonTable.Config.Options.APPLIED_PLAYER_TABLE, true)
        frame:SetScript("OnUpdate", nil)
      end
    end)
  end
end

function addonTable.MessagesMonitorMixin:OnLoad()
  self.spacing = addonTable.Config.Get(addonTable.Config.Options.MESSAGE_SPACING)
  self.timestampFormat = addonTable.Config.Get(addonTable.Config.Options.TIMESTAMP_FORMAT)

  self.liveModifiers = {}

  self.fontKey = addonTable.Config.Get(addonTable.Config.Options.MESSAGE_FONT)
  self.font = addonTable.Core.GetFontByID(self.fontKey)
  self.scalingFactor = addonTable.Core.GetFontScalingFactor()
  self.widths = {}

  self.inset = 0

  self.sizingFontString = self:CreateFontString(nil, "BACKGROUND")

  self.sizingFontString:SetNonSpaceWrap(true)
  self.sizingFontString:SetWordWrap(true)
  self.sizingFontString:Hide()

  CHATTYNATOR_MESSAGE_LOG = CHATTYNATOR_MESSAGE_LOG or GetNewLog()
  if CHATTYNATOR_MESSAGE_LOG.version ~= 1 then
    CHATTYNATOR_MESSAGE_LOG = GetNewLog()
  end

  ConvertFormat()

  CHATTYNATOR_MESSAGE_LOG.cleanIndex = CHATTYNATOR_MESSAGE_LOG.cleanIndex or 0
  CHATTYNATOR_MESSAGE_LOG.cleanIndex = self:CleanStore(CHATTYNATOR_MESSAGE_LOG.current, CHATTYNATOR_MESSAGE_LOG.cleanIndex)

  self:ConfigureStore()

  self.messages = CopyTable(CHATTYNATOR_MESSAGE_LOG.current)
  self.newMessageStartPoint = #self.messages + 1
  self.formatters = {}
  self.messagesProcessed = {}
  self.messageCount = #self.messages
  self.messageIDCounter = 0

  self.awaitingRecorderSet = {}
  self.pending = 0

  if DEFAULT_CHAT_FRAME:GetNumMessages() > 0 then
    for i = 1, DEFAULT_CHAT_FRAME:GetNumMessages() do
      self:SetIncomingType(nil)
      local text, r, g, b = DEFAULT_CHAT_FRAME:GetMessageInfo(i)
      self:AddMessage(text, r, g, b)
    end
  end

  self.heights = {}

  self.defaultColors = {}

  self.editBox = ChatFrame1EditBox
  local events = {
    "PLAYER_LOGIN",
    "UI_SCALE_CHANGED",

    "PLAYER_ENTERING_WORLD",
    --"SETTINGS_LOADED", (taints)
    "UPDATE_CHAT_COLOR",
    "UPDATE_CHAT_WINDOWS",
    "CHANNEL_UI_UPDATE",
    "CHANNEL_LEFT",
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_COMMUNITIES_CHANNEL",
    "CLUB_REMOVED",
    "UPDATE_INSTANCE_INFO",
    --"UPDATE_CHAT_COLOR_NAME_BY_CLASS", (errors)
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
  self.messageTypeList = {}
  self.historyBuffer = {elements = {1}} -- Questie Compatibility

  self.channelMap = {}
  self.defaultChannels = {}
  self.maxDisplayChannels = 0

  local ignoredGroups
  if addonTable.Config.Get(addonTable.Config.Options.ENABLE_COMBAT_MESSAGES) then
    ignoredGroups = {}
  else
    ignoredGroups = {
      ["TRADESKILLS"] = true,
      ["OPENING"] = true,
      ["PET_INFO"] = true,
      ["COMBAT_MISC_INFO"] = true,
    }
  end
  for event, group in pairs(ChatTypeGroupInverted) do
    if not ignoredGroups[group] then
      self:RegisterEvent(event)
    end
  end

  hooksecurefunc(C_ChatInfo, "UncensorChatLine", function(lineID)
    local found
    for index, formatter in pairs(self.formatters) do
      if lineID == formatter.lineID then
        local message = self.messages[index]
        found = message.id
        message.text = formatter.Formatter(C_ChatInfo.GetChatLineText(lineID))
        break
      end
    end
    if found then
      self:InvalidateProcessedMessage(found)
    end
  end)

  hooksecurefunc(DEFAULT_CHAT_FRAME, "AddMessage", function(_, ...)
    local fullTrace = debugstack()
    if fullTrace:find("ChatFrame_OnEvent") then
      return
    end
    local trace = debugstack(3, 1, 0)
    if trace:find("Interface/AddOns/Chattynator") then
      return
    end

    local type, source
    if fullTrace:find("DevTools_Dump") then
      type = "DUMP"
    elseif trace:find("Interface/AddOns/Blizzard_") ~= nil and trace:find("PrintHandler") == nil then
      type = "SYSTEM"
    else
      type = "ADDON"
      local addonPath
      -- Different position based on `print` or `AddMessage`
      if trace:find("PrintHandler") ~= nil then
        addonPath = debugstack(9, 1, 0)
      else
        addonPath = debugstack(3, 1, 0)
      end
      -- Special case, AceConsole will be shared between addons
      source = addonPath:match("Interface/AddOns/([^/]+)/")
      if addonPath:find("/[Ll]ibs?/Ace") then
        source = "/aceconsole"
      elseif source == nil then
        source = "/loadstring"
      end
    end
    self:SetIncomingType({type = type, event = "NONE", source = source})
    self:AddMessage(...)
  end)
  self.DEFAULT_CHAT_FRAME_AddMessage = DEFAULT_CHAT_FRAME.AddMessage

  EventUtil.ContinueOnAddOnLoaded("oRA3", function()
    DEFAULT_CHAT_FRAME.AddMessage = self.DEFAULT_CHAT_FRAME_AddMessage
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
    ChatTypeInfo = addonTable.Config.Get(addonTable.Config.Options.CHAT_COLORS),
  }

  setmetatable(env, {__index = _G, __newindex = _G})
  setfenv(ChatFrame_MessageEventHandler, env)
  setfenv(ChatFrame_SystemEventHandler, env)
  self:SetScript("OnEvent", self.OnEvent)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    local renderNeeded = false
    if settingName == addonTable.Config.Options.MESSAGE_SPACING then
      self.spacing = addonTable.Config.Get(addonTable.Config.Options.MESSAGE_SPACING)
      renderNeeded = true
    elseif settingName == addonTable.Config.Options.TIMESTAMP_FORMAT then
      self.timestampFormat = addonTable.Config.Get(addonTable.Config.Options.TIMESTAMP_FORMAT)
      self:SetInset()
      renderNeeded = true
    elseif settingName == addonTable.Config.Options.CHAT_COLORS then
      local colors = addonTable.Config.Get(addonTable.Config.Options.CHAT_COLORS)
      for group, c in pairs(self.defaultColors) do
        if colors[group] == nil then
          colors[group] = CopyTable(c)
        end
      end
      env.ChatTypeInfo = colors
      self:ReplaceColors()
      renderNeeded = true
    elseif settingName == addonTable.Config.Options.STORE_MESSAGES then
      self:ConfigureStore()
    end
    if renderNeeded then
      addonTable.CallbackRegistry:TriggerEvent("MessageDisplayChanged")
      if self:GetScript("OnUpdate") == nil then
        self:SetScript("OnUpdate", function()
          self:SetScript("OnUpdate", nil)
          addonTable.CallbackRegistry:TriggerEvent("Render")
        end)
      end
    end
  end, self)

  addonTable.CallbackRegistry:RegisterCallback("RefreshStateChange", function(_, state)
    if state[addonTable.Constants.RefreshReason.MessageFont] then
      self.font = addonTable.Core.GetFontByID(addonTable.Config.Get(addonTable.Config.Options.MESSAGE_FONT))
      self.scalingFactor = addonTable.Core.GetFontScalingFactor()
      self:SetInset()
      self.heights = {}
      addonTable.CallbackRegistry:TriggerEvent("MessageDisplayChanged")
      if self:GetScript("OnUpdate") == nil then
        self:SetScript("OnUpdate", function()
          self:SetScript("OnUpdate", nil)
          addonTable.CallbackRegistry:TriggerEvent("Render")
        end)
      end
    elseif state[addonTable.Constants.RefreshReason.MessageColor] then
      self:ReplaceColors()
      if self:GetScript("OnUpdate") == nil then
        self:SetScript("OnUpdate", function()
          self:SetScript("OnUpdate", nil)
          addonTable.CallbackRegistry:TriggerEvent("Render")
        end)
      end
    end
  end)

  if ChatFrame_AddCommunitiesChannel then
    hooksecurefunc("ChatFrame_AddCommunitiesChannel", function()
      self:UpdateChannels()
    end)
    hooksecurefunc("ChatFrame_RemoveCommunitiesChannel", function()
      self:UpdateChannels()
    end)
  end

  -- Handle channel indexes swapping
  hooksecurefunc(C_ChatInfo, "SwapChatChannelsByChannelIndex", function()
    self:UpdateChannels()
  end)

  self:SetInset()
end

function addonTable.MessagesMonitorMixin:InvalidateProcessedMessage(id)
  for index, message in ipairs(self.messages) do
    if message.id == id then
      self.messagesProcessed[index] = nil
      self.heights[index] = nil
      addonTable.CallbackRegistry:TriggerEvent("ResetOneMessageCache", id)
      if self:GetScript("OnUpdate") == nil and self.playerLoginFired then
        self:SetScript("OnUpdate", function()
          addonTable.CallbackRegistry:TriggerEvent("Render")
        end)
      end
    end
  end
end

function addonTable.MessagesMonitorMixin:ConfigureStore()
  if addonTable.Config.Get(addonTable.Config.Options.STORE_MESSAGES) then
    self.store = CHATTYNATOR_MESSAGE_LOG.current
  else
    CHATTYNATOR_MESSAGE_LOG = GetNewLog()
    self.store = {} -- fake store to hide that messages aren't being saved
  end
  self.storeCount = #self.store
  self.storeIDRoot = #CHATTYNATOR_MESSAGE_LOG.historical

  self:UpdateStores()
end

function addonTable.MessagesMonitorMixin:SetInset()
  self.sizingFontString:SetFontObject(self.font)
  self.sizingFontString:SetTextScale(self.scalingFactor)
  if self.timestampFormat == "%X" then
    self.sizingFontString:SetText("00:00:00")
  elseif self.timestampFormat == "%H:%M" then
    self.sizingFontString:SetText("00:00")
  elseif self.timestampFormat == "%I:%M %p" then
    self.sizingFontString:SetText("00:00 mm")
  elseif self.timestampFormat == "%I:%M:%S %p" then
    self.sizingFontString:SetText("00:00:00 mm")
  elseif self.timestampFormat == " " then
    self.sizingFontString:SetText(" ")
  else
    error("unknown format")
  end
  self.inset = self.sizingFontString:GetUnboundedStringWidth() + 10
  if self.timestampFormat == " " then
    self.inset = 8
  end
end

function addonTable.MessagesMonitorMixin:ShowGMOTD()
  local guildID = C_Club.GetGuildClubId()
  if not guildID then
    return
  end
  local motd = C_Club.GetClubInfo(guildID).broadcast
  if motd and motd ~= "" and motd ~= self.seenMOTD then
    self.seenMOTD = motd
    local info = addonTable.Config.Get(addonTable.Config.Options.CHAT_COLORS)["GUILD"] or ChatTypeInfo["GUILD"]
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
  elseif eventName == "PLAYER_REGEN_ENABLED" then
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self:ReduceMessages()
    self:UpdateStores()
  elseif eventName == "UPDATE_CHAT_COLOR" then
    local group, r, g, b = ...
    local colors = addonTable.Config.Get(addonTable.Config.Options.CHAT_COLORS)
    group = group and string.upper(group)
    if group then
      self.defaultColors[group] = {r = r, g = g, b = b}
    end
    if group and not colors[group] then
      colors[group] = {r = r, g = g, b = b}
      if self.messageCount >= self.newMessageStartPoint then
        for i = self.newMessageStartPoint, self.messageCount do
          local data = self.messages[i]
          if data.typeInfo.type == group then
            data.color = {r = r, g = g, b = b}
          end
        end
        if self:GetScript("OnUpdate") == nil then
          self:SetScript("OnUpdate", function()
            self:SetScript("OnUpdate", nil)
            addonTable.CallbackRegistry:TriggerEvent("Render")
          end)
        end
      end
    end
  elseif eventName == "GUILD_MOTD" then
    self:ShowGMOTD()
  elseif eventName == "UI_SCALE_CHANGED" then
    self:SetInset()
    self.heights = {}
    addonTable.CallbackRegistry:TriggerEvent("MessageDisplayChanged")
  elseif eventName == "PLAYER_REPORT_SUBMITTED" then
    --TODO
  elseif eventName == "PLAYER_LOGIN" then
    self.playerLoginFired = true
    local oldFontKey = self.fontKey
    self.fontKey = addonTable.Config.Get(addonTable.Config.Options.MESSAGE_FONT)
    self.font = addonTable.Core.GetFontByID(self.fontKey)
    self.scalingFactor = addonTable.Core.GetFontScalingFactor()
    if oldFontKey ~= self.fontKey then
      self.heights = {}
    end
    self:SetInset()
    local name, realm = UnitFullName("player")
    addonTable.Data.CharacterName = name .. "-" .. realm
    for _, data in ipairs(self.awaitingRecorderSet) do
      data[1].recordedBy = addonTable.Data.CharacterName
      self.messagesProcessed[data[2]] = nil
    end

    self:UpdateChannels()

    addonTable.CallbackRegistry:TriggerEvent("Render")
  else
    local _, playerArg, _, _, _, _, channelID, channelIndex, _, _, lineID, playerGUID = ...
    local channelName = self.channelMap[channelIndex]
    local playerClass, playerRace, playerSex, _
    if playerGUID then
      _, playerClass, _, playerRace, playerSex = GetPlayerInfoByGUID(playerGUID)
    elseif type(playerArg) ~= "string" or playerArg == "" then
      playerArg = nil
    end
    self:SetIncomingType({
      type = ChatTypeGroupInverted[eventName] or "NONE",
      event = eventName,
      player = playerArg and {name = playerArg, class = playerClass, race = playerRace, sex = playerSex},
      channel = channelName and {name = channelName, index = channelIndex, isDefault = self.defaultChannels[channelName], zoneID = channelID} or nil,
    })
    self.lineID = lineID
    self.lockType = true
    ChatFrame_OnEvent(self, eventName, ...)
    self.lockType = false
    self.incomingType = nil
    self.lineID = nil
  end
end

function addonTable.MessagesMonitorMixin:ReplaceColors()
  self:ImportChannelColors()
  local colors = addonTable.Config.Get(addonTable.Config.Options.CHAT_COLORS)
  if self.messageCount >= self.newMessageStartPoint then
    for i = self.newMessageStartPoint, self.messageCount do
      local data = self.messages[i]
      local c = colors[data.typeInfo.type] or (data.typeInfo.channel and colors["CHANNEL" .. data.typeInfo.channel.index])
      if c then
        data.color = {r = c.r, g = c.g, b = c.b}
      end
    end
  end
  if self.storeCount >= self.newMessageStartPoint then
    for i = self.newMessageStartPoint, self.storeCount do
      local data = self.store[i]
      local c = colors[data.typeInfo.type] or (data.typeInfo.channel and colors["CHANNEL" .. data.typeInfo.channel.index])
      if c then
        data.color = {r = c.r, g = c.g, b = c.b}
      end
    end
  end
  self.messagesProcessed = {}
end

function addonTable.MessagesMonitorMixin:ImportChannelColors()
  local colors = addonTable.Config.Get(addonTable.Config.Options.CHAT_COLORS)
  for index, key in pairs(self.channelMap) do
    if colors["CHANNEL_" .. key] then
      colors["CHANNEL" .. index] = colors["CHANNEL_" .. key]
    else
      colors["CHANNEL_" .. key] = colors["CHANNEL" .. index]
    end
  end
end

function addonTable.MessagesMonitorMixin:AddLiveModifier(func)
  local index = tIndexOf(self.liveModifiers, func)
  if not index then
    self.messagesProcessed = {}
    self.heights = {}
    table.insert(self.liveModifiers, func)
    if self:GetScript("OnUpdate") == nil and self.playerLoginFired then
      self:SetScript("OnUpdate", function()
        self:SetScript("OnUpdate", nil)
        addonTable.CallbackRegistry:TriggerEvent("Render")
      end)
    end
  end
end

function addonTable.MessagesMonitorMixin:RemoveLiveModifier(func)
  local index = tIndexOf(self.liveModifiers, func)
  if index then
    self.messagesProcessed = {}
    self.heights = {}
    table.remove(self.liveModifiers, index)
    if self:GetScript("OnUpdate") == nil and self.playerLoginFired then
      self:SetScript("OnUpdate", function()
        self:SetScript("OnUpdate", nil)
        addonTable.CallbackRegistry:TriggerEvent("Render")
      end)
    end
  end
end

function addonTable.MessagesMonitorMixin:CleanStore(store, index)
  if #store <= index then
    return #store
  end
  for i = index + 1, #store do
    local data = store[i]
    if data.text:find("|K.-|k") or (data.typeInfo.player and data.typeInfo.player.name:find("|K.-|k")) then
      data.text = data.text:gsub("|K.-|k", "???")
      data.text = data.text:gsub("|HBNplayer.-|h(.-)|h", "%1")
      if data.typeInfo.player then
        data.typeInfo.player.name = data.typeInfo.player.name:gsub("|K.-|k", addonTable.Locales.UNKNOWN)
      end
    end
    if data.text:find("censoredmessage:") then
      data.text = data.text:gsub("|Hcensoredmessage:.-|h.-|h", "[" .. addonTable.Locales.CENSORED_CONTENTS_LOST .. "]")
    end
    if data.text:find("reportcensoredmessage:") then
      data.text = data.text:gsub("|Hreportcensoredmessage:.-|h.-|h", "[???]")
    end
  end
  return #store
end

function addonTable.MessagesMonitorMixin:RegisterWidth(width)
  width = math.floor(width)
  self.widths[width] = (self.widths[width] or 0) + 1
  if self.widths[width] == 1 then
    self.heights = {} -- No need to recompute, rendering will do that (other widths are low cost to reassess)
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

function addonTable.MessagesMonitorMixin:GetMessageProcessed(reverseIndex)
  local index = self.messageCount - reverseIndex + 1
  if not self.messages[index] then
    return
  end
  if self.messagesProcessed[index] then
    return self.messagesProcessed[index]
  end
  local new = CopyTable(self.messages[index])
  for _, func in ipairs(self.liveModifiers) do
    func(new)
  end
  self.heights[index] = nil
  self.messagesProcessed[index] = new
  return new
end

function addonTable.MessagesMonitorMixin:GetMessageRaw(reverseIndex)
  local index = self.messageCount - reverseIndex + 1
  return self.messages[index]
end

function addonTable.MessagesMonitorMixin:GetMessageHeight(reverseIndex)
  local index = self.messageCount - reverseIndex + 1
  if not self.heights[index] and self.messagesProcessed[index] then
    local height = {}
    self.heights[index] = height
    self.sizingFontString:SetText("")
    self.sizingFontString:SetSpacing(0)
    self.sizingFontString:SetText(self.messagesProcessed[index].text)
    for width in pairs(self.widths) do
      self.sizingFontString:SetWidth(width + 0.1)
      height[width] = self.sizingFontString:GetStringHeight()
    end
  end
  return self.heights[index]
end

function addonTable.MessagesMonitorMixin:UpdateStores()
  if self.storeCount < conversionThreshold or not addonTable.Config.Get(addonTable.Config.Options.STORE_MESSAGES) then
    return
  end
  if InCombatLockdown() then
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    return
  end

  local newStore = {}
  for i = 1, self.storeCount - conversionThreshold / 2 - 1 do
    table.insert(newStore, CopyTable(self.store[i]))
  end
  if CHATTYNATOR_MESSAGE_LOG.cleanIndex <= #newStore then
    self:CleanStore(newStore, CHATTYNATOR_MESSAGE_LOG.cleanIndex)
  end
  local newCurrent = {}
  for i = self.storeCount - conversionThreshold / 2, self.storeCount do
    table.insert(newCurrent, self.store[i])
  end
  CHATTYNATOR_MESSAGE_LOG.cleanIndex = math.max(0, math.floor(CHATTYNATOR_MESSAGE_LOG.cleanIndex - conversionThreshold / 2))
  table.insert(CHATTYNATOR_MESSAGE_LOG.historical, {
    startTimestamp = newStore[1].timestamp,
    endTimestamp = newStore[#newStore].timestamp,
    data = C_EncodingUtil and C_EncodingUtil.SerializeJSON(newStore) or {}
  })
  self.storeIDRoot = #CHATTYNATOR_MESSAGE_LOG.historical
  CHATTYNATOR_MESSAGE_LOG.current = newCurrent
  self.store = newCurrent
  self.storeCount = #self.store
end

function addonTable.MessagesMonitorMixin:ReduceMessages()
  if self.messageCount < conversionThreshold then
    return
  end
  if InCombatLockdown() then
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    return
  end

  local oldMessages = self.messages
  local oldHeights = self.heights
  local oldFormatters = self.formatters
  local oldProcessed = self.messagesProcessed
  self.messages = {}
  self.heights = {}
  self.formatters = {}
  self.messagesProcessed = {}
  for i = math.max(1, math.floor(self.messageCount - conversionThreshold / 2)), self.messageCount do
    table.insert(self.messages, oldMessages[i])
    if oldHeights[i] then
      self.heights[#self.messages] = oldHeights[i]
    end
    if oldFormatters[i] then
      self.formatters[#self.messages] = oldFormatters[i]
    end
    if oldProcessed[i] then
      self.messagesProcessed[#self.messages] = oldProcessed[i]
    end
  end
  self.newMessageStartPoint = self.newMessageStartPoint - (#oldMessages - #self.messages)
  self.messageCount = #self.messages
end

function addonTable.MessagesMonitorMixin:UpdateChannels()
  -- Setup parameters for Blizzard code to show channel messages
  self.channelList = {}
  self.zoneChannelList = {}
  local channelDetails = {GetChannelList()}
  if #channelDetails > 0 then
    for i = 1, #channelDetails, 3 do
      local name = channelDetails[i + 1]
      local _, fullName = GetChannelName(name)
      if fullName then
        local zoneID = C_ChatInfo.GetChannelInfoFromIdentifier(fullName).zoneChannelID
        table.insert(self.channelList, fullName)
        table.insert(self.zoneChannelList, zoneID)
      end
    end
  end

  self.defaultChannels = {}

  self.channelMap = {}
  self.maxDisplayChannels = 0
  for i = 1, GetNumDisplayChannels() do
    local name, isHeader, _, channelNumber, _, _, category = GetChannelDisplayInfo(i)
    if not isHeader then
      if channelNumber then
        self.channelMap[channelNumber] = name
        self.maxDisplayChannels = math.max(self.maxDisplayChannels, channelNumber)
      end

      if category ~= "CHANNEL_CATEGORY_CUSTOM" then
        self.defaultChannels[name] = true
      end
    end
  end

  for _, channelName in ipairs(self.channelList) do
    local communityIDStr, channelID = channelName:match("^Community:(%d+):(%d+)$")
    if communityIDStr then
      local index = GetChannelName(channelName)
      local clubInfo = C_Club.GetClubInfo(communityIDStr)
      local streamInfo = C_Club.GetStreamInfo(communityIDStr, channelID)
      if clubInfo and streamInfo and ChatFrame_ContainsChannel(ChatFrame1, channelName) then
        local key = clubInfo.name .. " - " .. streamInfo.name
        self.channelMap[index] = key
        self.defaultChannels[key] = true
        self.maxDisplayChannels = math.max(self.maxDisplayChannels, index)
      end
    end
  end

  self:ImportChannelColors()
end

function addonTable.MessagesMonitorMixin:GetChannels()
  return self.channelMap, self.maxDisplayChannels
end

function addonTable.MessagesMonitorMixin:SetIncomingType(eventType)
  self.incomingType = eventType
end

local ignoreTypes = {
  ["ADDON"] = true,
  ["SYSTEM"] = true,
  ["ERRORS"] = true,
  ["IGNORED"] = true,
  ["CHANNEL"] = true,
  ["DUMP"] = true,
  ["BN_INLINE_TOAST_ALERT"] = true,

  ["TRADESKILLS"] = true,
  ["OPENING"] = true,
  ["PET_INFO"] = true,
  ["COMBAT_MISC_INFO"] = true,
  ["COMBAT_XP_GAIN"] = true,
  ["COMBAT_FACTION_CHANGE"] = true,
  ["COMBAT_HONOR_GAIN"] = true,
}

local ignoreEvents = {
  ["GUILD_MOTD"] = true,
  ["CHAT_SERVER_DISCONNECTED"] = true,
  ["CHAT_SERVER_RECONNECTED"] = true,
  ["CHAT_REGIONAL_SEND_FAILED"] = true,
  ["NOTIFY_CHAT_SUPPRESSED"] = true,
  ["BN_CONNECTED"] = true,
  ["BN_DISCONNECTED"] = true,
  ["CHARACTER_POINTS_CHANGED"] = true,
  ["UPDATE_INSTANCE_INFO"] = true,
  ["CHAT_MSG_AFK"] = true,
  ["CHAT_MSG_DND"] = true,
}

function addonTable.MessagesMonitorMixin:ShouldLog(data)
  return not ignoreTypes[data.typeInfo.type] and not ignoreEvents[data.typeInfo.event] and not data.typeInfo.channel
end

function addonTable.MessagesMonitorMixin:GetFont() -- Compatibility with any emoji filters
  return self.font and _G[self.font]:GetFont()
end

function addonTable.MessagesMonitorMixin:AddMessage(text, r, g, b, _, _, _, _, _, Formatter)
  if text == "" or type(text) ~= "string" then
    if not self.lockType then
      self.incomingType = nil
    end
    return
  end

  local data = {
    text = text,
    color = {r = r or 1, g = g or 1, b = b or 1},
    timestamp = time(),
    typeInfo = self.incomingType or {type = "ADDON", event = "NONE"},
    recordedBy = addonTable.Data.CharacterName or "",
  }
  if addonTable.Data.CharacterName == nil then
    table.insert(self.awaitingRecorderSet, {data, self.messageCount + 1})
  end
  table.insert(self.messages, data)
  self.formatters[self.messageCount + 1] = {
    Formatter = Formatter,
    lineID = self.lineID,
  }
  if not self.lockType then
    self.incomingType = nil
    self.lineID = nil
  end
  if self:ShouldLog(data) then
    self.storeCount = self.storeCount + 1
    self.store[self.storeCount] = data
    data.id = "s" .. self.storeIDRoot .. "_" .. self.storeCount
  else
    data.id = "l" .. self.messageIDCounter
    self.messageIDCounter = self.messageIDCounter + 1
  end
  self.pending = self.pending + 1
  self.messageCount = self.messageCount + 1
  self:SetScript("OnUpdate", function()
    self:SetScript("OnUpdate", nil)
    self:ReduceMessages()
    local pending = self.pending
    self.pending = 0
    addonTable.CallbackRegistry:TriggerEvent("Render", pending)

    self:UpdateStores()
  end)
end
