---@class addonTableChatanator
local addonTable = select(2, ...)

---@class Frame
addonTable.ChatFrameMixin = {}

function addonTable.ChatFrameMixin:OnLoad()
  self:SetHyperlinkPropagateToParent(true)

  self.messages = {}
  self.font = "GameFontNormal"

  self.sizingFontString = self:CreateFontString(nil, "BACKGROUND", self.font)
  self.sizingFontString:SetPoint("TOPLEFT", 80, 0)
  self.sizingFontString:SetPoint("TOPRIGHT", -10, 0)
  self.sizingFontString:Hide()

  self.ScrollBox = CreateFrame("Frame", nil, self, "WowScrollBoxList")
  local view = CreateScrollBoxListLinearView()
  view:SetElementExtentCalculator(function(index)
    return self.messages[index].height
  end)
  view:SetElementInitializer("Frame", function(frame, data)
    if not frame.initialized then
      frame.initialized = true
      frame:SetHyperlinkPropagateToParent(true)
      frame.DisplayString = frame:CreateFontString(nil, "ARTWORK", self.font)
      frame.DisplayString:SetPoint("TOPLEFT", 80, 0)
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
    frame.DisplayString:SetTextColor(data.r or 1, data.g or 1, data.b or 1)
  end)
  self.ScrollBox:SetAllPoints(self)
  self.ScrollBox:Init(view)
  self.ScrollBox:SetHyperlinkPropagateToParent(true)
  self.ScrollBox:GetScrollTarget():SetHyperlinkPropagateToParent(true)
  self.ScrollBox:GetScrollTarget():SetPropagateMouseClicks(true)
end

function addonTable.ChatFrameMixin:AddMessage(text, r, g, b, id)
  local data = {
    text = text,
    color = CreateColor(r, g, b),
    timestamp = GetTime(),
    id = id,
  }
  if data.font ~= self.font or data.width ~= self:GetWidth() then
    data.font = self.font
    data.width = self:GetWidth()
    self.sizingFontString:SetText(data.text)
    data.height = (self.sizingFontString:GetLineHeight() + self.sizingFontString:GetSpacing()) * self.sizingFontString:GetNumLines()
  end
  table.insert(self.messages, data)
  self:Render()
end

function addonTable.ChatFrameMixin:Render()
  self.ScrollBox:SetDataProvider(CreateDataProvider(self.messages))
  self.ScrollBox:ScrollToEnd()
end
