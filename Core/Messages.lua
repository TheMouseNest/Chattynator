---@class addonTableChattynator
local addonTable = select(2, ...)

---@class MessagesMonitorMixin: Frame
addonTable.MessagesMonitorMixin ={}

local conversionThreshold = 5000
local batchLimit = 10

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
    if fullTrace:find("ChatFrame_OnEvent") or fullTrace:find("Blizzard_Channels") then
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
      self.pending = 0
      addonTable.CallbackRegistry:TriggerEvent("Render")
    elseif state[addonTable.Constants.RefreshReason.MessageColor] then
      self:ReplaceColors()
      self.pending = 0
      addonTable.CallbackRegistry:TriggerEvent("Render")
    end
  end)

  if ChatFrame_AddCommunitiesChannel then
    hooksecurefunc("ChatFrame_AddCommunitiesChannel", function()
      self:UpdateChannels()
    end)
    hooksecurefunc("ChatFrame_RemoveCommunitiesChannel", function()
      self:UpdateChannels()
    end)
  elseif ChatFrameUtil and ChatFrameUtil.AddCommunitiesChannel then
    hooksecurefunc(ChatFrameUtil, "AddCommunitiesChannel", function()
      self:UpdateChannels()
    end)
    hooksecurefunc(ChatFrameUtil, "RemoveCommunitiesChannel", function()
      self:UpdateChannels()
    end)
  end

  -- Handle channel indexes swapping
  hooksecurefunc(C_ChatInfo, "SwapChatChannelsByChannelIndex", function()
    self:UpdateChannels()
  end)

  self.defaultLanguage = GetDefaultLanguage()
  self.alternativeDefaultLanguage = GetAlternativeDefaultLanguage()
end

function addonTable.MessagesMonitorMixin:InvalidateProcessedMessage(id)
  for index, message in ipairs(self.messages) do
    if message.id == id then
      self.messagesProcessed[index] = nil
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
    self:PurgeOldMessages()
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
  self.inset = self.sizingFontString:GetUnboundedStringWidth() + 8
  if self.timestampFormat == " " then
    self.inset = 6
  end
end

function addonTable.MessagesMonitorMixin:ShowGMOTD()
  local guildID = C_Club.GetGuildClubId()
  if not guildID then
    return
  end
  local motd = C_Club.GetClubInfo(guildID).broadcast
  if motd and (issecretvalue and (not issecretvalue(motd) and motd ~= "" and motd ~= self.seenMOTD or issecretvalue(motd)) or
      not issecretvalue and motd ~= "" and motd ~= self.seenMOTD) then
    self.seenMOTD = (not issecretvalue or not issecretvalue(motd)) and motd or nil
    local info = addonTable.Config.Get(addonTable.Config.Options.CHAT_COLORS)["GUILD"] or ChatTypeInfo["GUILD"]
    local formatted = string.format(GUILD_MOTD_TEMPLATE, motd)
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
    C_Timer.After(0, function()
      addonTable.CallbackRegistry:TriggerEvent("MessageDisplayChanged")
      self.pending = 0
      addonTable.CallbackRegistry:TriggerEvent("Render")
    end)
  elseif eventName == "PLAYER_REPORT_SUBMITTED" then -- Remove messages from chat log
    if self.messageCount < self.newMessageStartPoint then
      return
    end
    local reportedGUID = ...
    local removedIDs = {}
    for index = self.messageCount, self.newMessageStartPoint, -1 do
      local m = self.messages[index]
      local guid = self.formatters[index] and self.formatters[index].playerGUID
      if guid == reportedGUID then
        removedIDs[m.id] = true
        table.remove(self.messages, index)
        self.messagesProcessed[index] = nil
        if index < self.messageCount then
          for j = index + 1, self.messageCount do
            if self.messagesProcessed[j] then
              self.messagesProcessed[j-1] = self.messagesProcessed[j]

              self.messagesProcessed[j] = nil
            end
          end
        end
        self.messageCount = self.messageCount - 1
        addonTable.CallbackRegistry:TriggerEvent("ResetOneMessageCache", m.id)
      end
    end

    if self.newMessageStartPoint > 1 then
      for index = self.storeCount, 1, -1 do
        local m = self.store[index]
        if removedIDs[m.id] then
          table.remove(self.store, index)
          self.storeCount = self.storeCount - 1
        end
      end
    end

    if self:GetScript("OnUpdate") == nil then
      self:SetScript("OnUpdate", function()
        addonTable.CallbackRegistry:TriggerEvent("Render")
      end)
    end
  elseif eventName == "PLAYER_LOGIN" then
    self.playerLoginFired = true
    local oldFontKey = self.fontKey
    self.fontKey = addonTable.Config.Get(addonTable.Config.Options.MESSAGE_FONT)
    self.font = addonTable.Core.GetFontByID(self.fontKey)
    self.scalingFactor = addonTable.Core.GetFontScalingFactor()
    local name, realm = UnitFullName("player")
    addonTable.Data.CharacterName = name .. "-" .. realm
    for _, data in ipairs(self.awaitingRecorderSet) do
      data[1].recordedBy = addonTable.Data.CharacterName
      self.messagesProcessed[data[2]] = nil
    end

    self:UpdateChannels()

    self.pending = 0
    addonTable.CallbackRegistry:TriggerEvent("Render")
  elseif eventName == "PLAYER_ENTERING_WORLD" then
    self.defaultLanguage = GetDefaultLanguage()
    self.alternativeDefaultLanguage = GetAlternativeDefaultLanguage()
    self:SetInset()
  else
    local text, playerArg, _, _, _, _, channelID, channelIndex, _, _, lineID, playerGUID = ...
    local channelName = self.channelMap[channelIndex]
    local playerClass, playerRace, playerSex, _
    if (not issecretvalue or not issecretvalue(playerGUID)) and playerGUID then
      _, playerClass, _, playerRace, playerSex = GetPlayerInfoByGUID(playerGUID)
    elseif (issecretvalue and issecretvalue(playerArg)) or type(playerArg) ~= "string" or playerArg == "" then
      playerArg = nil
    end
    self:SetIncomingType({
      type = ChatTypeGroupInverted[eventName] or "NONE",
      event = eventName,
      player = playerArg and {name = playerArg, class = playerClass, race = playerRace, sex = playerSex},
      channel = channelName and {name = channelName, index = channelIndex, isDefault = self.defaultChannels[channelName], zoneID = channelID} or nil,
    })
    self.lineID = lineID
    self.playerGUID = playerGUID
    self.lockType = true
    if not (ChatFrame_SystemEventHandler or ChatFrameMixin.SystemEventHandler)(self, eventName, ...) then
      self:MessageEventHandler(eventName, ...)
    end
    self.lockType = false
    self.incomingType = nil
    self.playerGUID = nil
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

function addonTable.MessagesMonitorMixin:GetMessageProcessed(reverseIndex)
  local index = self.messageCount - reverseIndex + 1
  if not self.messages[index] then
    return
  end
  if self.messagesProcessed[index] then
    return self.messagesProcessed[index]
  end
  local new = CopyTable(self.messages[index])
  if not issecretvalue or not issecretvalue(new.text) then
    for _, func in ipairs(self.liveModifiers) do
      func(new)
    end
  end
  self.messagesProcessed[index] = new
  return new
end

function addonTable.MessagesMonitorMixin:GetMessageRaw(reverseIndex)
  local index = self.messageCount - reverseIndex + 1
  return self.messages[index]
end

function addonTable.MessagesMonitorMixin:PurgeOldMessages()
  if addonTable.Config.Get(addonTable.Config.Options.REMOVE_OLD_MESSAGES) and #CHATTYNATOR_MESSAGE_LOG.historical > batchLimit then
    for i = 1, #CHATTYNATOR_MESSAGE_LOG.historical - batchLimit do
      CHATTYNATOR_MESSAGE_LOG.historical[i].data = {}
    end
  end
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
  self:PurgeOldMessages()
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
  local oldFormatters = self.formatters
  local oldProcessed = self.messagesProcessed
  self.messages = {}
  self.formatters = {}
  self.messagesProcessed = {}
  for i = math.max(1, math.floor(self.messageCount - conversionThreshold / 2)), self.messageCount do
    table.insert(self.messages, oldMessages[i])
    if oldFormatters[i] then
      self.formatters[#self.messages] = oldFormatters[i]
    end
    if oldProcessed[i] then
      self.messagesProcessed[#self.messages] = oldProcessed[i]
    end
  end
  self.newMessageStartPoint = math.max(1, self.newMessageStartPoint - (#oldMessages - #self.messages))
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
        if not issecretvalue or not issecretvalue(key) then
          self.channelMap[index] = key
          self.defaultChannels[key] = true
          self.maxDisplayChannels = math.max(self.maxDisplayChannels, index)
        end
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
  return not ignoreTypes[data.typeInfo.type] and not ignoreEvents[data.typeInfo.event] and not data.typeInfo.channel and (not issecretvalue or not issecretvalue(data.text))
end

function addonTable.MessagesMonitorMixin:GetFont() -- Compatibility with any emoji filters
  return self.font and _G[self.font]:GetFont()
end

function addonTable.MessagesMonitorMixin:AddMessage(text, r, g, b, _, _, _, _, _, Formatter)
  if (not issecretvalue or not issecretvalue(text)) and text == "" or type(text) ~= "string" then
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
    playerGUID = self.playerGUID,
  }
  if not self.lockType then
    self.incomingType = nil
    self.playerGUID = nil
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

local function GetDecoratedSenderName(event, ...)
  local text, senderName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, senderGUID, bnSenderID, isMobile = ...;
  local chatType = string.sub(event, 10);

  if string.find(chatType, "^WHISPER") then
    chatType = "WHISPER";
  end

  if string.find(chatType, "^CHANNEL") then
    chatType = "CHANNEL" .. channelIndex;
  end

  local chatTypeInfo = ChatTypeInfo[chatType];
  local decoratedPlayerName = senderName;

  local localizedClass, englishClass, localizedRace, englishRace, sex, firstName
  if senderGUID then
    localizedClass, englishClass, localizedRace, englishRace, sex, firstName = GetPlayerInfoByGUID(senderGUID);
  end

  local removedRealm = false
  -- Ambiguate guild chat names
  if Ambiguate and (not issecretvalue or not issecretvalue(senderName)) then
    removedRealm = true
    if chatType == "GUILD" then
      decoratedPlayerName = Ambiguate(decoratedPlayerName, "guild");
    else
      decoratedPlayerName = Ambiguate(decoratedPlayerName, "none");
    end
  elseif firstName then
    decoratedPlayerName = firstName
  end

  -- Add timerunning icon when necessary based on player guid
  if senderGUID and (not issecretvalue or not issecretvalue(senderGUID)) and C_ChatInfo.IsTimerunningPlayer(senderGUID) then
    decoratedPlayerName = TimerunningUtil.AddSmallIcon(decoratedPlayerName);
  end

  if senderGUID and chatTypeInfo and --[[ChatFrameUtil.ShouldColorChatByClass(chatTypeInfo) and]] GetPlayerInfoByGUID ~= nil then
    if englishClass then
      local classColor
      if C_ClassColor then
        classColor = C_ClassColor.GetClassColor(englishClass);
      else
        if CUSTOM_CLASS_COLORS then
          local color = CUSTOM_CLASS_COLORS[englishClass]
          classColor = CreateColor(color.r, color.g, color.b)
        else
          classColor = RAID_CLASS_COLORS[englishClass]
        end
      end

      if classColor then
        decoratedPlayerName = classColor:WrapTextInColorCode(decoratedPlayerName);
      end
    end
  end

  if ChatFrameUtil.ProcessSenderNameFilters then
    decoratedPlayerName = ChatFrameUtil.ProcessSenderNameFilters(event, decoratedPlayerName, ...);
  end
  return decoratedPlayerName;
end

local function GetPlayerLink(characterName, linkDisplayText, lineID, chatType, chatTarget)
  return string.format("|Hplayer:%s:%s:%s:%s|h%s|h", characterName, lineID or 0, chatType or 0, chatTarget or "", linkDisplayText);
end

function GetBNPlayerLink(name, linkDisplayText, bnetIDAccount, lineID, chatType, chatTarget)
  return string.format("|HBNplayer:%s:%s:%s:%s:%s|h%s|h", name, bnetIDAccount, lineID, chatType, chatTarget, linkDisplayText);
end

local function SanitizeCommunityData(clubId, streamId, epoch, position)
  if type(clubId) == "number" then
    clubId = ("%.f"):format(clubId);
  end
  if type(streamId) == "number" then
    streamId = ("%.f"):format(streamId);
  end
  epoch = ("%.f"):format(epoch);
  position = ("%.f"):format(position);

  return clubId, streamId, epoch, position;
end

local function GetBNPlayerCommunityLink(playerName, linkDisplayText, bnetIDAccount, clubId, streamId, epoch, position)
  clubId, streamId, epoch, position = SanitizeCommunityData(clubId, streamId, epoch, position);
  return string.format("|HBNplayerCommunity:%s:%s:%s:%s:%s:%s|h%s|h", playerName, bnetIDAccount, clubId, streamId, epoch, position, linkDisplayText)
end

local function GetPlayerCommunityLink(playerName, linkDisplayText, clubId, streamId, epoch, position)
  clubId, streamId, epoch, position = SanitizeCommunityData(clubId, streamId, epoch, position);
  return string.format("|HBNplayerCommunity:%s:%s:%s:%s:%s|h%s|h", playerName, clubId, streamId, epoch, position, linkDisplayText)
end

local function GetOutMessageFormatKey(chatEventSubtype, isSecret)
  local formatKey
  if isSecret and addonTable.Config.Get(addonTable.Config.Options.REDUCE_REDUNDANT_TEXT) then
    formatKey = addonTable.Modifiers.CHAT_GET[chatEventSubtype]
  end
  if not formatKey then
    formatKey = _G["CHAT_"..chatEventSubtype.."_GET"];
  end
  if isSecret and addonTable.Modifiers.ShortenPatterns then
    local pat = addonTable.Modifiers.ShortenPatterns[chatEventSubtype == "GUILD" and "guild" or addonTable.Modifiers.ShortenTypeToPattern[chatEventSubtype]]
    if pat then
      return formatKey:gsub(pat.p, pat.r, 1)
    end
  end
  assertsafe(formatKey ~= nil, "'formatKey' at _G[CHAT_%s_GET] doesn't exist.", chatEventSubtype);
  return formatKey or "";
end

local function GetCommunityAndStreamFromChannel(communityChannel)
	local clubId, streamId = communityChannel:match("(%d+)%:(%d+)");
	return tonumber(clubId), tonumber(streamId);
end

local function GetCommunityAndStreamName(clubId, streamId)
	local streamInfo = C_Club.GetStreamInfo(clubId, streamId);

	if streamInfo and (streamInfo.streamType == Enum.ClubStreamType.Guild or streamInfo.streamType == Enum.ClubStreamType.Officer) then
		return streamInfo.name;
	end

	local streamName = streamInfo and streamInfo.name or "";

	local clubInfo = C_Club.GetClubInfo(clubId);
	if streamInfo and streamInfo.streamType == Enum.ClubStreamType.General then
		local communityName = clubInfo and (clubInfo.shortName or clubInfo.name) or "";
		return communityName;
	else
		local communityName = clubInfo and (clubInfo.shortName or clubInfo.name) or "";
		return communityName.." - "..streamName;
	end
end

local function ResolveChannelName(communityChannel)
	local clubId, streamId = GetCommunityAndStreamFromChannel(communityChannel);
	if not clubId or not streamId then
		return communityChannel;
	end

	return GetCommunityAndStreamName(clubId, streamId);
end

function ResolvePrefixedChannelName(communityChannelArg)
	local prefix, communityChannel = communityChannelArg:match("(%d+. )(.*)");
	return prefix..ResolveChannelName(communityChannel);
end

local function GetChannelDecorated(zoneID, channelID, channelName, isSecret)
  local decorated = "|Hchannel:channel:"..channelID.."|h[" .. ResolvePrefixedChannelName(channelName) .. "]|h "

  if isSecret and addonTable.Modifiers.ShortenPatterns then
    return decorated:gsub(addonTable.Modifiers.ShortenPatterns.channel.p, addonTable.Modifiers.ShortenPatterns.channel.r({typeInfo = {channel = {index = channelID, zoneID = zoneID}}}), 1)
  end
  return decorated
end

local function GetChatCategory(chatType)
  return CHAT_INVERTED_CATEGORY_LIST[chatType] or chatType;
end

function GetMobileEmbeddedTexture(r, g, b)
  r, g, b = floor(r * 255), floor(g * 255), floor(b * 255);
  return format("|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat:14:14:0:0:16:16:0:16:0:16:%d:%d:%d|t", r, g, b);
end

function GetPFlag(specialFlag, zoneChannelID, localChannelID)
  if specialFlag ~= "" then
    if specialFlag == "GM" or specialFlag == "DEV" then
      -- Add Blizzard Icon if  this was sent by a GM/DEV
      return "|TInterface\\ChatFrame\\UI-ChatIcon-Blizz:12:20:0:0:32:16:4:28:0:16|t ";
    elseif specialFlag == "GUIDE" then
      if ChatFrameUtil.GetMentorChannelStatus(Enum.PlayerMentorshipStatus.Mentor, C_ChatInfo.GetChannelRulesetForChannelID(zoneChannelID)) == Enum.PlayerMentorshipStatus.Mentor then
        return NPEV2_CHAT_USER_TAG_GUIDE .. " "; -- possibly unable to save global string with trailing whitespace...
      end
    elseif specialFlag == "NEWCOMER" then
      if ChatFrameUtil.GetMentorChannelStatus(Enum.PlayerMentorshipStatus.Newcomer, C_ChatInfo.GetChannelRulesetForChannelID(zoneChannelID)) == Enum.PlayerMentorshipStatus.Newcomer then
        return NPEV2_CHAT_USER_TAG_NEWCOMER;
      end
    else
      local pflag = _G["CHAT_FLAG_"..specialFlag];
      assertsafe(pflag ~= nil, "'pflag' at _G[CHAT_FLAG_%s] doesn't exist.", specialFlag);
      return pflag or "";
    end
  end

  return "";
end

local ProcessMessageEventFilters
if ChatFrameUtil.ProcessMessageEventFilters then
  ProcessMessageEventFilters = ChatFrameUtil.ProcessMessageEventFilters
else
  ProcessMessageEventFilters = function(self, event, ...)
    local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17 = ...;
    local filter = false;
    local filters = ChatFrame_GetMessageEventFilters(event)
    if filters then
      local newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10, newarg11, newarg12, newarg13, newarg14;
      for _, filterFunc in next, filters do
        filter, newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10, newarg11, newarg12, newarg13, newarg14 = filterFunc(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14);
        if ( filter ) then
          return true;
        elseif ( newarg1 ) then
          arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14 = newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10, newarg11, newarg12, newarg13, newarg14;
        end
      end
    end
    return false, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17
  end
end

local function GetChatTarget(chatGroup, arg2, arg8)
  local chatTarget;
  if chatGroup == "CHANNEL" then
    chatTarget = tostring(arg8);
  elseif chatGroup == "WHISPER" or chatGroup == "BN_WHISPER" then
    chatTarget = arg2;
    if (not issecretvalue or not issecretvalue(arg2)) and strsub(arg2, 1, 2) ~= "|K" then
      chatTarget = strupper(arg2)
    end
  end

  return chatTarget
end

function addonTable.MessagesMonitorMixin:MessageEventHandler(event, ...)
  if strsub(event, 1, 8) ~= "CHAT_MSG" then
    return
  end

  local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17 = ...;
  if arg16 then
    -- hiding sender in letterbox: do NOT even show in chat window (only shows in cinematic frame)
    return true;
  end

  local isSecret = issecretvalue and issecretvalue(arg1)
  local playerWrapper = isSecret and addonTable.Modifiers.PlayerWrapper or "[%s]"

  local type = strsub(event, 10);
  local chatTypeInfo = addonTable.Config.Get(addonTable.Config.Options.CHAT_COLORS)
  local info = chatTypeInfo[type];

  --If it was a GM whisper, dispatch it to the GMChat addon.
  if arg6 == "GM" and type == "WHISPER" then
    return;
  end

  local shouldDiscardMessage = false;
  shouldDiscardMessage, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14
    = ProcessMessageEventFilters(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14);

  if shouldDiscardMessage then
    return true;
  end

  local coloredName = GetDecoratedSenderName(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14);

  local channelLength = strlen(arg4);
  local infoType = type;

  if type == "VOICE_TEXT" and not GetCVarBool("speechToText") then
    return;

  elseif type == "COMMUNITIES_CHANNEL"
      or strsub(type, 1, 7) == "CHANNEL" and type ~= "CHANNEL_LIST" and ((issecretvalue and issecretvalue(arg1)) or arg1 ~= "INVITE" or type ~= "CHANNEL_NOTICE_USER")
  then
    if ( (not issecretvalue or not issecretvalue(arg1)) and arg1 == "WRONG_PASSWORD" ) then
      if ( staticPopup and strupper(staticPopup.data) == strupper(arg9) ) then
        -- Don't display invalid password messages if we're going to prompt for a password (bug 102312)
        return;
      end
    end
    local newInfoType = "CHANNEL"..arg8;
    if chatTypeInfo[newInfoType] then
      infoType = newInfoType
      info = chatTypeInfo[infoType]
    end
  end

  local chatGroup = GetChatCategory(type);
  local chatTarget = GetChatTarget(chatGroup, arg2, arg8);

  if ( type == "SYSTEM" or type == "SKILL" or type == "CURRENCY" or type == "MONEY" or
      type == "OPENING" or type == "TRADESKILLS" or type == "PET_INFO" or type == "TARGETICONS" or type == "BN_WHISPER_PLAYER_OFFLINE") then
    self:AddMessage(arg1, info.r, info.g, info.b, info.id);
  elseif (type == "LOOT") then
    self:AddMessage(arg1, info.r, info.g, info.b, info.id);
  elseif ( strsub(type,1,7) == "COMBAT_" ) then
    self:AddMessage(arg1, info.r, info.g, info.b, info.id);
  elseif ( strsub(type,1,6) == "SPELL_" ) then
    self:AddMessage(arg1, info.r, info.g, info.b, info.id);
  elseif ( strsub(type,1,10) == "BG_SYSTEM_" ) then
    self:AddMessage(arg1, info.r, info.g, info.b, info.id);
  elseif ( strsub(type,1,11) == "ACHIEVEMENT" ) then
    self:AddMessage(string.format(arg1, string.format("|Hplayer:%s|h%s|h", arg2, playerWrapper:format(coloredName))), info.r, info.g, info.b, info.id);
  elseif ( strsub(type,1,18) == "GUILD_ACHIEVEMENT" ) then
    local message = string.format(arg1, string.format("|Hplayer:%s|h%s|h", arg2, playerWrapper:format(coloredName)));
    self:AddMessage(message, info.r, info.g, info.b, info.id);
  elseif (type == "PING") then
    local outMsg = arg1;
    self:AddMessage(outMsg, info.r, info.g, info.b, info.id);
  elseif ( type == "IGNORED" ) then
    self:AddMessage(string.format(CHAT_IGNORED, arg2), info.r, info.g, info.b, info.id);
  elseif ( type == "FILTERED" ) then
    self:AddMessage(string.format(CHAT_FILTERED, arg2), info.r, info.g, info.b, info.id);
  elseif ( type == "RESTRICTED" ) then
    self:AddMessage(CHAT_RESTRICTED_TRIAL, info.r, info.g, info.b, info.id);
  elseif ( type == "CHANNEL_LIST") then
    if(channelLength > 0) then
      self:AddMessage(string.format(GetOutMessageFormatKey(type, isSecret)..arg1, tonumber(arg8), arg4), info.r, info.g, info.b, info.id)
    else
      self:AddMessage(arg1, info.r, info.g, info.b, info.id);
    end
  elseif (type == "CHANNEL_NOTICE_USER") then
    if isSecret then
      return
    end
    local globalstring = _G["CHAT_"..arg1.."_NOTICE_BN"];
    if ( not globalstring ) then
      globalstring = _G["CHAT_"..arg1.."_NOTICE"];
    end
    if not globalstring then
      GMError(("Missing global string for %q"):format("CHAT_"..arg1.."_NOTICE_BN"));
      return;
    end
    if(arg5 ~= "") then
      -- TWO users in this notice (E.G. x kicked y)
      self:AddMessage(format(globalstring, arg8, arg4, arg2, arg5), info.r, info.g, info.b, info.id);
    elseif ( arg1 == "INVITE" ) then
      local playerLink = GetPlayerLink(arg2, playerWrapper:format(arg2), arg11);
      local accessID = 0
      local typeID = 0
      self:AddMessage(string.format(globalstring, arg4, playerLink), info.r, info.g, info.b, info.id, accessID, typeID);
    else
      self:AddMessage(string.format(globalstring, arg8, arg4, arg2), info.r, info.g, info.b, info.id);
    end
    if ( arg1 == "INVITE" and GetCVarBool("blockChannelInvites") ) then
      self:AddMessage(CHAT_MSG_BLOCK_CHAT_CHANNEL_INVITE, info.r, info.g, info.b, info.id);
    end
  elseif (type == "CHANNEL_NOTICE") then
    if isSecret or not tIndexOf(self.zoneChannelList, arg7) then
      return
    end

    local accessID = 0
    local typeID = 0

    if arg1 == "YOU_CHANGED" and C_ChatInfo.GetChannelRuleset and C_ChatInfo.GetChannelRuleset(arg8) == Enum.ChatChannelRuleset.Mentor then
      --self:UpdateDefaultChatTarget();
      --self.editBox:UpdateNewcomerEditBoxHint();
    else
      if arg1 == "YOU_LEFT" and self.editBox.UpdateNewcomerEditBoxHint then
        self.editBox:UpdateNewcomerEditBoxHint(arg8);
      end

      local globalstring;
      if arg1 == "TRIAL_RESTRICTED" then
        globalstring = CHAT_TRIAL_RESTRICTED_NOTICE_TRIAL;
      else
        globalstring = _G["CHAT_"..arg1.."_NOTICE_BN"];
        if ( not globalstring ) then
          globalstring = _G["CHAT_"..arg1.."_NOTICE"];
          if not globalstring then
            GMError(("Missing global string for %q"):format("CHAT_"..arg1.."_NOTICE"));
            return;
          end
        end
      end

      if channelLength > 0 then
        self:AddMessage(string.format(globalstring, arg8, (ChatFrame_ResolvePrefixedChannelName or ChatFrameUtil.ResolvePrefixedChannelName)(arg4)), info.r, info.g, info.b, info.id, accessID, typeID);
      end
    end
  elseif ( type == "BN_INLINE_TOAST_ALERT" ) then
    if isSecret then
      return
    end
    local globalstring = _G["BN_INLINE_TOAST_"..arg1];
    if not globalstring then
      GMError(("Missing global string for %q"):format("BN_INLINE_TOAST_"..arg1));
      return;
    end
    local message;
    if ( arg1 == "FRIEND_REQUEST" ) then
      message = globalstring;
    elseif ( arg1 == "FRIEND_PENDING" ) then
      message = format(BN_INLINE_TOAST_FRIEND_PENDING, BNGetNumFriendInvites());
    elseif ( arg1 == "FRIEND_REMOVED" or arg1 == "BATTLETAG_FRIEND_REMOVED" ) then
      message = format(globalstring, arg2);
    elseif ( arg1 == "FRIEND_ONLINE" or arg1 == "FRIEND_OFFLINE") then
      local accountInfo = C_BattleNet.GetAccountInfoByID(arg13);
      if accountInfo and accountInfo.gameAccountInfo.clientProgram ~= "" then
        C_Texture.GetTitleIconTexture(accountInfo.gameAccountInfo.clientProgram, Enum.TitleIconVersion.Small, function(success, texture)
          if success then
            local characterName = BNet_GetValidatedCharacterNameWithClientEmbeddedTexture(accountInfo.gameAccountInfo.characterName, accountInfo.battleTag, texture, 32, 32, 10);
            local linkDisplayText = ("[%s] (%s)"):format(arg2, characterName);
            local playerLink = GetBNPlayerLink(arg2, linkDisplayText, arg13, arg11, GetChatCategory(type), 0);
            local message = format(globalstring, playerLink);
            self:AddMessage(message, info.r, info.g, info.b, info.id);
          end
        end);
        return;
      else
        local linkDisplayText = playerWrapper:format(arg2);
        local playerLink = GetBNPlayerLink(arg2, linkDisplayText, arg13, arg11, GetChatCategory(type), 0);
        message = format(globalstring, playerLink);
      end
    else
      local linkDisplayText = playerWrapper:format(arg2);
      local playerLink = GetBNPlayerLink(arg2, linkDisplayText, arg13, arg11, GetChatCategory(type), 0);
      message = format(globalstring, playerLink);
    end
    self:AddMessage(message, info.r, info.g, info.b, info.id);
  elseif ( type == "BN_INLINE_TOAST_BROADCAST" ) then
    if ( arg1 ~= "" ) then
      if C_StringUtil and C_StringUtil.RemoveContiguousSpaces then
        arg1 = C_StringUtil.RemoveContiguousSpaces(arg1, 4)
      else
        arg1 = RemoveNewlines(RemoveExtraSpaces(arg1));
      end
      local linkDisplayText = playerWrapper:format(arg2);
      local playerLink = GetBNPlayerLink(arg2, linkDisplayText, arg13, arg11, GetChatCategory(type), 0);
      self:AddMessage(format(BN_INLINE_TOAST_BROADCAST, playerLink, arg1), info.r, info.g, info.b, info.id);
    end
  elseif ( type == "BN_INLINE_TOAST_BROADCAST_INFORM" ) then
    if ( arg1 ~= "" ) then
      if C_StringUtil and C_StringUtil.RemoveContiguousSpaces then
        arg1 = C_StringUtil.RemoveContiguousSpaces(arg1, 4)
      else
        arg1 = RemoveExtraSpaces(arg1)
      end
      self:AddMessage(BN_INLINE_TOAST_BROADCAST_INFORM, info.r, info.g, info.b, info.id);
    end
  else
    local playerName, lineID, bnetIDAccount = arg2, arg11, arg13;

    local function MessageFormatter(msg)
      local fontHeight = 14;

      -- Add AFK/DND flags
      local pflag = GetPFlag(arg6, arg7, arg8);

      if ( type == "WHISPER_INFORM" and GMChatFrame_IsGM and GMChatFrame_IsGM(arg2) ) then
        return;
      end

      local showLink = 1;
      if ( strsub(type, 1, 7) == "MONSTER" or strsub(type, 1, 9) == "RAID_BOSS") then
        showLink = nil;
      elseif C_StringUtil and C_StringUtil.EscapeLuaFormatString then
        msg = C_StringUtil.EscapeLuaFormatString(msg)
      else
        msg = string.gsub(msg, "%%", "%%%%");
      end

      -- Search for icon links and replace them with texture links.
      msg = (ChatFrame_ReplaceIconAndGroupExpressions or C_ChatInfo.ReplaceIconAndGroupExpressions)(msg, arg17, not (ChatFrame_CanChatGroupPerformExpressionExpansion or ChatFrameUtil.CanChatGroupPerformExpressionExpansion)(chatGroup)); -- If arg17 is true, don't convert to raid icons

      --Remove groups of many spaces
      if C_StringUtil and C_StringUtil.RemoveContiguousSpaces then
        msg = C_StringUtil.RemoveContiguousSpaces(msg, 4)
      else
        msg = RemoveExtraSpaces(msg);
      end

      local playerLink;
      local playerLinkDisplayText = coloredName;
      local relevantDefaultLanguage = self.defaultLanguage;
      if ( (type == "SAY") or (type == "YELL") ) then
        relevantDefaultLanguage = self.alternativeDefaultLanguage;
      end
      local usingDifferentLanguage = (arg3 ~= "") and (arg3 ~= relevantDefaultLanguage);
      local usingEmote = (type == "EMOTE") or (type == "TEXT_EMOTE");

      if ( usingDifferentLanguage or not usingEmote ) then
        playerLinkDisplayText = playerWrapper:format(coloredName);
      end

      if type == "COMMUNITIES_CHANNEL" then
        local isBattleNetCommunity = bnetIDAccount ~= nil
        local messageInfo, clubId, streamId, clubType = C_Club.GetInfoFromLastCommunityChatLine();
        if (messageInfo ~= nil) then
          if ( isBattleNetCommunity ) then
            playerLink = GetBNPlayerCommunityLink(playerName, playerLinkDisplayText, bnetIDAccount, clubId, streamId, messageInfo.messageId.epoch, messageInfo.messageId.position);
          else
            playerLink = GetPlayerCommunityLink(playerName, playerLinkDisplayText, clubId, streamId, messageInfo.messageId.epoch, messageInfo.messageId.position);
          end
        else
          playerLink = playerLinkDisplayText;
        end
      else
        if ( type == "BN_WHISPER" or type == "BN_WHISPER_INFORM" ) then
          playerLink = GetBNPlayerLink(playerName, playerLinkDisplayText, bnetIDAccount, lineID, chatGroup, chatTarget);
        else
          playerLink = GetPlayerLink(playerName, playerLinkDisplayText, lineID, chatGroup, chatTarget);
          local senderGUID = arg12;
          --[[if not usingEmote and ShouldAddRecentAllyIconToName(self.chatType, senderGUID) then
            playerLink = playerLink .. " " .. CreateAtlasMarkup("friendslist-recentallies-yellow", 11, 11);
          end]]
        end
      end

      local message = msg;
      -- isMobile
      if arg14 then
        message = GetMobileEmbeddedTexture(info.r, info.g, info.b)..message;
      end

      local outMsg;
      if ( usingDifferentLanguage ) then
        local languageHeader = "["..arg3.."] ";
        if showLink or (isSecret) or arg2 ~= "" then
          outMsg = string.format(GetOutMessageFormatKey(type, isSecret)..languageHeader..message, pflag..playerLink);
        else
          outMsg = string.format(GetOutMessageFormatKey(type, isSecret)..languageHeader..message, pflag..arg2);
        end
      else
        if not showLink or (not isSecret) and arg2 == "" then
          if ( type == "TEXT_EMOTE" ) then
            outMsg = message;
          elseif addonTable.Constants.IsClassic and not isSecret then -- Correct badly formatted message with %o instead of %s
            outMsg = string.format(GetOutMessageFormatKey(type, isSecret)..message:gsub("%%o", "%%s"), pflag .. arg2, arg2);
          else
            outMsg = string.format(GetOutMessageFormatKey(type, isSecret)..message, pflag .. arg2, arg2);
          end
        else
          if ( type == "EMOTE" ) then
            outMsg = string.format(GetOutMessageFormatKey(type, isSecret)..message, pflag .. playerLink);
          elseif ( type == "TEXT_EMOTE") then
            if not isSecret then
              outMsg = string.gsub(message, arg2, pflag..playerLink, 1);
            else
              outMsg = message
            end
          elseif (type == "GUILD_ITEM_LOOTED") then
            outMsg = string.gsub(message, "$s", GetPlayerLink(arg2, playerLinkDisplayText));
          else
            outMsg = string.format(GetOutMessageFormatKey(type, isSecret)..message, pflag..playerLink)
          end
        end
      end

      -- Add Channel
      if (channelLength > 0) then
        outMsg = GetChannelDecorated(arg7, arg8, arg4, isSecret) .. outMsg
      end

      return outMsg;
    end

    local isChatLineCensored = C_ChatInfo.IsChatLineCensored(lineID);
    local msg = isChatLineCensored and arg1 or MessageFormatter(arg1);
    local accessID = 0
    local typeID = 0

    -- The message formatter is captured so that the original message can be reformatted when a censored message
    -- is approved to be shown.
    local eventArgs = SafePack(...);
    self:AddMessage(msg, info.r, info.g, info.b, info.id, accessID, typeID, event, eventArgs, MessageFormatter);
  end

  if ( type == "WHISPER" or type == "BN_WHISPER" ) then
    --BN_WHISPER FIXME
    if not isSecret then
      (ChatEdit_SetLastTellTarget or ChatFrameUtil.SetLastTellTarget)(arg2, type);
    end

    if ( not self.tellTimer or (GetTime() > self.tellTimer) ) then
      PlaySound(SOUNDKIT.TELL_MESSAGE);
    end
    self.tellTimer = GetTime() + (CHAT_TELL_ALERT_TIME or ChatFrameConstants.WhisperSoundAlertCooldown);

    -- We don't flash the app icon for front end chat for now.
    if FlashClientIcon then
      FlashClientIcon();
    end
  end

  return true;
end
