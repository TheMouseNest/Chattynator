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
    --addon = true,
    --api = true,
    azessence = true,
    battlepet = true,
    battlePetAbil = true,
    --calendarEvent = true,
    --channel = true,
    --clubFinder = true,
    --clubTicket = true,
    community = true,
    conduit = true,
    currency = true,
    --death = true,
    --dungeonScore = true,
    enchant = true,
    garrfollower = true,
    garrfollowerability = true,
    garrmission = true,
    instancelock = true,
    item = true,
    journal = true,
    keystone = true,
    --levelup = true,
    --lootHistory = true,
    mawpower = true,
    outfit = true,
    --player = true,
    --playerCommunity = true,
    --BNplayer = true,
    --BNplayerCommunity = true,
    quest = true,
    spell = true,
    --storecategory = true,
    talent = true,
    --talentbuild = true,
    transmogappearance = true,
    transmogillusion = true,
    transmogset = true,
    --unit = true,
    --urlIndex = true,
    --worldmap = true,
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
  for id, window in ipairs(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)) do
    local chatFrame = CreateFrame("Frame", nil, ChattynatorHyperlinkHandler)
    chatFrame:SetID(id)
    if id == 1 then
      addonTable.ChatFrame = chatFrame
    end
    Mixin(chatFrame, addonTable.ChatFrameMixin)
    chatFrame:OnLoad()
    chatFrame:Show()
    table.insert(addonTable.allChatFrames, chatFrame)
  end

  addonTable.Core.ApplyOverrides()
  addonTable.CustomiseDialog.Initialize()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, eventName, data)
  if eventName == "ADDON_LOADED" and data == "Chattynator" then
    addonTable.Core.Initialize()
  end
end)
