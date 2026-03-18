---@class addonTableChattynator
local addonTable = select(2, ...)

---@class ButtonsBarMixin: Frame
addonTable.Display.ButtonsBarMixin = {}

function addonTable.Display.ButtonsBarMixin:OnLoad()
  self.buttons = {}

  self.socialAnchor1 = {"TOPRIGHT", self:GetParent().ScrollingMessages, "TOPLEFT", -5, 20}

  addonTable.CallbackRegistry:RegisterCallback("SkinLoaded", self.Update, self)

  self:GetParent().ScrollingMessages:SetOnScrollChangedCallback(function()
    if self.ScrollToBottomButton then
      self.ScrollToBottomButton:SetShown(not self:GetParent().ScrollingMessages:AtBottom())
    end
  end)

  self.hookedButtons = false
  self.active = false

  self.fadeInterpolator = CreateInterpolator(InterpolatorUtil.InterpolateEaseIn)
end

function addonTable.Display.ButtonsBarMixin:AddBlizzardButtons()
  if addonTable.Data.BlizzardButtonsAssigned then
    return
  end

  addonTable.Data.BlizzardButtonsAssigned = true

  if QuickJoinToastButton then
    QuickJoinToastButton:SetParent(self)
    QuickJoinToastButton:SetScript("OnMouseDown", nil)
    QuickJoinToastButton:SetScript("OnMouseUp", nil)
    QuickJoinToastButton:ClearAllPoints()
    QuickJoinToastButton:SetPoint(unpack(self.socialAnchor1))
    QuickJoinToastButton:SetFrameStrata("HIGH")
    local SetPoint = QuickJoinToastButton.SetPoint
    hooksecurefunc(QuickJoinToastButton, "SetPoint", function(_, _, frame)
      if frame ~= self.socialAnchor1[2] then
        QuickJoinToastButton:SetParent(self)
        QuickJoinToastButton:ClearAllPoints()
        SetPoint(QuickJoinToastButton, unpack(self.socialAnchor1))
      end
    end)
    addonTable.Skins.AddFrame("ChatButton", QuickJoinToastButton, {"toasts"})
    table.insert(self.buttons, QuickJoinToastButton)
  end

  if FriendsMicroButton then
    FriendsMicroButton:SetParent(self)
    FriendsMicroButton:SetScript("OnMouseDown", nil)
    FriendsMicroButton:SetScript("OnMouseUp", nil)
    FriendsMicroButton:ClearAllPoints()
    FriendsMicroButton:SetPoint(unpack(self.socialAnchor1))
    FriendsMicroButton:SetFrameStrata("HIGH")
    local SetPoint = FriendsMicroButton.SetPoint
    hooksecurefunc(FriendsMicroButton, "SetPoint", function(_, _, frame)
      if frame ~= self.socialAnchor1[2] then
        FriendsMicroButton:SetParent(self)
        FriendsMicroButton:ClearAllPoints()
        SetPoint(FriendsMicroButton, unpack(self.socialAnchor1))
      end
    end)
    addonTable.Skins.AddFrame("ChatButton", FriendsMicroButton, {"toasts"})
    table.insert(self.buttons, FriendsMicroButton)
  end

  if ChatFrameChannelButton then
    ChatFrameChannelButton:SetParent(self)
    ChatFrameChannelButton:ClearAllPoints()
    ChatFrameChannelButton:SetScript("OnMouseDown", nil)
    ChatFrameChannelButton:SetScript("OnMouseUp", nil)
    if C_ChatInfo.InChatMessagingLockdown then
      ChatFrameChannelButton:SetScript("OnClick", function()
        if not InCombatLockdown() and not C_ChatInfo.InChatMessagingLockdown() then
          ShowUIPanel(ChannelFrame)
        else
          addonTable.Utilities.Message(addonTable.Locales.ACTION_UNAVAILABLE_DUE_TO_ENCOUNTER_RESTRICTIONS)
        end
      end)
    end
    addonTable.Skins.AddFrame("ChatButton", ChatFrameChannelButton, {"channels"})
    table.insert(self.buttons, ChatFrameChannelButton)
  end

  if ChatFrameToggleVoiceDeafenButton then
    ChatFrameToggleVoiceDeafenButton:SetParent(self)
    ChatFrameToggleVoiceDeafenButton:ClearAllPoints()
    ChatFrameToggleVoiceDeafenButton:SetPoint("LEFT", ChatFrameChannelButton, "RIGHT", 2, 0)
    addonTable.Skins.AddFrame("ChatButton", ChatFrameToggleVoiceDeafenButton, {"voiceChatNoAudio"})
    addonTable.Skins.AddFrame("ChatButton", ChatFrameToggleVoiceMuteButton, {"voiceChatMuteMic"})
  end

  ChatFrameMenuButton:SetParent(self)
  ChatFrameMenuButton:ClearAllPoints()
  ChatFrameMenuButton:SetScript("OnMouseDown", nil)
  ChatFrameMenuButton:SetScript("OnMouseUp", nil)
  addonTable.Skins.AddFrame("ChatButton", ChatFrameMenuButton, {"menu"})
  table.insert(self.buttons, ChatFrameMenuButton)

  ChatFrameMenuButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(ChatFrameMenuButton, "ANCHOR_RIGHT")
    GameTooltip:SetText(WHITE_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.QUICK_CHAT))
    GameTooltip:Show()
  end)
  ChatFrameMenuButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  addonTable.Skins.AddFrame("ChatButton", ChatFrameMenuButton, {"menu"})
end

local searchMarkup = CreateTextureMarkup("Interface/AddOns/Chattynator/Assets/Search.png", 64, 64, 12, 12, 0, 1, 0, 1)
local function RunSearch(windowIndex, tabIndex, text, isPattern)
  local window = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[windowIndex]
  local tab = window.tabs[tabIndex]

  local newTab = CopyTable(tab)
  text = text:lower()
  if isPattern then
    table.insert(newTab.filters, function(data)
      return data.text:lower():match(text) ~= nil
    end)
  else
    table.insert(newTab.filters, function(data)
      return data.text:lower():find(text, nil, true) ~= nil
    end)
  end
  newTab.name = searchMarkup
  newTab.isTemporary = true

  local newIndex = tabIndex + 1

  for index, otherTab in ipairs(window.tabs) do
    if otherTab.name == newTab.name and otherTab.isTemporary then
      table.remove(window.tabs, index)
      if index < newIndex then
        newIndex = newIndex - 1
      end
      break
    end
  end

  table.insert(window.tabs, newIndex, newTab)
  addonTable.allChatFrames[windowIndex].tabIndex = newIndex
  addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
end

function addonTable.Display.ButtonsBarMixin:AddButtons()
  if self.madeButtons then
    return
  end

  self.madeButtons = true

  local function MakeButton(tooltipText)
    local button = CreateFrame("Button", nil, self)
    button:SetScript("OnEnter", function()
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      GameTooltip:SetText(WHITE_FONT_COLOR:WrapTextInColorCode(tooltipText))
      GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    return button
  end

  self.SearchButton = MakeButton(SEARCH)
  self.SearchButton:SetScript("OnClick", function()
    local tab = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetParent():GetID()].tabs[self:GetParent().tabIndex]
    addonTable.Dialogs.ShowEditBox(addonTable.Locales.SEARCH_IN_X_MESSAGE:format(addonTable.Display.GetTabNameFromName(tab.name)), SEARCH, CANCEL, function(text)
      RunSearch(self:GetParent():GetID(), self:GetParent().tabIndex, text, IsShiftKeyDown())
    end)
  end)
  table.insert(self.buttons, self.SearchButton)
  addonTable.Skins.AddFrame("ChatButton", self.SearchButton, {"search"})
  self.CopyButton = MakeButton(addonTable.Locales.COPY_CHAT)
  self.CopyButton:SetScript("OnClick", function()
    if addonTable.CopyFrame:IsShown() then
      addonTable.CopyFrame:Hide()
    else
      addonTable.CopyFrame:LoadMessages(self:GetParent().ScrollingMessages.filterFunc, self:GetParent().ScrollingMessages.startingIndex)
    end
  end)
  table.insert(self.buttons, self.CopyButton)
  addonTable.Skins.AddFrame("ChatButton", self.CopyButton, {"copy"})
  self.SettingsButton = MakeButton(addonTable.Locales.GLOBAL_SETTINGS)
  self.SettingsButton:SetScript("OnClick", function()
    addonTable.CustomiseDialog.Toggle()
  end)
  table.insert(self.buttons, self.SettingsButton)
  addonTable.Skins.AddFrame("ChatButton", self.SettingsButton, {"settings"})

  self.ScrollToBottomButton = MakeButton(addonTable.Locales.SCROLL_TO_END)
  self.ScrollToBottomButton:SetScript("OnClick", function()
    self:GetParent().ScrollingMessages:ScrollToBottom()
  end)
  self.ScrollToBottomButton:Hide()
  addonTable.Skins.AddFrame("ChatButton", self.ScrollToBottomButton, {"scrollToEnd"})
end

function addonTable.Display.ButtonsBarMixin:OnEnter()
  for _, b in ipairs(self.buttons) do
    b:SetShown(b.fitsSize)
    b:SetFrameStrata("HIGH")
  end
  if self.hideTimer then
    self.hideTimer:Cancel()
  end
  self.active = true
  self.fadeInterpolator:Interpolate(self.buttons[1]:GetAlpha(), 1, 0.15, function(value)
    for _, b in ipairs(self.buttons) do
      b:SetAlpha(value)
    end
  end)
end

function addonTable.Display.ButtonsBarMixin:OnLeave()
  if self:IsMouseOver() then
    return
  end
  if self.hideTimer then
    self.hideTimer:Cancel()
  end
  local function Hide()
    self.hideTimer = C_Timer.NewTimer(2, function()
      if Menu.GetManager():IsAnyMenuOpen() and (InCombatLockdown() or tIndexOf(Menu.GetOpenMenuTags(), "MENU_CHAT_SHORTCUTS") ~= nil) then
        Hide()
        return
      end

      self.fadeInterpolator:Interpolate(self.buttons[1]:GetAlpha(), 0, 0.15, function(value)
        for _, b in ipairs(self.buttons) do
          b:SetAlpha(value)
        end
      end, function()
        for _, b in ipairs(self.buttons) do
          b:Hide()
        end
      end)
      self.active = false
    end)
  end
  Hide()
end

function addonTable.Display.ButtonsBarMixin:Update()
  if not self.ScrollToBottomButton then
    return
  end

  local position = addonTable.Config.Get(addonTable.Config.Options.BUTTON_POSITION)

  if addonTable.Config.Get(addonTable.Config.Options.SHOW_BUTTONS) == "hover" then
    self.lockActive = false
    self:SetScript("OnEnter", self.OnEnter)
    self:SetScript("OnLeave", self.OnLeave)
    if not self.hookedButtons then
      self.hookedButtons = true
      for _, b in ipairs(self.buttons) do
        b:HookScript("OnEnter", function()
          if not self.lockActive then
            self:OnEnter()
          end
        end)
        b:HookScript("OnLeave", function()
          if not self.lockActive then
            self:OnLeave()
          end
        end)
        b:Hide()
        b:SetAlpha(0)
      end
      self.active = false
    end
    if self.active then
      self:OnLeave() -- Hide if necessary
    end
  else
    self.active = true
    self.lockActive = true -- Prevent hooked stuff hiding the buttons
    self:SetScript("OnEnter", nil)
    self:SetScript("OnLeave", nil)
    if self.hideTimer then
      self.hideTimer:Cancel()
      self.hideTimer = nil
    end
    for _, b in ipairs(self.buttons) do
      b:SetAlpha(1)
    end
  end

  if position:match("left") then
    local offsetX, offsetY = -5, 20
    self.ScrollToBottomButton:ClearAllPoints()
    if not addonTable.Config.Get(addonTable.Config.Options.SHOW_TABS) then
      offsetY = -2
    end
    if position:match("inside") then
      offsetX, offsetY = 26 + 2, -2
    end
    self.ScrollToBottomButton:SetPoint("BOTTOMRIGHT", self:GetParent().ScrollingMessages, "BOTTOMRIGHT", -2, 5)
    local startingOffsetY = offsetY
    self:ClearAllPoints()
    self:SetPoint("TOPRIGHT", self:GetParent().ScrollingMessages, "TOPLEFT", offsetX, offsetY)
    for _, b in ipairs(self.buttons) do
      local anchor = {"TOPRIGHT", self:GetParent().ScrollingMessages, "TOPLEFT", offsetX, offsetY}
      if b == QuickJoinToastButton or b == FriendsMicroButton then
        self.socialAnchor1 = anchor
      end
      b:ClearAllPoints()
      b:SetPoint(unpack(anchor))
      offsetY = offsetY - b:GetHeight() - 5
    end

    local heightAvailable = self:GetParent().ScrollingMessages:GetHeight() - 2 + startingOffsetY
    local currentHeight = 0
    for _, b in ipairs(self.buttons) do
      currentHeight = currentHeight + b:GetHeight() + 5
      b.fitsSize = currentHeight <= heightAvailable
      b:SetShown(self.active and b.fitsSize)
      b:SetFrameStrata("HIGH")
    end
    self:SetSize(22, math.min(heightAvailable, currentHeight))
  elseif position:match("tabs") then
    local offsetX, offsetY = 2, -2
    if position:match("outside") then
      offsetY = 27 + 28 + 2
      if not addonTable.Config.Get(addonTable.Config.Options.SHOW_TABS) then
        offsetY = offsetY - 23
      end
    end
    self.ScrollToBottomButton:ClearAllPoints()
    self.ScrollToBottomButton:SetPoint("BOTTOMRIGHT", self:GetParent().ScrollingMessages, "BOTTOMRIGHT", -2, 5)
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", self:GetParent().ScrollingMessages, "TOPLEFT", offsetX, offsetY)
    for _, b in ipairs(self.buttons) do
      local anchor = {"TOPLEFT", self:GetParent().ScrollingMessages, "TOPLEFT", offsetX, offsetY}
      if b == QuickJoinToastButton or b == FriendsMicroButton then
        self.socialAnchor1 = anchor
      end
      b:ClearAllPoints()
      b:SetPoint(unpack(anchor))
      offsetX = offsetX + b:GetWidth() + 5
    end

    local widthAvailable = self:GetParent().ScrollingMessages:GetWidth() - 2
    local currentWidth = 0
    for _, b in ipairs(self.buttons) do
      currentWidth = currentWidth + b:GetWidth() + 5
      b.fitsSize = currentWidth <= widthAvailable
      b:SetShown(self.active and b.fitsSize)
      b:SetFrameStrata("HIGH")
    end
    self:SetSize(math.min(widthAvailable, currentWidth), 26)
  end
end
