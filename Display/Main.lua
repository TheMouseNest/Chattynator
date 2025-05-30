---@class addonTableChattynator
local addonTable = select(2, ...)

---@class ChatFrameMixin: Frame
addonTable.Display.ChatFrameMixin = {}

function addonTable.Display.ChatFrameMixin:OnLoad()
  self:SetHyperlinkPropagateToParent(true)
  self:SetMovable(true)
  self:SetResizable(true)
  self:SetResizeBounds(240, 140)
  self:SetClampedToScreen(true)

  self:SetScript("OnSizeChanged", function()
    self:UpdateButtons()
    self:SavePosition()
    self:SaveSize()
  end)

  self.ScrollingMessages = CreateFrame("Frame", nil, self)
  Mixin(self.ScrollingMessages, addonTable.Display.ScrollingMessagesMixin)
  self.ScrollingMessages:OnLoad()

  self.ScrollingMessages:SetPoint("TOPLEFT", 34, -27)
  self.ScrollingMessages:SetPoint("BOTTOMRIGHT", 0, 38)

  self.resizeWidget = CreateFrame("Button", nil, self)
  self.resizeWidget:SetSize(20, 22)
  self.resizeWidget:SetPoint("BOTTOMRIGHT", self.ScrollingMessages, -5,  0)
  self.resizeWidget:RegisterForDrag("LeftButton")
  self.resizeWidget:SetScript("OnDragStart", function()
    self:StartSizing("BOTTOMRIGHT")
  end)
  self.resizeWidget:SetScript("OnDragStop", function()
    self:StopMovingOrSizing()
    self:SaveSize()
  end)
  addonTable.Skins.AddFrame("ResizeWidget", self.resizeWidget)
  self.resizeWidget:SetShown(not addonTable.Config.Get(addonTable.Config.Options.LOCKED))

  addonTable.CallbackRegistry:RegisterCallback("Render", function(self, ...)
    if self:GetID() == 0 then
      return
    end
    self.ApplyFlashing(...)
    self.ScrollingMessages:Render(...)
  end, self)

  addonTable.CallbackRegistry:RegisterCallback("ScrollToEndImmediate", function(_, windowID)
    if windowID == self:GetID() then
      self:SetTabSelected(self.tabIndex)
    end
  end, self)

  addonTable.CallbackRegistry:RegisterCallback("RefreshStateChange", function(_, refreshState)
    if self:GetID() ~= 0 and refreshState[addonTable.Constants.RefreshReason.Tabs] then
      addonTable.Core.InitializeTabs(self)
      self.ScrollingMessages:Render()
    end
    if refreshState[addonTable.Constants.RefreshReason.MessageWidget] then
      if self:GetID() ~= 0 then
        self.ScrollingMessages:Render()
      end
    end
    if refreshState[addonTable.Constants.RefreshReason.Locked] then
      self.resizeWidget:SetShown(not addonTable.Config.Get(addonTable.Config.Options.LOCKED))
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if self:GetID() == 0 then
      return
    end
    if settingName == addonTable.Config.Options.WINDOWS then
      self:SetPoint(unpack(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].position))
      self:SetSize(unpack(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].size))
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SkinLoaded", self.UpdateButtons, self)

  addonTable.Skins.AddFrame("ChatFrame", self)
end

function addonTable.Display.ChatFrameMixin:Reset()
  local function SetPosition()
    self:SetPoint(unpack(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].position))
  end
  local state = pcall(SetPosition)
  if not state then
    self:SetPoint("CENTER", UIParent)
  end
  self:SetSize(unpack(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].size))

  self.filterFunc = nil

  self.tabIndex = 1
  self.Tabs = {}

  self:RepositionBlizzardWidgets() -- Only does stuff if self:GetID() is 1
  self.ScrollingMessages:Reset()

  addonTable.Core.InitializeTabs(self)
end

function addonTable.Display.ChatFrameMixin:SavePosition()
  local point1, anchorFrame, point2, x, y = self:GetPoint(1)
  local anchorFrameName = anchorFrame and anchorFrame:GetName() or "UIParent"
  addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].position = {point1, anchorFrameName, point2, x, y}
end

function addonTable.Display.ChatFrameMixin:SaveSize()
  local x, y = self:GetSize()
  addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].size = {x, y}
end

function addonTable.Display.ChatFrameMixin:RepositionBlizzardWidgets()
  if self.arrangedButtons then
    return
  end
  self.arrangedButtons = true
  local function ArrangeButtons(buttons)
    local lastButton
    for _, b in ipairs(buttons) do
      b:ClearAllPoints()
      if lastButton == nil then
        b:SetPoint("TOPRIGHT", self.ScrollingMessages, "TOPLEFT", -5, -8)
      else
        b:SetPoint("TOP", lastButton, "BOTTOM", 0, -5)
      end
      lastButton = b
    end
  end
  self.buttons = {}

  if self:GetID() == 1 and not addonTable.Data.BlizzardButtonsAssigned then
    addonTable.Data.BlizzardButtonsAssigned = true

    -- We use the default edit box rather than instantiating our own so that the keyboard shortcuts to open it work
    ChatFrame1EditBox:SetParent(self)
    ChatFrame1EditBox:ClearAllPoints()
    ChatFrame1EditBox:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, 32)
    ChatFrame1EditBox:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, 32)
    addonTable.Skins.AddFrame("ChatEditBox", ChatFrame1EditBox)

    if QuickJoinToastButton then
      QuickJoinToastButton:SetParent(self)
      QuickJoinToastButton:SetScript("OnMouseDown", nil)
      QuickJoinToastButton:SetScript("OnMouseUp", nil)
      QuickJoinToastButton:ClearAllPoints()
      QuickJoinToastButton:SetPoint("RIGHT", self.ScrollingMessages, "LEFT", -5, 0)
      QuickJoinToastButton:SetPoint("TOP", 0, -2)
      QuickJoinToastButton:SetFrameStrata("HIGH")
      local SetPoint = QuickJoinToastButton.SetPoint
      hooksecurefunc(QuickJoinToastButton, "SetPoint", function(_, _, frame)
        if frame ~= self.ScrollingMessages then
          QuickJoinToastButton:SetParent(self)
          QuickJoinToastButton:ClearAllPoints()
          SetPoint(QuickJoinToastButton, "RIGHT", self.ScrollingMessages, "LEFT", -5, 0)
          SetPoint(QuickJoinToastButton, "TOP", 0, -2)
        end
      end)
      addonTable.Skins.AddFrame("ChatButton", QuickJoinToastButton, {"toasts"})

      ChatFrameChannelButton:SetParent(self)
      ChatFrameChannelButton:ClearAllPoints()
      ChatFrameChannelButton:SetScript("OnMouseDown", nil)
      ChatFrameChannelButton:SetScript("OnMouseUp", nil)
      addonTable.Skins.AddFrame("ChatButton", ChatFrameChannelButton, {"channels"})
      table.insert(self.buttons, ChatFrameChannelButton)

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
  table.insert(self.buttons, self.SearchButton)
  addonTable.Skins.AddFrame("ChatButton", self.SearchButton, {"search"})
  self.CopyButton = MakeButton(addonTable.Locales.COPY_CHAT)
  table.insert(self.buttons, self.CopyButton)
  addonTable.Skins.AddFrame("ChatButton", self.CopyButton, {"copy"})
  self.SettingsButton = MakeButton(addonTable.Locales.GLOBAL_SETTINGS)
  self.SettingsButton:SetScript("OnClick", function()
    addonTable.CustomiseDialog.Toggle()
  end)
  table.insert(self.buttons, self.SettingsButton)
  addonTable.Skins.AddFrame("ChatButton", self.SettingsButton, {"settings"})

  self.ScrollToBottomButton = MakeButton(addonTable.Locales.SCROLL_TO_END)
  self.ScrollToBottomButton:SetPoint("BOTTOMRIGHT", self.ScrollingMessages, "BOTTOMLEFT", -5, 5)
  self.ScrollToBottomButton:SetScript("OnClick", function()
    self.ScrollingMessages:ScrollToEnd()
  end)
  addonTable.Skins.AddFrame("ChatButton", self.ScrollToBottomButton, {"scrollToEnd"})

  ArrangeButtons(self.buttons)
end

function addonTable.Display.ChatFrameMixin:SetFilter(func)
  self.ScrollingMessages:SetFilter(func)
end

function addonTable.Display.ChatFrameMixin:SetBackgroundColor(r, g, b)
  self.backgroundColor = {r= r, g = g, b = b}
end

function addonTable.Display.ChatFrameMixin:SetTabSelected(index)
  self.tabIndex = index
  self.tabChanged = true
  self.ScrollingMessages:Reset()
end

function addonTable.Display.ChatFrameMixin:UpdateButtons()
  local heightAvailable = self.ScrollingMessages:GetHeight() - 8 - self.ScrollToBottomButton:GetHeight() - 2
  local currentHeight = 0
  for _, b in ipairs(self.buttons) do
    currentHeight = currentHeight + b:GetHeight() + 5
    b:SetShown(currentHeight <= heightAvailable)
  end
end

function addonTable.Display.ChatFrameMixin:ApplyFlashing(newMessages)
  if not newMessages then
    return
  end
  local tabsMatching = {}
  for index, tab in ipairs(self.Tabs) do
    if tab.filter and FindInTableIf(newMessages, tab.filter) ~= nil then
      tabsMatching[index] = true
    end
  end

  if tabsMatching[self.tabIndex] then
    return
  end

  for index in pairs(tabsMatching) do
    self.Tabs[index]:SetFlashing(true)
  end
end
