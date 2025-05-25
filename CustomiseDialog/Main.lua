---@class addonTableChatanator
local addonTable = select(2, ...)

local customisers = {}
local filtersToRefresh = {}
addonTable.CallbackRegistry:RegisterCallback("TabSelected", function(_, windowIndex, tabIndex)
  for _, frame in ipairs(filtersToRefresh) do
    if frame and frame:IsShown() and windowIndex == 1 then
      frame:ShowSettings(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[1].tabs[addonTable.allChatFrames[1].tabIndex])
    end
  end
end)

local function SetupGeneral(parent)
  local container = CreateFrame("Frame", nil, parent)

  local allFrames = {}
  local infoInset = CreateFrame("Frame", nil, container, "InsetFrameTemplate")
  do
    table.insert(allFrames, infoInset)
    infoInset:SetPoint("TOP")
    infoInset:SetPoint("LEFT", 20, 0)
    infoInset:SetPoint("RIGHT", -20, 0)
    infoInset:SetHeight(75)
    addonTable.Skins.AddFrame("InsetFrame", infoInset)

    local logo = infoInset:CreateTexture(nil, "ARTWORK")
    logo:SetTexture("Interface\\AddOns\\Chatanator\\Assets\\Logo.png")
    logo:SetSize(52, 52)
    logo:SetPoint("LEFT", 8, 0)

    local name = infoInset:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    name:SetText(addonTable.Locales.CHATANATOR)
    name:SetPoint("TOPLEFT", logo, "TOPRIGHT", 10, 0)

    local credit = infoInset:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    credit:SetText(addonTable.Locales.BY_PLUSMOUSE)
    credit:SetPoint("BOTTOMLEFT", name, "BOTTOMRIGHT", 5, 0)

    local discordLinkDialog = "Chatanator_General_Settings_Discord_Dialog"
    StaticPopupDialogs[discordLinkDialog] = {
      text = addonTable.Locales.CTRL_C_TO_COPY,
      button1 = DONE,
      hasEditBox = 1,
      OnShow = function(self)
        self.editBox:SetText("https://discord.gg/3MpPfcP5c5")
        self.editBox:HighlightText()
      end,
      EditBoxOnEnterPressed = function(self)
        self:GetParent():Hide()
      end,
      EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
      editBoxWidth = 230,
      timeout = 0,
      hideOnEscape = 1,
    }
    local discordButton = CreateFrame("Button", nil, infoInset, "UIPanelDynamicResizeButtonTemplate")
    discordButton:SetText(addonTable.Locales.JOIN_THE_DISCORD)
    DynamicResizeButton_Resize(discordButton)
    discordButton:SetPoint("BOTTOMLEFT", logo, "BOTTOMRIGHT", 8, 0)
    discordButton:SetScript("OnClick", function()
      StaticPopup_Show(discordLinkDialog)
    end)
    addonTable.Skins.AddFrame("Button", discordButton)
    local discordText = infoInset:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    discordText:SetPoint("LEFT", discordButton, "RIGHT", 10, 0)
    discordText:SetText(addonTable.Locales.DISCORD_DESCRIPTION)
  end

  do
    local header = addonTable.CustomiseDialog.Components.GetHeader(container, addonTable.Locales.DEVELOPMENT_IS_TIME_CONSUMING)
    header:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -30)
    table.insert(allFrames, header)

    local donateFrame = CreateFrame("Frame", nil, container)
    donateFrame:SetPoint("LEFT")
    donateFrame:SetPoint("RIGHT")
    donateFrame:SetPoint("TOP", allFrames[#allFrames], "BOTTOM")
    donateFrame:SetHeight(40)
    local text = donateFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("RIGHT", donateFrame, "CENTER", -50, 0)
    text:SetText(addonTable.Locales.DONATE)
    text:SetJustifyH("RIGHT")

    local donateLinkDialog = "Baganator_General_Settings_Donate_Dialog"
    StaticPopupDialogs[donateLinkDialog] = {
      text = addonTable.Locales.CTRL_C_TO_COPY,
      button1 = DONE,
      hasEditBox = 1,
      OnShow = function(self)
        self.editBox:SetText("https://linktr.ee/plusmouse")
        self.editBox:HighlightText()
      end,
      EditBoxOnEnterPressed = function(self)
        self:GetParent():Hide()
      end,
      EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
      editBoxWidth = 230,
      timeout = 0,
      hideOnEscape = 1,
    }

    local button = CreateFrame("Button", nil, donateFrame, "UIPanelDynamicResizeButtonTemplate")
    button:SetText(addonTable.Locales.LINK)
    DynamicResizeButton_Resize(button)
    button:SetPoint("LEFT", donateFrame, "CENTER", -35, 0)
    button:SetScript("OnClick", function()
      StaticPopup_Show(donateLinkDialog)
    end)
    addonTable.Skins.AddFrame("Button", button)
    table.insert(allFrames, donateFrame)
  end

  local showCombatLog = addonTable.CustomiseDialog.Components.GetCheckbox(container, addonTable.Locales.SHOW_COMBAT_LOG, 30, function(state)
    addonTable.Config.Set(addonTable.Config.Options.SHOW_COMBAT_LOG, state)
  end)
  showCombatLog.option = addonTable.Config.Options.SHOW_COMBAT_LOG
  showCombatLog:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -30)
  table.insert(allFrames, showCombatLog)

  local locked = addonTable.CustomiseDialog.Components.GetCheckbox(container, addonTable.Locales.LOCK_CHAT_POSITION, 30, function(state)
    addonTable.Config.Set(addonTable.Config.Options.LOCKED, state)
  end)
  locked.option = addonTable.Config.Options.LOCKED
  locked:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, 0)
  table.insert(allFrames, locked)

  container:SetScript("OnShow", function()
    for _, f in ipairs(allFrames) do
      if f.SetValue then
        f:SetValue(addonTable.Config.Get(f.option))
      end
    end
  end)

  return container
end

local function SetupFilters(parent)
  local filters = addonTable.CustomiseDialog.SetupTabFilters(parent)

  table.insert(filtersToRefresh, filters)

  filters:ShowSettings(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[1].tabs[addonTable.allChatFrames[1].tabIndex])

  filters:HookScript("OnShow", function()
    filters:ShowSettings(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[1].tabs[addonTable.allChatFrames[1].tabIndex])
  end)

  return filters
end

local TabSetups = {
  {name = GENERAL, callback = SetupGeneral},
  {name = FILTERS, callback = SetupFilters},
}

function addonTable.CustomiseDialog.Toggle()
  if customisers[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)] then
    local frame = customisers[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)]
    frame:SetShown(not frame:IsVisible())
    return
  end

  local frame = CreateFrame("Frame", "ChatanatorCustomiseDialog" .. addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN), UIParent, "ButtonFrameTemplate")
  frame:SetToplevel(true)
  customisers[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)] = frame
  table.insert(UISpecialFrames, frame:GetName())
  frame:SetSize(600, 700)
  frame:SetPoint("CENTER")
  frame:Raise()

  ButtonFrameTemplate_HidePortrait(frame)
  ButtonFrameTemplate_HideButtonBar(frame)
  frame.Inset:Hide()
  frame:EnableMouse(true)
  frame:SetScript("OnMouseWheel", function() end)

  frame:SetTitle(addonTable.Locales.CUSTOMISE_CHATANATOR)

  local containers = {}
  local lastTab
  local Tabs = {}
  for _, setup in ipairs(TabSetups) do
    local tabContainer = setup.callback(frame)
    tabContainer:SetPoint("TOPLEFT", 0 + addonTable.Constants.ButtonFrameOffset, -65)
    tabContainer:SetPoint("BOTTOMRIGHT")

    local tabButton = addonTable.CustomiseDialog.Components.GetTab(frame)
    if lastTab then
      tabButton:SetPoint("LEFT", lastTab, "RIGHT", 5, 0)
    else
      tabButton:SetPoint("TOPLEFT", 0 + addonTable.Constants.ButtonFrameOffset + 5, -25)
    end
    lastTab = tabButton
    tabContainer.button = tabButton
    tabButton:SetScript("OnClick", function()
      for _, c in ipairs(containers) do
        PanelTemplates_DeselectTab(c.button)
        c:Hide()
      end
      PanelTemplates_SelectTab(tabButton)
      tabContainer:Show()
    end)
    tabButton:SetText(setup.name)
    tabContainer:Hide()

    table.insert(Tabs, tabButton)
    table.insert(containers, tabContainer)
  end
  frame.Tabs = Tabs
  PanelTemplates_SetNumTabs(frame, #frame.Tabs)
  containers[1].button:Click()
end
