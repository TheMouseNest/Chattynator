--[[
    TwitchEmotes integration.
    Applies TwitchEmotes replacements to Chattynator-rendered messages and
    updates animated emotes inside Chattynator's custom scrolling frames.
]]
local addonTable = select(2, ...)

EventUtil.ContinueOnAddOnLoaded("TwitchEmotes", function()
  local elapsedSinceLastUpdate = 0
  local statlessMessageID = "chattynator_twitchemotes"
  local countedMessageIDs = {}
  local seededExistingMessageIDs = false

  local function SeedExistingMessageIDs()
    if seededExistingMessageIDs or not addonTable.Messages or not addonTable.Messages.messages then
      return
    end
    seededExistingMessageIDs = true

    for _, message in ipairs(addonTable.Messages.messages) do
      countedMessageIDs[message.id] = true
    end
  end

  local function CountMessageStats(data)
    SeedExistingMessageIDs()

    if countedMessageIDs[data.id] or type(UpdateEmoteStats) ~= "function" then
      return
    end
    countedMessageIDs[data.id] = true

    local senderGUID = data.playerGUID or data.typeInfo.playerGUID
    local localPlayerGUID = UnitGUID("player")
    local isSent = localPlayerGUID ~= nil and localPlayerGUID == senderGUID
    local delimiters = "%s,'<>?-%.!"

    for word in string.gmatch(data.text, "[^" .. delimiters .. "]+") do
      local emote = TwitchEmotes_emoticons[word]
      if emote and TwitchEmotes_defaultpack[emote] ~= nil then
        UpdateEmoteStats(emote, false, isSent, not isSent)
      end
    end
  end

  Emoticons_RunReplacement("", nil, statlessMessageID)

  Chattynator.API.AddModifier(function(data)
    if type(Emoticons_RunReplacement) ~= "function" then
      return
    end
    if not Emoticons_Settings[data.typeInfo.event] then
      return
    end

    CountMessageStats(data)
    data.text = Emoticons_RunReplacement(data.text, data.playerGUID or data.typeInfo.playerGUID, statlessMessageID)
  end)
  C_Timer.After(0, SeedExistingMessageIDs)

  hooksecurefunc("TwitchEmotesAnimator_OnUpdate", function(_, elapsed)
    if type(TwitchEmotesAnimator_UpdateEmoteInFontString) ~= "function" or not addonTable.allChatFrames then
      return
    end
    elapsedSinceLastUpdate = elapsedSinceLastUpdate + (elapsed or 0)
    if elapsedSinceLastUpdate < 0.033 then
      return
    end
    elapsedSinceLastUpdate = 0

    for _, chatFrame in ipairs(addonTable.allChatFrames) do
      local scrollingMessages = chatFrame.ScrollingMessages
      if chatFrame:IsShown() and scrollingMessages and scrollingMessages:IsShown() then
        for _, visibleLine in ipairs(scrollingMessages.visibleLines) do
          if visibleLine.messageInfo ~= TwitchEmotes_HoverMessageInfo then
            TwitchEmotesAnimator_UpdateEmoteInFontString(visibleLine, 28, 28)
          end
        end
      end
    end
  end)
end)
