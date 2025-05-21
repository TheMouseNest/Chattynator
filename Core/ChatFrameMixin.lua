---@class addonTableChatanator
local addonTable = select(2, ...)

---@class ChatFrameMixin: Frame
addonTable.ChatFrameMixin = {}

local rightInset = 10
local intensity = 0.8

function addonTable.ChatFrameMixin:OnLoad()
  self:SetHyperlinkPropagateToParent(true)
  self:SetMovable(true)
  self:SetResizable(true)
  self:SetClampedToScreen(true)

  self:SetPoint(unpack(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].position))
  self:SetSize(unpack(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].size))

  self.filterFunc = nil
  self.heights = {}

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
      frame.DisplayString:SetPoint("TOPLEFT", addonTable.Messages.inset, 0)
      frame.DisplayString:SetJustifyV("TOP")
      frame.DisplayString:SetJustifyH("LEFT")
      frame.DisplayString:SetNonSpaceWrap(true)
      frame.DisplayString:SetWordWrap(true)
      frame.Timestamp = frame:CreateFontString(nil, "ARTWORK", addonTable.Messages.font)
      frame.Timestamp:SetPoint("TOPLEFT", 0, 0)
      frame.Timestamp:SetJustifyH("LEFT")
      frame.Timestamp:SetTextColor(0.5, 0.5, 0.5)
      frame:SetScript("OnEnter", function()
        if addonTable.Config.Get(addonTable.Config.Options.DEBUG) then
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:SetText("Type: " .. tostring(frame.data.typeInfo.type))
          GameTooltip:AddLine("Event: " .. tostring(frame.data.typeInfo.event))
          GameTooltip:AddLine("Source: " .. tostring(frame.data.typeInfo.source))
          GameTooltip:AddLine("Recorder: " .. tostring(frame.data.recordedCharacter))
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
      frame.Fading = frame:CreateTexture(nil, "BACKGROUND")
      frame.Fading:SetTexture("Interface/AddOns/Chatanator/Assets/Fade.png")
      frame.Fading:SetPoint("RIGHT", frame.DisplayString, "LEFT", -4, 0)
      frame.Fading:SetPoint("TOP", 0, 0)
      frame.Fading:SetPoint("BOTTOM", 0, 1 + 5)
      frame.Fading:SetWidth(2)
    end
    frame.DisplayString:SetWidth(self.currentStringWidth)
    frame.data = data
    frame.Timestamp:SetText(date("%X", data.timestamp))
    frame.DisplayString:SetText(data.text)
    frame.DisplayString:SetTextColor(data.color.r, data.color.g, data.color.b)
  end)
  self.ScrollBox:SetPoint("TOPLEFT", 32, -27)
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
    self.scrolling = self.ScrollBox:GetScrollPercentage() ~= 1
  end)

  self.background = self:CreateTexture(nil, "BACKGROUND")
  self.background:SetTexture("Interface/AddOns/Chatanator/Assets/ChatTabMiddle")
  self.background:SetTexCoord(0, 1, 1, 0)
  self.background:SetPoint("TOP", self.ScrollBox, 0, 5)
  self.background:SetPoint("LEFT")
  self.background:SetPoint("BOTTOMRIGHT", self.ScrollBox, 0, -5)
  self.background:SetAlpha(0.8)

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
  local tex = self.resizeWidget:CreateTexture(nil, "ARTWORK")
  tex:SetVertexColor(intensity, intensity, intensity)
  tex:SetTexture("Interface/AddOns/Chatanator/Assets/resize.png")
  tex:SetAllPoints()
  self.resizeWidget:SetScript("OnEnter", function()
    tex:SetVertexColor(59/255, 210/255, 237/255)
  end)
  self.resizeWidget:SetScript("OnLeave", function()
    tex:SetVertexColor(1, 1, 1)
  end)

  self:RepositionBlizzardWidgets()

  addonTable.CallbackRegistry:RegisterCallback("Render", self.Render, self)
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

function addonTable.ChatFrameMixin:RepositionBlizzardWidgets()
  if self:GetID() ~= 1 then
    return
  end

  -- We use the default edit box rather than instantiating our own so that the keyboard shortcuts to open it work
  ChatFrame1EditBox:SetParent(self)
  ChatFrame1EditBox:ClearAllPoints()
  ChatFrame1EditBox:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, 32)
  ChatFrame1EditBox:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, 32)

  for _, texName in ipairs({"Left", "Right", "Mid", "FocusLeft", "FocusRight", "FocusMid"}) do
    _G[ChatFrame1EditBox:GetName() .. texName]:SetParent(addonTable.hiddenFrame)
  end
  local background = ChatFrame1EditBox:CreateTexture(nil, "BACKGROUND")
  background:SetColorTexture(0.1, 0.1, 0.1, 0.8)
  background:SetPoint("TOPLEFT", ChatFrame1EditBox)
  background:SetPoint("BOTTOM", ChatFrame1EditBox)
  background:SetPoint("RIGHT", self)

  local function RestyleButton(button)
    button:SetSize(26, 28)
    button:SetNormalTexture("Interface/AddOns/Chatanator/Assets/ChatButton.png")
    button:GetNormalTexture():SetVertexColor(0.15, 0.15, 0.15)
    button:GetNormalTexture():SetDrawLayer("BACKGROUND")
    button:SetPushedTexture("Interface/AddOns/Chatanator/Assets/ChatButton.png")
    button:GetPushedTexture():SetVertexColor(0, 0, 0)
    button:GetPushedTexture():SetDrawLayer("BACKGROUND")
  end

  QuickJoinToastButton:SetParent(self)
  QuickJoinToastButton:ClearAllPoints()
  QuickJoinToastButton:SetPoint("RIGHT", self.ScrollBox, "LEFT", -3, 0)
  QuickJoinToastButton:SetPoint("TOP", self.ScrollBox)
  RestyleButton(QuickJoinToastButton)
  QuickJoinToastButton:SetScript("OnMouseDown", function()
    QuickJoinToastButton.FriendsButton:SetPoint("TOP", 2, -4)
  end)
  QuickJoinToastButton:SetScript("OnMouseUp", function()
    QuickJoinToastButton.FriendsButton:SetPoint("TOP", 0, -2)
  end)
  QuickJoinToastButton.FriendsButton:SetTexture("Interface/AddOns/Chatanator/Assets/ChatSocial.png")
  QuickJoinToastButton.FriendsButton:SetVertexColor(intensity, intensity, intensity)
  QuickJoinToastButton.FriendsButton:SetDrawLayer("ARTWORK")
  QuickJoinToastButton.FriendsButton:SetSize(12, 12)
  QuickJoinToastButton.FriendsButton:ClearAllPoints()
  QuickJoinToastButton.FriendsButton:SetPoint("TOP", 0, -2)

  ChatFrameChannelButton:SetParent(self)
  ChatFrameChannelButton:ClearAllPoints()
  ChatFrameChannelButton:SetPoint("TOP", QuickJoinToastButton, "BOTTOM", 0, -5)
  RestyleButton(ChatFrameChannelButton)
  ChatFrameChannelButton.Icon:SetTexture("Interface/Addons/Chatanator/Assets/ChatChannels.png")
  ChatFrameChannelButton.Icon:SetVertexColor(intensity, intensity, intensity)
  ChatFrameChannelButton:SetScript("OnMouseDown", function()
    ChatFrameChannelButton.Icon:SetPoint("CENTER", 2, -2)
  end)
  ChatFrameChannelButton:SetScript("OnMouseUp", function()
    ChatFrameChannelButton.Icon:SetPoint("CENTER", 0, 0)
  end)

  ChatFrameMenuButton:SetParent(self)
  ChatFrameMenuButton:ClearAllPoints()
  ChatFrameMenuButton:SetPoint("TOP", ChatFrameChannelButton, "BOTTOM", 0, -5)
  RestyleButton(ChatFrameMenuButton)
  ChatFrameMenuButton.Icon = ChatFrameMenuButton:CreateTexture(nil, "ARTWORK")
  ChatFrameMenuButton.Icon:SetTexture("Interface/AddOns/Chatanator/Assets/ChatMenu.png")
  ChatFrameMenuButton.Icon:SetVertexColor(intensity, intensity, intensity)
  ChatFrameMenuButton.Icon:SetPoint("CENTER")
  ChatFrameMenuButton.Icon:SetSize(15, 15)
  ChatFrameMenuButton:SetScript("OnMouseDown", function()
    ChatFrameMenuButton.Icon:SetPoint("CENTER", 2, -2)
  end)
  ChatFrameMenuButton:SetScript("OnMouseUp", function()
    ChatFrameMenuButton.Icon:SetPoint("CENTER", 0, 0)
  end)

  ChatFrameMenuButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(ChatFrameMenuButton, "ANCHOR_RIGHT")
    GameTooltip:SetText(WHITE_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.QUICK_CHAT))
    GameTooltip:Show()
  end)
  ChatFrameMenuButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  local function MakeButton(texture, tooltipText)
    local button = CreateFrame("Button", nil, self)
    button:SetNormalTexture("Interface/AddOns/Chatanator/Assets/ChatButton.png")
    button:GetNormalTexture():SetVertexColor(0.15, 0.15, 0.15)
    button:SetPushedTexture("Interface/AddOns/Chatanator/Assets/ChatButton.png")
    button:GetPushedTexture():SetVertexColor(0, 0, 0)
    button.Icon = button:CreateTexture(nil, "OVERLAY")
    button.Icon:SetTexture(texture)
    button:SetScript("OnMouseDown", function()
      button.Icon:SetPoint("CENTER", 2, -2)
    end)
    button:SetScript("OnMouseUp", function()
      button.Icon:SetPoint("CENTER", 0, 0)
    end)
    button.Icon:SetPoint("CENTER")
    button.Icon:SetSize(15, 15)
    button.Icon:SetVertexColor(intensity, intensity, intensity)
    button:SetHighlightAtlas("chatframe-button-highlight")
    button:SetSize(26, 28)

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

  self.SearchButton = MakeButton("Interface/AddOns/Chatanator/Assets/Search.png", SEARCH)
  self.SearchButton:SetPoint("TOP", ChatFrameMenuButton, "BOTTOM", 0, -5)
  self.CopyButton = MakeButton("Interface/AddOns/Chatanator/Assets/Copy.png", addonTable.Locales.COPY_CHAT)
  self.CopyButton:SetPoint("TOP", self.SearchButton, "BOTTOM", 0, -5)
  self.SettingsButton = MakeButton("Interface/AddOns/Chatanator/Assets/SettingsCog.png", SETTINGS)
  self.SettingsButton:SetPoint("TOP", self.CopyButton, "BOTTOM", 0, -5)
end

function addonTable.ChatFrameMixin:SetFilter(func)
  self.filterFunc = func
end

function addonTable.ChatFrameMixin:SetBackgroundColor(r, g, b)
  self.background:SetVertexColor(r, g, b)
end

function addonTable.ChatFrameMixin:SetTabChanged()
  self.tabChanged = true
end

function addonTable.ChatFrameMixin:FilterMessages()
  local result1, result2 = {}, {}
  local data = addonTable.Messages:GetMessage(1)
  local index = 1
  local limit = addonTable.Config.Get(addonTable.Config.Options.ROWS_LIMIT)
  while #result1 < limit and data do
    if (
      (data.recordedCharacter == addonTable.Data.CharacterName or not addonTable.Messages:ShouldLog(data)) and
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
  self.ScrollBox:SetDataProvider(CreateDataProvider(filteredMessages), true)
  if not self.scrolling or self.tabChanged then
    self.ScrollBox:ScrollToEnd(self.tabChanged)
  end
  self.tabChanged = false
end
