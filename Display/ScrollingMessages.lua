---@class addonTableChattynator
local addonTable = select(2, ...)

local rightInset = 3

---@class DisplayScrollingMessages: Frame
addonTable.Display.ScrollingMessagesMixin = {}

function addonTable.Display.ScrollingMessagesMixin:MyOnLoad()
  self:SetHyperlinkPropagateToParent(true)
  self:SetHyperlinksEnabled(true)

  self:SetFontObject(addonTable.Messages.font)
  self:SetTextColor(1, 1, 1)
  self:SetJustifyH("LEFT")
  self:SetIndentedWordWrap(true)

  self:SetTimeVisible(addonTable.Config.Get(addonTable.Config.Options.MESSAGE_FADE_TIME))

  self:SetScript("OnMouseWheel", function(_, delta)
    if delta > 0 then
      self:ScrollUp()
    else
      self:ScrollDown()
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("MessageDisplayChanged", function()
    self:SetFontObject(addonTable.Messages.font)
    self:SetTextColor(1, 1, 1)
    self:SetScale(addonTable.Core.GetFontScalingFactor())
  end)
end

function addonTable.Display.ScrollingMessagesMixin:SetFilter(filterFunc)
  self.filterFunc = filterFunc
end

function addonTable.Display.ScrollingMessagesMixin:Render(newMessages)
  if newMessages == nil then
    self:Clear()
    newMessages = 200
  end
  local index = 1
  local messages = {}
  while index <= newMessages do
    local m = addonTable.Messages:GetMessageRaw(index)
    if not m then
      break
    end
    if m.recordedBy == addonTable.Data.CharacterName and (not self.filterFunc or self.filterFunc(m)) then
      m = addonTable.Messages:GetMessageProcessed(index)
      table.insert(messages, m)
    end
    index = index + 1
  end

  if #messages > 0 then
    for i = #messages, 1, -1 do
      local m = messages[i]
      self:AddMessage("|cff989898" .. date(addonTable.Messages.timestampFormat, m.timestamp) .. " || |r" .. m.text, m.color.r, m.color.g, m.color.b)
    end
  end
end
