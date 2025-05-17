---@class addonTableChatanator
local addonTable = select(2, ...)

---@class Frame
addonTable.ChatFrameMixin = {}

function addonTable.ChatFrameMixin:OnLoad()
  self:SetHyperlinkPropagateToParent(true)

  self.filterFunc = nil
  self.messages = {}
  self.filteredMessages = self.messages
  self.font = "GameFontNormal"

  self.sizingFontString = self:CreateFontString(nil, "BACKGROUND", self.font)

  self.sizingFontString:SetText("00:00:00")
  self.inset = self.sizingFontString:GetUnboundedStringWidth() + 20

  self.sizingFontString:SetPoint("TOPLEFT", self.inset, 0)
  self.sizingFontString:SetPoint("TOPRIGHT", -10, 0)
  self.sizingFontString:Hide()

  self.ScrollBox = CreateFrame("Frame", nil, self, "WowScrollBoxList")
  local view = CreateScrollBoxListLinearView()
  view:SetElementExtentCalculator(function(index)
    return self.filteredMessages[index].height
  end)
  view:SetElementInitializer("Frame", function(frame, data)
    if not frame.initialized then
      frame.initialized = true
      frame:SetHyperlinkPropagateToParent(true)
      frame.DisplayString = frame:CreateFontString(nil, "ARTWORK", self.font)
      frame.DisplayString:SetPoint("TOPLEFT", self.inset, 0)
      frame.DisplayString:SetPoint("RIGHT", -10, 0)
      frame.DisplayString:SetJustifyH("LEFT")
      frame.Timestamp = frame:CreateFontString(nil, "ARTWORK", self.font)
      frame.Timestamp:SetPoint("TOPLEFT", 10, 0)
      frame.Timestamp:SetJustifyH("LEFT")
      frame.Timestamp:SetTextColor(0.5, 0.5, 0.5)
    end
    if data.font ~= self.font or data.width ~= self:GetWidth() then
      self.sizingFontString:SetText(data.text)
      data.height = self.sizingFontString:GetLineHeight() * self.sizingFontString:GetNumLines()
    end
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
  self.ScrollBox:SetPanExtent(50)

  -- Preserve location when scrolling up
  hooksecurefunc(self.ScrollBox, "scrollInternal", function()
    self.scrolling = self.ScrollBox:GetScrollPercentage() ~= 1
  end)
end

function addonTable.ChatFrameMixin:SetFilter(func)
  self.filterFunc = func
end

function addonTable.ChatFrameMixin:SetIncomingType(eventType)
  self.incomingType = eventType
end

function addonTable.ChatFrameMixin:AddMessage(text, r, g, b, id)
  local data = {
    text = text,
    color = CreateColor(r or 1, g or 1, b or 1),
    timestamp = time(),
    id = id,
    typeInfo = self.incomingType or {type = "MANUAL", source = "UNKNOWN"},
  }
  self.incomingType = nil
  if data.font ~= self.font or data.width ~= self:GetWidth() then
    data.font = self.font
    data.width = self:GetWidth()
    self.sizingFontString:SetText(data.text)
    data.height = (self.sizingFontString:GetLineHeight() + self.sizingFontString:GetSpacing()) * self.sizingFontString:GetNumLines()
  end
  table.insert(self.messages, data)
  self:SetScript("OnUpdate", self.Render)
end

function addonTable.ChatFrameMixin:Render()
  self:SetScript("OnUpdate", nil)
  if self.filterFunc then
    self.filteredMessages = tFilter(self.messages, self.filterFunc, true)
  else
    self.filteredMessages = self.messages
  end
  self.ScrollBox:SetDataProvider(CreateDataProvider(self.filteredMessages), true)
  if not self.scrolling then
    self.ScrollBox:ScrollToEnd()
  end
end
