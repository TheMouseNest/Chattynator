---@class addonTableChattynator
local addonTable = select(2, ...)

addonTable.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
addonTable.CallbackRegistry:OnLoad()
addonTable.CallbackRegistry:GenerateCallbackEvents(addonTable.Constants.Events)

function addonTable.Core.MigrateSettings()
  local windowsToRemove = {}
  local allWindows = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)
  for index, window in ipairs(allWindows) do
    window.tabs = tFilter(window.tabs, function(t) return not t.isTemporary end, true)
    for _, tab in ipairs(window.tabs) do
      tab.filters = tab.filters or {}
      tab.whispersTemp = {}
      tab.addons = tab.addons or {}
    end
    if #window.tabs == 0 then
      table.insert(windowsToRemove, index)
    end
  end
  if #windowsToRemove > 0 then
    for i = #windowsToRemove, 1, -1 do
      table.remove(allWindows, windowsToRemove[i])
    end
  end
  local buttonPositionMap = {
    left_always = "outside_left",
    left_hover = "inside_left",
    top_hover = "inside_tabs",
  }
  local position = addonTable.Config.Get(addonTable.Config.Options.BUTTON_POSITION)
  if buttonPositionMap[position] then
    addonTable.Config.Set(addonTable.Config.Options.BUTTON_POSITION, buttonPositionMap[position])
    if position:match("hover") then
      addonTable.Config.Set(addonTable.Config.Options.SHOW_BUTTONS_ON_HOVER, true)
    end
  end
  if addonTable.Config.Get(addonTable.Config.Options.SHOW_BUTTONS) == "unset" then
    addonTable.Config.Set(addonTable.Config.Options.SHOW_BUTTONS, addonTable.Config.Get("show_buttons_on_hover") and "hover" or "always")
  end
  if addonTable.Config.Get(addonTable.Config.Options.COMBAT_LOG_MIGRATION) == 0 then
    if addonTable.Config.Get(addonTable.Config.Options.SHOW_COMBAT_LOG) then
      local blank = addonTable.Config.GetEmptyTabConfig("COMBAT_LOG")
      blank.backgroundColor = "262626"
      blank.tabColor = "c97c48"
      blank.custom = "combat_log"
      table.insert(allWindows[1].tabs, blank)
    end
    addonTable.Config.Set(addonTable.Config.Options.COMBAT_LOG_MIGRATION, 1)
  end
  addonTable.Skins.InstallOptions()
end

local incompatibleAddons = {
  "Prat-3.0",
  "BasicChatMods",
  "alaChat",
  "Chatter",
  "DejaChat",
  "ls_Glass",
  "XanChat",
  "MinimalistChat",
}

function addonTable.Core.CompatibilityWarnings()
  for _, addon in ipairs(incompatibleAddons) do
    if C_AddOns.IsAddOnLoaded(addon) then
      local _, title = C_AddOns.GetAddOnInfo(addon)
      local text =  addonTable.Locales.DISABLE_ADDON_X:format(title)
      addonTable.Utilities.Message(text)
      addonTable.Dialogs.ShowConfirm(text, DISABLE, IGNORE, function()
        C_AddOns.DisableAddOn(addon, UnitGUID("player"))
        ReloadUI()
      end)
      break
    end
  end
end

local hidden = CreateFrame("Frame")
hidden:Hide()
addonTable.hiddenFrame = hidden

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
    dungeonScore = true,
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
      GameTooltip:SetOwner(ChattynatorHyperlinkHandler:GetParent(), "ANCHOR_CURSOR_RIGHT")
      GameTooltip:SetHyperlink(hyperlink)
      GameTooltip:Show()
    end
  end)

  ChattynatorHyperlinkHandler:SetScript("OnHyperlinkLeave", function()
    GameTooltip:Hide()
  end)

  addonTable.Messages = CreateFrame("Frame")
  Mixin(addonTable.Messages, addonTable.MessagesMonitorMixin)
  addonTable.Messages:OnLoad()

  addonTable.Skins.Initialize()

  addonTable.allChatFrames = {}
  addonTable.ChatFramePool = CreateFramePool("Frame", ChattynatorHyperlinkHandler, nil, nil, false, function(frame)
    if not frame.OnLoad then
      Mixin(frame, addonTable.Display.ChatFrameMixin)
      frame:OnLoad()
    end
  end)
  for id, _ in pairs(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)) do
    local chatFrame = addonTable.ChatFramePool:Acquire()
    chatFrame:SetID(id)
    chatFrame:Reset()
    chatFrame:Show()
    table.insert(addonTable.allChatFrames, chatFrame)
  end

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.WINDOWS then
      local windows = addonTable.Config.Get(settingName)
      while #windows > #addonTable.allChatFrames do
        local chatFrame = addonTable.ChatFramePool:Acquire()
        chatFrame:SetID(#addonTable.allChatFrames + 1)
        chatFrame:Reset()
        chatFrame:Show()
        table.insert(addonTable.allChatFrames, chatFrame)
      end
    end
  end)

  addonTable.CopyFrame = CreateFrame("Frame", "ChattynatorCopyChatDialog", UIParent, "ButtonFrameTemplate")
  Mixin(addonTable.CopyFrame, addonTable.Display.CopyChatMixin)
  addonTable.CopyFrame:OnLoad()

  SlashCmdList["ChattynatorCopy"] = function()
    if not addonTable.allChatFrames[1] then
      return
    end
    if addonTable.CopyFrame:IsShown() then
      addonTable.CopyFrame:Hide()
    end
    addonTable.CopyFrame:LoadMessages(addonTable.allChatFrames[1].ScrollingMessages.filterFunc, addonTable.allChatFrames[1].ScrollingMessages.startingIndex)
  end
  SLASH_ChattynatorCopy1 = "/copy"

  addonTable.Core.ApplyOverrides()
  addonTable.Core.InitializeChatCommandLogging()
  addonTable.Modifiers.InitializeShortenChannels()
  addonTable.Modifiers.InitializeClassColors()
  addonTable.Modifiers.InitializeURLs()
  addonTable.Modifiers.InitializeRedundantText()
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
  addonTable.Core.ReleaseClosedChatFrame(id)
  table.remove(addonTable.Config.Get(addonTable.Config.Options.WINDOWS), id)
  for index, frame in ipairs(addonTable.allChatFrames) do
    frame:SetID(index)
  end
end

function addonTable.Core.ReleaseClosedChatFrame(id)
  addonTable.allChatFrames[id]:SetID(0)
  addonTable.ChatFramePool:Release(addonTable.allChatFrames[id])
  table.remove(addonTable.allChatFrames, id)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, eventName, data)
  if eventName == "ADDON_LOADED" and data == "Chattynator" then
    addonTable.Core.Initialize()
    addonTable.API.Initialize()
  elseif eventName == "PLAYER_LOGIN" then
    C_Timer.After(1, addonTable.Core.CompatibilityWarnings)
    addonTable.allChatFrames[1]:UpdateEditBox()
  end
end)
