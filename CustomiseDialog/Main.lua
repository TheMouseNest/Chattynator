---@class addonTableChattynator
local addonTable = select(2, ...)

local customisers = {}

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
    logo:SetTexture("Interface\\AddOns\\Chattynator\\Assets\\Logo.png")
    logo:SetSize(52, 52)
    logo:SetPoint("LEFT", 8, 0)

    local name = infoInset:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    name:SetText(addonTable.Locales.CHATTYNATOR)
    name:SetPoint("TOPLEFT", logo, "TOPRIGHT", 10, 0)

    local credit = infoInset:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    credit:SetText(addonTable.Locales.BY_PLUSMOUSE)
    credit:SetPoint("BOTTOMLEFT", name, "BOTTOMRIGHT", 5, 0)

    local discordLinkDialog = "Chattynator_General_Settings_Discord_Dialog"
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

    local donateLinkDialog = "Chattynator_General_Settings_Donate_Dialog"
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

  local profileDropdown = addonTable.CustomiseDialog.Components.GetBasicDropdown(container, addonTable.Locales.PROFILES)
  do
    profileDropdown.SetValue = nil

    local clone = false
    local function ValidateAndCreate(profileName)
      if profileName ~= "" and CHATTYNATOR_CONFIG.Profiles[profileName] == nil then
        addonTable.Config.MakeProfile(profileName, clone)
        profileDropdown.DropDown:GenerateMenu()
      end
    end
    local makeProfileDialog = "Chattynator_MakeProfileDialog"
    StaticPopupDialogs[makeProfileDialog] = {
      text = addonTable.Locales.ENTER_PROFILE_NAME,
      button1 = ACCEPT,
      button2 = CANCEL,
      hasEditBox = 1,
      OnAccept = function(self)
        ValidateAndCreate(self.editBox:GetText())
      end,
      EditBoxOnEnterPressed = function(self)
        ValidateAndCreate(self:GetText())
        self:GetParent():Hide()
      end,
      EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
      timeout = 0,
      hideOnEscape = 1,
    }
    local deleteProfileDialog = "Chattynator_DeleteProfileDialog"
    StaticPopupDialogs[deleteProfileDialog] = {
      button1 = YES,
      button2 = NO,
      OnAccept = function(_, data)
        addonTable.Config.DeleteProfile(data)
      end,
      timeout = 0,
      hideOnEscape = 1,
    }
    profileDropdown:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -30)
    profileDropdown.DropDown:SetupMenu(function(menu, rootDescription)
      local profiles = addonTable.Config.GetProfileNames()
      table.sort(profiles, function(a, b) return a:lower() < b:lower() end)
      for _, name in ipairs(profiles) do
        local button = rootDescription:CreateRadio(name ~= "DEFAULT" and name or LIGHTBLUE_FONT_COLOR:WrapTextInColorCode(DEFAULT), function()
          return CHATTYNATOR_CURRENT_PROFILE == name
        end, function()
          addonTable.Config.ChangeProfile(name)
        end)
        if name ~= "DEFAULT" and name ~= CHATTYNATOR_CURRENT_PROFILE then
          button:AddInitializer(function(button, description, menu)
            local delete = MenuTemplates.AttachAutoHideButton(button, "transmog-icon-remove")
            delete:SetPoint("RIGHT")
            delete:SetSize(18, 18)
            delete.Texture:SetAtlas("transmog-icon-remove")
            delete:SetScript("OnClick", function()
              menu:Close()
              StaticPopupDialogs[deleteProfileDialog].text = addonTable.Locales.CONFIRM_DELETE_PROFILE_X:format(name)
              StaticPopup_Show(deleteProfileDialog, nil, nil, name)
            end)
            MenuUtil.HookTooltipScripts(delete, function(tooltip)
              GameTooltip_SetTitle(tooltip, DELETE);
            end);
          end)
        end
      end
      rootDescription:CreateButton(NORMAL_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.NEW_PROFILE_CLONE), function()
        clone = true
        StaticPopup_Show(makeProfileDialog)
      end)
      rootDescription:CreateButton(NORMAL_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.NEW_PROFILE_BLANK), function()
        clone = false
        StaticPopup_Show(makeProfileDialog)
      end)
    end)
  end
  table.insert(allFrames, profileDropdown)

  local showCombatLog = addonTable.CustomiseDialog.Components.GetCheckbox(container, addonTable.Locales.SHOW_COMBAT_LOG, 28, function(state)
    addonTable.Config.Set(addonTable.Config.Options.SHOW_COMBAT_LOG, state)
  end)
  showCombatLog.option = addonTable.Config.Options.SHOW_COMBAT_LOG
  showCombatLog:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -30)
  table.insert(allFrames, showCombatLog)

  container:SetScript("OnShow", function()
    for _, f in ipairs(allFrames) do
      if f.SetValue then
        f:SetValue(addonTable.Config.Get(f.option))
      end
    end
  end)

  return container
end

local function SetupLayout(parent)
  local container = CreateFrame("Frame", nil, parent)

  local allFrames = {}

  local messageSpacing
  messageSpacing = addonTable.CustomiseDialog.Components.GetSlider(container, addonTable.Locales.MESSAGE_SPACING, 0, 60, "%spx", function()
    addonTable.Config.Set(addonTable.Config.Options.MESSAGE_SPACING, messageSpacing:GetValue())
  end)
  messageSpacing.option = addonTable.Config.Options.MESSAGE_SPACING
  messageSpacing:SetPoint("TOP")
  table.insert(allFrames, messageSpacing)

  local showSeparator = addonTable.CustomiseDialog.Components.GetCheckbox(container, addonTable.Locales.SHOW_VERTICAL_SEPARATOR, 28, function(state)
    addonTable.Config.Set(addonTable.Config.Options.SHOW_TIMESTAMP_SEPARATOR, state)
  end)
  showSeparator.option = addonTable.Config.Options.SHOW_TIMESTAMP_SEPARATOR
  showSeparator:SetPoint("TOP", allFrames[#allFrames], "BOTTOM")
  table.insert(allFrames, showSeparator)

  local editBoxPositionDropdown = addonTable.CustomiseDialog.Components.GetBasicDropdown(container, addonTable.Locales.EDIT_BOX_POSITION, function(value)
    return addonTable.Config.Get(addonTable.Config.Options.EDIT_BOX_POSITION) == value
  end, function(value)
    addonTable.Config.Set(addonTable.Config.Options.EDIT_BOX_POSITION, value)
  end)
  editBoxPositionDropdown:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -30)
  do
    local entries = {
      addonTable.Locales.BOTTOM,
      addonTable.Locales.TOP,
    }
    local values = {
      "bottom",
      "top"
    }
    editBoxPositionDropdown:Init(entries, values)
  end
  table.insert(allFrames, editBoxPositionDropdown)

  local newWhispersNewTab = addonTable.CustomiseDialog.Components.GetCheckbox(container, addonTable.Locales.NEW_WHISPERS_TO_NEW_TAB, 28, function(state)
    addonTable.Config.Set(addonTable.Config.Options.NEW_WHISPER_NEW_TAB, state and 1 or 0)
  end)
  newWhispersNewTab.option = addonTable.Config.Options.NEW_WHISPER_NEW_TAB
  newWhispersNewTab:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -30)
  table.insert(allFrames, newWhispersNewTab)

  local locked = addonTable.CustomiseDialog.Components.GetCheckbox(container, addonTable.Locales.LOCK_CHAT, 28, function(state)
    addonTable.Config.Set(addonTable.Config.Options.LOCKED, state)
  end)
  locked.option = addonTable.Config.Options.LOCKED
  locked:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -30)
  table.insert(allFrames, locked)

  container:SetScript("OnShow", function()
    for _, f in ipairs(allFrames) do
      if f.SetValue then
        if f.option == addonTable.Config.Options.NEW_WHISPER_NEW_TAB then
          f:SetValue(addonTable.Config.Get(f.option) ~= 0)
        elseif f.option then
          f:SetValue(addonTable.Config.Get(f.option))
        else
          f:SetValue()
        end
      end
    end
  end)

  return container
end

local function SetupDisplay(parent)
  local LibSharedMedia = LibStub("LibSharedMedia-3.0")

  local container = CreateFrame("Frame", nil, parent)

  local allFrames = {}

  local fontDropdown = addonTable.CustomiseDialog.Components.GetBasicDropdown(container, addonTable.Locales.MESSAGE_FONT)
  fontDropdown:SetPoint("TOP")
  table.insert(allFrames, fontDropdown)

  local fontSize
  fontSize = addonTable.CustomiseDialog.Components.GetSlider(container, addonTable.Locales.MESSAGE_FONT_SIZE, 2, 40, "%spx", function()
    addonTable.Config.Set(addonTable.Config.Options.MESSAGE_FONT_SIZE, fontSize:GetValue())
  end)
  fontSize.option = addonTable.Config.Options.MESSAGE_FONT_SIZE
  fontSize:SetPoint("TOP", fontDropdown, "BOTTOM")
  table.insert(allFrames, fontSize)

  local enableMessageFade = addonTable.CustomiseDialog.Components.GetCheckbox(container, addonTable.Locales.ENABLE_MESSAGE_FADE, 28, function(state)
    addonTable.Config.Set(addonTable.Config.Options.ENABLE_MESSAGE_FADE, state)
  end)
  enableMessageFade.option = addonTable.Config.Options.ENABLE_MESSAGE_FADE
  enableMessageFade:SetPoint("TOP", fontSize, "BOTTOM", 0, -30)
  table.insert(allFrames, enableMessageFade)

  local messageFadeTimer
  messageFadeTimer = addonTable.CustomiseDialog.Components.GetSlider(container, addonTable.Locales.MESSAGE_FADE_TIME, 5, 240, "%ss", function()
    addonTable.Config.Set(addonTable.Config.Options.MESSAGE_FADE_TIME, messageFadeTimer:GetValue())
  end)
  messageFadeTimer.option = addonTable.Config.Options.MESSAGE_FADE_TIME
  messageFadeTimer:SetPoint("TOP", allFrames[#allFrames], "BOTTOM")
  table.insert(allFrames, messageFadeTimer)

  container:SetScript("OnShow", function()
    local fontValues = CopyTable(LibSharedMedia:List("font"))
    local fontLabels = CopyTable(LibSharedMedia:List("font"))
    table.insert(fontValues, 1, "default")
    table.insert(fontLabels, 1, DEFAULT)

    fontDropdown.DropDown:SetupMenu(function(_, rootDescription)
      for index, label in ipairs(fontLabels) do
        local radio = rootDescription:CreateRadio(label,
          function()
            return addonTable.Config.Get(addonTable.Config.Options.MESSAGE_FONT) == fontValues[index]
          end,
          function()
            addonTable.Config.Set(addonTable.Config.Options.MESSAGE_FONT, fontValues[index])
          end
        )
        radio:AddInitializer(function(button, elementDescription, menu)
          button.fontString:SetFontObject(addonTable.Core.GetFontByID(fontValues[index]))
        end)
      end
      rootDescription:SetScrollMode(20 * 20)
    end)

    for _, f in ipairs(allFrames) do
      if f.SetValue then
        if f.option then
          f:SetValue(addonTable.Config.Get(f.option))
        end
      end
    end
  end)

  return container
end

local function SetupFormatting(parent)
  local container = CreateFrame("Frame", nil, parent)

  local allFrames = {}

  local timestampDropdown = addonTable.CustomiseDialog.Components.GetBasicDropdown(container, addonTable.Locales.TIMESTAMP, function(value)
    return addonTable.Config.Get(addonTable.Config.Options.TIMESTAMP_FORMAT) == value
  end, function(value)
    addonTable.Config.Set(addonTable.Config.Options.TIMESTAMP_FORMAT, value)
  end)
  timestampDropdown:SetPoint("TOP")
  do
    local entries = {
      "HH:MM",
      "HH:MM:SS",
      "HH:MM AM/PM",
      "HH:MM:SS AM/PM",
    }
    local values = {
      "%H:%M",
      "%X",
      "%I:%M %p",
      "%I:%M:%S %p",
    }
    timestampDropdown:Init(entries, values)
  end
  table.insert(allFrames, timestampDropdown)

  local useClassColors = addonTable.CustomiseDialog.Components.GetCheckbox(container, addonTable.Locales.USE_CLASS_COLORS, 28, function(state)
    addonTable.Config.Set(addonTable.Config.Options.CLASS_COLORS, state)
  end)
  useClassColors.option = addonTable.Config.Options.CLASS_COLORS
  useClassColors:SetPoint("TOP", allFrames[#allFrames], "BOTTOM")
  table.insert(allFrames, useClassColors)

  local shorteningDropdown = addonTable.CustomiseDialog.Components.GetBasicDropdown(container, addonTable.Locales.SHORTEN_CHANNELS, function(value)
    return addonTable.Config.Get(addonTable.Config.Options.SHORTEN_FORMAT) == value
  end, function(value)
    addonTable.Config.Set(addonTable.Config.Options.SHORTEN_FORMAT, value)
  end)
  shorteningDropdown:SetPoint("TOP", useClassColors, "BOTTOM")
  do
    local entries = {
      addonTable.Locales.NONE,
      addonTable.Locales.SHORTEN_STYLE_1,
      addonTable.Locales.SHORTEN_STYLE_2,
    }
    local values = {
      "none",
      "number",
      "letter",
    }
    shorteningDropdown:Init(entries, values)
  end
  table.insert(allFrames, shorteningDropdown)

  container:SetScript("OnShow", function()
    for _, f in ipairs(allFrames) do
      if f.SetValue then
        if f.option then
          f:SetValue(addonTable.Config.Get(f.option))
        else
          f:SetValue()
        end
      end
    end
  end)

  return container
end

local function SetupThemes(parent)
  local container = CreateFrame("Frame", nil, parent)

  local allFrames = {}

  local reloadDialog = "Chattynator_ReloadDialog"
  StaticPopupDialogs[reloadDialog] = {
    text = addonTable.Locales.RELOAD_REQUIRED,
    button1 = YES,
    button2 = NO,
    OnAccept = function()
      ReloadUI()
    end,
    timeout = 0,
    hideOnEscape = 1,
  }

  local themeDropdown = addonTable.CustomiseDialog.Components.GetBasicDropdown(container, addonTable.Locales.THEME, function(value)
    return addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN) == value
  end, function(value)
    addonTable.Config.Set(addonTable.Config.Options.CURRENT_SKIN, value)
    StaticPopup_Show(reloadDialog)
  end)
  themeDropdown:SetPoint("TOP")
  do
    local skins = {}
    for _, skin in pairs(addonTable.Skins.availableSkins) do
      table.insert(skins, {name = skin.label, value = skin.key})
    end
    table.sort(skins, function(a, b) return a.name < b.name end)
    local entries, values = {}, {}
    for _, skinDetails in ipairs(skins) do
      table.insert(entries, skinDetails.name)
      table.insert(values, skinDetails.value)
    end
    themeDropdown:Init(entries, values)
  end
  table.insert(allFrames, themeDropdown)

  local skinKey = addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)
  local currentSkin = addonTable.Skins.availableSkins[skinKey]
  for index, option in ipairs(currentSkin.options) do
    if option.type == "slider" then
      local slider
      local optionKey = "skins." .. skinKey .. "." .. option.option
      slider = addonTable.CustomiseDialog.Components.GetSlider(container, option.text, option.min, option.max, option.valuePattern, function()
        addonTable.Config.Set(optionKey, slider:GetValue() / (option.scale or 1))
      end)
      slider.option = optionKey
      slider.scale = option.scale
      slider:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, index == 1 and -30 or 0)
      table.insert(allFrames, slider)
    end
  end

  container:SetScript("OnShow", function()
    for _, f in ipairs(allFrames) do
      if f.SetValue then
        if f.option and f.scale then
          f:SetValue(addonTable.Config.Get(f.option) * f.scale)
        elseif f.option then
          f:SetValue(addonTable.Config.Get(f.option))
        else
          f:SetValue()
        end
      end
    end
  end)

  return container
end

local TabSetups = {
  {name = GENERAL, callback = SetupGeneral},
  {name = addonTable.Locales.THEME, callback = SetupThemes},
  {name = addonTable.Locales.LAYOUT, callback = SetupLayout},
  {name = addonTable.Locales.DISPLAY, callback = SetupDisplay},
  {name = addonTable.Locales.FORMATTING, callback = SetupFormatting},
}

function addonTable.CustomiseDialog.Toggle()
  if customisers[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)] then
    local frame = customisers[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)]
    frame:SetShown(not frame:IsVisible())
    return
  end

  local frame = CreateFrame("Frame", "ChattynatorCustomiseDialog" .. addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN), UIParent, "ButtonFrameTemplate")
  frame:SetToplevel(true)
  customisers[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)] = frame
  table.insert(UISpecialFrames, frame:GetName())
  frame:SetSize(600, 700)
  frame:SetPoint("CENTER")
  frame:Raise()

  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function()
    frame:StartMoving()
    frame:SetUserPlaced(false)
  end)
  frame:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    frame:SetUserPlaced(false)
  end)

  ButtonFrameTemplate_HidePortrait(frame)
  ButtonFrameTemplate_HideButtonBar(frame)
  frame.Inset:Hide()
  frame:EnableMouse(true)
  frame:SetScript("OnMouseWheel", function() end)

  frame:SetTitle(addonTable.Locales.CUSTOMISE_CHATTYNATOR)

  local containers = {}
  local lastTab
  local Tabs = {}
  for _, setup in ipairs(TabSetups) do
    local tabContainer = setup.callback(frame)
    tabContainer:SetPoint("TOPLEFT", 0 + addonTable.Constants.ButtonFrameOffset, -65)
    tabContainer:SetPoint("BOTTOMRIGHT")

    local tabButton = addonTable.CustomiseDialog.Components.GetTab(frame, setup.name)
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
    tabContainer:Hide()

    table.insert(Tabs, tabButton)
    table.insert(containers, tabContainer)
  end
  frame.Tabs = Tabs
  PanelTemplates_SetNumTabs(frame, #frame.Tabs)
  containers[1].button:Click()

  frame:SetScript("OnShow", function()
    local shownContainer = FindValueInTableIf(containers, function(c) return c:IsShown() end)
    if shownContainer then
      PanelTemplates_SetTab(frame, tIndexOf(containers, shownContainer))
    end
  end)

  addonTable.Skins.AddFrame("ButtonFrame", frame, {"customise"})
end
