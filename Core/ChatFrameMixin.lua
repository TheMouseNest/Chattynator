---@class addonTableChatanator
local addonTable = select(2, ...)

---@class ChatFrameMixin: Frame
addonTable.ChatFrameMixin = {}

local rightInset = 10

function addonTable.ChatFrameMixin:OnLoad()
  self:SetHyperlinkPropagateToParent(true)
  self:SetMovable(true)
  self:SetResizable(true)

  self.filterFunc = nil
  self.filteredMessages = addonTable.Messages.messages

  self.ScrollBox = CreateFrame("Frame", nil, self, "WowScrollBoxList")
  local view = CreateScrollBoxListLinearView()
  view:SetElementExtentCalculator(function(index)
    return self.filteredMessages[index].height[self.key]
  end)
  local oldWidth = 0
  self:SetScript("OnSizeChanged", function(_, width, height)
    width = math.floor(width - addonTable.Messages.inset - rightInset)
    addonTable.Messages:RegisterWidth(width)
    addonTable.Messages:UnregisterWidth(oldWidth)
    oldWidth = width
    self.key = addonTable.Messages.font .. " " .. width
    self:Render()
  end)
  view:SetElementInitializer("Frame", function(frame, data)
    if not frame.initialized then
      frame.initialized = true
      frame:SetHyperlinkPropagateToParent(true)
      frame.DisplayString = frame:CreateFontString(nil, "ARTWORK", addonTable.Messages.font)
      frame.DisplayString:SetPoint("TOPLEFT", addonTable.Messages.inset, 0)
      frame.DisplayString:SetPoint("RIGHT", -rightInset, 0)
      frame.DisplayString:SetJustifyV("TOP")
      frame.DisplayString:SetJustifyH("LEFT")
      frame.DisplayString:SetNonSpaceWrap(true)
      frame.DisplayString:SetWordWrap(true)
      frame.Timestamp = frame:CreateFontString(nil, "ARTWORK", addonTable.Messages.font)
      frame.Timestamp:SetPoint("TOPLEFT", 10, 0)
      frame.Timestamp:SetJustifyH("LEFT")
      frame.Timestamp:SetTextColor(0.5, 0.5, 0.5)
      frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Type: " .. tostring(frame.data.typeInfo.type))
        GameTooltip:AddLine("Event: " .. tostring(frame.data.typeInfo.event))
        GameTooltip:AddLine("Source: " .. tostring(frame.data.typeInfo.source))
        GameTooltip:AddLine("Channel: " .. tostring(frame.data.typeInfo.channel))
        GameTooltip:AddLine("Color: " .. frame.data.color:GenerateHexColorNoAlpha())
        GameTooltip:Show()
      end)
      frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)
      frame:SetPropagateMouseClicks(true)
      frame:SetPropagateMouseMotion(true)
    end
    frame.data = data
    frame.Timestamp:SetText(date("%X", data.timestamp))
    frame.DisplayString:SetText(data.text)
    frame.DisplayString:SetTextColor(data.color.r, data.color.g, data.color.b)
  end)
  self.ScrollBox:SetAllPoints(self)
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
  self.background:SetPoint("TOPLEFT", 0, 5)
  self.background:SetPoint("BOTTOMRIGHT", 0, -5)
  self.background:SetAlpha(0.8)

  self.resizeWidget = CreateFrame("Button", nil, self)
  self.resizeWidget:SetSize(25, 27.5)
  self.resizeWidget:SetPoint("BOTTOMRIGHT", -5,  0)
  self.resizeWidget:RegisterForDrag("LeftButton")
  self.resizeWidget:SetScript("OnDragStart", function()
    self:StartSizing("BOTTOMRIGHT")
  end)
  self.resizeWidget:SetScript("OnDragStop", function()
    self:StopMovingOrSizing()
  end)
  local tex = self.resizeWidget:CreateTexture(nil, "ARTWORK")
  tex:SetTexture("Interface/AddOns/Chatanator/Assets/resize.png")
  tex:SetAllPoints()
  self.resizeWidget:SetScript("OnEnter", function()
    tex:SetVertexColor(59/255, 210/255, 237/255)
  end)
  self.resizeWidget:SetScript("OnLeave", function()
    tex:SetVertexColor(1, 1, 1)
  end)

  self:RepositionEditBox()

  addonTable.CallbackRegistry:RegisterCallback("Render", self.Render, self)
end

function addonTable.ChatFrameMixin:RepositionEditBox()
  ChatFrame1EditBox:ClearAllPoints()
  ChatFrame1EditBox:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
  ChatFrame1EditBox:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT")
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

function addonTable.ChatFrameMixin:Render(newMessages)
  if newMessages and self.filterFunc and next(tFilter(newMessages, self.filterFunc)) == nil then
    return
  end
  if self.filterFunc then
    self.filteredMessages = tFilter(addonTable.Messages.messages, self.filterFunc, true)
  else
    self.filteredMessages = addonTable.Messages.messages
  end
  self.ScrollBox:SetDataProvider(CreateDataProvider(self.filteredMessages), true)
  if not self.scrolling or self.tabChanged then
    self.ScrollBox:ScrollToEnd(self.tabChanged)
  end
  self.tabChanged = false
end
