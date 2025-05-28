---@class addonTableChattynator
local addonTable = select(2, ...)

addonTable.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
addonTable.CallbackRegistry:OnLoad()
addonTable.CallbackRegistry:GenerateCallbackEvents(addonTable.Constants.Events)

function addonTable.Core.MigrateSettings()
  for _, window in ipairs(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)) do
    window.tabs = tFilter(window.tabs, function(t) return not t.isTemporary end, true)
    for _, tab in ipairs(window.tabs) do
      tab.filters = tab.filters or {}
      tab.whispersTemp = {}
    end
  end
end

local hidden = CreateFrame("Frame")
hidden:Hide()
addonTable.hiddenFrame = hidden

local offscreen = CreateFrame("Frame")
offscreen:SetPoint("TOPLEFT", UIParent, "TOPRIGHT")
addonTable.offscreenFrame = hidden

function addonTable.Core.Initialize()
  addonTable.Config.InitializeData()
  addonTable.Core.MigrateSettings()

  addonTable.SlashCmd.Initialize()

  local validLinks = {
    achievement = true,
    api = false,
    battlepet = false,
    battlePetAbil = false,
    calendarEvent = false,
    channel = false,
    clubFinder = false,
    clubTicket = false,
    community = false,
    conduit = true,
    currency = true,
    death = false,
    dungeonScore = false,
    enchant = false,
    garrfollower = false,
    garrfollowerability = false,
    garrmission = false,
    instancelock = true,
    item = true,
    journal = false,
    keystone = true,
    levelup = false,
    lootHistory = false,
    mawpower = true,
    outfit = false,
    player = false,
    playerCommunity = false,
    BNplayer = false,
    BNplayerCommunity = false,
    quest = true,
    shareachieve = false,
    shareitem = false,
    sharess = false,
    spell = true,
    storecategory = false,
    talent = true,
    talentbuild = false,
    trade = false,
    transmogappearance = false,
    transmogillusion = false,
    transmogset = false,
    unit = true,
    urlIndex = false,
    worldmap = false,
  }

  ChattynatorHyperlinkHandler:SetScript("OnHyperlinkEnter", function(_, hyperlink)
    local type = hyperlink:match("^(.-):")
    if validLinks[type] then
      GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR_RIGHT")
      GameTooltip:SetHyperlink(hyperlink)
      GameTooltip:Show()
    end
  end)

  ChattynatorHyperlinkHandler:SetScript("OnHyperlinkLeave", function()
    GameTooltip:Hide()
  end)

  addonTable.Messages = CreateFrame("Frame", nil, UIParent)
  Mixin(addonTable.Messages, addonTable.MessagesMonitorMixin)
  addonTable.Messages:OnLoad()

  addonTable.Skins.Initialize()

  addonTable.allChatFrames = {}
  addonTable.ChatFramePool = CreateFramePool("Frame", ChattynatorHyperlinkHandler, nil, nil, false, function(frame)
    if not frame.OnLoad then
      Mixin(frame, addonTable.ChatFrameMixin)
      frame:OnLoad()
    end
  end)
  for id, window in pairs(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)) do
    local chatFrame = addonTable.ChatFramePool:Acquire()
    chatFrame:SetID(id)
    chatFrame:Reset()
    chatFrame:Show()
    table.insert(addonTable.allChatFrames, chatFrame)
  end

  addonTable.Core.ApplyOverrides()
  addonTable.CustomiseDialog.Initialize()
end

function addonTable.Core.MakeChatFrame()
  local newChatFrame = addonTable.ChatFramePool:Acquire()
  table.insert(addonTable.allChatFrames, newChatFrame)
  local windows = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)
  local newConfig = addonTable.Config.GetEmptyWindowConfig()
  table.insert(newConfig.tabs, addonTable.Config.GetEmptyTabConfig(GENERAL))
  table.insert(windows, newConfig)
  newChatFrame:SetID(#windows)
  newChatFrame:Show()

  return newChatFrame
end

function addonTable.Core.DeleteChatFrame(id)
  addonTable.allChatFrames[id]:SetID(0)
  addonTable.ChatFramePool:Release(addonTable.allChatFrames[id])
  table.remove(addonTable.Config.Get(addonTable.Config.Options.WINDOWS), id)
  table.remove(addonTable.allChatFrames, id)
  for index, frame in ipairs(addonTable.allChatFrames) do
    frame:SetID(index)
  end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, eventName, data)
  if eventName == "ADDON_LOADED" and data == "Chattynator" then
    addonTable.Core.Initialize()
  end
end)
