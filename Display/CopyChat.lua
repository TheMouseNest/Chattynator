---@class addonTableChattynator
local addonTable = select(2, ...)

---@class ButtonFrameTemplate
addonTable.Display.CopyChatMixin = {}

function addonTable.Display.CopyChatMixin:OnLoad()
  self:Hide()

  self:SetToplevel(true)
  table.insert(UISpecialFrames, self:GetName())
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()
  self:EnableMouse(true)
  self:SetScript("OnMouseWheel", function() end)

  self.textBox = CreateFrame("Frame", nil, self, "ScrollingEditBoxTemplate")
  self.textBox:SetPoint("TOPLEFT", addonTable.Constants.ButtonFrameOffset + 10, -30)
  self.textBox:SetPoint("BOTTOMRIGHT", -10, 10)

  self:SetSize(600, 600)
  self:SetPoint("CENTER")
  self:SetTitle(addonTable.Locales.COPY_CHAT)

  addonTable.Skins.AddFrame("ButtonFrame", self, {"copyChat"})
end

function addonTable.Display.CopyChatMixin:LoadMessages(filterFunc, indexOffset)
  local messages = {}
  local index = indexOffset or 1
  while #messages < 200 do
    local m = addonTable.Messages:GetMessageRaw(index)
    if not m then
      break
    end
    if m.recordedBy == addonTable.Data.CharacterName and (not filterFunc or filterFunc(m)) then
      m = addonTable.Messages:GetMessageProcessed(index)
      local color = CreateColor(m.color.r, m.color.g, m.color.b)
      local text = color:WrapTextInColorCode(m.text):gsub("|K(.-)|k", "|ck%1|r")
      text = StripHyperlinks(text, true, true, false, false)
      text = text:gsub("|ck(.-)|r", "|K%1|k")
      table.insert(messages, 1, text)
    end
    index = index + 1
  end

  self.textBox:SetText(table.concat(messages, "\n"))
  self.textBox:GetEditBox():HighlightText(0, #self.textBox:GetText())
  C_Timer.After(0, function()
    self.textBox:SetFocus()
    C_Timer.After(0, function()
      self.textBox:GetScrollBox():ScrollToEnd()
    end)
  end)

  self:Show()
end
