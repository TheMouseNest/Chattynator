---@class addonTableChattynator
local addonTable = select(2, ...)

---@class ButtonFrameTemplate
addonTable.Display.CopyChatMixin = {}

local substitutions = {
  {"%f[|]|K.-%f[|]|k", "???"},
  {"%f[|]|W.-%f[|]|w", "???"},
  {"%f[|]|T.-%f[|]|t", "???"},
  {"%f[|]|A:Professions%-ChatIcon%-Quality%-Tier(%d):.-%f[|]|a", "%1*"},
  {"%f[|]|A.-%f[|]|a", "???"},
  {"%f[|]|H.-%f[|]|h(.-)%f[|]|h", "%1"}
}

local function CustomCleanup(text)
  for _, p in ipairs(substitutions) do
    text = text:gsub(p[1], p[2])
  end
  return text
end

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

  self:SetSize(800, 600)
  self:SetPoint("CENTER")
  self:SetTitle(addonTable.Locales.COPY_CHAT)

  self.clicks = {0, 0, 0}
  self.textBox:GetEditBox():HookScript("OnMouseDown",
    ---@param editBox EditBox
    function(editBox)
      if GetTime() - self.clicks[#self.clicks] < 0.5 then
        local pattern = "[%s%p]"
        local cursorPosition = editBox:GetCursorPosition()
        local text = editBox:GetText()
        if self.clicks[#self.clicks] - self.clicks[#self.clicks - 1] < 0.5 then
          pattern = "\n"
        end
        if text:sub(cursorPosition + 1, cursorPosition + 1):match(pattern) then
          if cursorPosition > 0 then
            cursorPosition = cursorPosition - 1
          else
            cursorPosition = cursorPosition + 1
          end
        end
        local startPos = cursorPosition
        local endPos = cursorPosition
        while startPos > 0 and not text:sub(startPos, startPos):match(pattern) do
          startPos = startPos - 1
        end
        while startPos >= endPos and endPos < #text do
          endPos = endPos + 1
        end
        while endPos < #text and not text:sub(endPos, endPos):match(pattern) do
          endPos = endPos + 1
        end
        if text:sub(endPos, endPos):match(pattern) then
          endPos = endPos - 1
        end
        C_Timer.After(0, function()
          editBox:HighlightText(startPos, endPos)
        end)
      end
      table.insert(self.clicks, GetTime())
      if #self.clicks > 3 then
        table.remove(self.clicks, 1)
      end
  end)

  addonTable.Skins.AddFrame("ButtonFrame", self, {"copyChat"})
end

function addonTable.Display.CopyChatMixin:LoadMessages(filterFunc, indexOffset)
  self:SetParent(ChattynatorHyperlinkHandler:GetParent())
  local messages = {}
  local index = indexOffset or 1
  local showTimestamp = addonTable.Config.Get(addonTable.Config.Options.COPY_TIMESTAMPS)
  local timestampFormat = addonTable.Messages.timestampFormat
  if timestampFormat == " " then
    showTimestamp = false
  end
  while #messages < 200 do
    local m = addonTable.Messages:GetMessageRaw(index)
    if not m then
      break
    end
    if m.recordedBy == addonTable.Data.CharacterName and (not filterFunc or filterFunc(m)) then
      m = addonTable.Messages:GetMessageProcessed(index)
      local color = CreateColor(m.color.r, m.color.g, m.color.b)
      local timestamp = ""
      if showTimestamp then
        timestamp = GRAY_FONT_COLOR:WrapTextInColorCode("[" .. date(timestampFormat, m.timestamp) .. "] ")
      end
      local text = timestamp .. color:WrapTextInColorCode(m.text):gsub("|K(.-)|k", "???")
      text = CustomCleanup(text)
      table.insert(messages, 1, text)
    end
    index = index + 1
  end

  self.textBox:SetText(table.concat(messages, "\n"))
  self.textBox:GetEditBox():HighlightText(0, #self.textBox:GetEditBox():GetText())
  C_Timer.After(0, function()
    self.textBox:SetFocus()
    C_Timer.After(0, function()
      self.textBox:GetScrollBox():ScrollToEnd()
    end)
  end)

  self:Show()
end
