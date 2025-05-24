---@class addonTableChatanator
local addonTable = select(2, ...)

---@class ChatFrameMixin: Frame
addonTable.ChatFrameMixin = {}

local rightInset = 10

function addonTable.ChatFrameMixin:OnLoad()
  self:SetHyperlinkPropagateToParent(true)
  self:SetMovable(true)
  self:SetResizable(true)
  self:SetClampedToScreen(true)

  self:SetPoint(unpack(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].position))
  self:SetSize(unpack(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].size))

  self.filterFunc = nil
  self.heights = {}

  self.alphas = {}

  self.ScrollBox = CreateFrame("Frame", nil, self, "WowScrollBoxList")
  local view = CreateScrollBoxListLinearView()
  view:SetElementExtentCalculator(function(index)
    return self.heights[index][self.key] + 5
  end)
  self.currentStringWidth = 0
  self:SetScript("OnSizeChanged", function(_, width, _)
    width = math.floor(self.ScrollBox:GetWidth() - addonTable.Messages.inset - rightInset)
    addonTable.Messages:RegisterWidth(width)
    addonTable.Messages:UnregisterWidth(self.currentStringWidth)
    self.currentStringWidth = width
    self.key = addonTable.Messages.font .. " " .. width
    self:Render()
  end)
  view:SetElementInitializer("Frame", function(frame, data)
    if not frame.initialized then
      frame.initialized = true
      frame:SetHyperlinkPropagateToParent(true)
      frame.DisplayString = frame:CreateFontString(nil, "ARTWORK", addonTable.Messages.font)
      frame.DisplayString:SetJustifyH("LEFT")
      frame.DisplayString:SetNonSpaceWrap(true)
      frame.DisplayString:SetWordWrap(true)
      frame.Timestamp = frame:CreateFontString(nil, "ARTWORK", addonTable.Messages.font)
      frame.Timestamp:SetPoint("TOPLEFT", 0, 0)
      frame.Timestamp:SetJustifyH("LEFT")
      frame.Timestamp:SetTextColor(0.5, 0.5, 0.5)
      frame.Bar = frame:CreateTexture(nil, "BACKGROUND")
      frame.Bar:SetTexture("Interface/AddOns/Chatanator/Assets/Fade.png")
      frame.Bar:SetPoint("RIGHT", frame.DisplayString, "LEFT", -4, 0)
      frame.Bar:SetPoint("TOP", 0, 0)
      frame.Bar:SetPoint("BOTTOM", 0, 1 + 5)
      frame.Bar:SetWidth(2)

      frame.FadeAnimation = frame:CreateAnimationGroup()
      frame.FadeAnimation.alpha = frame.FadeAnimation:CreateAnimation("Alpha")
      frame.FadeAnimation.alpha:SetDuration(0.20)
      frame.FadeAnimation:SetToFinalAlpha(true)
      frame.FadeAnimation:SetScript("OnFinished", function()
        frame.FadeAnimation:SetScript("OnUpdate", nil)
        self.alphas[frame.data] = frame:GetAlpha()
      end)
      frame.FadeAnimation:SetScript("OnStop", function()
        frame.FadeAnimation:SetScript("OnUpdate", nil)
      end)

      frame.DisplayString:SetPoint("TOPLEFT", frame.Timestamp, "TOPRIGHT")
    end
    if not frame.debugAttached and not InCombatLockdown() then
      frame.debugAttached = true
      frame:SetScript("OnEnter", function()
        if addonTable.Config.Get(addonTable.Config.Options.DEBUG) then
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:SetText("Type: " .. tostring(frame.data.typeInfo.type))
          GameTooltip:AddLine("Event: " .. tostring(frame.data.typeInfo.event))
          GameTooltip:AddLine("Player: " .. tostring(frame.data.typeInfo.player))
          GameTooltip:AddLine("Source: " .. tostring(frame.data.typeInfo.source))
          GameTooltip:AddLine("Recorder: " .. tostring(frame.data.recordedBy))
          GameTooltip:AddLine("Channel: " .. tostring(frame.data.typeInfo.channel))
          local color = frame.data.color
          GameTooltip:AddLine("Color: " .. CreateColor(color.r, color.g, color.b):GenerateHexColorNoAlpha())
          GameTooltip:Show()
        end
      end)
      frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)
      frame:SetPropagateMouseClicks(true)
      frame:SetPropagateMouseMotion(true)
    end
    frame.Timestamp:SetWidth(addonTable.Messages.inset)
    frame.DisplayString:SetWidth(self.currentStringWidth)
    frame.data = data
    frame.Timestamp:SetText(date("%X", data.timestamp))
    frame.DisplayString:SetText(data.text)
    frame.DisplayString:SetTextColor(data.color.r, data.color.g, data.color.b)
    frame.FadeAnimation:Stop()
    frame:SetAlpha(self.alphas[data] or 0)
  end)
  self.ScrollBox:SetPoint("TOPLEFT", 34, -27)
  self.ScrollBox:SetPoint("BOTTOMRIGHT", 0, 38)
  self.ScrollBox:SetInterpolateScroll(true)
  self.ScrollBox:Init(view)
  self.ScrollBox:SetHyperlinkPropagateToParent(true)
  self.ScrollBox:GetScrollTarget():SetHyperlinkPropagateToParent(true)
  self.ScrollBox:GetScrollTarget():SetPropagateMouseClicks(true)
  self.ScrollBox:GetScrollTarget():SetPropagateMouseMotion(true)
  self.ScrollBox:SetPanExtent(50)

  -- Preserve location when scrolling up
  hooksecurefunc(self.ScrollBox, "scrollInternal", function()
    self.scrolling = self.ScrollBox:GetScrollPercentage() ~= 1 and self.ScrollBox:GetScrollInterpolator():GetInterpolateTo() ~= 1
    self.ScrollToBottomButton:SetShown(self.scrolling)
    self:UpdateAlphas()
  end)

  self.pauseAlphas = false
  self.ScrollBox:RegisterCallback("OnUpdate", self.UpdateAlphas, self)
  self.ScrollBox:RegisterCallback("OnScroll", self.UpdateAlphas, self)

  self.resizeWidget = CreateFrame("Button", nil, self)
  self.resizeWidget:SetSize(20, 22)
  self.resizeWidget:SetPoint("BOTTOMRIGHT", self.ScrollBox, -5,  0)
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

  self:RepositionBlizzardWidgets()

  addonTable.CallbackRegistry:RegisterCallback("Render", self.Render, self)
  addonTable.CallbackRegistry:RegisterCallback("ScrollToEndImmediate", function()
    self:SetTabSelected(self.tabIndex)
  end, self)

  addonTable.Core.InitializeTabs(self)

  addonTable.Skins.AddFrame("ChatFrame", self)

  addonTable.CallbackRegistry:RegisterCallback("RefreshStateChange", function(_, refreshState)
    if refreshState[addonTable.Constants.RefreshReason.Tabs] then
      addonTable.Core.InitializeTabs(self)
    end
    if refreshState[addonTable.Constants.RefreshReason.Locked] then
      self.resizeWidget:SetShown(not addonTable.Config.Get(addonTable.Config.Options.LOCKED))
    end
  end)
end

function addonTable.ChatFrameMixin:SavePosition()
  local point1, anchorFrame, point2, x, y = self:GetPoint(1)
  local anchorFrameName = anchorFrame and anchorFrame:GetName() or "UIParent"
  addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].position = {point1, anchorFrameName, point2, x, y}
end

function addonTable.ChatFrameMixin:SaveSize()
  local x, y = self:GetSize()
  addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].size = {x, y}
end

function addonTable.ChatFrameMixin:UpdateAlphas()
  if self.pauseAlphas then
    return
  end
  local oldAlphas = self.alphas
  self.alphas = {}
  for _, f in ipairs(self.ScrollBox:GetFrames()) do
    if f.data and f:IsVisible() then
      self.alphas[f.data] = oldAlphas[f.data] or 0

      local targetAlpha
      if f.DisplayString:GetBottom() - self.ScrollBox:GetTop() > -f.DisplayString:GetLineHeight() * 0.9 or f.DisplayString:GetTop() - self.ScrollBox:GetBottom() < f.DisplayString:GetLineHeight() * 0.9 then
        if f:GetAlpha() ~= 0.5 then
          targetAlpha = 0.5
        end
      elseif f:GetAlpha() ~= 1 then
        targetAlpha = 1
      end
      if targetAlpha then
        f.FadeAnimation.alpha:SetFromAlpha(f:GetAlpha())
        f.FadeAnimation.alpha:SetToAlpha(targetAlpha)
        f.FadeAnimation:Play()
        f.FadeAnimation:SetScript("OnUpdate", function()
          self.alphas[f.data] = f:GetAlpha()
        end)
      else
        f.FadeAnimation:Stop()
      end
    end
  end
end

function addonTable.ChatFrameMixin:RepositionBlizzardWidgets()
  if self:GetID() ~= 1 then
    return
  end

  -- We use the default edit box rather than instantiating our own so that the keyboard shortcuts to open it work
  ChatFrame1EditBox:SetParent(self)
  ChatFrame1EditBox:ClearAllPoints()
  ChatFrame1EditBox:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, 32)
  ChatFrame1EditBox:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, 32)
  addonTable.Skins.AddFrame("ChatEditBox", ChatFrame1EditBox)

  local function ArrangeButtons(buttons)
    local lastButton
    for _, b in ipairs(buttons) do
      b:ClearAllPoints()
      if lastButton == nil then
        b:SetPoint("TOPRIGHT", self.ScrollBox, "TOPLEFT", -5, 0)
      else
        b:SetPoint("TOP", lastButton, "BOTTOM", 0, -5)
      end
      lastButton = b
    end
  end
  local buttons = {}

  if QuickJoinToastButton then
    QuickJoinToastButton:SetParent(self)
    QuickJoinToastButton:SetScript("OnMouseDown", nil)
    QuickJoinToastButton:SetScript("OnMouseUp", nil)
    QuickJoinToastButton:ClearAllPoints()
    QuickJoinToastButton:SetPoint("BOTTOMRIGHT", self.ScrollBox, "TOPLEFT", -5, 35)
    hooksecurefunc(QuickJoinToastButton, "SetPoint", function(_, _, frame)
      if frame ~= self.ScrollBox then
        QuickJoinToastButton:SetPoint("BOTTOMRIGHT", self.ScrollBox, "TOPLEFT", -5, 35)
      end
    end)
    addonTable.Skins.AddFrame("ChatButton", QuickJoinToastButton, {"toasts"})
  end

  ChatFrameChannelButton:SetParent(self)
  ChatFrameChannelButton:ClearAllPoints()
  ChatFrameChannelButton:SetScript("OnMouseDown", nil)
  ChatFrameChannelButton:SetScript("OnMouseUp", nil)
  addonTable.Skins.AddFrame("ChatButton", ChatFrameChannelButton, {"channels"})
  table.insert(buttons, ChatFrameChannelButton)

  ChatFrameMenuButton:SetParent(self)
  ChatFrameMenuButton:ClearAllPoints()
  ChatFrameMenuButton:SetScript("OnMouseDown", nil)
  ChatFrameMenuButton:SetScript("OnMouseUp", nil)
  addonTable.Skins.AddFrame("ChatButton", ChatFrameMenuButton, {"menu"})
  table.insert(buttons, ChatFrameMenuButton)

  ChatFrameMenuButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(ChatFrameMenuButton, "ANCHOR_RIGHT")
    GameTooltip:SetText(WHITE_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.QUICK_CHAT))
    GameTooltip:Show()
  end)
  ChatFrameMenuButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  addonTable.Skins.AddFrame("ChatButton", ChatFrameMenuButton, {"menu"})

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
  table.insert(buttons, self.SearchButton)
  addonTable.Skins.AddFrame("ChatButton", self.SearchButton, {"search"})
  self.CopyButton = MakeButton(addonTable.Locales.COPY_CHAT)
  table.insert(buttons, self.CopyButton)
  addonTable.Skins.AddFrame("ChatButton", self.CopyButton, {"copy"})
  self.SettingsButton = MakeButton(SETTINGS)
  self.SettingsButton:SetScript("OnClick", function()
    addonTable.CustomiseDialog.Toggle()
  end)
  table.insert(buttons, self.SettingsButton)
  addonTable.Skins.AddFrame("ChatButton", self.SettingsButton, {"settings"})

  self.ScrollToBottomButton = MakeButton(addonTable.Locales.SCROLL_TO_END)
  self.ScrollToBottomButton:SetPoint("BOTTOMRIGHT", self.ScrollBox, "BOTTOMLEFT", -5, 5)
  self.ScrollToBottomButton:SetScript("OnClick", function()
    self.ScrollBox:ScrollToEnd()
  end)
  addonTable.Skins.AddFrame("ChatButton", self.ScrollToBottomButton, {"scrollToEnd"})

  ArrangeButtons(buttons)
end

function addonTable.ChatFrameMixin:SetFilter(func)
  self.filterFunc = func
end

function addonTable.ChatFrameMixin:SetBackgroundColor(r, g, b)
  self.backgroundColor = {r= r, g = g, b = b}
end

function addonTable.ChatFrameMixin:SetTabSelected(index)
  self.tabIndex = index
  self.tabChanged = true
end

function addonTable.ChatFrameMixin:FilterMessages()
  local result1, result2 = {}, {}
  local data = addonTable.Messages:GetMessage(1)
  local index = 1
  local limit = addonTable.Config.Get(addonTable.Config.Options.ROWS_LIMIT)
  while #result1 < limit and data do
    if (
      data.recordedBy == addonTable.Data.CharacterName and
      (not self.filterFunc or self.filterFunc(data))
    ) then
      table.insert(result1, 1, data)
      table.insert(result2, 1, addonTable.Messages:GetMessageHeight(index))
    end
    index = index + 1
    data = addonTable.Messages:GetMessage(index)
  end
  return result1, result2
end

function addonTable.ChatFrameMixin:Render(newMessages)
  if newMessages and self.filterFunc and next(tFilter(newMessages, self.filterFunc)) == nil then
    return
  end
  local filteredMessages, heights = self:FilterMessages()
  self.heights = heights

  local lowest, data = nil, nil
  for _, f in ipairs(self.ScrollBox:GetFrames()) do
    local testLow = f:GetBottom()
    if not lowest or testLow < lowest then
      data = f.data
      lowest = testLow
    end
  end
  local extent
  if data then
    extent = self.ScrollBox:GetExtentUntil(self.ScrollBox:FindElementDataIndex(data)) - self.ScrollBox:GetDerivedScrollOffset()
  end
  self.pauseAlphas = true
  self.ScrollBox:SetDataProvider(CreateDataProvider(filteredMessages), true)
  if not self.scrolling or self.tabChanged then
    self.ScrollBox:ScrollToEnd(self.tabChanged)
  elseif data then
    local newIndex = tIndexOf(filteredMessages, data)
    if newIndex then
      local diff = extent - (self.ScrollBox:GetExtentUntil(newIndex) - self.ScrollBox:GetDerivedScrollOffset())
      self.ScrollBox:SetScrollPercentage(self.ScrollBox:GetScrollPercentage() - diff / self.ScrollBox:GetDerivedScrollRange(), true)
    end
  end
  self.pauseAlphas = false
  self:UpdateAlphas()
  self.tabChanged = false
end
