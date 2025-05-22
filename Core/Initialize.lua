---@class addonTableChatanator
local addonTable = select(2, ...)

addonTable.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
addonTable.CallbackRegistry:OnLoad()
addonTable.CallbackRegistry:GenerateCallbackEvents(addonTable.Constants.Events)

function addonTable.Core.MigrateSettings()
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

  ChatanatorHyperlinkHandler:SetScript("OnHyperlinkEnter", function(_, hyperlink)
    if hyperlink:match("battlepet:") or hyperlink:match("item:") then
      GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR_RIGHT")
      GameTooltip:SetHyperlink(hyperlink)
      GameTooltip:Show()
    end
  end)

  ChatanatorHyperlinkHandler:SetScript("OnHyperlinkLeave", function()
    GameTooltip:Hide()
  end)

  addonTable.Messages = CreateFrame("Frame", nil, UIParent)
  Mixin(addonTable.Messages, addonTable.MessagesMonitorMixin)
  addonTable.Messages:OnLoad()

  addonTable.Skins.Initialize()

  for id, window in ipairs(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)) do
    local chatFrame = CreateFrame("Frame", nil, ChatanatorHyperlinkHandler)
    chatFrame:SetID(id)
    if id == 1 then
      addonTable.ChatFrame = chatFrame
    end
    Mixin(chatFrame, addonTable.ChatFrameMixin)
    chatFrame:OnLoad()
    chatFrame:Show()
    addonTable.Core.InitializeTabs(chatFrame)
  end

  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", function()
    C_Timer.After(0, function()
      FloatingChatFrameManager:UnregisterAllEvents()
      for _, tabName in pairs(CHAT_FRAMES) do
        local tab = _G[tabName]
        tab:SetParent(hidden)
        if tabName ~= "ChatFrame2" then
          tab:UnregisterAllEvents()
          tab:RegisterEvent("UPDATE_CHAT_COLOR") -- Needed to prevent errors in OnUpdate from UIParent
        end
        local tabButton = _G[tabName .. "Tab"]
        tabButton:SetParent(hidden)
        local SetParent = tabButton.SetParent
        hooksecurefunc(tabButton, "SetParent", function(self) SetParent(self, hidden) end)
      end
    end)
  end)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, eventName, data)
  if eventName == "ADDON_LOADED" and data == "Chatanator" then
    addonTable.Core.Initialize()
  elseif eventName == "PLAYER_LOGIN" then
    local name, realm = UnitFullName("player")
    addonTable.Data.CharacterName = name .. "-" .. realm

    addonTable.ChatFrame:Render()
  end
end)
